// swift-tools-version: 5.7

import PackageDescription

let package = Package(
	name: "Pack",
	platforms: [
		.macOS(.v11),
		.iOS(.v13)
	],
	products: [
		.library(name: "Pack", targets: ["Pack"]),
	],
	targets: [
		.target(name: "Pack"),
		.testTarget(name: "PackTests", dependencies: ["Pack"]),
	]
)
