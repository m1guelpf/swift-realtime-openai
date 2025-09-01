// swift-tools-version: 6.0

import PackageDescription

let package = Package(
	name: "RealtimeAPI",
	platforms: [
		.iOS(.v17),
		.tvOS(.v17),
		.macOS(.v14),
		.visionOS(.v1),
		.macCatalyst(.v17),
	],
	products: [
		.library(name: "RealtimeAPI", targets: ["RealtimeAPI"]),
	],
	dependencies: [
		.package(url: "https://github.com/livekit/webrtc-xcframework.git", branch: "main"),
		.package(url: "https://github.com/SwiftyLab/MetaCodable.git", .upToNextMajor(from: "1.0.0")),
	],
	targets: [
		.target(name: "Core", dependencies: [
			.product(name: "MetaCodable", package: "MetaCodable"),
			.product(name: "HelperCoders", package: "MetaCodable"),
		]),
		.target(name: "WebSocket", dependencies: ["Core"]),
		.target(name: "UI", dependencies: ["Core", "WebRTC"]),
		.target(name: "RealtimeAPI", dependencies: ["Core", "WebSocket", "WebRTC", "UI"]),
		.target(name: "WebRTC", dependencies: ["Core", .product(name: "LiveKitWebRTC", package: "webrtc-xcframework")]),
	]
)
