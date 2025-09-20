import SwiftUI

struct ChordEditorView: View {
    @Binding var binding: ChordBinding
    @EnvironmentObject private var recorder: ChordRecorder
    @EnvironmentObject private var engine: ChordEngine

    var body: some View {
        Form {
            Section(header: Text("Shortcut")) {
                TextField("Name", text: $binding.name)
                VStack(alignment: .leading, spacing: 8) {
                    Text("Chord Sequence")
                        .font(.headline)
                    if binding.steps.isEmpty {
                        Text("No chord assigned yet. Use Record to capture one.")
                            .foregroundColor(.secondary)
                    } else {
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 8) {
                                ForEach(binding.steps) { step in
                                    Text(step.displayText)
                                        .padding(.vertical, 4)
                                        .padding(.horizontal, 8)
                                        .background(Color.accentColor.opacity(0.12))
                                        .cornerRadius(6)
                                }
                            }
                        }
                        .frame(maxHeight: 40)
                    }
                    HStack(spacing: 12) {
                        Button(recorder.isRecording ? "Stop Recording" : "Record Chord") {
                            toggleRecording()
                        }
                        Button("Clear") {
                            binding.steps.removeAll()
                        }
                        .disabled(binding.steps.isEmpty && recorder.recordedSteps.isEmpty)
                    }
                    if recorder.isRecording {
                        Text("Recording… Press the sequence now. Press Escape to cancel.")
                            .foregroundColor(.secondary)
                    } else if !recorder.recordedSteps.isEmpty {
                        Text("Last capture: " + recorder.recordedSteps.map { $0.displayText }.joined(separator: "  ›  "))
                            .foregroundColor(.secondary)
                    }
                }
            }

            Section(header: Text("Action")) {
                Picker("Type", selection: Binding(
                    get: { binding.action.type },
                    set: { binding.action.type = $0 }
                )) {
                    ForEach(ChordActionType.allCases) { type in
                        Text(type.title).tag(type)
                    }
                }
                actionEditor
            }
        }
        .onDisappear {
            if recorder.isRecording {
                recorder.stop()
            }
            engine.setDetectionEnabled(true)
        }
        .onChange(of: recorder.isRecording) { recording in
            engine.setDetectionEnabled(!recording)
        }
        .padding()
    }

    @ViewBuilder
    private var actionEditor: some View {
        switch binding.action.type {
        case .shellCommand:
            VStack(alignment: .leading, spacing: 6) {
                Text("Shell command (runs via /bin/zsh -lc)")
                    .font(.footnote)
                    .foregroundColor(.secondary)
                TextEditor(text: Binding(
                    get: { binding.action.payload },
                    set: { binding.action.payload = $0 }
                ))
                .frame(minHeight: 120)
                .border(Color(nsColor: .separatorColor))
            }
        case .openURL:
            TextField("https://example.com", text: Binding(
                get: { binding.action.payload },
                set: { binding.action.payload = $0 }
            ))
        }
    }

    private func toggleRecording() {
        if recorder.isRecording {
            recorder.stop()
            if !recorder.recordedSteps.isEmpty {
                binding.steps = recorder.recordedSteps
            }
        } else {
            recorder.start()
        }
    }
}
