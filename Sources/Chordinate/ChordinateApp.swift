import SwiftUI

@main
struct ChordinateApp: App {
    @StateObject private var store: ChordStore
    @StateObject private var engine: ChordEngine
    @StateObject private var recorder = ChordRecorder()

    init() {
        let store = ChordStore()
        _store = StateObject(wrappedValue: store)
        _engine = StateObject(wrappedValue: ChordEngine(store: store))
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(store)
                .environmentObject(engine)
                .environmentObject(recorder)
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
