// swift-tools-version: 5.9
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "TextExpander",
    platforms: [
        .macOS(.v13)
    ],
    products: [
        .executable(
            name: "TextExpander",
            targets: ["TextExpander"]
        )
    ],
    dependencies: [],
    targets: [
        .executableTarget(
            name: "TextExpander",
            dependencies: [],
            path: "Sources/TextExpander",
            swiftSettings: [
                .enableUpcomingFeature("BareSlashRegexLiterals")
            ]
        ),
        .testTarget(
            name: "TextExpanderTests",
            dependencies: ["TextExpander"],
            path: "Tests/TextExpanderTests"
        )
    ]
)
