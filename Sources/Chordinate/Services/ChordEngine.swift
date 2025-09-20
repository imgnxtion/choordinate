import Foundation
import AppKit
import Combine

final class ChordEngine: ObservableObject {
    @Published private(set) var lastTriggered: ChordBinding?
    @Published var detectionEnabled: Bool = true

    private let store: ChordStore
    private var cancellables = Set<AnyCancellable>()
    private var globalMonitor: Any?
    private var localMonitor: Any?

    private let timeout: TimeInterval = 1.25
    private var lastEventDate: Date = .distantPast
    private var sequence: [KeyStroke] = []
    private var maxSequenceLength: Int = 0

    init(store: ChordStore) {
        self.store = store
        configureObservers()
        startMonitors()
    }

    deinit {
        stopMonitors()
    }

    func setDetectionEnabled(_ enabled: Bool) {
        DispatchQueue.main.async {
            self.detectionEnabled = enabled
            if !enabled {
                self.sequence.removeAll()
            }
        }
    }

    private func configureObservers() {
        store.$bindings
            .receive(on: DispatchQueue.main)
            .sink { [weak self] bindings in
                self?.maxSequenceLength = bindings.map { $0.steps.count }.max() ?? 0
            }
            .store(in: &cancellables)
    }

    private func startMonitors() {
        globalMonitor = NSEvent.addGlobalMonitorForEvents(matching: .keyDown) { [weak self] event in
            self?.handle(event: event)
        }
        localMonitor = NSEvent.addLocalMonitorForEvents(matching: .keyDown) { [weak self] event in
            self?.handle(event: event)
            return event
        }
    }

    private func stopMonitors() {
        if let token = globalMonitor {
            NSEvent.removeMonitor(token)
        }
        if let token = localMonitor {
            NSEvent.removeMonitor(token)
        }
    }

    private func handle(event: NSEvent) {
        guard detectionEnabled else { return }
        guard !event.isARepeat else { return }
        guard let stroke = KeyStroke.from(event: event) else { return }

        let now = Date()
        if now.timeIntervalSince(lastEventDate) > timeout {
            sequence.removeAll()
        }
        lastEventDate = now

        sequence.append(stroke)
        if maxSequenceLength > 0, sequence.count > maxSequenceLength {
            sequence.removeFirst(sequence.count - maxSequenceLength)
        }
        evaluateSequence()
    }

    private func evaluateSequence() {
        guard !sequence.isEmpty else { return }
        for binding in store.bindings {
            guard !binding.steps.isEmpty else { continue }
            if sequence.suffix(binding.steps.count) == binding.steps {
                trigger(binding)
                break
            }
        }
    }

    private func trigger(_ binding: ChordBinding) {
        lastTriggered = binding
        execute(binding.action)
        sequence.removeAll()
    }

    private func execute(_ action: ChordAction) {
        switch action.type {
        case .shellCommand:
            runShellCommand(action.payload)
        case .openURL:
            openURL(action.payload)
        }
    }

    private func runShellCommand(_ command: String) {
        let trimmed = command.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        let task = Process()
        task.executableURL = URL(fileURLWithPath: "/bin/zsh")
        task.arguments = ["-lc", trimmed]
        task.standardOutput = Pipe()
        task.standardError = Pipe()
        do {
            try task.run()
        } catch {
            NSLog("Failed to run shell command: \(error.localizedDescription)")
        }
    }

    private func openURL(_ string: String) {
        guard let url = URL(string: string) else { return }
        DispatchQueue.main.async {
            NSWorkspace.shared.open(url)
        }
    }
}
