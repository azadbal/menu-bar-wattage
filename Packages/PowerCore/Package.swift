// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "PowerCore",
    platforms: [
        .macOS(.v13)
    ],
    products: [
        .library(
            name: "PowerCore",
            targets: ["PowerCore"]
        )
    ],
    targets: [
        .target(
            name: "PowerCore"
        ),
        .testTarget(
            name: "PowerCoreTests",
            dependencies: ["PowerCore"]
        )
    ]
)
