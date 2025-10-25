//
//  ColorMode.swift
//
//  Created by Juri Pakaste on 25.10.2025.
//

import Foundation

public enum ColorMode: Sendable {
    case noColor
    case ansi
    case ansi256
    case trueColor

    /// Determine `ColorMode` based on the environment variables and the file handle.
    ///
    /// - Parameters:
    ///     - environment: Environment variables. If nil, the current environment is used.
    ///     - fileHandle: The file handle whose TTY status is checked.
    /// - Returns: A `ColorMode` that should tell which colors are safe to use.
    public static func current(
        environment: [String: String]? = nil,
        fileHandle: FileHandle,
    ) -> ColorMode {
        guard isatty(fileHandle.fileDescriptor) == 1 else { return .noColor }
        return self.current(environment: environment ?? ProcessInfo.processInfo.environment)
    }

    /// Determine `ColorMode` based on the environment variables.
    ///
    /// - Parameters:
    ///     - environment: Environment variables.
    /// - Returns: A `ColorMode` that should tell which colors are safe to use.
    public static func current(
        environment env: [String: String],
    ) -> ColorMode {
        // The following logic is shamelessly copied from
        // https://github.com/muesli/termenv/blob/368a3572b8146cc038b3f240da6792003d7e42c5/termenv_unix.go#L23
        if env["GOOGLE_CLOUD_SHELL"] == "true" {
            return .trueColor
        }

        let term = env["TERM"]
        let colorTerm = env["COLORTERM"]
        switch colorTerm?.lowercased() {
        case .none:
            break
        case .some("24bit"), .some("truecolor"):
            if let term, term.hasPrefix("screen") {
                // tmux supports trueColor, screen only ansi256
                if env["TERM_PROGRAM"] != "tmux" {
                    return .ansi256
                }
            }
            return .trueColor
        case .some("yes"), .some("true"):
            return .ansi256
        default:
            break
        }

        guard let term else { return .noColor }

        switch term {
        case "alacritty",
            "contour",
            "rio",
            "wezterm",
            "xterm-ghostty",
            "xterm-kitty":
            return .trueColor

        case "linux", "xterm":
            return .ansi

        default:
            break
        }

        if term.contains("256color") { return .ansi256 }
        if term.contains("color") { return .ansi }
        if term.contains("ansi") { return .ansi }

        return .noColor
    }
}
