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
}
