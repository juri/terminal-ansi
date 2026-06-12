//
//  ANSIWidthTests.swift
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

import TerminalANSI
import Testing

@Suite struct ANSIWidthTests {
    @Test(arguments: [
        ("empty", "", "", 0),
        ("ascii", "hello", "hello", 5),
        ("emoji", "👋", "👋", 2),
        ("wide emoji", "🫧", "🫧", 2),
        ("combining", "a\u{0300}", "a\u{0300}", 1),
        ("control", "\u{1b}[31mhello\u{1b}[0m", "hello", 5),
        ("control emoji", "\u{1b}[31m👋\u{1b}[0m", "👋", 2),
        ("OSC", "\u{1b}]2;terminal title\u{9c}", "", 0),
        ("OSC title with emoji", "\u{1b}]2;title👨‍👩‍👦\u{7}", "", 0),
        ("family emoji with CSI", "\u{1b}[31m👨‍👩‍👦\u{1b}[m", "👨‍👩‍👦", 2),
        ("multi emoji CSI", "👨‍👩‍👦\u{1b}[38;5;1mhello\u{1b}[m", "👨‍👩‍👦hello", 7),
        ("OSC 8 east asian link", "\u{1b}]8;id=1;https://example.com/\u{9c}打豆豆\u{1b}]8;id=1;\u{7}", "打豆豆", 6),
        ("DCS arabic", "\u{1b}P?123$pسلام\u{1b}\\اهلا", "اهلا", 4),
        ("newline", "hello\nworld", "hello\nworld", 10),
        ("tab", "hello\tworld", "hello\tworld", 10),
        ("control newline", "\u{1b}[31mhello\u{1b}[0m\nworld", "hello\nworld", 10),
        ("style", "\u{1b}[38;2;249;38;114mfoo", "foo", 3),
        ("unicode punctuation", "\u{1b}[35m“box”\u{1b}[0m", "“box”", 5),
        ("curly apostrophe", "Claire’s Boutique", "Claire’s Boutique", 17),
        ("unclosed ANSI", "Hey, \u{1b}[7m\n猴", "Hey, \n猴", 7),
        ("double asian runes", " 你\u{1b}[8m好.", " 你好.", 6),
        ("flag", "🇸🇦", "🇸🇦", 2),
        ("half width and ascii", "(ﾟ", "(ﾟ", 1),
    ]) func `strips ANSI and measures display width`(
        _ name: String,
        _ input: String,
        _ stripped: String,
        _ width: Int,
    ) {
        #expect(input.strippingANSISequences() == stripped, "strip failed for \(name)")
        #expect(input.terminalDisplayWidth == width, "width failed for \(name)")
    }
}
