//
//  Runner.swift
//
//  Created by Juri Pakaste on 27.9.2025.
//

import TerminalANSI

@main
struct Runner {
    static func main() async throws {
        guard let terminal = Terminal() else {
            return
        }

        let isDark = try terminal.hasDarkBackground()

        let size = try terminal.size()
        terminal.writeCodes([
            .clearScreen,
            .moveCursor(x: size.width / 2, y: size.height / 2 - 6),
            .setGraphicsRendition([
                .textRGB(isDark ? RGBColor8(intR: 0xD0, g: 0x80, b: 0xC0) : RGBColor8(intR: 0x80, g: 0x30, b: 0x60))
            ]),
            .literal("Hello world!\n"),
            .moveCursor(x: 0, y: size.height),
            .setGraphicsRendition([
                .reset
            ]),
        ])
    }
}
