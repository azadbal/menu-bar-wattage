// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "StatusbarPowerApp",
    platforms: [
        .macOS(.v13)
    ],
    products: [
        .library(
            name: "StatusbarPowerUI",
            targets: ["StatusbarPowerUI"]
        ),
        .executable(
            name: "StatusbarPowerApp",
            targets: ["StatusbarPowerApp"]
        )
    ],
    dependencies: [
        .package(path: "../Packages/PowerCore")
    ],
    targets: [
        .target(
            name: "StatusbarPowerUI",
            dependencies: [
                .product(name: "PowerCore", package: "PowerCore")
            ]
        ),
        .executableTarget(
            name: "StatusbarPowerApp",
            dependencies: [
                "StatusbarPowerUI",
                .product(name: "PowerCore", package: "PowerCore")
            ]
        ),
        .testTarget(
            name: "StatusbarPowerAppTests",
            dependencies: [
                "StatusbarPowerUI",
                .product(name: "PowerCore", package: "PowerCore")
            ]
        )
    ]
)
