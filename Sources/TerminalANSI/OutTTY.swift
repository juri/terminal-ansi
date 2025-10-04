//
//  OutTTY.swift
//
//  Created by Juri Pakaste on 27.9.2025.
//

import Foundation

/// `OutTTY` wraps output to a TTY.
@MainActor
public final class OutTTY {
    private let fileHandle: FileHandle

    /// Opens TTY and if it succeeds and the device is a TTY, returns a non-nil instance.
    public convenience init?() {
        guard let outTTYHandle = FileHandle(forUpdatingAtPath: "/dev/tty") else {
            return nil
        }
        self.init(fileHandle: outTTYHandle)
    }

    public init?(fileHandle: FileHandle) {
        guard isatty(fileHandle.fileDescriptor) == 1 else { return nil }
        self.fileHandle = fileHandle
    }

    public func close() throws {
        try self.fileHandle.synchronize()
        tcflush(self.fileHandle.fileDescriptor, TCOFLUSH)
        try self.fileHandle.close()
    }

    public func write(_ strings: [String]) {
        for string in strings {
            try! self.fileHandle.write(contentsOf: Data(string.utf8))
        }
        try! self.fileHandle.synchronize()
    }

    public func writeCodes(_ codes: [ANSIControlCode]) {
        self.write(codes.map(\.ansiCommand.message))
    }

    public func foregroundColor() throws -> RGBAColor16 {
        try TerminalANSI.foregroundColor(fileHandle: self.fileHandle)
    }

    public func backgroundColor() throws -> RGBAColor16 {
        try TerminalANSI.backgroundColor(fileHandle: self.fileHandle)
    }
}
