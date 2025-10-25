//
//  Size.swift
//  terminal-ansi
//
//  Created by Juri Pakaste on 7.10.2025.
//

import Foundation

/// Terminal size in characters.
public struct TerminalSize: Sendable, Equatable {
    /// Height of a terminal, as the number of text lines in the window.
    public var height: Int

    /// Width of a terminal, as the number of text columns in the window.
    public var width: Int
}

extension TerminalSize {
    /// Return the current terminal size.
    @MainActor
    public static func current(fileHandle: FileHandle) throws(TerminalReadFailure) -> Self {
        var w = winsize()
        guard ioctl(fileHandle.fileDescriptor, UInt(TIOCGWINSZ), &w) >= 0 else {
            throw .callFailure(.ioctl, errno: errno)
        }
        return TerminalSize(height: Int(w.ws_row), width: Int(w.ws_col))
    }
}
