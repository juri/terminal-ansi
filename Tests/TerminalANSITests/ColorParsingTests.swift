//
//  ColorParsingTests.swift
//
//  Created by Juri Pakaste on 12.10.2025.
//

import TerminalANSI
import Testing

@Suite struct ColorParsingTests {
    // MARK: RGB

    @Test func `parse rgb without a leading hash`() {
        let parsed = RGBColor<UInt8>(hexString: "ABC")
        let expectation = RGBColor<UInt8>(intR: 0xAA, g: 0xBB, b: 0xCC)
        #expect(parsed == expectation)
    }

    @Test func `parse rgb with a leading hash`() {
        let parsed = RGBColor<UInt8>(hexString: "#321")
        let expectation = RGBColor<UInt8>(intR: 0x33, g: 0x22, b: 0x11)
        #expect(parsed == expectation)
    }

    @Test func `parse rrggbb without a leading hash`() {
        let parsed = RGBColor<UInt8>(hexString: "9ABCDE")
        let expectation = RGBColor<UInt8>(intR: 0x9A, g: 0xBC, b: 0xDE)
        #expect(parsed == expectation)
    }

    @Test func `parse rrggbb with a leading hash`() {
        let parsed = RGBColor<UInt8>(hexString: "#123456")
        let expectation = RGBColor<UInt8>(intR: 0x12, g: 0x34, b: 0x56)
        #expect(parsed == expectation)
    }

    // MARK: RGBA

    @Test func `parse rgba without a leading hash`() {
        let parsed = RGBAColor<UInt8>(hexString: "ABCD")
        let expectation = RGBAColor<UInt8>(intR: 0xAA, g: 0xBB, b: 0xCC, a: 0xDD)
        #expect(parsed == expectation)
    }

    @Test func `parse rgba with a leading hash`() {
        let parsed = RGBAColor<UInt8>(hexString: "#4321")
        let expectation = RGBAColor<UInt8>(intR: 0x44, g: 0x33, b: 0x22, a: 0x11)
        #expect(parsed == expectation)
    }

    @Test func `parse rrggbbaa without a leading hash`() {
        let parsed = RGBAColor<UInt8>(hexString: "89ABCDEF")
        let expectation = RGBAColor<UInt8>(intR: 0x89, g: 0xAB, b: 0xCD, a: 0xEF)
        #expect(parsed == expectation)
    }

    @Test func `parse rrggbbaa with a leading hash`() {
        let parsed = RGBAColor<UInt8>(hexString: "#12345678")
        let expectation = RGBAColor<UInt8>(intR: 0x12, g: 0x34, b: 0x56, a: 0x78)
        #expect(parsed == expectation)
    }
}
