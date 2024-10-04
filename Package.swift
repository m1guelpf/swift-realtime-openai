// swift-tools-version: 6.0

import PackageDescription

let package = Package(
	name: "OpenAI",
	platforms: [
		.iOS(.v17),
		.tvOS(.v17),
		.macOS(.v14),
		.watchOS(.v10),
		.visionOS(.v1),
		.macCatalyst(.v17),
	],
	products: [
		.library(name: "OpenAI", targets: ["OpenAI"]),
	],
	targets: [
		.target(name: "OpenAI", path: "./src"),
	]
)
