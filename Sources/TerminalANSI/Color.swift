//
//  Color.swift
//
//  Created by Juri Pakaste on 4.10.2025.
//

/// `RGBColor` is RGB color with Base as the value range of each channel.
public struct RGBColor<Base: UnsignedInteger & FixedWidthInteger & Sendable>: Hashable, Sendable {
    public typealias Component = RGBAColor<Base>.Component

    /// The red channel of the color.
    public var r: Component = Component(rawValue: 0)

    /// The green channel of the color.
    public var g: Component = Component(rawValue: 0)

    /// The blue channel of the color.
    public var b: Component = Component(rawValue: 0)

    /// Create a `RGBColor` with component values.
    public init(r: Component, g: Component, b: Component) {
        self.r = r
        self.g = g
        self.b = b
    }

    /// Initialize a `RGBColor` with percentage values in the range [0...1].
    public init(percentageR r: Double, g: Double, b: Double) {
        self.r = Component(percentage: r)
        self.g = Component(percentage: g)
        self.b = Component(percentage: b)
    }

    /// Initialize a `RGBColor` with raw component values.
    public init(rawR r: Base, g: Base, b: Base) {
        self.r = Component(rawValue: r)
        self.g = Component(rawValue: g)
        self.b = Component(rawValue: b)
    }

    /// Initialize a `RGBColor` with `Int` component values.
    public init(intR r: Int, g: Int, b: Int) {
        self.r = Component(rawValue: Base(r))
        self.g = Component(rawValue: Base(g))
        self.b = Component(rawValue: Base(b))
    }

    /// Initialize a `RGBColor` with all-zero values, i.e. as black.
    public init() {
        self.init(
            r: Component(rawValue: 0),
            g: Component(rawValue: 0),
            b: Component(rawValue: 0),
        )
    }
}

extension RGBColor<UInt16> {
    /// Scale a `RGBColor` from 16 bit channels to 8 bit channels.
    public var scaledTo8: RGBColor<UInt8> {
        return RGBColor<UInt8>(
            r: self.r.scaledTo8,
            g: self.g.scaledTo8,
            b: self.b.scaledTo8,
        )
    }
}

extension RGBColor<UInt8> {
    /// Initialize a `RGBColor<UInt8>` from a CSS-style hex color string.
    ///
    /// Supports both 3-character (`#RGB` or `RGB`) and 6-character (`#RRGGBB` or `RRGGBB`) formats.
    /// The leading `#` is optional.
    ///
    /// - Parameter hexString: A hex color string (e.g., `"#FF0000"`, `"FF0000"`, `"#F00"`, `"F00"`)
    /// - Returns: A `RGBColor<UInt8>` if parsing succeeds, `nil` otherwise
    public init?(hexString: String) {
        let cleanedString = hexString.hasPrefix("#") ? String(hexString.dropFirst()) : hexString

        guard cleanedString.allSatisfy({ $0.isHexDigit }) else {
            return nil
        }

        switch cleanedString.count {
        case 3:
            // 3-character format: RGB -> RRGGBB
            let rs = cleanedString.prefix(1)
            let gs = cleanedString.dropFirst().prefix(1)
            let bs = cleanedString.dropFirst(2).prefix(1)

            guard let r = UInt8(rs, radix: 16),
                let g = UInt8(gs, radix: 16),
                let b = UInt8(bs, radix: 16)
            else {
                return nil
            }

            // Expand each digit: F -> FF (15 -> 255)
            self.init(rawR: r * 17, g: g * 17, b: b * 17)

        case 6:
            // 6-character format: RRGGBB
            let rs = String(cleanedString.prefix(2))
            let gs = String(cleanedString.dropFirst(2).prefix(2))
            let bs = String(cleanedString.dropFirst(4).prefix(2))

            guard let r = UInt8(rs, radix: 16),
                let g = UInt8(gs, radix: 16),
                let b = UInt8(bs, radix: 16)
            else {
                return nil
            }

            self.init(rawR: r, g: g, b: b)

        default:
            return nil
        }
    }
}

extension RGBColor {
    /// Convert a ``RGBAColor`` into a `RGBColor`, dropping the alpha channel.
    public init(rgba: RGBAColor<Base>) {
        self.init(r: rgba.r, g: rgba.g, b: rgba.b)
    }

    /// Create a `RGBColor` from a ``HSLColor``.
    public init(hsl: HSLColor) {
        guard hsl.saturation > 0 else {
            let gray = Component(percentage: hsl.luminance)
            self.init(r: gray, g: gray, b: gray)
            return
        }

        let t1: Double =
            if hsl.luminance < 0.5 {
                hsl.luminance * (1.0 + hsl.saturation)
            } else {
                hsl.luminance + hsl.saturation - (hsl.luminance * hsl.saturation)
            }

        let t2 = 2 * hsl.luminance - t1
        let hue = hsl.hue / 360
        var tr = hue + 1.0 / 3.0
        var tg = hue
        var tb = hue - 1.0 / 3.0

        if tr < 0.0 { tr += 1.0 }
        if tr > 1.0 { tr -= 1.0 }

        if tg < 0.0 { tg += 1.0 }
        if tg > 1.0 { tg -= 1.0 }

        if tb < 0.0 { tb += 1.0 }
        if tb > 1.0 { tb -= 1.0 }

        let red = colorComponent(t: tr, t1: t1, t2: t2)
        let green = colorComponent(t: tg, t1: t1, t2: t2)
        let blue = colorComponent(t: tb, t1: t1, t2: t2)

        self.init(
            r: Component(percentage: red),
            g: Component(percentage: green),
            b: Component(percentage: blue),
        )
    }
}

private func colorComponent(t: Double, t1: Double, t2: Double) -> Double {
    if 6.0 * t < 1.0 {
        t2 + (t1 - t2) * 6 * t
    } else if 2.0 * t < 1 {
        t1
    } else if 3.0 * t < 2.0 {
        t2 + (t1 - t2) * (2.0 / 3.0 - t) * 6.0
    } else {
        t2
    }
}

/// `RGBColor8` is 8 bits per channel, range 0…255/FF.
public typealias RGBColor8 = RGBColor<UInt8>

/// `RGBAColor` is RGBA color with `Base` as the value range of each channel.
public struct RGBAColor<Base: UnsignedInteger & FixedWidthInteger & Sendable>: Hashable, Sendable {
    public struct Component: RawRepresentable, Hashable, Sendable {
        public var rawValue: Base

        public init(rawValue: Base) {
            self.rawValue = rawValue
        }
    }

    /// The red channel of the color.
    public var r: Component

    /// The green channel of the color.
    public var g: Component

    /// The blue channel of the color.
    public var b: Component

    /// The alpha channel of the color.
    public var a: Component

    /// Create a `RGBAColor` with component values.
    public init(r: Component, g: Component, b: Component, a: Component) {
        self.r = r
        self.g = g
        self.b = b
        self.a = a
    }

    /// Initialize a `RGBAColor` with raw component values.
    public init(rawR r: Base, g: Base, b: Base, a: Base) {
        self.r = Component(rawValue: r)
        self.g = Component(rawValue: g)
        self.b = Component(rawValue: b)
        self.a = Component(rawValue: a)
    }

    /// Initialize a `RGBAColor` with `Int` component values.
    public init(intR r: Int, g: Int, b: Int, a: Int) {
        self.r = Component(rawValue: Base(r))
        self.g = Component(rawValue: Base(g))
        self.b = Component(rawValue: Base(b))
        self.a = Component(rawValue: Base(a))
    }

    /// Initialize a `RGBColor` with all-zero values, i.e. as transparent black.
    public init() {
        self.init(
            r: Component(rawValue: 0),
            g: Component(rawValue: 0),
            b: Component(rawValue: 0),
            a: Component(rawValue: 0),
        )
    }
}

extension RGBAColor<UInt8> {
    /// Initialize a `RGBAColor<UInt8>` from a CSS-style hex color string with alpha.
    ///
    /// Supports both 4-character (`#RGBA` or `RGBA`) and 8-character (`#RRGGBBAA` or `RRGGBBAA`) formats.
    /// The leading `#` is optional.
    ///
    /// - Parameter hexString: A hex color string (e.g., "#FF0000FF", "FF0000FF", "#F00F", "F00F")
    /// - Returns: A `RGBAColor<UInt8>` if parsing succeeds, `nil` otherwise
    public init?(hexString: String) {
        let cleanedString = hexString.hasPrefix("#") ? String(hexString.dropFirst()) : hexString

        guard cleanedString.allSatisfy({ $0.isHexDigit }) else {
            return nil
        }

        switch cleanedString.count {
        case 4:
            // 4-character format: RGBA -> RRGGBBAA
            let rs = cleanedString.prefix(1)
            let gs = cleanedString.dropFirst().prefix(1)
            let bs = cleanedString.dropFirst(2).prefix(1)
            let `as` = cleanedString.dropFirst(3).prefix(1)

            guard let r = UInt8(rs, radix: 16),
                let g = UInt8(gs, radix: 16),
                let b = UInt8(bs, radix: 16),
                let a = UInt8(`as`, radix: 16)
            else {
                return nil
            }

            // Expand each digit: F -> FF (15 -> 255)
            self.init(rawR: r * 17, g: g * 17, b: b * 17, a: a * 17)

        case 8:
            // 8-character format: RRGGBBAA
            let rs = String(cleanedString.prefix(2))
            let gs = String(cleanedString.dropFirst(2).prefix(2))
            let bs = String(cleanedString.dropFirst(4).prefix(2))
            let `as` = String(cleanedString.dropFirst(6).prefix(2))

            guard let r = UInt8(rs, radix: 16),
                let g = UInt8(gs, radix: 16),
                let b = UInt8(bs, radix: 16),
                let a = UInt8(`as`, radix: 16)
            else {
                return nil
            }

            self.init(rawR: r, g: g, b: b, a: a)

        default:
            return nil
        }
    }
}

extension RGBAColor {
    /// Initialize a `RGBAColor` with a ``RGBColor`` and an alpha channel.
    public init(rgb: RGBColor<Base>, a: Component = .max) {
        self.init(r: rgb.r, g: rgb.g, b: rgb.b, a: a)
    }
}

extension RGBAColor<UInt16>.Component {
    /// Scale a `UInt16` based `RGBAColor.Component` to a `UInt8` based one.
    public var scaledTo8: RGBAColor<UInt8>.Component {
        // No idea if this is the best way to do it. This way everything from 0x0000 to 0x00FF goes
        // to 0x00. Maybe everything from 0x007F should be rounded to 0x01? That way the buckets
        // for 0x00 and 0xFF would be smaller than for everything in between, though.
        let scaledValue = UInt8(self.rawValue >> 8)
        return RGBAColor<UInt8>.Component(rawValue: scaledValue)
    }
}

extension RGBAColor<UInt16> {
    /// Scale a `UInt16` based `RGBAColor` to a `UInt8` based one.
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
    ///
    /// The number is repeated four times, i.e. 0x3 becomes 0x3333.
    public init(value4bit value: some BinaryInteger) {
        self.rawValue = UInt16(value << 12 | value << 8 | value << 4 | value)
    }

    /// Initialize with a 8 bit number, i.e. two hex digits, 0…FF.
    ///
    /// The number is repeated, i.e. 0x37 becomes 0x3737.
    public init(value8bit value: some BinaryInteger) {
        self.rawValue = UInt16(value << 8 | value)
    }

    /// Initialize with a 12 bit number, i.e. three hex digits, 0…FFF.
    ///
    /// The last number is repeated, i.e. 0x379 becomes 0x3799.
    public init(value12bit value: some BinaryInteger) {
        self.rawValue = UInt16((value << 4) | (value & 0xf))
    }
}

extension RGBAColor.Component {
    /// Minimum value for this component type.
    public static var min: Self { Self(rawValue: 0) }

    /// Maximum value for this component type.
    public static var max: Self { Self(rawValue: Base.max) }

    /// Convert the value of this component to a percentage, in the range [0...1].
    public var percentage: Double { Double(self.rawValue) / Double(Base.max) }

    /// Initialize with a percentage, range [0...1].
    public init(percentage: Double) {
        self.init(rawValue: Base(Double(Base.max) * Swift.min(percentage, Swift.max(0.0, percentage))))
    }
}

/// `RGBAColor16` is 16 bits per channel, range 0…65 025/FFFF.
public typealias RGBAColor16 = RGBAColor<UInt16>

/// `RGBAColor8` is 8 bits per channel, range 0…255/FF.
public typealias RGBAColor8 = RGBAColor<UInt8>

/// A terminal color decoded from SGR color parameters.
public enum Color: Equatable, Sendable {
    /// The terminal should use an implementation-defined color.
    case implementationDefined

    /// A transparent color.
    case transparent

    /// A 24-bit RGB color.
    case rgb(RGBColor8)

    /// A 32-bit RGBA color.
    case rgba(RGBAColor8)

    /// One of the first eight indexed ANSI colors.
    case indexed(BasicPalette)

    /// One of the bright indexed ANSI colors.
    case indexedBright(BasicPalette)

    /// An indexed ANSI 256-color value outside the basic palette.
    case indexed256(Int)
}

/// Decode a color from SGR color parameters.
///
/// This reads parameters beginning with the SGR color selector, such as `38`, `48`, or `58`.
/// The consumed parameters are removed from `parameters` when decoding succeeds.
public func readStyleColor(_ parameters: inout ArraySlice<ANSIParameter>) -> Color? {
    let params = Array(parameters)
    guard params.count >= 2 else { return nil }

    let selector = params[0]
    let colorType = params[1]
    var consumedCount = 2

    func parameter(_ index: Int, default defaultValue: Int = 0) -> Int {
        params[index].value(default: defaultValue)
    }

    func colorParameters() -> (Int, Int, Int, Int)? {
        switch true {
        case selector.hasMore && colorType.hasMore && params.count > 8
            && params[2].hasMore && params[3].hasMore && params[4].hasMore && params[5].hasMore
            && params[6].hasMore && params[7].hasMore:
            consumedCount += 7
            return (parameter(3), parameter(4), parameter(5), parameter(6))

        case selector.hasMore && colorType.hasMore && params.count > 7
            && params[2].hasMore && params[3].hasMore && params[4].hasMore && params[5].hasMore
            && params[6].hasMore:
            consumedCount += 6
            return (parameter(3), parameter(4), parameter(5), parameter(6))

        case selector.hasMore && colorType.hasMore && params.count > 6
            && params[2].hasMore && params[3].hasMore && params[4].hasMore && params[5].hasMore:
            consumedCount += 5
            return (parameter(3), parameter(4), parameter(5), parameter(6))

        case selector.hasMore && colorType.hasMore && params.count > 5
            && params[2].hasMore && params[3].hasMore && params[4].hasMore && !params[5].hasMore:
            consumedCount += 4
            return (parameter(3), parameter(4), parameter(5), -1)

        // The format config specifies NoCasesWithOnlyFallthrough, but in this cases the
        // fallthrough is just way more readable than using comma.
        // swift-format-ignore
        case selector.hasMore && colorType.hasMore && parameter(1) == 2 && params.count > 4
            && params[2].hasMore && params[3].hasMore && !params[4].hasMore:
            fallthrough

        case !selector.hasMore && !colorType.hasMore && parameter(1) == 2 && params.count > 4
            && !params[2].hasMore && !params[3].hasMore && !params[4].hasMore:
            consumedCount += 3
            return (parameter(2), parameter(3), parameter(4), -1)

        default:
            return nil
        }
    }

    func component(_ value: Int) -> UInt8 {
        UInt8(truncatingIfNeeded: value)
    }

    func indexedColor(_ value: Int) -> Color {
        let index = Int(UInt8(truncatingIfNeeded: value))
        switch index {
        case 0...7:
            return .indexed(BasicPalette(rawValue: index)!)
        case 8...15:
            return .indexedBright(BasicPalette(rawValue: index - 8)!)
        default:
            return .indexed256(index)
        }
    }

    let color: Color
    switch parameter(1) {
    case 0:
        color = .implementationDefined

    case 1:
        color = .transparent

    case 2:
        guard params.count >= 5, let values = colorParameters(), values.0 != -1, values.1 != -1, values.2 != -1
        else { return nil }
        color = .rgb(RGBColor8(rawR: component(values.0), g: component(values.1), b: component(values.2)))

    case 5:
        guard params.count >= 3 else { return nil }
        switch true {
        case selector.hasMore && colorType.hasMore && !params[2].hasMore:
            break
        case !selector.hasMore && !colorType.hasMore && !params[2].hasMore:
            break
        default:
            return nil
        }
        consumedCount = 3
        color = indexedColor(parameter(2))

    case 6:
        guard params.count >= 6, let values = colorParameters(),
            values.0 != -1, values.1 != -1, values.2 != -1, values.3 != -1
        else { return nil }
        color = .rgba(
            RGBAColor8(
                rawR: component(values.0),
                g: component(values.1),
                b: component(values.2),
                a: component(values.3),
            )
        )

    default:
        return nil
    }

    parameters = parameters.dropFirst(consumedCount)
    return color
}

/// `HSLColor` represents color as hue ([0...359]), saturation ([0...1]) and luminance ([0...1]).
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
        self.init(red: rgb.r.percentage, green: rgb.g.percentage, blue: rgb.b.percentage)
    }

    /// Create a `HSLColor` from a ``RGBAColor``.
    init<Base>(rgba: RGBAColor<Base>) {
        self.init(rgb: RGBColor<Base>(rgba: rgba))
    }
}
