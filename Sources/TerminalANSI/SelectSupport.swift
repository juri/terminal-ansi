//
//  SelectSupport.swift
//  terminal-ansi
//
//  Created by Juri Pakaste on 2.10.2025.
//

import Foundation

func fdZero(_ set: inout fd_set) {
    set.fds_bits = (0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0)
}

func fdSet(_ fd: Int32, _ set: inout fd_set) {
    let intOffset = Int(fd / 16)
    let bitOffset = Int(fd % 16)
    var fdsBits = set.fds_bits
    let mask = Int32(1 << bitOffset)

    switch intOffset {
    case 0: fdsBits.0 = fdsBits.0 | mask
    case 1: fdsBits.1 = fdsBits.1 | mask
    case 2: fdsBits.2 = fdsBits.2 | mask
    case 3: fdsBits.3 = fdsBits.3 | mask
    case 4: fdsBits.4 = fdsBits.4 | mask
    case 5: fdsBits.5 = fdsBits.5 | mask
    case 6: fdsBits.6 = fdsBits.6 | mask
    case 7: fdsBits.7 = fdsBits.7 | mask
    case 8: fdsBits.8 = fdsBits.8 | mask
    case 9: fdsBits.9 = fdsBits.9 | mask
    case 10: fdsBits.10 = fdsBits.10 | mask
    case 11: fdsBits.11 = fdsBits.11 | mask
    case 12: fdsBits.12 = fdsBits.12 | mask
    case 13: fdsBits.13 = fdsBits.13 | mask
    case 14: fdsBits.14 = fdsBits.14 | mask
    case 15: fdsBits.15 = fdsBits.15 | mask
    case 16: fdsBits.16 = fdsBits.16 | mask
    case 17: fdsBits.17 = fdsBits.17 | mask
    case 18: fdsBits.18 = fdsBits.18 | mask
    case 19: fdsBits.19 = fdsBits.19 | mask
    case 20: fdsBits.20 = fdsBits.20 | mask
    case 21: fdsBits.21 = fdsBits.21 | mask
    case 22: fdsBits.22 = fdsBits.22 | mask
    case 23: fdsBits.23 = fdsBits.23 | mask
    case 24: fdsBits.24 = fdsBits.24 | mask
    case 25: fdsBits.25 = fdsBits.25 | mask
    case 26: fdsBits.26 = fdsBits.26 | mask
    case 27: fdsBits.27 = fdsBits.27 | mask
    case 28: fdsBits.28 = fdsBits.28 | mask
    case 29: fdsBits.29 = fdsBits.29 | mask
    case 30: fdsBits.30 = fdsBits.30 | mask
    case 31: fdsBits.31 = fdsBits.31 | mask
    default: break
    }
    set.fds_bits = fdsBits
}

func fdIsSet(_ fd: Int32, _ set: inout fd_set) -> Bool {
    let intOffset = Int(fd / 32)
    let bitOffset = Int(fd % 32)
    let fdsBits = set.fds_bits
    let mask = Int32(1 << bitOffset)

    switch intOffset {
    case 0: return fdsBits.0 & mask != 0
    case 1: return fdsBits.1 & mask != 0
    case 2: return fdsBits.2 & mask != 0
    case 3: return fdsBits.3 & mask != 0
    case 4: return fdsBits.4 & mask != 0
    case 5: return fdsBits.5 & mask != 0
    case 6: return fdsBits.6 & mask != 0
    case 7: return fdsBits.7 & mask != 0
    case 8: return fdsBits.8 & mask != 0
    case 9: return fdsBits.9 & mask != 0
    case 10: return fdsBits.10 & mask != 0
    case 11: return fdsBits.11 & mask != 0
    case 12: return fdsBits.12 & mask != 0
    case 13: return fdsBits.13 & mask != 0
    case 14: return fdsBits.14 & mask != 0
    case 15: return fdsBits.15 & mask != 0
    case 16: return fdsBits.16 & mask != 0
    case 17: return fdsBits.17 & mask != 0
    case 18: return fdsBits.18 & mask != 0
    case 19: return fdsBits.19 & mask != 0
    case 20: return fdsBits.20 & mask != 0
    case 21: return fdsBits.21 & mask != 0
    case 22: return fdsBits.22 & mask != 0
    case 23: return fdsBits.23 & mask != 0
    case 24: return fdsBits.24 & mask != 0
    case 25: return fdsBits.25 & mask != 0
    case 26: return fdsBits.26 & mask != 0
    case 27: return fdsBits.27 & mask != 0
    case 28: return fdsBits.28 & mask != 0
    case 29: return fdsBits.29 & mask != 0
    case 30: return fdsBits.30 & mask != 0
    case 31: return fdsBits.31 & mask != 0
    default: return false
    }
}
