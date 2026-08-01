// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "MenuBarWattageApp",
    platforms: [
        .macOS(.v13)
    ],
    products: [
        .library(
            name: "MenuBarWattageUI",
            targets: ["MenuBarWattageUI"]
        ),
        .executable(
            name: "MenuBarWattageApp",
            targets: ["MenuBarWattageApp"]
        )
    ],
    dependencies: [
        .package(path: "../Packages/PowerCore")
    ],
    targets: [
        .target(
            name: "MenuBarWattageUI",
            dependencies: [
                .product(name: "PowerCore", package: "PowerCore")
            ]
        ),
        .executableTarget(
            name: "MenuBarWattageApp",
            dependencies: [
                "MenuBarWattageUI",
                .product(name: "PowerCore", package: "PowerCore")
            ]
        ),
        .testTarget(
            name: "MenuBarWattageAppTests",
            dependencies: [
                "MenuBarWattageUI",
                .product(name: "PowerCore", package: "PowerCore")
            ]
        )
    ]
)
