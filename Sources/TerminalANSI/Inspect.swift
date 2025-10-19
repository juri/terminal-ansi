//
//  Inspect.swift
//
//  Created by Juri Pakaste on 28.9.2025.
//

import CSelect
import Foundation

enum QueryColor: Int {
    case foreground = 10
    case background = 11
}

func foregroundColor(fileHandle: FileHandle) throws(ColorReadFailure) -> RGBAColor<UInt16> {
    let report = try statusReport(fileHandle: fileHandle, queryColor: .foreground)
    let parsedColor = try parseTerminalColor(s: report)
    return parsedColor
}

func backgroundColor(fileHandle: FileHandle) throws(ColorReadFailure) -> RGBAColor<UInt16> {
    let report = try statusReport(fileHandle: fileHandle, queryColor: .background)
    let parsedColor = try parseTerminalColor(s: report)
    return parsedColor
}

enum ColorReadFailure: Error {
    case errorInSelect(Int32)
    case invalidTerminalResponse(String)
    case invalidStatusForColorRead(String)
    case notForeground
    case tcgetattrFailure
    case terminalDoesntSupportStatusReporting
    case terminalResponseReadFailure
    case unsupportedQuery
}

func parseTerminalColor(s: String) throws(ColorReadFailure) -> RGBAColor<UInt16> {
    var subs = s[...]

    if subs.hasSuffix(Codes.bel) {
        subs = subs.dropLast(Codes.bel.count)
    } else if subs.hasSuffix(Codes.esc) {
        subs = subs.dropLast(Codes.esc.count)
    } else if subs.hasSuffix(Codes.st) {
        subs = subs.dropLast(Codes.st.count)
    } else {
        throw ColorReadFailure.invalidStatusForColorRead(s)
    }

    subs = subs.dropFirst(4)
    if !subs.hasPrefix(";rgb:") {
        throw ColorReadFailure.invalidStatusForColorRead(s)
    }
    subs = subs.dropFirst(5)
    let components = subs.split(separator: "/")
    let componentCount = components.count
    if !(3...4).contains(componentCount) {
        throw ColorReadFailure.invalidStatusForColorRead(s)
    }
    var color = RGBAColor<UInt16>()
    func parseComponent(_ component: Substring) throws(ColorReadFailure) -> RGBAColor<UInt16>.Component {
        guard let i = UInt16(component, radix: 16) else { throw ColorReadFailure.invalidStatusForColorRead(s) }
        switch component.count {
        case 1: return RGBAColor<UInt16>.Component(value4bit: i)
        case 2: return RGBAColor<UInt16>.Component(value8bit: i)
        case 3: return RGBAColor<UInt16>.Component(value4bit: i)
        case 4: return RGBAColor<UInt16>.Component(rawValue: i)
        default: throw ColorReadFailure.invalidStatusForColorRead(s)
        }
    }
    color.r = try parseComponent(components[0])
    color.g = try parseComponent(components[1])
    color.b = try parseComponent(components[2])
    color.a = componentCount == 4 ? try parseComponent(components[3]) : RGBAColor<UInt16>.Component(rawValue: 0xffff)

    return color
}

func statusReport(fileHandle: FileHandle, queryColor: QueryColor) throws(ColorReadFailure) -> String {
    let term = ProcessInfo.processInfo.environment["TERM"]
    if let term, term.hasPrefix("screen") || term.hasPrefix("tmux") || term.hasPrefix("dumb") {
        throw .terminalDoesntSupportStatusReporting
    }

    guard isForeground(fileHandle: fileHandle) else {
        throw .notForeground
    }

    var originalTermios = termios()
    if tcgetattr(fileHandle.fileDescriptor, &originalTermios) == -1 {
        throw .tcgetattrFailure
    }

    defer {
        tcsetattr(fileHandle.fileDescriptor, TCSAFLUSH, &originalTermios)
    }

    var noEcho = originalTermios
    noEcho.c_lflag ^= tcflag_t(ECHO)
    noEcho.c_lflag ^= tcflag_t(ICANON)

    tcsetattr(fileHandle.fileDescriptor, TCSAFLUSH, &noEcho)

    // first, send OSC query, which is ignored by terminal which do not support it
    try? fileHandle.write(contentsOf: Data("\(Codes.osc)\(queryColor.rawValue);?\(Codes.st)".utf8))

    // then, query cursor position, should be supported by all terminals
    try? fileHandle.write(contentsOf: Data("\(Codes.csi)6n".utf8))

    let (response, isOSC) = try readNextResponse(fileHandle: fileHandle)

    // if this is not OSC response, then the terminal does not support it
    guard isOSC else {
        throw .unsupportedQuery
    }

    // read the cursor query response next and discard the result
    _ = try readNextResponse(fileHandle: fileHandle)

    // OSC response format: "\x1b]11;rgb:RRRR/GGGG/BBBB\x1b\\"
    return response
}

let oscTimeout = Duration.seconds(5)

// Helper function to wait for data with timeout using select
func waitForData(fileDescriptor: Int32, timeout: Duration) throws(ColorReadFailure) {
    let timeoutSeconds = timeout.components.seconds
    let timeoutMicroseconds = suseconds_t(timeout.components.attoseconds / 1_000_000_000_000)

    var tv = timeval(tv_sec: Int(timeoutSeconds), tv_usec: timeoutMicroseconds)

    var readfds = fd_set()

    fd_zero(&readfds)
    fd_setter(fileDescriptor, &readfds)

    while true {
        let result = select(fileDescriptor + 1, &readfds, nil, nil, &tv)

        if result == -1 {
            let error = errno
            if error == EINTR {
                continue  // Interrupted by signal, retry
            }
            throw .errorInSelect(error)
        }

        if result == 0 {
            throw .terminalResponseReadFailure
        }

        break  // Data is available
    }
}

// Helper function to read next byte with timeout
func readNextByte(fileHandle: FileHandle, unsafe: Bool = false) throws(ColorReadFailure) -> UInt8 {
    if !unsafe {
        try waitForData(fileDescriptor: fileHandle.fileDescriptor, timeout: oscTimeout)
    }

    let data: Data?
    do {
        data = try fileHandle.read(upToCount: 1)
    } catch {
        throw .terminalResponseReadFailure
    }

    guard let data = data, data.count == 1 else {
        throw .terminalResponseReadFailure
    }
    return data[0]
}

func readNextResponse(fileHandle: FileHandle) throws(ColorReadFailure) -> (response: String, isOSC: Bool) {
    let escStartByte = UInt8(Codes.esc.first!.asciiValue!)
    var start: UInt8
    repeat {
        start = try readNextByte(fileHandle: fileHandle)
    } while start != escStartByte

    var response = String(Character(UnicodeScalar(start)))

    // Next byte determines the response type: '[' for cursor position, ']' for OSC
    let responseType = try readNextByte(fileHandle: fileHandle)
    response += String(Character(UnicodeScalar(responseType)))

    let isOSCResponse: Bool
    switch responseType {
    case UInt8(ascii: "["):
        isOSCResponse = false
    case UInt8(ascii: "]"):
        isOSCResponse = true
    default:
        throw .invalidTerminalResponse(response)
    }

    // Read the rest of the response
    let belByte = UInt8(Codes.bel.first!.asciiValue!)
    while true {
        let byte = try readNextByte(fileHandle: fileHandle)
        response += String(Character(UnicodeScalar(byte)))

        if isOSCResponse {
            if byte == belByte || response.hasSuffix(Codes.st) {
                return (response: response, isOSC: true)
            }
        } else {
            // Cursor position response is terminated by 'R'
            if byte == UInt8(ascii: "R") {
                return (response: response, isOSC: false)
            }
        }

        if response.count > 100 {
            break
        }
    }

    throw .invalidTerminalResponse(response)
}

func isForeground(fileHandle: FileHandle) -> Bool {
    var pgrp = pid_t()
    guard ioctl(fileHandle.fileDescriptor, UInt(TIOCGPGRP), &pgrp) > -1 else { return false }
    return pgrp == getpgrp()
}
