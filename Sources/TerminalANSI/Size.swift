//
//  Size.swift
//  terminal-ansi
//
//  Created by Juri Pakaste on 7.10.2025.
//

import Foundation

public struct TerminalSize: Sendable, Equatable {
    public var height: Int
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
