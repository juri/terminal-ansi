//
//  EnvironmentColorMode.swift
//
//  Created by Juri Pakaste on 25.10.2025.
//

import Foundation

/// Environment-based color mode.
///
/// This value is determined by the environment variables `NO_COLOR`, `CLICOLOR_FORCE` and `CLICOLOR`, as specified
/// in [https://bixense.com/clicolors/].
///
/// [https://bixense.com/clicolors/]: https://bixense.com/clicolors/
public enum EnvironmentColorMode {
    /// Colors should not be used, no matter what.
    case disable

    /// Colors are enabled if the output device allows them.
    case enable

    /// Colors should be used regardless of the output device.
    case force

    /// Nothing found in the environment to tell if colors should be used.
    case none

    /// Create an `EnvironmentColorMode` from the environment variables.
    ///
    /// - Parameter environment: Environment variables. If nil, current process environment is used.
    public static func current(
        environment: [String: String]? = nil
    ) -> EnvironmentColorMode {
        let env = environment ?? ProcessInfo.processInfo.environment

        if env["NO_COLOR"] != nil { return .disable }
        if env["CLICOLOR_FORCE"] != nil { return .force }
        if env["CLICOLOR"] != nil { return .enable }
        return .none
    }

    /// Tells if colors should be used, assuming the output device allows them and you'd prefer to use them.
    ///
    /// This method assumes you'd prefer to use colors — you are using this library, after all — and
    /// want to know if it's feasible given the current environment and the given output device.
    ///
    /// - Parameter fileHandle: The output device.
    /// - Returns: true if `fileHandle` is a TTY and the value isn't ``EnvironmentColorMode/disable``.
    public func shouldUseColorIfPossible(
        fileHandle: FileHandle,
    ) -> Bool {
        switch self {
        case .disable:
            false
        case .enable:
            isatty(fileHandle.fileDescriptor) == 1
        case .force:
            true
        case .none:
            isatty(fileHandle.fileDescriptor) == 1
        }
    }
}
