//
//  ANSIParserTypes.swift
//

// Based on the ANSI parser by Charmbracelet in https://github.com/charmbracelet/x/tree/main/ansi
//
// All bugs are my own. Original license:
//
// MIT License
//
// Copyright (c) 2023 Charmbracelet, Inc.
//
// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files (the "Software"), to deal
// in the Software without restriction, including without limitation the rights
// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
// copies of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions:
//
// The above copyright notice and this permission notice shall be included in all
// copies or substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
// SOFTWARE.

/// A parsed ANSI sequence or printable text.
public enum ANSISequence: Equatable, Sendable {
    /// Printable terminal text.
    case print(String)
    /// A C0 or C1 control byte.
    case execute(UInt8)
    /// An ESC sequence.
    case escape(ANSIEscapeSequence)
    /// A control sequence introducer sequence.
    case csi(ANSIControlSequence)
    /// An operating system command sequence.
    case osc(ANSIOSCSequence)
    /// A device control string sequence.
    case dcs(ANSIDCSSequence)
    /// A start-of-string sequence.
    case sos([UInt8])
    /// A privacy message sequence.
    case pm([UInt8])
    /// An application program command sequence.
    case apc([UInt8])
}

/// Callback hooks for observing what ``ANSIParser`` encounters.
///
/// All callbacks are optional. Set only the sequence kinds you need to monitor.
public struct ANSIParserHandler: Sendable {
    /// Called when printable terminal text is encountered.
    public var print: (@Sendable (String) -> Void)?
    /// Called when a C0 or C1 control byte is encountered.
    public var execute: (@Sendable (UInt8) -> Void)?
    /// Called when an ESC sequence is encountered.
    public var handleEscape: (@Sendable (ANSIEscapeSequence) -> Void)?
    /// Called when a CSI sequence is encountered.
    public var handleCSI: (@Sendable (ANSIControlSequence) -> Void)?
    /// Called when an OSC sequence is encountered.
    public var handleOSC: (@Sendable (ANSIOSCSequence) -> Void)?
    /// Called when a DCS sequence is encountered.
    public var handleDCS: (@Sendable (ANSIDCSSequence) -> Void)?
    /// Called when a start-of-string sequence is encountered.
    public var handleSOS: (@Sendable ([UInt8]) -> Void)?
    /// Called when a privacy message sequence is encountered.
    public var handlePM: (@Sendable ([UInt8]) -> Void)?
    /// Called when an application program command sequence is encountered.
    public var handleAPC: (@Sendable ([UInt8]) -> Void)?

    public init(
        print: (@Sendable (String) -> Void)? = nil,
        execute: (@Sendable (UInt8) -> Void)? = nil,
        handleEscape: (@Sendable (ANSIEscapeSequence) -> Void)? = nil,
        handleCSI: (@Sendable (ANSIControlSequence) -> Void)? = nil,
        handleOSC: (@Sendable (ANSIOSCSequence) -> Void)? = nil,
        handleDCS: (@Sendable (ANSIDCSSequence) -> Void)? = nil,
        handleSOS: (@Sendable ([UInt8]) -> Void)? = nil,
        handlePM: (@Sendable ([UInt8]) -> Void)? = nil,
        handleAPC: (@Sendable ([UInt8]) -> Void)? = nil,
    ) {
        self.print = print
        self.execute = execute
        self.handleEscape = handleEscape
        self.handleCSI = handleCSI
        self.handleOSC = handleOSC
        self.handleDCS = handleDCS
        self.handleSOS = handleSOS
        self.handlePM = handlePM
        self.handleAPC = handleAPC
    }
}

/// Options for ``ANSIParser``.
public struct ANSIParserOptions: Equatable, Sendable {
    /// Maximum number of CSI/DCS parameters to keep.
    public var parameterLimit: Int
    /// Maximum number of OSC/DCS/SOS/PM/APC payload bytes to keep.
    ///
    /// Use `nil` for an unbounded data buffer.
    public var dataLimit: Int?

    public init(parameterLimit: Int = 32, dataLimit: Int? = 64 * 1024) {
        self.parameterLimit = max(0, parameterLimit)
        self.dataLimit = dataLimit.map { max(0, $0) }
    }
}

/// A CSI or DCS parameter.
public struct ANSIParameter: Equatable, Sendable {
    /// The parameter value, or `nil` when the parameter was omitted.
    public var value: Int?
    /// Whether this parameter is followed by more colon-separated subparameters.
    public var hasMore: Bool

    public init(value: Int?, hasMore: Bool = false) {
        self.value = value
        self.hasMore = hasMore
    }

    /// Returns the parameter value, falling back to `defaultValue` when omitted.
    public func value(default defaultValue: Int) -> Int {
        self.value ?? defaultValue
    }
}

/// A parsed ESC sequence.
public struct ANSIEscapeSequence: Equatable, Sendable {
    /// The final byte of the sequence.
    public var finalByte: UInt8
    /// The last intermediate byte, if present.
    public var intermediateByte: UInt8?

    public init(finalByte: UInt8, intermediateByte: UInt8? = nil) {
        self.finalByte = finalByte
        self.intermediateByte = intermediateByte
    }
}

/// A parsed CSI sequence.
public struct ANSIControlSequence: Equatable, Sendable {
    /// The final byte of the sequence.
    public var finalByte: UInt8
    /// The private prefix byte, if present.
    public var prefixByte: UInt8?
    /// The last intermediate byte, if present.
    public var intermediateByte: UInt8?
    /// Raw parameters, including omitted parameters and colon subparameters.
    public var parameters: [ANSIParameter]

    public init(
        finalByte: UInt8,
        prefixByte: UInt8? = nil,
        intermediateByte: UInt8? = nil,
        parameters: [ANSIParameter] = [],
    ) {
        self.finalByte = finalByte
        self.prefixByte = prefixByte
        self.intermediateByte = intermediateByte
        self.parameters = parameters
    }

    /// Returns a parameter value by raw index, falling back to `defaultValue`.
    public func parameter(at index: Int, default defaultValue: Int) -> Int {
        guard self.parameters.indices.contains(index) else { return defaultValue }
        return self.parameters[index].value(default: defaultValue)
    }
}

/// A parsed OSC sequence.
public struct ANSIOSCSequence: Equatable, Sendable {
    /// Numeric command parsed from the beginning of the payload, if present.
    public var command: Int?
    /// Raw payload bytes, including the command bytes.
    public var data: [UInt8]

    public init(command: Int?, data: [UInt8]) {
        self.command = command
        self.data = data
    }
}

/// A parsed DCS sequence.
public struct ANSIDCSSequence: Equatable, Sendable {
    /// The final byte of the sequence command.
    public var finalByte: UInt8
    /// The private prefix byte, if present.
    public var prefixByte: UInt8?
    /// The last intermediate byte, if present.
    public var intermediateByte: UInt8?
    /// Raw parameters, including omitted parameters and colon subparameters.
    public var parameters: [ANSIParameter]
    /// Raw payload bytes.
    public var data: [UInt8]

    public init(
        finalByte: UInt8,
        prefixByte: UInt8? = nil,
        intermediateByte: UInt8? = nil,
        parameters: [ANSIParameter] = [],
        data: [UInt8] = [],
    ) {
        self.finalByte = finalByte
        self.prefixByte = prefixByte
        self.intermediateByte = intermediateByte
        self.parameters = parameters
        self.data = data
    }

    /// Returns a parameter value by raw index, falling back to `defaultValue`.
    public func parameter(at index: Int, default defaultValue: Int) -> Int {
        guard self.parameters.indices.contains(index) else { return defaultValue }
        return self.parameters[index].value(default: defaultValue)
    }
}
