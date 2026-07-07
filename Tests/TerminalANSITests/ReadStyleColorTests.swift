//
//  ReadStyleColorTests.swift
//  terminal-ansi
//

import TerminalANSI
import Testing

@Suite struct ReadStyleColorTests {
    @Test func `reads legacy semicolon RGB color`() {
        var parameters: ArraySlice<ANSIParameter> = [
            ANSIParameter(value: 38),
            ANSIParameter(value: 2),
            ANSIParameter(value: 255),
            ANSIParameter(value: 0),
            ANSIParameter(value: 128),
            ANSIParameter(value: 1),
        ][...]

        #expect(readStyleColor(&parameters) == .rgb(RGBColor8(intR: 255, g: 0, b: 128)))
        #expect(Array(parameters) == [ANSIParameter(value: 1)])
    }

    @Test func `reads colon RGB color with omitted color space id`() {
        var parameters: ArraySlice<ANSIParameter> = [
            ANSIParameter(value: 48, hasMore: true),
            ANSIParameter(value: 2, hasMore: true),
            ANSIParameter(value: nil, hasMore: true),
            ANSIParameter(value: 12, hasMore: true),
            ANSIParameter(value: 34, hasMore: true),
            ANSIParameter(value: 56),
            ANSIParameter(value: 7),
        ][...]

        #expect(readStyleColor(&parameters) == .rgb(RGBColor8(intR: 12, g: 34, b: 56)))
        #expect(Array(parameters) == [ANSIParameter(value: 7)])
    }

    @Test func `reads indexed color into basic palette`() {
        var parameters: ArraySlice<ANSIParameter> = [
            ANSIParameter(value: 38),
            ANSIParameter(value: 5),
            ANSIParameter(value: 4),
        ][...]

        #expect(readStyleColor(&parameters) == .indexed(.blue))
        #expect(parameters.isEmpty)
    }

    @Test func `reads bright indexed color into basic palette`() {
        var parameters: ArraySlice<ANSIParameter> = [
            ANSIParameter(value: 38),
            ANSIParameter(value: 5),
            ANSIParameter(value: 12),
        ][...]

        #expect(readStyleColor(&parameters) == .indexedBright(.blue))
        #expect(parameters.isEmpty)
    }

    @Test func `reads extended indexed color`() {
        var parameters: ArraySlice<ANSIParameter> = [
            ANSIParameter(value: 38, hasMore: true),
            ANSIParameter(value: 5, hasMore: true),
            ANSIParameter(value: 234),
        ][...]

        #expect(readStyleColor(&parameters) == .indexed256(234))
        #expect(parameters.isEmpty)
    }

    @Test func `reads RGBA color`() {
        var parameters: ArraySlice<ANSIParameter> = [
            ANSIParameter(value: 58, hasMore: true),
            ANSIParameter(value: 6, hasMore: true),
            ANSIParameter(value: nil, hasMore: true),
            ANSIParameter(value: 10, hasMore: true),
            ANSIParameter(value: 20, hasMore: true),
            ANSIParameter(value: 30, hasMore: true),
            ANSIParameter(value: 40),
        ][...]

        #expect(readStyleColor(&parameters) == .rgba(RGBAColor8(intR: 10, g: 20, b: 30, a: 40)))
        #expect(parameters.isEmpty)
    }

    @Test func `does not consume mixed separators`() {
        let original = [
            ANSIParameter(value: 38, hasMore: true),
            ANSIParameter(value: 2),
            ANSIParameter(value: 255),
            ANSIParameter(value: 0),
            ANSIParameter(value: 128),
        ]
        var parameters = original[...]

        #expect(readStyleColor(&parameters) == nil)
        #expect(Array(parameters) == original)
    }
}
