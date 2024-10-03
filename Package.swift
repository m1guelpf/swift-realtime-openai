// swift-tools-version: 6.0

import PackageDescription

let package = Package(
    name: "OpenAI",
    platforms: [
        .iOS(.v16),
        .tvOS(.v16),
        .macOS(.v13),
        .watchOS(.v9),
        .visionOS(.v1)
    ],
    products: [
        .library(name: "OpenAI", targets: ["OpenAI"]),
    ],
    targets: [
        .target(name: "OpenAI", path: "./src"),
    ]
)
