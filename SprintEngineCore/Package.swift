// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "SprintEngineCore",
    platforms: [.macOS(.v15)],
    products: [
        .library(name: "SprintEngineCore", targets: ["SprintEngineCore"]),
    ],
    targets: [
        .target(name: "SprintEngineCore"),
        .testTarget(name: "SprintEngineCoreTests", dependencies: ["SprintEngineCore"]),
    ]
)