//
//  ANSIWrappingTests.swift
//

import TerminalANSI
import Testing

@Suite struct ANSIWrappingTests {
    @Test(arguments: [
        ("empty", "", 0, true, ""),
        ("passthrough", "foobar\n ", 0, true, "foobar\n "),
        ("pass", "foo", 4, true, "foo"),
        ("simple", "foobarfoo", 4, true, "foob\narfo\no"),
        ("line feed", "f\no\nobar", 3, true, "f\no\noba\nr"),
        ("line feed space", "foo bar\n  baz", 3, true, "foo\n ba\nr\n  b\naz"),
        ("tab", "foo\tbar", 3, true, "foo\n\tbar"),
        ("unicode space", "foo\u{a0}bar", 3, false, "foo\nbar"),
        (
            "style",
            "\u{1b}[38;2;249;38;114m(\u{1b}[0m\u{1b}[38;2;248;248;242mjust another test\u{1b}[38;2;249;38;114m)\u{1b}[0m",
            3,
            false,
            "\u{1b}[38;2;249;38;114m(\u{1b}[0m\u{1b}[38;2;248;248;242mju\nst \nano\nthe\nr t\nest\u{1b}[38;2;249;38;114m\n)\u{1b}[0m",
        ),
        (
            "hyperlink",
            "I really \u{1b}]8;;https://example.com/\u{1b}\\love\u{1b}]8;;\u{1b}\\ Go!",
            10,
            false,
            "I really \u{1b}]8;;https://example.com/\u{1b}\\l\nove\u{1b}]8;;\u{1b}\\ Go!",
        ),
        (
            "dcs",
            "\u{1b}Pq#0;2;0;0;0#1~~@@\u{1b}\\foobar",
            3,
            false,
            "\u{1b}Pq#0;2;0;0;0#1~~@@\u{1b}\\foo\nbar",
        ),
        ("emoji", "foo🫧foobar", 4, false, "foo\n🫧fo\nobar"),
        ("column", "VERTICAL", 1, false, "V\nE\nR\nT\nI\nC\nA\nL"),
    ]) func hardWrapping(
        _ name: String,
        _ input: String,
        _ width: Int,
        _ preservingSpaces: Bool,
        _ expected: String,
    ) {
        #expect(
            ANSIString.hardWrapping(input, width: width, preservingSpaces: preservingSpaces) == expected,
            "failed for \(name)",
        )
    }

    @Test(arguments: [
        ("empty", "", 0, "", ""),
        ("passthrough", "foobar\n ", 0, "", "foobar\n "),
        ("pass", "foo", 3, "", "foo"),
        ("too long", "foobarfoo", 4, "", "foobarfoo"),
        ("white space", "foo bar foo", 4, "", "foo\nbar\nfoo"),
        ("broken at spaces", "foo bars foobars", 4, "", "foo\nbars\nfoobars"),
        ("hyphen", "foo-foobar", 4, "-", "foo-\nfoobar"),
        ("emoji breakpoint", "foo😃 foobar", 4, "😃", "foo😃\nfoobar"),
        ("wide emoji breakpoint", "foo🫧 foobar", 4, "🫧", "foo🫧\nfoobar"),
        ("remove white spaces", "foo    \nb   ar   ", 4, "", "foo\nb\nar"),
        ("explicit line break", "foo bar foo\n", 4, "", "foo\nbar\nfoo\n"),
        ("explicit breaks", "\nfoo bar\n\n\nfoo\n", 4, "", "\nfoo\nbar\n\n\nfoo\n"),
        (
            "style",
            "\u{1b}[38;2;249;38;114m(\u{1b}[0m\u{1b}[38;2;248;248;242mjust another test\u{1b}[38;2;249;38;114m)\u{1b}[0m",
            3,
            "",
            "\u{1b}[38;2;249;38;114m(\u{1b}[0m\u{1b}[38;2;248;248;242mjust\nanother\ntest\u{1b}[38;2;249;38;114m)\u{1b}[0m",
        ),
        (
            "osc8",
            "สวัสดีสวัสดี\u{1b}]8;;https://example.com\u{1b}\\ สวัสดีสวัสดี\u{1b}]8;;\u{1b}\\",
            8,
            "",
            "สวัสดีสวัสดี\u{1b}]8;;https://example.com\u{1b}\\\nสวัสดีสวัสดี\u{1b}]8;;\u{1b}\\",
        ),
    ]) func wordWrapping(
        _ name: String,
        _ input: String,
        _ width: Int,
        _ breakpoints: String,
        _ expected: String,
    ) {
        #expect(
            ANSIString.wordWrapping(input, width: width, breakpoints: breakpoints) == expected,
            "failed for \(name)",
        )
    }

    @Test(arguments: [
        (
            "wrap wordwrap",
            "the quick brown foxxxxxxxxxxxxxxxx jumped over the lazy dog.",
            16,
            "",
            "the quick brown\nfoxxxxxxxxxxxxxx\nxx jumped over\nthe lazy dog.",
        ),
        (
            "simple", "I really \u{1b}[38;2;249;38;114mlove\u{1b}[0m Go!", 8, "",
            "I really\n\u{1b}[38;2;249;38;114mlove\u{1b}[0m Go!",
        ),
        ("passthrough", "hello world", 11, "", "hello world"),
        ("asian", "こんにち", 7, "", "こんに\nち"),
        ("emoji", "😃👰🏻‍♀️🫧", 2, "", "😃\n👰🏻‍♀️\n🫧"),
        (
            "long style",
            "\u{1b}[38;2;249;38;114ma really long string\u{1b}[0m",
            10,
            "",
            "\u{1b}[38;2;249;38;114ma really\nlong\nstring\u{1b}[0m",
        ),
        (
            "long style nbsp",
            "\u{1b}[38;2;249;38;114ma really\u{a0}long string\u{1b}[0m",
            10,
            "",
            "\u{1b}[38;2;249;38;114ma\nreally\u{a0}lon\ng string\u{1b}[0m",
        ),
        ("hyphen breakpoint", "a-good-offensive-cheat-code", 10, "", "a-good-\noffensive-\ncheat-code"),
        ("exact incomplete ansi", "\u{1b}[91mfoo\u{1b}[0", 3, "", "\u{1b}[91mfoo\u{1b}[0"),
        ("extra space", "foo ", 3, "", "foo"),
        ("extra space style", "\u{1b}[mfoo \u{1b}[m", 3, "", "\u{1b}[mfoo\u{1b}[m"),
        (
            "multi byte spaces",
            "A\u{202f}B\u{202f}C\u{202f}DA\u{205f}\u{205f}B\u{205f}C\u{205f}DA\u{3000}B\u{3000}C\u{3000}D", 7, "",
            "A\u{202f}B\u{202f}C\nDA\u{205f}\u{205f}B\u{205f}C\nDA\u{3000}B\nC\u{3000}D",
        ),
        ("hyphen break", "foo-bar", 5, "", "foo-\nbar"),
        ("tab", "foo\tbar", 3, "", "foo\nbar"),
        ("narrow nbsp", "0\u{202f}1\u{202f}2\u{202f}3\u{202f}4", 7, "", "0\u{202f}1\u{202f}2\u{202f}3\n4"),
        ("ideographic space", "0\u{3000}1\u{3000}2\u{3000}3\u{3000}", 7, "", "0\u{3000}1\u{3000}2\n3\u{3000}"),
    ]) func wrapping(
        _ name: String,
        _ input: String,
        _ width: Int,
        _ breakpoints: String,
        _ expected: String,
    ) {
        #expect(
            ANSIString.wrapping(input, width: width, breakpoints: breakpoints) == expected,
            "failed for \(name)",
        )
    }
}
