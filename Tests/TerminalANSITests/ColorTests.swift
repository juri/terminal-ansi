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
        #expect(
            input.scaledTo8 == expected,
            "Scaling failure, input: 0x\(String(input.rawValue, radix: 16)), expected: 0x\(String(expected.rawValue, radix: 16)), actual: 0x\(String(input.scaledTo8.rawValue, radix: 16))"
        )
    }
}
