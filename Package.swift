// swift-tools-version: 6.0

import PackageDescription

let package = Package(
	name: "RealtimeAPI",
	platforms: [
		.iOS(.v17),
		.tvOS(.v17),
		.macOS(.v14),
		.watchOS(.v10),
		.visionOS(.v1),
		.macCatalyst(.v17),
	],
	products: [
		.library(name: "RealtimeAPI", targets: ["RealtimeAPI"]),
	],
	dependencies: [
		.package(url: "https://github.com/stasel/WebRTC.git", from: "139.0.0"),
		.package(url: "https://github.com/SwiftyLab/MetaCodable.git", from: "1.0.0"),
	],
	targets: [
		.target(name: "Core", dependencies: [
			.product(name: "MetaCodable", package: "MetaCodable"),
			.product(name: "HelperCoders", package: "MetaCodable"),
		]),
		.target(name: "WebSocketConnector", dependencies: ["Core"]),
		.target(name: "UI", dependencies: ["Core", "WebRTCConnector"]),
		.target(name: "RealtimeAPI", dependencies: ["Core", "WebRTCConnector", "UI"]),
		.target(name: "WebRTCConnector", dependencies: ["Core", .product(name: "WebRTC", package: "WebRTC")]),
	]
)
