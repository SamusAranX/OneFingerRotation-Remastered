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
    targets: [
        .target(name: "OneFingerRotation"),
    ]
)
