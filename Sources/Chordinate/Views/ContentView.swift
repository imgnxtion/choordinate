import SwiftUI

struct ContentView: View {
    @EnvironmentObject private var store: ChordStore
    @EnvironmentObject private var engine: ChordEngine
    @EnvironmentObject private var recorder: ChordRecorder

    @State private var selection: ChordBinding.ID?

    var body: some View {
        NavigationSplitView {
            List(selection: $selection) {
                ForEach(store.bindings) { binding in
                    VStack(alignment: .leading, spacing: 4) {
                        Text(binding.name.isEmpty ? "Untitled" : binding.name)
                            .font(.headline)
                        Text(binding.displaySequence.isEmpty ? "No chord" : binding.displaySequence)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    .tag(binding.id)
                }
                .onDelete(perform: delete)
            }
            .toolbar {
                ToolbarItemGroup {
                    Button(action: addBinding) {
                        Label("New", systemImage: "plus")
                    }
                    Button(action: duplicateSelected) {
                        Label("Duplicate", systemImage: "doc.on.doc")
                    }
                    .disabled(selection == nil)
                }
            }
            .navigationTitle("Chords")
        } detail: {
            if let binding = bindingForSelection() {
                ChordEditorView(binding: binding)
                    .navigationTitle("Edit Chord")
            } else {
                VStack(spacing: 16) {
                    Text("Select a chord to edit")
                        .font(.headline)
                    Text("Use the + button to create a new shortcut chord.")
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
        .onChange(of: selection) { _ in
            recorder.cancel()
            engine.setDetectionEnabled(true)
        }
        .overlay(alignment: .bottomLeading) {
            if let last = engine.lastTriggered {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Last triggered: \(last.name.isEmpty ? last.displaySequence : last.name)")
                        .font(.footnote)
                        .padding(8)
                        .background(.ultraThinMaterial)
                        .cornerRadius(8)
                }
                .padding()
                .transition(.opacity)
            }
        }
    }

    private func bindingForSelection() -> Binding<ChordBinding>? {
        guard let selection,
              let index = store.bindings.firstIndex(where: { $0.id == selection })
        else {
            return nil
        }
        return Binding(
            get: { store.bindings[index] },
            set: { store.bindings[index] = $0 }
        )
    }

    private func addBinding() {
        let new = ChordBinding(name: "New Chord", steps: [], action: ChordAction())
        store.add(new)
        selection = new.id
    }

    private func duplicateSelected() {
        guard let selection,
              let original = store.bindings.first(where: { $0.id == selection })
        else { return }
        var copy = original
        copy.id = UUID()
        copy.name += " Copy"
        store.add(copy)
        self.selection = copy.id
    }

    private func delete(at offsets: IndexSet) {
        let ids = offsets.map { store.bindings[$0].id }
        store.bindings.remove(atOffsets: offsets)
        if let selection, ids.contains(selection) {
            self.selection = nil
        }
    }
}
