//
//  ANSIWrapping.swift
//

// Based on the ANSI wrapping tools by Charmbracelet in https://github.com/charmbracelet/x/tree/main/ansi
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

extension ANSIString {
    /// Wraps text to `width` cells, breaking words when needed.
    ///
    /// ANSI escape sequences are preserved and ignored for display width.
    public static func hardWrapping(
        _ string: String,
        width: Int,
        preservingSpaces: Bool = false,
    ) -> String {
        guard width >= 1 else { return string }

        var result = ""
        var currentWidth = 0
        var forceNewline = false

        func addNewline() {
            result.append("\n")
            currentWidth = 0
        }

        for token in ANSIRawToken.tokenize(string) {
            switch token {
            case let .control(raw):
                result.append(raw)

            case let .text(raw, character, characterWidth):
                if character == "\n" {
                    addNewline()
                    forceNewline = false
                    continue
                }

                let wrappingWidth = characterWidth == 0 && character.isTerminalControlCharacter ? 1 : characterWidth
                if currentWidth + wrappingWidth > width {
                    addNewline()
                    forceNewline = true
                }

                if currentWidth == 0 {
                    if !preservingSpaces, forceNewline, character.isWhitespace {
                        continue
                    }
                    forceNewline = false
                }

                result.append(raw)
                currentWidth += characterWidth
            }
        }

        return result
    }

    /// Wraps text to `width` cells without breaking words.
    ///
    /// ANSI escape sequences are preserved and ignored for display width. A
    /// hyphen is always a breakpoint; `breakpoints` can provide additional
    /// one-cell breakpoint characters.
    public static func wordWrapping(
        _ string: String,
        width: Int,
        breakpoints: String = "",
    ) -> String {
        guard width >= 1 else { return string }

        var result = ""
        var word = ""
        var space = ""
        var currentWidth = 0
        var wordWidth = 0

        func addSpace() {
            currentWidth += space.count
            result.append(space)
            space.removeAll(keepingCapacity: true)
        }

        func addWord() {
            guard !word.isEmpty else { return }
            addSpace()
            currentWidth += wordWidth
            result.append(word)
            word.removeAll(keepingCapacity: true)
            wordWidth = 0
        }

        func addNewline() {
            result.append("\n")
            currentWidth = 0
            space.removeAll(keepingCapacity: true)
        }

        for token in ANSIRawToken.tokenize(string) {
            switch token {
            case let .control(raw):
                word.append(raw)

            case let .text(raw, character, characterWidth):
                switch character {
                case "\n":
                    if wordWidth == 0 {
                        if currentWidth + space.count > width {
                            currentWidth = 0
                        } else {
                            result.append(space)
                        }
                        space.removeAll(keepingCapacity: true)
                    }

                    addWord()
                    addNewline()

                case _ where character.isBreakingWhitespace:
                    addWord()
                    space.append(raw)

                case _ where character.isWrappingBreakpoint(in: breakpoints):
                    addSpace()
                    addWord()
                    result.append(raw)
                    currentWidth += characterWidth

                default:
                    word.append(raw)
                    wordWidth += characterWidth
                    if currentWidth + space.count + wordWidth > width, wordWidth < width {
                        addNewline()
                    }
                }
            }
        }

        addWord()

        return result
    }

    /// Wraps text to `width` cells, preferring word boundaries and breaking long
    /// words only when needed.
    ///
    /// ANSI escape sequences are preserved and ignored for display width. A
    /// hyphen is always a breakpoint; `breakpoints` can provide additional
    /// one-cell breakpoint characters.
    public static func wrapping(
        _ string: String,
        width: Int,
        breakpoints: String = "",
    ) -> String {
        guard width >= 1 else { return string }

        var result = ""
        var word = ""
        var space = ""
        var spaceWidth = 0
        var currentWidth = 0
        var wordWidth = 0

        func addSpace() {
            guard spaceWidth > 0 || !space.isEmpty else { return }
            currentWidth += spaceWidth
            result.append(space)
            space.removeAll(keepingCapacity: true)
            spaceWidth = 0
        }

        func addWord() {
            guard !word.isEmpty else { return }
            addSpace()
            currentWidth += wordWidth
            result.append(word)
            word.removeAll(keepingCapacity: true)
            wordWidth = 0
        }

        func addNewline() {
            result.append("\n")
            currentWidth = 0
            space.removeAll(keepingCapacity: true)
            spaceWidth = 0
        }

        for token in ANSIRawToken.tokenize(string) {
            switch token {
            case let .control(raw):
                word.append(raw)

            case let .text(raw, character, characterWidth):
                switch character {
                case "\n":
                    if wordWidth == 0 {
                        if currentWidth + spaceWidth > width {
                            currentWidth = 0
                        } else {
                            result.append(space)
                        }
                        space.removeAll(keepingCapacity: true)
                        spaceWidth = 0
                    }

                    addWord()
                    addNewline()

                case _ where character.isBreakingWhitespace:
                    addWord()
                    space.append(raw)
                    spaceWidth += characterWidth

                case _ where character.isWrappingBreakpoint(in: breakpoints):
                    addSpace()
                    if currentWidth + wordWidth + characterWidth > width {
                        word.append(raw)
                        wordWidth += characterWidth
                    } else {
                        addWord()
                        result.append(raw)
                        currentWidth += characterWidth
                    }

                default:
                    if wordWidth + characterWidth > width {
                        addWord()
                    }

                    word.append(raw)
                    wordWidth += characterWidth

                    if currentWidth + wordWidth + spaceWidth > width {
                        addNewline()
                    }

                    if wordWidth == width {
                        addWord()
                    }
                }
            }
        }

        if wordWidth == 0 {
            if currentWidth + spaceWidth > width {
                currentWidth = 0
            } else {
                result.append(space)
            }
            space.removeAll(keepingCapacity: true)
            spaceWidth = 0
        }

        addWord()

        return result
    }
}

private enum ANSIRawToken {
    case control(String)
    case text(String, Character, Int)

    static func tokenize(_ string: String) -> [Self] {
        var parser = ANSIParser()
        var sequenceBytes: [UInt8] = []
        var textBytes: [UInt8] = []
        var tokens: [Self] = []

        func flushText() {
            guard !textBytes.isEmpty else { return }
            let text = String(decoding: textBytes, as: UTF8.self)
            for character in text {
                tokens.append(.text(String(character), character, character.terminalDisplayWidth))
            }
            textBytes.removeAll(keepingCapacity: true)
        }

        func flushControl() {
            guard !sequenceBytes.isEmpty else { return }
            flushText()
            tokens.append(.control(String(decoding: sequenceBytes, as: UTF8.self)))
            sequenceBytes.removeAll(keepingCapacity: true)
        }

        for byte in string.utf8 {
            sequenceBytes.append(byte)
            guard let sequence = parser.advance(byte) else { continue }

            switch sequence {
            case .print, .execute:
                textBytes.append(contentsOf: sequenceBytes)
                sequenceBytes.removeAll(keepingCapacity: true)

            case .escape, .csi, .osc, .dcs, .sos, .pm, .apc:
                flushControl()
            }
        }

        flushText()
        flushControl()

        return tokens
    }
}

private let nonBreakingSpace: Character = "\u{a0}"

private extension Character {
    var isBreakingWhitespace: Bool {
        self != nonBreakingSpace && self.isWhitespace
    }

    func isWrappingBreakpoint(in breakpoints: String) -> Bool {
        self == "-" || breakpoints.contains(self)
    }
}
