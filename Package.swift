// swift-tools-version: 6.0

import PackageDescription

let package = Package(
	name: OpenAIRealTime",
	platforms: [
		.iOS(.v17),
		.tvOS(.v17),
		.macOS(.v14),
		.watchOS(.v10),
		.visionOS(.v1),
		.macCatalyst(.v17),
	],
	products: [
		.library(name: "OpenAIRealTime", targets: ["OpenAIRealTime"]),
	],
	targets: [
		.target(name: "OpenAIRealTime", path: "./src"),
	]
)
