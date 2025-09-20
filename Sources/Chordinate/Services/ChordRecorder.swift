import Foundation
import AppKit

final class ChordRecorder: ObservableObject {
    @Published var isRecording: Bool = false
    @Published var recordedSteps: [KeyStroke] = []

    private var monitor: Any?

    func start() {
        guard !isRecording else { return }
        recordedSteps.removeAll()
        isRecording = true
        monitor = NSEvent.addLocalMonitorForEvents(matching: .keyDown) { [weak self] event in
            guard let self else { return event }
            guard self.isRecording else { return event }
            guard !event.isARepeat else { return nil }
            if let stroke = KeyStroke.from(event: event) {
                if stroke.key == "Escape" && stroke.modifiers.isEmpty {
                    self.cancel()
                    return nil
                }
                self.recordedSteps.append(stroke)
            }
            return nil
        }
    }

    func stop() {
        guard isRecording else { return }
        if let monitor {
            NSEvent.removeMonitor(monitor)
        }
        self.monitor = nil
        isRecording = false
    }

    func cancel() {
        stop()
        recordedSteps.removeAll()
    }
}
