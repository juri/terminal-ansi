//
//  Terminal.swift
//
//  Created by Juri Pakaste on 27.9.2025.
//

import Foundation

/// `Terminal` wraps a TTY.
@MainActor
public final class Terminal {
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

    /// Read the current terminal foreground color.
    public func foregroundColor() throws(TerminalReadFailure) -> RGBAColor<UInt16> {
        try TerminalANSI.foregroundColor(fileHandle: self.fileHandle)
    }

    /// Read the current terminal background color.
    public func backgroundColor() throws(TerminalReadFailure) -> RGBAColor<UInt16> {
        try TerminalANSI.backgroundColor(fileHandle: self.fileHandle)
    }

    /// Check if the current terminal has a dark background.
    ///
    /// - Returns: true if the luminosity of the current background color is less than 0.5.
    public func hasDarkBackground() throws(TerminalReadFailure) -> Bool {
        try HSLColor(rgba: self.backgroundColor()).luminance < 0.5
    }

    /// Read the current terminal's size.
    public func size() throws(TerminalReadFailure) -> TerminalSize {
        try TerminalSize.current(fileHandle: self.fileHandle)
    }

    /// Query the terminal for the current mouse pointer.
    ///
    /// - Returns: a ``OSCPointer`` with the current pointer's name.
    /// - Throws: a ``TerminalReadFailure`` in case of any error. Notably ``TerminalReadFailure/unsupportedQuery``
    ///           indicates your terminal does not support a mouse pointer query.
    public func currentPointer() throws(TerminalReadFailure) -> OSCPointer {
        try TerminalANSI.currentPointer(fileHandle: self.fileHandle)
    }

    /// Query the terminal for supported pointers.
    ///
    /// - Parameter pointers: a list of pointers to query.
    /// - Returns: a dictionary of pointer to booleans, indicating which of the queried ones are supported.
    /// - Throws: a ``TerminalReadFailure`` in case of any error. Notably ``TerminalReadFailure/unsupportedQuery``
    ///           indicates your terminal does not support a mouse pointer query.
    public func supportedPointers(_ pointers: [OSCPointer]) throws(TerminalReadFailure) -> [OSCPointer: Bool] {
        try TerminalANSI.supportedPointers(fileHandle: self.fileHandle, pointers: pointers)
    }
}
