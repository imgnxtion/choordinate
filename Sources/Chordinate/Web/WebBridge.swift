import AppKit
import Combine
import Foundation
import WebKit

// Simple event envelope for JS <-> Swift bridge
private struct BridgeMessage: Decodable {
    let type: String
    let payload: Data?  // raw JSON payload, decoded per message type

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        type = try container.decode(String.self, forKey: .type)
        if let any = try? container.decode(AnyCodable.self, forKey: .payload) {
            payload = try? JSONSerialization.data(withJSONObject: any.value, options: [])
        } else {
            payload = nil
        }
    }

    private enum CodingKeys: String, CodingKey { case type, payload }
}

// Helper to decode arbitrary JSON into Foundation object
private struct AnyCodable: Decodable {
    let value: Any
    init(from decoder: Decoder) throws {
        let c = try decoder.singleValueContainer()
        if let v = try? c.decode(String.self) {
            value = v
            return
        }
        if let v = try? c.decode(Bool.self) {
            value = v
            return
        }
        if let v = try? c.decode(Int.self) {
            value = v
            return
        }
        if let v = try? c.decode(Double.self) {
            value = v
            return
        }
        if let v = try? c.decode([String: AnyCodable].self) {
            value = v.mapValues { $0.value }
            return
        }
        if let v = try? c.decode([AnyCodable].self) {
            value = v.map { $0.value }
            return
        }
        throw DecodingError.dataCorruptedError(in: c, debugDescription: "Unsupported JSON type")
    }
}

final class WebBridge: NSObject, WKScriptMessageHandler {
    private weak var webView: WKWebView?
    private let store: ChordStore
    private let engine: ChordEngine
    private let recorder: ChordRecorder
    private var cancellables = Set<AnyCancellable>()

    init(webView: WKWebView, store: ChordStore, engine: ChordEngine, recorder: ChordRecorder) {
        self.webView = webView
        self.store = store
        self.engine = engine
        self.recorder = recorder
        super.init()
        observeState()
    }

    // MARK: - Observe Swift state and push updates to JS
    private func observeState() {
        store.$bindings
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in self?.sendBindings() }
            .store(in: &cancellables)

        engine.$detectionEnabled
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in self?.sendDetectionEnabled() }
            .store(in: &cancellables)

        engine.$lastTriggered
            .receive(on: DispatchQueue.main)
            .sink { [weak self] binding in
                guard let self else { return }
                let payload: [String: Any] = [
                    "binding": binding.flatMap { try? self.encodeJSON($0) } ?? NSNull()
                ]
                self.send(event: "lastTriggered", payload: payload)
            }
            .store(in: &cancellables)
    }

    func sendInitialState() {
        sendBindings()
        sendDetectionEnabled()
    }

    private func sendBindings() {
        let payload: [String: Any] = [
            "bindings": (try? encodeJSONArray(store.bindings)) ?? []
        ]
        send(event: "bindingsChanged", payload: payload)
    }

    private func sendDetectionEnabled() {
        let payload: [String: Any] = ["enabled": engine.detectionEnabled]
        send(event: "detectionChanged", payload: payload)
    }

    private func send(event: String, payload: [String: Any]) {
        guard let webView else { return }
        if let data = try? JSONSerialization.data(withJSONObject: payload),
            let json = String(data: data, encoding: .utf8)
        {
            let js =
                "window.chordinate && window.chordinate.__dispatch(\"\") + event + \"\", " + json
                + ");"
            webView.evaluateJavaScript(js, completionHandler: nil)
        }
    }

    private func encodeJSON<T: Encodable>(_ value: T) throws -> [String: Any] {
        let data = try JSONEncoder().encode(value)
        let obj = try JSONSerialization.jsonObject(with: data, options: [])
        return obj as? [String: Any] ?? [:]
    }

    private func encodeJSONArray<T: Encodable>(_ value: T) throws -> [Any] {
        let data = try JSONEncoder().encode(value)
        let obj = try JSONSerialization.jsonObject(with: data, options: [])
        return obj as? [Any] ?? []
    }

    // MARK: - WKScriptMessageHandler
    func userContentController(
        _ userContentController: WKUserContentController, didReceive message: WKScriptMessage
    ) {
        guard message.name == "bridge" else { return }
        guard let body = message.body as? [String: Any] else { return }
        do {
            let data = try JSONSerialization.data(withJSONObject: body, options: [])
            let msg = try JSONDecoder().decode(BridgeMessage.self, from: data)
            handle(message: msg)
        } catch {
            NSLog("Bridge decode error: \(error.localizedDescription)")
        }
    }

    private func handle(message: BridgeMessage) {
        switch message.type {
        case "ready":
            sendInitialState()
        case "setDetectionEnabled":
            if let data = message.payload,
                let obj = try? JSONDecoder().decode(Bool.self, from: data)
            {
                engine.setDetectionEnabled(obj)
            }
        case "createBinding":
            if let data = message.payload,
                let binding = try? JSONDecoder().decode(ChordBinding.self, from: data)
            {
                store.add(binding)
            }
        case "updateBinding":
            if let data = message.payload,
                let binding = try? JSONDecoder().decode(ChordBinding.self, from: data)
            {
                store.update(binding)
            }
        case "removeBinding":
            if let data = message.payload,
                let binding = try? JSONDecoder().decode(ChordBinding.self, from: data)
            {
                store.remove(binding)
            }
        case "recordStart":
            recorder.start()
        case "recordStop":
            recorder.stop()
        case "recordCancel":
            recorder.cancel()
        default:
            break
        }
    }
}
