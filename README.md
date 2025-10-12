[![Build](https://github.com/juri/terminal-ansi/actions/workflows/ci.yml/badge.svg)](https://github.com/juri/terminal-ansi/actions/workflows/ci.yml)
[![Build](https://github.com/juri/terminal-ansi/actions/workflows/format.yml/badge.svg)](https://github.com/juri/terminal-ansi/actions/workflows/format.yml)
[![](https://img.shields.io/endpoint?url=https%3A%2F%2Fswiftpackageindex.com%2Fapi%2Fpackages%2Fjuri%2Fterminal-ansi%2Fbadge%3Ftype%3Dswift-versions)](https://swiftpackageindex.com/juri/terminal-ansi)
[![](https://img.shields.io/endpoint?url=https%3A%2F%2Fswiftpackageindex.com%2Fapi%2Fpackages%2Fjuri%2Fterminal-ansi%2Fbadge%3Ftype%3Dplatforms)](https://swiftpackageindex.com/juri/terminal-ansi)

# terminal-ansi

This is a Swift package for outputting terminal ANSI control codes and inspecting the current terminal. It has been extracted and expanded from [tui-fuzzy-finder].

The goal of `terminal-ansi` is to provide basic low-level support for styling terminal output. For higher-level tooling, you could take a look at [terminal-styles].

[terminal-styles]: https://github.com/juri/terminal-styles

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

## Features

- Query terminal background and foreground colors
- Query terminal size
- Parse color strings (`RGB`, `RRGGBB`, `RGBA`, `RRGGBBAA`, with or without leading `#`)
- Convert color to and from HSL
- Cursor movements, alternative buffer, erasing contents
- Colors, text styles
- Hyperlinks (OSC 8)
- Terminal progress bar (OSC 9)

[tui-fuzzy-finder]: https://github.com/juri/tui-fuzzy-finder/
