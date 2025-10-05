//
//  Runner.swift
//
//  Created by Juri Pakaste on 27.9.2025.
//

import TerminalANSI

@main
struct Runner {
    static func main() async throws {
        guard let outTTY = Terminal() else {
            return
        }

        outTTY.writeCodes([
            .clearScreen,
            .moveCursor(x: 20, y: 20),
            .literal("hello world\n"),
        ])
    }
}
