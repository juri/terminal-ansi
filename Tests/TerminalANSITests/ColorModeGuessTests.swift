//
//  ColorModeGuessTests.swift
//  terminal-ansi
//
//  Created by Juri Pakaste on 25.10.2025.
//

import TerminalANSI
import Testing

@Suite("Color Mode Guessing")
struct ColorModeGuessTests {
    @Test(
        arguments: [
            (["GOOGLE_CLOUD_SHELL": "true"], .trueColor),
            (["GOOGLE_CLOUD_SHELL": "false"], .noColor),
            (["TERM": "alacritty"], .trueColor),
            (["TERM": "contour"], .trueColor),
            (["TERM": "rio"], .trueColor),
            (["TERM": "wezterm"], .trueColor),
            (["TERM": "xterm-ghostty"], .trueColor),
            (["TERM": "xterm-kitty"], .trueColor),
            (["TERM": "something-256color-middle"], .ansi256),
            (["TERM": "foo-color-bar"], .ansi),
            (["TERM": "asdfansiqw"], .ansi),
            (["COLORTERM": "yes"], .ansi256),
            (["COLORTERM": "true"], .ansi256),
            (["COLORTERM": "no"], .noColor),
            (["COLORTERM": "24bit"], .trueColor),
            (["COLORTERM": "truecolor"], .trueColor),
            (["COLORTERM": "24bit", "TERM": "screen"], .ansi256),
            (["COLORTERM": "truecolor", "TERM": "screen", "TERM_PROGRAM": "tmux"], .trueColor),
        ] as [([String: String], ColorMode)])
    func `guess mode from environment`(
        _ environment: [String: String],
        _ mode: ColorMode,
    ) async throws {
        #expect(ColorMode.current(environment: environment) == mode)
    }
}
