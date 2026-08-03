// swift-tools-version: 6.0

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
		.target(name: "Pack", swiftSettings: [.swiftLanguageMode(.v6)]),
		.testTarget(name: "PackTests", dependencies: ["Pack"], swiftSettings: [.swiftLanguageMode(.v6)]),
	]
)
