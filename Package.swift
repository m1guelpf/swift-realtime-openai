// swift-tools-version: 6.0

import PackageDescription

let package = Package(
    name: "OpenAI",
    platforms: [
        .iOS(.v16),
        .tvOS(.v13),
        .macOS(.v13),
        .watchOS(.v6),
        .visionOS(.v1)
    ],
    products: [
        .library(name: "OpenAI", targets: ["OpenAI"]),
    ],
    targets: [
        .target(name: "OpenAI", path: "./src"),
    ]
)
