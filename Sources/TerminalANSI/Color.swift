//
//  Color.swift
//
//  Created by Juri Pakaste on 4.10.2025.
//

/// RGBAColor16 is 16 bits per channel, range 0…65 025/FFFF.
public struct RGBAColor16 {
    public struct Component: RawRepresentable, Hashable {
        public var rawValue: Int

        public init(rawValue: Int) {
            self.rawValue = rawValue
        }
    }

    public var r: Component = Component(rawValue: 0)
    public var g: Component = Component(rawValue: 0)
    public var b: Component = Component(rawValue: 0)
    public var a: Component = Component(rawValue: 0)
}

extension RGBAColor16.Component: Comparable {
    public static func < (lhs: Self, rhs: Self) -> Bool {
        return lhs.rawValue < rhs.rawValue
    }
}

extension RGBAColor16.Component {
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
