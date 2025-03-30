// swift-tools-version:6.0
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "OneFingerRotation",
    platforms: [
		.iOS(.v17), .macCatalyst(.v17), .macOS(.v14), .tvOS(.v17), .visionOS(.v1), .watchOS(.v10)
    ],
    products: [
        .library(name: "OneFingerRotation", targets: ["OneFingerRotation"]),
    ],
	dependencies: [
		.package(url: "https://github.com/apple/swift-numerics", from: "1.0.3")
	],
    targets: [
        .target(
			name: "OneFingerRotation",
			dependencies: [
				.product(name: "RealModule", package: "swift-numerics")
			]
		),
    ]
)
