//
//  ANSIControlCode.swift
//
//  Created by Juri Pakaste on 27.9.2025.
//

/// `ANSIControlCode` defines ANSI escape sequences for controlling Unix style terminals.
public enum ANSIControlCode: Equatable, Sendable {
    case clearLine
    /// See also ``erase(_:)``. This is the same as ``Erase/entireScreen``.
    case clearScreen
    case disableAlternativeBuffer
    case enableAlternativeBuffer
    case erase(Erase)
    case insertBlanks(Int)
    case insertLines(Int)
    case literal(String)
    case moveCursor(x: Int, y: Int?)
    case moveCursorBeginningOfLineDown(n: Int)
    case moveCursorBeginningOfLineUp(n: Int)
    case moveCursorDown(n: Int)
    case moveCursorLeft(n: Int)
    case moveCursorRight(n: Int)
    case moveCursorToColumn(n: Int)
    case moveCursorUp(n: Int)
    case operatingSystemCommand(OperatingSystemCommand)
    case reset
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
        case let .erase(erase): return ANSICommand(rawValue: erase.rawValue)
        case let .insertBlanks(n): return ANSICommand(rawValue: "[\(n)@")
        case let .insertLines(n): return ANSICommand(rawValue: "[\(n)L")
        case let .literal(str): return ANSICommand(rawValue: str, escape: false)

        case let .moveCursor(x: x, y: y):
            if let y {
                return ANSICommand(rawValue: "[\(y + 1);\(x + 1)H")
            } else {
                return ANSICommand(rawValue: "[\(x + 1)H")
            }
        case let .moveCursorBeginningOfLineDown(n: n):
            return n >= 0 ? ANSICommand(rawValue: "[\(n)E") : ANSICommand(rawValue: "[\(abs(n))F")
        case let .moveCursorBeginningOfLineUp(n: n):
            return n >= 0 ? ANSICommand(rawValue: "[\(n)F") : ANSICommand(rawValue: "[\(abs(n))E")
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

        case .reset: return ANSICommand(rawValue: "c")
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

/// `ANSICommand` is an ANSI escape sequence ready for outputting to the terminal.
public struct ANSICommand: Equatable, Sendable {
    public var rawValue: String
    public var escape: Bool = true

    public init(rawValue: String, escape: Bool = true) {
        self.rawValue = rawValue
        self.escape = escape
    }

    public var message: String {
        "\(self.escape ? Codes.esc : "")\(self.rawValue)"
    }
}

/// `Erase` defines the various erase control codes.
public enum Erase: Equatable, Sendable {
    case endOfScreen
    case beginningOfScreen
    case entireScreen
    case savedLines
    case endOfLine
    case startOfLine
    case entireLine

    public var rawValue: String {
        switch self {
        case .endOfScreen: "[0J"
        case .beginningOfScreen: "[1J"
        case .entireScreen: "[2J"
        case .savedLines: "[3J"
        case .endOfLine: "[0K"
        case .startOfLine: "[1K"
        case .entireLine: "[2K"
        }
    }
}

/// `SetGraphicsRendition` defines the SGR control codes.
public enum SetGraphicsRendition: Equatable, Sendable {
    case background256(Int)
    case backgroundBasic(BasicPalette)
    case backgroundBasicBright(BasicPalette)
    case backgroundRGB(RGBColor8)
    case blink
    case bold
    case crossOut
    case faint
    case italic
    case overline
    case reset
    case reverse
    case text256(Int)
    case textBasic(BasicPalette)
    case textBasicBright(BasicPalette)
    case textRGB(RGBColor8)
    case underline
    case doubleUnderline

    public var rawValue: String {
        switch self {
        case let .background256(index): return "48;5;\(index)"
        case let .backgroundBasic(p): return String(describing: 40 + p.rawValue)
        case let .backgroundBasicBright(p): return String(describing: 100 + p.rawValue)
        case let .backgroundRGB(rgb): return "48;2;\(rgb.r.rawValue);\(rgb.g.rawValue);\(rgb.b.rawValue)"
        case .blink: return "5"
        case .bold: return "1"
        case .crossOut: return "9"
        case .faint: return "2"
        case .italic: return "3"
        case .overline: return "53"
        case .reverse: return "7"
        case .underline: return "4"
        case .doubleUnderline: return "21"
        case let .text256(index): return "38;5;\(index)"
        case let .textBasic(p): return String(describing: 30 + p.rawValue)
        case let .textBasicBright(p): return String(describing: 90 + p.rawValue)
        case let .textRGB(rgb): return "38;2;\(rgb.r.rawValue);\(rgb.g.rawValue);\(rgb.b.rawValue)"
        case .reset: return "0"
        }
    }
}

/// `OperatingSystemCommand` defines the OSC control codes.
public enum OperatingSystemCommand: Equatable, Sendable {
    /// OSC 8
    case link(id: String?, target: String, title: String)
    /// OSC 9
    case setProgress(OSCProgress)
    /// OSC 0
    case setTitle(String)

    public var rawValue: String {
        let suffix = Codes.st
        let action: String

        switch self {
        case let .link(id: id, target: target, title: title):
            var codes = "8;"
            if let id {
                codes += "id=\(id)"
            }
            codes += ";\(target)\(Codes.st)\(title)\(Codes.esc)]8;;"
            action = codes

        case let .setProgress(oscp): action = "9;" + oscp.rawValue

        case let .setTitle(t): action = "0;\(t)"
        }

        return "]\(action)\(suffix)"
    }
}

/// `OSCProgress` is a OSC progress indicator.
public enum OSCProgress: Equatable, Sendable {
    case remove
    case value(Int)
    case error
    case indeterminate
    case paused

    public var rawValue: String {
        let prefix = "4;"

        switch self {
        case .remove: return "\(prefix)0;0"
        case let .value(value): return "\(prefix)1;\(min(100, max(0, value)))"
        case .error: return "\(prefix)2;0"
        case .indeterminate: return "\(prefix)3;0"
        case .paused: return "\(prefix)4;0"
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

enum Codes {
    static let bel: String = "\u{0007}"
    static let csi: String = "\(esc)["
    static let esc: String = "\u{001B}"
    static let osc: String = "\(esc)]"
    static let st: String = "\(Codes.esc)\\"
}
