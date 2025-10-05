//
//  Color.swift
//
//  Created by Juri Pakaste on 4.10.2025.
//

/// RGBColor is RGB color with Base as the value range of each channel.
public struct RGBColor<Base: UnsignedInteger & FixedWidthInteger & Sendable>: Hashable, Sendable {
    public typealias Component = RGBAColor<Base>.Component

    public var r: Component = Component(rawValue: 0)
    public var g: Component = Component(rawValue: 0)
    public var b: Component = Component(rawValue: 0)

    public init(r: Component, g: Component, b: Component) {
        self.r = r
        self.g = g
        self.b = b
    }

    public init() {
        self.init(
            r: Component(rawValue: 0),
            g: Component(rawValue: 0),
            b: Component(rawValue: 0),
        )
    }
}

extension RGBColor<UInt16> {
    public var scaledTo8: RGBColor<UInt8> {
        return RGBColor<UInt8>(
            r: self.r.scaledTo8,
            g: self.g.scaledTo8,
            b: self.b.scaledTo8,
        )
    }
}

extension RGBColor {
    /// Convert a ``RGBAColor`` into a `RGBColor`, dropping the alpha channel.
    public init(rgba: RGBAColor<Base>) {
        self.init(r: rgba.r, g: rgba.g, b: rgba.b)
    }
}

/// RGBColor8 is 16 bits per channel, range 0…255/FF.
public typealias RGBColor8 = RGBColor<UInt8>

/// RGBAColor is RGBA color with Base as the value range of each channel.
public struct RGBAColor<Base: UnsignedInteger & FixedWidthInteger & Sendable>: Hashable, Sendable {
    public struct Component: RawRepresentable, Hashable, Sendable {
        public var rawValue: Base

        public init(rawValue: Base) {
            self.rawValue = rawValue
        }
    }

    public var r: Component
    public var g: Component
    public var b: Component
    public var a: Component

    public init(r: Component, g: Component, b: Component, a: Component) {
        self.r = r
        self.g = g
        self.b = b
        self.a = a
    }

    public init() {
        self.init(
            r: Component(rawValue: 0),
            g: Component(rawValue: 0),
            b: Component(rawValue: 0),
            a: Component(rawValue: 0),
        )
    }
}

extension RGBAColor<UInt16>.Component {
    public var scaledTo8: RGBAColor<UInt8>.Component {
        // No idea if this is the best way to do it. This way everything from 0x0000 to 0x00FF goes
        // to 0x00. Maybe everything from 0x007F should be rounded to 0x01? That way the buckets
        // for 0x00 and 0xFF would be smaller than for everything in between, though.
        let scaledValue = UInt8(self.rawValue >> 8)
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
    public init(value4bit value: some BinaryInteger) {
        self.rawValue = UInt16(value << 12 | value << 8 | value << 4 | value)
    }

    /// Initialize with a 8 bit number, i.e. two hex digits, 0…FF.
    public init(value8bit value: some BinaryInteger) {
        self.rawValue = UInt16(value << 8 | value)
    }

    /// Initialize with a 12 bit number, i.e. three hex digits, 0…FFF.
    public init(value12bit value: some BinaryInteger) {
        self.rawValue = UInt16((value << 4) | (value & 0xf))
    }
}

extension RGBAColor.Component {
    public var min: Self { Self(rawValue: 0) }
    public var max: Self { Self(rawValue: Base.max) }

    public var asDouble: Double { Double(self.rawValue) / Double(Base.max) }

    /// Initialize with a percentage, range [0...1].
    public init(percentage: Double) {
        self.init(rawValue: Base(Double(Base.max) * Swift.min(percentage, Swift.max(0.0, percentage))))
    }
}

/// RGBAColor16 is 16 bits per channel, range 0…65 025/FFFF.
public typealias RGBAColor16 = RGBAColor<UInt16>

/// RGBAColor8 is 16 bits per channel, range 0…255/FF.
public typealias RGBAColor8 = RGBAColor<UInt8>

/// HSLColor represents color as hue ([0...359]), saturation ([0...1]) and luminance ([0...1]).
public struct HSLColor: Hashable, Sendable {
    public var hue: Double
    public var saturation: Double
    public var luminance: Double

    public init(hue: Double, saturation: Double, luminance: Double) {
        self.hue = hue
        self.saturation = saturation
        self.luminance = luminance
    }
}

public extension HSLColor {
    // Initialize a HSLColor with RGB values.
    init(red: Double, green: Double, blue: Double) {
        let minColor = min(red, green, blue)
        let maxColor = max(red, green, blue)

        self.luminance = (minColor + maxColor) / 2.0

        guard maxColor != minColor else {
            self.hue = 0.0
            self.saturation = 0.0
            return
        }

        if self.luminance < 0.5 {
            self.saturation = (maxColor - minColor) / (maxColor + minColor)
        } else {
            self.saturation = (maxColor - minColor) / (2.0 - maxColor - minColor)
        }

        if maxColor == red {
            self.hue = (green - blue) / (maxColor - minColor)
        } else if maxColor == green {
            self.hue = 2.0 + (blue - red) / (maxColor - minColor)
        } else {
            self.hue = 4.0 + (red - green) / (maxColor - minColor)
        }

        self.hue *= 60.0

        if self.hue < 0.0 {
            self.hue += 360.0
        }
    }

    /// Create a `HSLColor` from a ``RGBColor``.
    init<Base>(rgb: RGBColor<Base>) {
        self.init(red: rgb.r.asDouble, green: rgb.g.asDouble, blue: rgb.b.asDouble)
    }

    /// Create a `HSLColor` from a ``RGBAColor``.
    init<Base>(rgba: RGBAColor<Base>) {
        self.init(rgb: RGBColor<Base>(rgba: rgba))
    }
}
