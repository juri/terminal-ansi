//
//  ANSIParserTests.swift
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

import Synchronization
import TerminalANSI
import Testing

@Suite struct ANSIParserTests {
    @Test func `parses printable text`() {
        var parser = ANSIParser()
        #expect(parser.parse("Hi") == [.print("H"), .print("i")])
    }

    @Test func `parses C0 controls`() {
        var parser = ANSIParser()
        #expect(parser.parse("a\nb") == [.print("a"), .execute(0x0a), .print("b")])
    }

    @Test func `parses CSI without parameters`() {
        var parser = ANSIParser()
        #expect(parser.parse("\u{1b}[m") == [.csi(ANSIControlSequence(finalByte: UInt8(ascii: "m")))])
    }

    @Test func `parses CSI parameters and omitted parameters`() {
        var parser = ANSIParser()
        #expect(
            parser.parse("\u{1b}[;4;m") == [
                .csi(
                    ANSIControlSequence(
                        finalByte: UInt8(ascii: "m"),
                        parameters: [
                            ANSIParameter(value: nil),
                            ANSIParameter(value: 4),
                            ANSIParameter(value: nil),
                        ],
                    )
                )
            ]
        )
    }

    @Test func `parses CSI prefix intermediate and subparameters`() {
        var parser = ANSIParser()
        #expect(
            parser.parse("\u{1b}[?38:2:255:0:255$m") == [
                .csi(
                    ANSIControlSequence(
                        finalByte: UInt8(ascii: "m"),
                        prefixByte: UInt8(ascii: "?"),
                        intermediateByte: UInt8(ascii: "$"),
                        parameters: [
                            ANSIParameter(value: 38, hasMore: true),
                            ANSIParameter(value: 2, hasMore: true),
                            ANSIParameter(value: 255, hasMore: true),
                            ANSIParameter(value: 0, hasMore: true),
                            ANSIParameter(value: 255),
                        ],
                    )
                )
            ]
        )
    }

    @Test func `parses 8-bit CSI from bytes`() {
        var parser = ANSIParser()
        #expect(
            parser.parse([0x9b, 0x33, 0x38, 0x3b, 0x35, 0x3b, 0x31, 0x6d]) == [
                .csi(
                    ANSIControlSequence(
                        finalByte: UInt8(ascii: "m"),
                        parameters: [
                            ANSIParameter(value: 38),
                            ANSIParameter(value: 5),
                            ANSIParameter(value: 1),
                        ],
                    )
                )
            ]
        )
    }

    @Test func `parses ESC sequence with intermediate`() {
        var parser = ANSIParser()
        #expect(
            parser.parse("\u{1b}(A") == [
                .escape(
                    ANSIEscapeSequence(
                        finalByte: UInt8(ascii: "A"),
                        intermediateByte: UInt8(ascii: "("),
                    )
                )
            ]
        )
    }

    @Test func `parses OSC sequences`() {
        var parser = ANSIParser()
        #expect(
            parser.parse("\u{1b}]2;title\u{7}") == [
                .osc(ANSIOSCSequence(command: 2, data: Array("2;title".utf8)))
            ]
        )
    }

    @Test func `parses OSC with ST terminator`() {
        var parser = ANSIParser()
        #expect(
            parser.parse("\u{1b}]11;ff/00/ff\u{1b}\\") == [
                .osc(ANSIOSCSequence(command: 11, data: Array("11;ff/00/ff".utf8))),
                .escape(ANSIEscapeSequence(finalByte: UInt8(ascii: "\\"))),
            ]
        )
    }

    @Test func `parses DCS sequences`() {
        var parser = ANSIParser()
        #expect(
            parser.parse("\u{1b}P1;2+xa\u{7f}b\u{1b}\\") == [
                .dcs(
                    ANSIDCSSequence(
                        finalByte: UInt8(ascii: "x"),
                        intermediateByte: UInt8(ascii: "+"),
                        parameters: [
                            ANSIParameter(value: 1),
                            ANSIParameter(value: 2),
                        ],
                        data: [UInt8(ascii: "a"), 0x7f, UInt8(ascii: "b")],
                    )
                ),
                .escape(ANSIEscapeSequence(finalByte: UInt8(ascii: "\\"))),
            ]
        )
    }

    @Test func `parses UTF-8 printable characters`() {
        var parser = ANSIParser()
        #expect(parser.parse("👋Ä") == [.print("👋"), .print("Ä")])
    }

    @Test func `parses SOS PM and APC strings`() {
        var parser = ANSIParser()
        #expect(parser.parse("\u{1b}Xone\u{1b}\\").first == .sos(Array("one".utf8)))

        parser.reset()
        #expect(parser.parse("\u{1b}^two\u{1b}\\").first == .pm(Array("two".utf8)))

        parser.reset()
        #expect(parser.parse("\u{1b}_three\u{1b}\\").first == .apc(Array("three".utf8)))
    }

    @Test func `handler monitors parsed sequences`() {
        let events: Mutex<[ANSISequence]> = .init([])
        var parser = ANSIParser(
            handler: ANSIParserHandler(
                print: { p in events.withLock { $0.append(.print(p)) } },
                execute: { p in events.withLock { $0.append(.execute(p)) } },
                handleEscape: { p in events.withLock { $0.append(.escape(p)) } },
                handleCSI: { p in events.withLock { $0.append(.csi(p)) } },
                handleOSC: { p in events.withLock { $0.append(.osc(p)) } },
                handleDCS: { p in events.withLock { $0.append(.dcs(p)) } },
                handleSOS: { p in events.withLock { $0.append(.sos(p)) } },
                handlePM: { p in events.withLock { $0.append(.pm(p)) } },
                handleAPC: { p in events.withLock { $0.append(.apc(p)) } },
            )
        )

        let sequences = parser.parse(
            "A\n\u{1b}[31m\u{1b}]2;title\u{7}\u{1b}P1+qpayload\u{1b}\\\u{1b}Xone\u{1b}\\\u{1b}^two\u{1b}\\\u{1b}_three\u{1b}\\"
        )

        let collectedEvents = events.withLock { $0 }
        #expect(collectedEvents == sequences)
        #expect(collectedEvents.contains(.print("A")))
        #expect(collectedEvents.contains(.execute(0x0a)))
        #expect(
            collectedEvents.contains(
                .csi(
                    ANSIControlSequence(
                        finalByte: UInt8(ascii: "m"),
                        parameters: [ANSIParameter(value: 31)],
                    )
                )
            )
        )
        #expect(collectedEvents.contains(.osc(ANSIOSCSequence(command: 2, data: Array("2;title".utf8)))))
        #expect(collectedEvents.contains(.sos(Array("one".utf8))))
        #expect(collectedEvents.contains(.pm(Array("two".utf8))))
        #expect(collectedEvents.contains(.apc(Array("three".utf8))))
    }

    @Test func `setHandler replaces the parser handler`() {
        let prints: Mutex<[String]> = .init([])
        var parser = ANSIParser()

        parser.setHandler(ANSIParserHandler(print: { p in prints.withLock { $0.append(p) } }))
        _ = parser.parse("Hi")

        parser.setHandler(nil)
        _ = parser.parse("!")

        #expect(prints.withLock { $0 } == ["H", "i"])
    }

    @Test func `parameter helper returns default for missing and out of bounds`() {
        let sequence = ANSIControlSequence(
            finalByte: UInt8(ascii: "m"),
            parameters: [ANSIParameter(value: nil), ANSIParameter(value: 7)],
        )
        #expect(sequence.parameter(at: 0, default: 0) == 0)
        #expect(sequence.parameter(at: 1, default: 0) == 7)
        #expect(sequence.parameter(at: 9, default: 42) == 42)
    }
}
