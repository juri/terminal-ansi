// swift-tools-version: 6.2

import PackageDescription

let package = Package(
    name: "terminal-ansi",
    platforms: [.macOS(.v15)],
    products: [
        .executable(
            name: "run-terminal-ansi",
            targets: ["RunTerminalANSI"],
        ),
        .library(
            name: "TerminalANSI",
            targets: ["TerminalANSI"],
        ),
    ],
    dependencies: [
        .package(url: "https://github.com/apple/swift-numerics", from: "1.0.0")
    ],
    targets: [
        .executableTarget(
            name: "RunTerminalANSI",
            dependencies: [
                "TerminalANSI"
            ],
        ),
        .target(
            name: "TerminalANSI",
        ),
        .testTarget(
            name: "TerminalANSITests",
            dependencies: [
                "TerminalANSI",
                .product(name: "Numerics", package: "swift-numerics"),
            ],
        ),
    ]
)
