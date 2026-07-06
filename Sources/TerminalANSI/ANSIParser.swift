//
//  ANSIParser.swift
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

/// A streaming ANSI sequence parser.
public struct ANSIParser: Sendable {
    public var options: ANSIParserOptions
    /// Optional callbacks invoked whenever the parser completes a sequence.
    public var handler: ANSIParserHandler?

    private var state: ANSIParserState = .ground
    private var parameters: [ANSIParameter] = []
    private var prefixByte: UInt8?
    private var intermediateByte: UInt8?
    private var finalByte: UInt8?
    private var data: [UInt8] = []
    private var utf8Bytes: [UInt8] = []

    public init(options: ANSIParserOptions = ANSIParserOptions(), handler: ANSIParserHandler? = nil) {
        self.options = options
        self.handler = handler
        self.reset()
    }

    /// Sets the parser handler.
    public mutating func setHandler(_ handler: ANSIParserHandler?) {
        self.handler = handler
    }

    /// Resets the parser to its initial state.
    public mutating func reset() {
        self.state = .ground
        self.clearSequence()
    }

    /// Advances the parser by one byte.
    ///
    /// Returns a sequence when the byte completes one, or `nil` while the parser
    /// is collecting a multi-byte character or control sequence.
    public mutating func advance(_ byte: UInt8) -> ANSISequence? {
        if self.state == .utf8 {
            return self.advanceUTF8(byte)
        }

        let transition = ANSITransitionTable.shared.transition(from: self.state, byte: byte)

        if self.state != transition.state {
            if self.state == .escape {
                self.clearSequence()
            }
            if transition.action == .put, self.state == .dcsEntry, transition.state == .dcsString {
                _ = self.perform(.start, byte: 0)
            }
        }

        let action: ANSIParserAction =
            if byte == 0x1b, self.state == .escape {
                .execute
            } else {
                transition.action
            }

        let sequence = self.perform(action, byte: byte)
        self.state = transition.state
        return sequence
    }

    /// Parses a sequence of bytes.
    public mutating func parse(_ bytes: some Sequence<UInt8>) -> [ANSISequence] {
        var sequences: [ANSISequence] = []
        for byte in bytes {
            if let sequence = self.advance(byte) {
                sequences.append(sequence)
            }
        }
        return sequences
    }

    /// Parses a string as UTF-8.
    public mutating func parse(_ string: String) -> [ANSISequence] {
        self.parse(string.utf8)
    }

    private mutating func clearSequence() {
        self.parameters.removeAll(keepingCapacity: true)
        self.parameters.append(ANSIParameter(value: nil))
        self.prefixByte = nil
        self.intermediateByte = nil
        self.finalByte = nil
        self.data.removeAll(keepingCapacity: true)
        self.utf8Bytes.removeAll(keepingCapacity: true)
    }

    private mutating func advanceUTF8(_ byte: UInt8) -> ANSISequence? {
        self.utf8Bytes.append(byte)
        guard let expectedLength = utf8Length(firstByte: self.utf8Bytes[0]) else {
            self.state = .ground
            self.utf8Bytes.removeAll(keepingCapacity: true)
            return nil
        }
        guard self.utf8Bytes.count >= expectedLength else { return nil }

        defer {
            self.state = .ground
            self.utf8Bytes.removeAll(keepingCapacity: true)
        }

        guard let string = String(bytes: self.utf8Bytes, encoding: .utf8) else {
            return self.emit(.print(String(decoding: self.utf8Bytes, as: UTF8.self)))
        }
        return self.emit(.print(string))
    }

    private mutating func perform(_ action: ANSIParserAction, byte: UInt8) -> ANSISequence? {
        switch action {
        case .none:
            return nil

        case .clear:
            self.clearSequence()
            return nil

        case .print:
            return self.emit(.print(String(UnicodeScalar(byte))))

        case .execute:
            return self.emit(.execute(byte))

        case .prefix:
            self.prefixByte = byte
            return nil

        case .collect:
            if ANSITransitionTable.shared.transition(from: self.state, byte: byte).state == .utf8 {
                self.utf8Bytes.removeAll(keepingCapacity: true)
                self.utf8Bytes.append(byte)
            } else {
                self.intermediateByte = byte
            }
            return nil

        case .param:
            self.collectParameter(byte)
            return nil

        case .start:
            self.data.removeAll(keepingCapacity: true)
            if self.state >= .dcsEntry, self.state <= .dcsString {
                self.finalByte = byte == 0 ? nil : byte
            } else {
                self.finalByte = nil
            }
            return nil

        case .put:
            self.putData(byte)
            return nil

        case .dispatch:
            return self.dispatch(byte)
        }
    }

    private mutating func collectParameter(_ byte: UInt8) {
        guard self.parameters.count <= self.options.parameterLimit else { return }

        if self.parameters.isEmpty {
            self.parameters.append(ANSIParameter(value: nil))
        }

        let lastIndex = self.parameters.count - 1
        if byte >= ASCII.zero, byte <= ASCII.nine {
            let digit = Int(byte - ASCII.zero)
            let current = self.parameters[lastIndex].value ?? 0
            self.parameters[lastIndex].value = current * 10 + digit
        }

        if byte == ASCII.colon {
            self.parameters[lastIndex].hasMore = true
        }

        if byte == ASCII.semicolon || byte == ASCII.colon {
            guard self.parameters.count < self.options.parameterLimit else { return }
            self.parameters.append(ANSIParameter(value: nil))
        }
    }

    private mutating func putData(_ byte: UInt8) {
        guard self.options.dataLimit.map({ self.data.count < $0 }) ?? true else { return }
        self.data.append(byte)
    }

    private mutating func dispatch(_ byte: UInt8) -> ANSISequence? {
        let parameters = self.dispatchedParameters()
        let data = self.data

        switch self.state {
        case .csiEntry, .csiParam, .csiIntermediate:
            return self.emit(
                .csi(
                    ANSIControlSequence(
                        finalByte: byte,
                        prefixByte: self.prefixByte,
                        intermediateByte: self.intermediateByte,
                        parameters: parameters,
                    )
                )
            )

        case .escape, .escapeIntermediate:
            return self.emit(
                .escape(
                    ANSIEscapeSequence(
                        finalByte: byte,
                        intermediateByte: self.intermediateByte,
                    )
                )
            )

        case .dcsEntry, .dcsParam, .dcsIntermediate, .dcsString:
            return self.emit(
                .dcs(
                    ANSIDCSSequence(
                        finalByte: self.finalByte ?? byte,
                        prefixByte: self.prefixByte,
                        intermediateByte: self.intermediateByte,
                        parameters: parameters,
                        data: data,
                    )
                )
            )

        case .oscString:
            return self.emit(.osc(ANSIOSCSequence(command: self.oscCommand(data), data: data)))

        case .sosString:
            return self.emit(.sos(data))

        case .pmString:
            return self.emit(.pm(data))

        case .apcString:
            return self.emit(.apc(data))

        default:
            return nil
        }
    }

    private func emit(_ sequence: ANSISequence) -> ANSISequence {
        switch sequence {
        case let .print(string):
            self.handler?.print?(string)
        case let .execute(byte):
            self.handler?.execute?(byte)
        case let .escape(sequence):
            self.handler?.handleEscape?(sequence)
        case let .csi(sequence):
            self.handler?.handleCSI?(sequence)
        case let .osc(sequence):
            self.handler?.handleOSC?(sequence)
        case let .dcs(sequence):
            self.handler?.handleDCS?(sequence)
        case let .sos(data):
            self.handler?.handleSOS?(data)
        case let .pm(data):
            self.handler?.handlePM?(data)
        case let .apc(data):
            self.handler?.handleAPC?(data)
        }
        return sequence
    }

    private func dispatchedParameters() -> [ANSIParameter] {
        if self.parameters.isEmpty {
            return []
        }
        if self.parameters.count == 1, self.parameters[0].value == nil, !self.parameters[0].hasMore {
            return []
        }
        return self.parameters
    }

    private func oscCommand(_ data: [UInt8]) -> Int? {
        var command: Int?
        for byte in data {
            guard byte >= ASCII.zero, byte <= ASCII.nine else { break }
            command = (command ?? 0) * 10 + Int(byte - ASCII.zero)
        }
        return command
    }
}

private enum ANSIParserAction: UInt8 {
    case none
    case clear
    case collect
    case prefix
    case dispatch
    case execute
    case start
    case put
    case param
    case print
}

private enum ANSIParserState: UInt8, Comparable, CaseIterable {
    case ground
    case csiEntry
    case csiIntermediate
    case csiParam
    case dcsEntry
    case dcsIntermediate
    case dcsParam
    case dcsString
    case escape
    case escapeIntermediate
    case oscString
    case sosString
    case pmString
    case apcString
    case utf8

    static func < (lhs: ANSIParserState, rhs: ANSIParserState) -> Bool {
        lhs.rawValue < rhs.rawValue
    }
}

private struct ANSITransitionTable: Sendable {
    static let shared = ANSITransitionTable()

    private var table: [UInt8]

    init() {
        self.table = Array(
            repeating: ANSIParserAction.none.rawValue << 4 | ANSIParserState.ground.rawValue,
            count: 4096,
        )
        self.generate()
    }

    func transition(from state: ANSIParserState, byte: UInt8) -> (state: ANSIParserState, action: ANSIParserAction) {
        let value = self.table[Int(state.rawValue) << 8 | Int(byte)]
        return (
            ANSIParserState(rawValue: value & 0x0f) ?? .ground,
            ANSIParserAction(rawValue: value >> 4) ?? .none,
        )
    }

    private mutating func add(
        _ byte: UInt8, _ state: ANSIParserState, _ action: ANSIParserAction, _ next: ANSIParserState,
    ) {
        self.table[Int(state.rawValue) << 8 | Int(byte)] = action.rawValue << 4 | next.rawValue
    }

    private mutating func add(
        _ bytes: [UInt8], _ state: ANSIParserState, _ action: ANSIParserAction, _ next: ANSIParserState,
    ) {
        for byte in bytes {
            self.add(byte, state, action, next)
        }
    }

    private mutating func add(
        _ range: ClosedRange<UInt8>, _ state: ANSIParserState, _ action: ANSIParserAction, _ next: ANSIParserState,
    ) {
        for byte in range {
            self.add(byte, state, action, next)
        }
    }

    private mutating func generate() {
        for state in ANSIParserState.allCases {
            self.add([0x18, 0x1a, 0x99, 0x9a], state, .execute, .ground)
            self.add(0x80...0x8f, state, .execute, .ground)
            self.add(0x90...0x97, state, .execute, .ground)
            self.add(0x9c, state, .execute, .ground)
            self.add(0x1b, state, .clear, .escape)
            self.add(0x98, state, .start, .sosString)
            self.add(0x9e, state, .start, .pmString)
            self.add(0x9f, state, .start, .apcString)
            self.add(0x9b, state, .clear, .csiEntry)
            self.add(0x90, state, .clear, .dcsEntry)
            self.add(0x9d, state, .start, .oscString)
            self.add(0xc2...0xdf, state, .collect, .utf8)
            self.add(0xe0...0xef, state, .collect, .utf8)
            self.add(0xf0...0xf4, state, .collect, .utf8)
        }

        self.add(0x00...0x17, .ground, .execute, .ground)
        self.add(0x19, .ground, .execute, .ground)
        self.add(0x1c...0x1f, .ground, .execute, .ground)
        self.add(0x20...0x7e, .ground, .print, .ground)
        self.add(0x7f, .ground, .execute, .ground)

        self.add(0x00...0x17, .escapeIntermediate, .execute, .escapeIntermediate)
        self.add(0x19, .escapeIntermediate, .execute, .escapeIntermediate)
        self.add(0x1c...0x1f, .escapeIntermediate, .execute, .escapeIntermediate)
        self.add(0x20...0x2f, .escapeIntermediate, .collect, .escapeIntermediate)
        self.add(0x7f, .escapeIntermediate, .none, .escapeIntermediate)
        self.add(0x30...0x7e, .escapeIntermediate, .dispatch, .ground)

        self.add(0x00...0x17, .escape, .execute, .escape)
        self.add(0x19, .escape, .execute, .escape)
        self.add(0x1c...0x1f, .escape, .execute, .escape)
        self.add(0x7f, .escape, .none, .escape)
        self.add(0x30...0x4f, .escape, .dispatch, .ground)
        self.add(0x51...0x57, .escape, .dispatch, .ground)
        self.add(0x59, .escape, .dispatch, .ground)
        self.add(0x5a, .escape, .dispatch, .ground)
        self.add(0x5c, .escape, .dispatch, .ground)
        self.add(0x60...0x7e, .escape, .dispatch, .ground)
        self.add(0x20...0x2f, .escape, .collect, .escapeIntermediate)
        self.add(UInt8(ascii: "X"), .escape, .start, .sosString)
        self.add(UInt8(ascii: "^"), .escape, .start, .pmString)
        self.add(UInt8(ascii: "_"), .escape, .start, .apcString)
        self.add(UInt8(ascii: "P"), .escape, .clear, .dcsEntry)
        self.add(UInt8(ascii: "["), .escape, .clear, .csiEntry)
        self.add(UInt8(ascii: "]"), .escape, .start, .oscString)

        for state in [ANSIParserState.sosString, .pmString, .apcString] {
            self.add(0x00...0x17, state, .put, state)
            self.add(0x19, state, .put, state)
            self.add(0x1c...0x1f, state, .put, state)
            self.add(0x20...0x7f, state, .put, state)
            self.add(0x1b, state, .dispatch, .escape)
            self.add(0x9c, state, .dispatch, .ground)
            self.add([0x18, 0x1a], state, .none, .ground)
        }

        self.addDCS()
        self.addCSI()
        self.addOSC()
    }

    private mutating func addDCS() {
        self.add(0x00...0x07, .dcsEntry, .none, .dcsEntry)
        self.add(0x0e...0x17, .dcsEntry, .none, .dcsEntry)
        self.add(0x19, .dcsEntry, .none, .dcsEntry)
        self.add(0x1c...0x1f, .dcsEntry, .none, .dcsEntry)
        self.add(0x7f, .dcsEntry, .none, .dcsEntry)
        self.add(0x20...0x2f, .dcsEntry, .collect, .dcsIntermediate)
        self.add(0x30...0x3b, .dcsEntry, .param, .dcsParam)
        self.add(0x3c...0x3f, .dcsEntry, .prefix, .dcsParam)
        self.add(0x08...0x0d, .dcsEntry, .put, .dcsString)
        self.add(0x1b, .dcsEntry, .put, .dcsString)
        self.add(0x40...0x7e, .dcsEntry, .start, .dcsString)

        self.add(0x00...0x17, .dcsIntermediate, .none, .dcsIntermediate)
        self.add(0x19, .dcsIntermediate, .none, .dcsIntermediate)
        self.add(0x1c...0x1f, .dcsIntermediate, .none, .dcsIntermediate)
        self.add(0x20...0x2f, .dcsIntermediate, .collect, .dcsIntermediate)
        self.add(0x7f, .dcsIntermediate, .none, .dcsIntermediate)
        self.add(0x30...0x3f, .dcsIntermediate, .start, .dcsString)
        self.add(0x40...0x7e, .dcsIntermediate, .start, .dcsString)

        self.add(0x00...0x17, .dcsParam, .none, .dcsParam)
        self.add(0x19, .dcsParam, .none, .dcsParam)
        self.add(0x1c...0x1f, .dcsParam, .none, .dcsParam)
        self.add(0x30...0x3b, .dcsParam, .param, .dcsParam)
        self.add(0x7f, .dcsParam, .none, .dcsParam)
        self.add(0x3c...0x3f, .dcsParam, .none, .dcsParam)
        self.add(0x20...0x2f, .dcsParam, .collect, .dcsIntermediate)
        self.add(0x40...0x7e, .dcsParam, .start, .dcsString)

        self.add(0x00...0x17, .dcsString, .put, .dcsString)
        self.add(0x19, .dcsString, .put, .dcsString)
        self.add(0x1c...0x1f, .dcsString, .put, .dcsString)
        self.add(0x20...0x7e, .dcsString, .put, .dcsString)
        self.add(0x7f, .dcsString, .put, .dcsString)
        self.add(0x80...0xff, .dcsString, .put, .dcsString)
        self.add(0x1b, .dcsString, .dispatch, .escape)
        self.add(0x9c, .dcsString, .dispatch, .ground)
        self.add([0x18, 0x1a], .dcsString, .none, .ground)
    }

    private mutating func addCSI() {
        self.add(0x00...0x17, .csiParam, .execute, .csiParam)
        self.add(0x19, .csiParam, .execute, .csiParam)
        self.add(0x1c...0x1f, .csiParam, .execute, .csiParam)
        self.add(0x30...0x3b, .csiParam, .param, .csiParam)
        self.add(0x7f, .csiParam, .none, .csiParam)
        self.add(0x3c...0x3f, .csiParam, .none, .csiParam)
        self.add(0x40...0x7e, .csiParam, .dispatch, .ground)
        self.add(0x20...0x2f, .csiParam, .collect, .csiIntermediate)

        self.add(0x00...0x17, .csiIntermediate, .execute, .csiIntermediate)
        self.add(0x19, .csiIntermediate, .execute, .csiIntermediate)
        self.add(0x1c...0x1f, .csiIntermediate, .execute, .csiIntermediate)
        self.add(0x20...0x2f, .csiIntermediate, .collect, .csiIntermediate)
        self.add(0x7f, .csiIntermediate, .none, .csiIntermediate)
        self.add(0x40...0x7e, .csiIntermediate, .dispatch, .ground)
        self.add(0x30...0x3f, .csiIntermediate, .none, .ground)

        self.add(0x00...0x17, .csiEntry, .execute, .csiEntry)
        self.add(0x19, .csiEntry, .execute, .csiEntry)
        self.add(0x1c...0x1f, .csiEntry, .execute, .csiEntry)
        self.add(0x7f, .csiEntry, .none, .csiEntry)
        self.add(0x40...0x7e, .csiEntry, .dispatch, .ground)
        self.add(0x20...0x2f, .csiEntry, .collect, .csiIntermediate)
        self.add(0x30...0x3b, .csiEntry, .param, .csiParam)
        self.add(0x3c...0x3f, .csiEntry, .prefix, .csiParam)
    }

    private mutating func addOSC() {
        self.add(0x00...0x06, .oscString, .none, .oscString)
        self.add(0x08...0x17, .oscString, .none, .oscString)
        self.add(0x19, .oscString, .none, .oscString)
        self.add(0x1c...0x1f, .oscString, .none, .oscString)
        self.add(0x20...0xff, .oscString, .put, .oscString)
        self.add(0x1b, .oscString, .dispatch, .escape)
        self.add(0x07, .oscString, .dispatch, .ground)
        self.add(0x9c, .oscString, .dispatch, .ground)
        self.add([0x18, 0x1a], .oscString, .none, .ground)
    }
}

private enum ASCII {
    static let zero = UInt8(ascii: "0")
    static let nine = UInt8(ascii: "9")
    static let colon = UInt8(ascii: ":")
    static let semicolon = UInt8(ascii: ";")
}

private func utf8Length(firstByte byte: UInt8) -> Int? {
    if byte <= 0b0111_1111 {
        return 1
    } else if byte >= 0b1100_0000, byte <= 0b1101_1111 {
        return 2
    } else if byte >= 0b1110_0000, byte <= 0b1110_1111 {
        return 3
    } else if byte >= 0b1111_0000, byte <= 0b1111_0111 {
        return 4
    }
    return nil
}
