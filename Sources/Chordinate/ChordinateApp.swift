import SwiftUI
import AppKit

@main
struct ChordinateApp: App {
    @StateObject private var store: ChordStore
    @StateObject private var engine: ChordEngine
    @StateObject private var recorder = ChordRecorder()

    init() {
        let store = ChordStore()
        _store = StateObject(wrappedValue: store)
        _engine = StateObject(wrappedValue: ChordEngine(store: store))
        // Ensure app activates to front so the web UI gets focus.
        DispatchQueue.main.async {
            NSApp.setActivationPolicy(.regular)
            NSApplication.shared.activate(ignoringOtherApps: true)
        }
    }

    var body: some Scene {
        WindowGroup {
            WebAppView(store: store, engine: engine, recorder: recorder)
        }
        .commands {
            CommandMenu("Chords") {
                Toggle("Enable Detection", isOn: detectionBinding)
            }
        }
    }

    private var detectionBinding: Binding<Bool> {
        Binding(
            get: { engine.detectionEnabled },
            set: { engine.setDetectionEnabled($0) }
        )
    }
}
