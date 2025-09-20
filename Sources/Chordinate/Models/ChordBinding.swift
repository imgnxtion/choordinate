import Foundation

struct ChordBinding: Identifiable, Codable, Hashable {
    var id: UUID
    var name: String
    var steps: [KeyStroke]
    var action: ChordAction

    init(id: UUID = UUID(), name: String, steps: [KeyStroke], action: ChordAction) {
        self.id = id
        self.name = name
        self.steps = steps
        self.action = action
    }

    var displaySequence: String {
        steps.map { $0.displayText }.joined(separator: "  ›  ")
    }
}
