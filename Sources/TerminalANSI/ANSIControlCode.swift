//
//  ANSIControlCode.swift
//
//  Created by Juri Pakaste on 27.9.2025.
//

public enum ANSIControlCode {
    case clearLine
    case clearScreen
    case disableAlternativeBuffer
    case enableAlternativeBuffer
    case insertLines(Int)
    case literal(String)
    case moveCursor(x: Int, y: Int?)
    case moveCursorDown(n: Int)
    case moveCursorLeft(n: Int)
    case moveCursorRight(n: Int)
    case moveCursorToColumn(n: Int)
    case moveCursorUp(n: Int)
    case operatingSystemCommand(OperatingSystemCommand)
    case restoreCursorPosition
    case restoreScreen
    case saveCursorPosition
    case saveScreen
    case setGraphicsRendition([SetGraphicsRendition])
    case scrollDown(Int)
    case scrollUp(Int)
    case setCursorHidden(Bool)

    public var ansiCommand: ANSICommand {
        switch self {
        case .clearLine: return ANSICommand(rawValue: "[2K")
        case .clearScreen: return ANSICommand(rawValue: "[2J")
        case .disableAlternativeBuffer: return ANSICommand(rawValue: "[?1049l")
        case .enableAlternativeBuffer: return ANSICommand(rawValue: "[?1049h")
        case let .insertLines(n): return ANSICommand(rawValue: "[\(n)L")
        case let .literal(str): return ANSICommand(rawValue: str, escape: false)

        case let .moveCursor(x: x, y: y):
            if let y {
                return ANSICommand(rawValue: "[\(y + 1);\(x + 1)H")
            } else {
                return ANSICommand(rawValue: "[\(x + 1)H")
            }
        case let .moveCursorLeft(n: n):
            return n >= 0 ? ANSICommand(rawValue: "[\(n)D") : ANSICommand(rawValue: "[\(abs(n))C")
        case let .moveCursorDown(n: n):
            return n >= 0 ? ANSICommand(rawValue: "[\(n)B") : ANSICommand(rawValue: "[\(abs(n))A")
        case let .moveCursorRight(n: n):
            return n >= 0 ? ANSICommand(rawValue: "[\(n)C") : ANSICommand(rawValue: "[\(abs(n))D")
        case let .moveCursorToColumn(n: n):
            return ANSICommand(rawValue: "[\(n)G")
        case let .moveCursorUp(n: n):
            return n >= 0 ? ANSICommand(rawValue: "[\(n)A") : ANSICommand(rawValue: "[\(abs(n))B")

        case let .operatingSystemCommand(osc): return ANSICommand(rawValue: osc.rawValue)

        case .restoreCursorPosition: return ANSICommand(rawValue: "8")
        case .restoreScreen: return ANSICommand(rawValue: "[?47l")
        case .saveCursorPosition: return ANSICommand(rawValue: "7")
        case .saveScreen: return ANSICommand(rawValue: "[?47h")
        case let .scrollDown(n): return ANSICommand(rawValue: "[\(n)T")
        case let .scrollUp(n): return ANSICommand(rawValue: "[\(n)S")
        case let .setCursorHidden(hidden): return ANSICommand(rawValue: "[?25\(hidden ? "l" : "h")")
        case let .setGraphicsRendition(sgr):
            return ANSICommand(rawValue: "[\(sgr.map(\.rawValue).joined(separator: ";"))m")
        }
    }
}

public struct ANSICommand {
    public var rawValue: String
    public var escape: Bool = true

    public var message: String {
        "\(self.escape ? "\u{001B}" : "")\(self.rawValue)"
    }
}

public enum SetGraphicsRendition {
    case background256(Int)
    case backgroundBasic(BasicPalette)
    case backgroundBasicBright(BasicPalette)
    case backgroundRGB(red: Int, green: Int, blue: Int)
    case bold
    case italic
    case reset
    case text256(Int)
    case textBasic(BasicPalette)
    case textBasicBright(BasicPalette)
    case textRGB(red: Int, green: Int, blue: Int)
    case underline

    public var rawValue: String {
        switch self {
        case let .background256(index): return "48;5;\(index)"
        case let .backgroundBasic(p): return String(describing: 40 + p.rawValue)
        case let .backgroundBasicBright(p): return String(describing: 100 + p.rawValue)
        case let .backgroundRGB(red: r, green: g, blue: b): return "48;2;\(r);\(g);\(b)"
        case .bold: return "1"
        case .italic: return "3"
        case .underline: return "4"
        case let .text256(index): return "38;5;\(index)"
        case let .textBasic(p): return String(describing: 30 + p.rawValue)
        case let .textBasicBright(p): return String(describing: 90 + p.rawValue)
        case let .textRGB(red: r, green: g, blue: b): return "38;2;\(r);\(g);\(b)"
        case .reset: return "0"
        }
    }
}

public enum OperatingSystemCommand {
    case setProgress(OSCProgress)

    public var rawValue: String {
        let prefix = "]9;"
        let suffix = "\u{0007}"
        let action: String

        switch self {
        case let .setProgress(oscp): action = oscp.rawValue
        }

        return "\(prefix)\(action)\(suffix)"
    }
}

public enum OSCProgress {
    case remove
    case value(Int)
    case error
    case indeterminate
    case paused

    public var rawValue: String {
        let prefix = "4;"
        let suffix = "\u{0007}"

        switch self {
        case .remove: return "\(prefix)0;0\(suffix)"
        case let .value(value): return "\(prefix)1;\(min(100, max(0, value)))\(suffix)"
        case .error: return "\(prefix)2;0\(suffix)"
        case .indeterminate: return "\(prefix)3;0\(suffix)"
        case .paused: return "\(prefix)4;0\(suffix)"
        }
    }
}

/// `BasicPalette` contains the basic eight terminal colors.
public enum BasicPalette: Int, Sendable {
    case black = 0
    case red = 1
    case green = 2
    case yellow = 3
    case blue = 4
    case magenta = 5
    case cyan = 6
    case white = 7
}
