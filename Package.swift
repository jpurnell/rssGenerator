// swift-tools-version: 6.1
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
	name: "rssGenerator",
		platforms: [
			.macOS(.v11),
		],
		dependencies: [
			.package(url: "https://github.com/swiftlang/swift-markdown.git", branch: "main"),
			.package(url: "https://github.com/jpsim/Yams.git", from: "6.0.1"),		 
		],
		targets: [
			// Targets are the basic building blocks of a package, defining a module or a test suite.
			// Targets can depend on other targets in this package and products from dependencies.
			.executableTarget(
				name: "rssGenerator",
				dependencies: [
						.product(name: "Markdown", package: "swift-markdown"),
						.product(name: "Yams", package: "yams")
					]
			),
			
		]
)
