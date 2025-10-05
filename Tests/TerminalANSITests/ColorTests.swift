//
//  ColorTests.swift
//  terminal-ansi
//
//  Created by Juri Pakaste on 4.10.2025.
//

import TerminalANSI
import Testing

@Suite struct ColorTests {
    @Test(arguments: [
        (RGBAColor16.Component(rawValue: 0x0000), RGBAColor8.Component(rawValue: 0x00)),
        (RGBAColor16.Component(rawValue: 0x00FF), RGBAColor8.Component(rawValue: 0x00)),
        (RGBAColor16.Component(rawValue: 0x0100), RGBAColor8.Component(rawValue: 0x01)),
        (RGBAColor16.Component(rawValue: 0x01FF), RGBAColor8.Component(rawValue: 0x01)),
        (RGBAColor16.Component(rawValue: 0x1212), RGBAColor8.Component(rawValue: 0x12)),
        (RGBAColor16.Component(rawValue: 0x5000), RGBAColor8.Component(rawValue: 0x50)),
        (RGBAColor16.Component(rawValue: 0x50FF), RGBAColor8.Component(rawValue: 0x50)),
        (RGBAColor16.Component(rawValue: 0xFEFF), RGBAColor8.Component(rawValue: 0xFE)),
        (RGBAColor16.Component(rawValue: 0xFF00), RGBAColor8.Component(rawValue: 0xFF)),
        (RGBAColor16.Component(rawValue: 0xFFFF), RGBAColor8.Component(rawValue: 0xFF)),
    ]) func scale16To8(_ input: RGBAColor16.Component, _ expected: RGBAColor8.Component) {
        let result = input.scaledTo8
        #expect(
            result == expected,
            "Scaling failure, input: \(hex(input.rawValue, width: 4)), expected: \(hex(expected.rawValue, width: 2)), actual: \(hex(result.rawValue, width: 2))"
        )
    }

    @Test(arguments: [
        (0x0, 0x0000),
        (0x5, 0x5555),
        (0xA, 0xAAAA),
        (0xF, 0xFFFF),
    ]) func init16With4Bit(_ input: Int, _ expected: UInt16) {
        let result = RGBAColor16.Component(value4bit: input)
        #expect(
            result == RGBAColor16.Component(rawValue: expected),
            "Creation failure, input: \(hex(input, width: 1)), expected: \(hex(expected, width: 4)), actual: \(hex(result.rawValue, width: 4))"
        )
    }

    @Test(arguments: [
        (0x00, 0x0000),
        (0x34, 0x3434),
        (0x55, 0x5555),
        (0x96, 0x9696),
        (0xFF, 0xFFFF),
    ]) func init16With8Bit(_ input: Int, _ expected: UInt16) {
        let result = RGBAColor16.Component(value8bit: input)
        #expect(
            result == RGBAColor16.Component(rawValue: expected),
            "Creation failure, input: \(hex(input, width: 1)), expected: \(hex(expected, width: 4)), actual: \(hex(result.rawValue, width: 4))"
        )
    }

    @Test(arguments: [
        (0x000, 0x0000),
        (0x34B, 0x34BB),
        (0x555, 0x5555),
        (0x962, 0x9622),
        (0xFFF, 0xFFFF),
    ]) func init16With12Bit(_ input: Int, _ expected: UInt16) {
        let result = RGBAColor16.Component(value12bit: input)
        #expect(
            result == RGBAColor16.Component(rawValue: expected),
            "Creation failure, input: \(hex(input, width: 1)), expected: \(hex(expected, width: 4)), actual: \(hex(result.rawValue, width: 4))"
        )
    }

    @Test func rgbaToRGB() {
        let r = RGBAColor16.Component(rawValue: 0x1234)
        let g = RGBAColor16.Component(rawValue: 0x5678)
        let b = RGBAColor16.Component(rawValue: 0xABCD)
        let a = RGBAColor16.Component(rawValue: 0x5555)
        #expect(RGBColor(rgba: RGBAColor16(r: r, g: g, b: b, a: a)) == RGBColor<UInt16>(r: r, g: g, b: b))
    }

    @Test(arguments: [
        (0x1234, 0.071107, 0.00001),
        (0x7FFF, 0.499992, 0.00001),
        (0xF000, 0.937514, 0.00001),
    ]) func asDouble(_ input: UInt16, _ expected: Double, _ accuracy: Double) {
        let c = RGBAColor16.Component(rawValue: input)
        let cd = c.asDouble
        #expect(cd > expected && cd < (expected + accuracy))
    }

    @Test(arguments: [
        (0.0, 0x0000),
        (0.5, 0x7FFF),
        (1.0, 0xFFFF),
    ]) func fromDouble(_ value: Double, _ expected: UInt16) {
        let comp = RGBAColor16.Component(percentage: value)
        #expect(
            comp.rawValue == expected,
            "Conversion failure, value: \(value), expected: \(hex(expected, width: 4)), actual: \(hex(comp.rawValue, width: 4))"
        )
    }
}

private func hex(_ int: some BinaryInteger, width: Int) -> String {
    let s = String(int, radix: 16, uppercase: true)
    let length = s.count
    let padding = width - length
    let full = padding > 0 ? String(repeating: "0", count: padding) + s : s
    return "0x" + full
}
