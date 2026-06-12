//
//  ANSIStringUtilities.swift
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

extension String {
    /// Returns this string with ANSI control sequences removed.
    ///
    /// Printable text and C0/C1 control characters are preserved.
    public func strippingANSISequences() -> String {
        var parser = ANSIParser()
        var result = ""
        for sequence in parser.parse(self) {
            switch sequence {
            case let .print(string):
                result += string
            case let .execute(byte):
                if let scalar = UnicodeScalar(Int(byte)) {
                    result.unicodeScalars.append(scalar)
                }
            case .escape, .csi, .osc, .dcs, .sos, .pm, .apc:
                break
            }
        }
        return result
    }

    /// The terminal display width of this string in cells, ignoring ANSI sequences.
    public var terminalDisplayWidth: Int {
        self.strippingANSISequences().terminalDisplayWidthWithoutANSI
    }

    private var terminalDisplayWidthWithoutANSI: Int {
        self.reduce(into: 0) { width, character in
            width += character.terminalDisplayWidth
        }
    }
}

extension Character {
    fileprivate var terminalDisplayWidth: Int {
        if self.isTerminalControlCharacter {
            return 0
        }
        if self.unicodeScalars.allSatisfy(\.isTerminalZeroWidth) {
            return 0
        }
        if self.isTerminalWideCharacter {
            return 2
        }
        return 1
    }

    private var isTerminalControlCharacter: Bool {
        self.unicodeScalars.allSatisfy { scalar in
            scalar.value < 0x20 || (scalar.value >= 0x7f && scalar.value < 0xa0)
        }
    }

    private var isTerminalWideCharacter: Bool {
        self.unicodeScalars.contains { scalar in
            scalar.isTerminalEmoji || scalar.isTerminalWideScalar
        }
    }
}

extension Unicode.Scalar {
    fileprivate var isTerminalZeroWidth: Bool {
        self.value == 0x200d
            || (0xfe00...0xfe0f).contains(self.value)
            || (0xe0100...0xe01ef).contains(self.value)
            || self.properties.generalCategory == .nonspacingMark
            || self.properties.generalCategory == .enclosingMark
            || self.properties.generalCategory == .format
    }

    fileprivate var isTerminalEmoji: Bool {
        self.properties.isEmojiPresentation
            || (0x1f1e6...0x1f1ff).contains(self.value)
            || (0x1f300...0x1faff).contains(self.value)
            || (0x2600...0x27bf).contains(self.value) && self.properties.isEmoji
    }

    fileprivate var isTerminalWideScalar: Bool {
        switch self.value {
        case 0x1100...0x115f,
            0x231a...0x231b,
            0x2329...0x232a,
            0x23e9...0x23ec,
            0x23f0,
            0x23f3,
            0x25fd...0x25fe,
            0x2614...0x2615,
            0x2648...0x2653,
            0x267f,
            0x2693,
            0x26a1,
            0x26aa...0x26ab,
            0x26bd...0x26be,
            0x26c4...0x26c5,
            0x26ce,
            0x26d4,
            0x26ea,
            0x26f2...0x26f3,
            0x26f5,
            0x26fa,
            0x26fd,
            0x2705,
            0x270a...0x270b,
            0x2728,
            0x274c,
            0x274e,
            0x2753...0x2755,
            0x2757,
            0x2795...0x2797,
            0x27b0,
            0x27bf,
            0x2b1b...0x2b1c,
            0x2b50,
            0x2b55,
            0x2e80...0x2e99,
            0x2e9b...0x2ef3,
            0x2f00...0x2fd5,
            0x2ff0...0x2ffb,
            0x3000...0x303e,
            0x3041...0x3096,
            0x3099...0x30ff,
            0x3105...0x312f,
            0x3131...0x318e,
            0x3190...0x31e3,
            0x31f0...0x321e,
            0x3220...0x3247,
            0x3250...0x4dbf,
            0x4e00...0xa48c,
            0xa490...0xa4c6,
            0xa960...0xa97c,
            0xac00...0xd7a3,
            0xf900...0xfaff,
            0xfe10...0xfe19,
            0xfe30...0xfe52,
            0xfe54...0xfe66,
            0xfe68...0xfe6b,
            0xff01...0xff60,
            0xffe0...0xffe6,
            0x16fe0...0x16fe4,
            0x16ff0...0x16ff1,
            0x17000...0x187f7,
            0x18800...0x18cd5,
            0x18d00...0x18d08,
            0x1b000...0x1b11e,
            0x1b150...0x1b152,
            0x1b164...0x1b167,
            0x1b170...0x1b2fb,
            0x1f200...0x1f202,
            0x1f210...0x1f23b,
            0x1f240...0x1f248,
            0x1f250...0x1f251,
            0x1f260...0x1f265,
            0x20000...0x2fffd,
            0x30000...0x3fffd:
            return true
        default:
            return false
        }
    }
}
