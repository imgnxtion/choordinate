import Foundation
import AppKit

enum ChordActionType: String, CaseIterable, Identifiable, Codable {
    case shellCommand
    case openURL

    var id: String { rawValue }

    var title: String {
        switch self {
        case .shellCommand:
            return "Run Shell Command"
        case .openURL:
            return "Open URL"
        }
    }
}

struct ChordAction: Codable, Hashable {
    var type: ChordActionType
    var payload: String

    init(type: ChordActionType = .shellCommand, payload: String = "") {
        self.type = type
        self.payload = payload
    }
}
