//
//  Color.swift
//
//  Created by Juri Pakaste on 4.10.2025.
//

/// RGBAColor16 is 16 bits per channel, range 0…65 025/FFFF.
public struct RGBAColor16 {
    public var r: RGBComponent16 = RGBComponent16(rawValue: 0)
    public var g: RGBComponent16 = RGBComponent16(rawValue: 0)
    public var b: RGBComponent16 = RGBComponent16(rawValue: 0)
    public var a: RGBComponent16 = RGBComponent16(rawValue: 0)
}

public struct RGBComponent16: RawRepresentable, Hashable {
    public var rawValue: Int

    public init(rawValue: Int) {
        self.rawValue = rawValue
    }
}

extension RGBComponent16: Comparable {
    public static func < (lhs: RGBComponent16, rhs: RGBComponent16) -> Bool {
        return lhs.rawValue < rhs.rawValue
    }
}

extension RGBComponent16 {
    /// Initialize with a 4 bit number, i.e. one hex digit, 0…F.
    init(value4bit value: Int) {
        self.rawValue = value * value * value * value
    }

    /// Initialize with a 8 bit number, i.e. two hex digits, 0…FF.
    init(value8bit value: Int) {
        self.rawValue = value * value
    }

    /// Initialize with a 12 bit number, i.e. three hex digits, 0…FFF.
    init(value12bit value: Int) {
        self.rawValue = (value << 4) & (value | 0xf)
    }
}
