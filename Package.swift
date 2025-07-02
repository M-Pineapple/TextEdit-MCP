// swift-tools-version: 5.9
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "TextEditMCP",
    platforms: [
        .macOS(.v12)
    ],
    products: [
        .executable(
            name: "textedit-mcp",
            targets: ["TextEditMCP"]
        )
    ],
    dependencies: [],
    targets: [
        .executableTarget(
            name: "TextEditMCP",
            dependencies: [],
            path: "Sources/TextEditMCP"
        ),
        .testTarget(
            name: "TextEditMCPTests",
            dependencies: ["TextEditMCP"],
            path: "Tests/TextEditMCPTests"
        )
    ]
)
