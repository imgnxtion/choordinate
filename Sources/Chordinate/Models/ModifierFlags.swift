import Foundation
import AppKit

struct ModifierFlags: OptionSet, Codable, Hashable {
    let rawValue: UInt8

    static let command = ModifierFlags(rawValue: 1 << 0)
    static let option = ModifierFlags(rawValue: 1 << 1)
    static let control = ModifierFlags(rawValue: 1 << 2)
    static let shift = ModifierFlags(rawValue: 1 << 3)

    init(rawValue: UInt8) {
        self.rawValue = rawValue
    }

    init(eventFlags: NSEvent.ModifierFlags) {
        var value: UInt8 = 0
        if eventFlags.contains(.command) { value |= ModifierFlags.command.rawValue }
        if eventFlags.contains(.option) { value |= ModifierFlags.option.rawValue }
        if eventFlags.contains(.control) { value |= ModifierFlags.control.rawValue }
        if eventFlags.contains(.shift) { value |= ModifierFlags.shift.rawValue }
        self.init(rawValue: value)
    }

    var eventFlags: NSEvent.ModifierFlags {
        var flags: NSEvent.ModifierFlags = []
        if contains(.command) { flags.insert(.command) }
        if contains(.option) { flags.insert(.option) }
        if contains(.control) { flags.insert(.control) }
        if contains(.shift) { flags.insert(.shift) }
        return flags
    }

    var symbols: [String] {
        var pieces: [String] = []
        if contains(.control) { pieces.append("⌃") }
        if contains(.option) { pieces.append("⌥") }
        if contains(.shift) { pieces.append("⇧") }
        if contains(.command) { pieces.append("⌘") }
        return pieces
    }

    var localizedDescription: String {
        if symbols.isEmpty { return "" }
        return symbols.joined(separator: "")
    }
}
