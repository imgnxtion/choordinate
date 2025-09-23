// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "Chordinate",
    defaultLocalization: "en",
    platforms: [
        .macOS(.v13)
    ],
    products: [
        .executable(name: "Chordinate", targets: ["Chordinate"])
    ],
    targets: [
        .executableTarget(
            name: "Chordinate",
            path: "Sources/Chordinate",
            resources: [
                .process("Resources"),
                .process("Shaders")
            ]
        ),
        .testTarget(
            name: "ChordinateTests",
            dependencies: ["Chordinate"],
            path: "Tests"
        )
    ]
)
