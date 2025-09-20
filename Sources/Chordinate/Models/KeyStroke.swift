import Foundation
import AppKit
import Carbon.HIToolbox

struct KeyStroke: Identifiable, Codable {
    var id = UUID()
    var key: String
    var modifiers: ModifierFlags

    init(id: UUID = UUID(), key: String, modifiers: ModifierFlags) {
        self.id = id
        self.key = key
        self.modifiers = modifiers
    }

    var displayText: String {
        let symbol = KeyStroke.displayName(for: key)
        let prefix = modifiers.localizedDescription
        if prefix.isEmpty { return symbol }
        return prefix + symbol
    }

    static func from(event: NSEvent) -> KeyStroke? {
        guard event.type == .keyDown else { return nil }
        guard let keyName = KeyStroke.keyRepresentation(for: event) else { return nil }
        let modifiers = ModifierFlags(eventFlags: event.modifierFlags.intersection([.command, .option, .control, .shift]))
        return KeyStroke(key: keyName, modifiers: modifiers)
    }

    private static func keyRepresentation(for event: NSEvent) -> String? {
        if let special = specialKeyDescriptions[event.keyCode] {
            return special
        }
        guard let characters = event.charactersIgnoringModifiers, !characters.isEmpty else {
            return nil
        }
        if characters.count == 1 {
            return characters.uppercased()
        }
        return characters
    }

    private static func displayName(for key: String) -> String {
        if let special = specialKeyDisplayOverrides[key] {
            return special
        }
        return key
    }

    private static let specialKeyDescriptions: [UInt16: String] = [
        UInt16(kVK_Return): "Return",
        UInt16(kVK_ANSI_KeypadEnter): "Enter",
        UInt16(kVK_Tab): "Tab",
        UInt16(kVK_Space): "Space",
        UInt16(kVK_Delete): "Delete",
        UInt16(kVK_ForwardDelete): "ForwardDelete",
        UInt16(kVK_Escape): "Escape",
        UInt16(kVK_Home): "Home",
        UInt16(kVK_End): "End",
        UInt16(kVK_PageUp): "PageUp",
        UInt16(kVK_PageDown): "PageDown",
        UInt16(kVK_LeftArrow): "LeftArrow",
        UInt16(kVK_RightArrow): "RightArrow",
        UInt16(kVK_UpArrow): "UpArrow",
        UInt16(kVK_DownArrow): "DownArrow",
        UInt16(kVK_Help): "Help",
        UInt16(kVK_ANSI_KeypadClear): "Clear",
        UInt16(kVK_F1): "F1",
        UInt16(kVK_F2): "F2",
        UInt16(kVK_F3): "F3",
        UInt16(kVK_F4): "F4",
        UInt16(kVK_F5): "F5",
        UInt16(kVK_F6): "F6",
        UInt16(kVK_F7): "F7",
        UInt16(kVK_F8): "F8",
        UInt16(kVK_F9): "F9",
        UInt16(kVK_F10): "F10",
        UInt16(kVK_F11): "F11",
        UInt16(kVK_F12): "F12",
        UInt16(kVK_F13): "F13",
        UInt16(kVK_F14): "F14",
        UInt16(kVK_F15): "F15",
        UInt16(kVK_F16): "F16",
        UInt16(kVK_F17): "F17",
        UInt16(kVK_F18): "F18",
        UInt16(kVK_F19): "F19",
        UInt16(kVK_F20): "F20"
    ]

    private static let specialKeyDisplayOverrides: [String: String] = [
        "Return": "↩︎",
        "Enter": "⌅",
        "Tab": "⇥",
        "Space": "␣",
        "Delete": "⌫",
        "ForwardDelete": "⌦",
        "Escape": "⎋",
        "LeftArrow": "←",
        "RightArrow": "→",
        "UpArrow": "↑",
        "DownArrow": "↓",
        "Home": "↖",
        "End": "↘",
        "PageUp": "⇞",
        "PageDown": "⇟"
    ]
}

extension KeyStroke: Equatable {
    static func == (lhs: KeyStroke, rhs: KeyStroke) -> Bool {
        lhs.key == rhs.key && lhs.modifiers == rhs.modifiers
    }
}

extension KeyStroke: Hashable {
    func hash(into hasher: inout Hasher) {
        hasher.combine(key)
        hasher.combine(modifiers.rawValue)
    }
}
