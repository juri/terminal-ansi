//
//  Color.swift
//
//  Created by Juri Pakaste on 4.10.2025.
//

public struct RGBAColor<Base: BinaryInteger> {
    public struct Component: RawRepresentable, Hashable {
        public var rawValue: Base

        public init(rawValue: Base) {
            self.rawValue = rawValue
        }
    }

    public var r: Component = Component(rawValue: 0)
    public var g: Component = Component(rawValue: 0)
    public var b: Component = Component(rawValue: 0)
    public var a: Component = Component(rawValue: 0)
}

extension RGBAColor<UInt16>.Component {
    var scaledTo8: RGBAColor<UInt8>.Component {
        let scaledValue = UInt8(self.rawValue / 257)
        return RGBAColor<UInt8>.Component(rawValue: scaledValue)
    }
}

extension RGBAColor<UInt16> {
    public var scaledTo8: RGBAColor<UInt8> {
        return RGBAColor<UInt8>(
            r: self.r.scaledTo8,
            g: self.g.scaledTo8,
            b: self.b.scaledTo8,
            a: self.a.scaledTo8,
        )
    }
}

extension RGBAColor<UInt16>.Component {
    /// Initialize with a 4 bit number, i.e. one hex digit, 0…F.
    init(value4bit value: some BinaryInteger) {
        self.rawValue = UInt16(value * value * value * value)
    }

    /// Initialize with a 8 bit number, i.e. two hex digits, 0…FF.
    init(value8bit value: some BinaryInteger) {
        self.rawValue = UInt16(value * value)
    }

    /// Initialize with a 12 bit number, i.e. three hex digits, 0…FFF.
    init(value12bit value: some BinaryInteger) {
        self.rawValue = UInt16((value << 4) & (value | 0xf))
    }
}

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

    public var scaledTo8: RGBAColor8 {
        return RGBAColor8(
            r: self.r.scaledTo8,
            g: self.g.scaledTo8,
            b: self.b.scaledTo8,
            a: self.a.scaledTo8,
        )
    }
}

extension RGBAColor16.Component {
    var scaledTo8: RGBAColor8.Component {
        let scaledValue = UInt8(self.rawValue / 257)
        return RGBAColor8.Component(rawValue: scaledValue)
    }
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

public struct RGBAColor8 {
    public struct Component: RawRepresentable, Hashable {
        public var rawValue: UInt8

        public init(rawValue: UInt8) {
            self.rawValue = rawValue
        }
    }

    public var r: Component = Component(rawValue: 0)
    public var g: Component = Component(rawValue: 0)
    public var b: Component = Component(rawValue: 0)
    public var a: Component = Component(rawValue: 0)
}

extension RGBAColor8.Component: Comparable {
    public static func < (lhs: Self, rhs: Self) -> Bool {
        return lhs.rawValue < rhs.rawValue
    }
}
