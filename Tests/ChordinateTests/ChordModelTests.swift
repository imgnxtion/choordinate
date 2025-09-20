import XCTest
@testable import Chordinate

final class ChordModelTests: XCTestCase {
    func testKeyStrokeEqualityIgnoresIdentifiers() {
        let first = KeyStroke(id: UUID(), key: "K", modifiers: [.command])
        let second = KeyStroke(id: UUID(), key: "K", modifiers: [.command])
        XCTAssertEqual(first, second)
    }

    func testDisplaySequenceFormatting() {
        let binding = ChordBinding(name: "Sample",
                                   steps: [KeyStroke(key: "K", modifiers: [.command]),
                                           KeyStroke(key: "C", modifiers: [.command])],
                                   action: ChordAction(type: .shellCommand, payload: "say hi"))
        XCTAssertEqual(binding.displaySequence, "⌘K  ›  ⌘C")
    }
}
