# ``TerminalANSI``

``TerminalANSI`` is a Swift library for working with terminals and ANSI escape codes.

`TerminalANSI` is contained in a Swift package called `terminal-ansi`. Its goal is to provide policy-free
tools for inspecting the terminal and the environment and for outputting ANSI escape codes for styling output
and for invoking special terminal behavior.

## Usage

```swift
import TerminalANSI

guard let terminal = Terminal() else {
    return
}

let isDark = try terminal.hasDarkBackground()

let size = try terminal.size()
terminal.writeCodes([
    .clearScreen,
    .moveCursor(x: size.width / 2, y: size.height / 2 - 6),
    .setGraphicsRendition([
        .textRGB(isDark ? RGBColor8(intR: 0xD0, g: 0x80, b: 0xC0) : RGBColor8(intR: 0x80, g: 0x30, b: 0x60)),
    ]),
    .literal("Hello world!\n"),
    .moveCursor(x: 0, y: size.height),
    .setGraphicsRendition([
        .reset,
    ])
])
```

## Topics

### Managing the Terminal

- ``Terminal``

### Inspecting the Terminal

- ``TerminalSize``
- ``ColorMode``
- ``EnvironmentColorMode``
- ``OSCPointerShapeQuery``

### Outputting Styled Text

- ``ANSIControlCode``
- ``SetGraphicsRendition``
- ``OperatingSystemCommand``
- ``Erase``
- ``ANSICommand``

### Terminal Feature Control

- ``OSCProgress``
- ``OSCPointer``
- ``OSCCode``

### Colors

- ``RGBColor``
- ``RGBAColor``
- ``RGBAColor16``
- ``RGBAColor8``
- ``RGBColor8``
- ``HSLColor``
- ``BasicPalette``
