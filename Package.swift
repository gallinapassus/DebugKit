// swift-tools-version: 5.7

import PackageDescription

let package = Package(
    name: "DebugKit",
    products: [
        .library(
            name: "DebugKit",
            targets: ["DebugKit"]),
        .executable(name: "testapp", targets: ["testapp"])
    ],
    dependencies: [
        .package(url: "https://github.com/apple/swift-argument-parser.git",
                 branch: "main"),
        .package(url: "git@github.com:gallinapassus/SemanticVersion.git",
                 branch: "main"),
    ],
    targets: [
        .target(
            name: "DebugKit",
            dependencies: ["SemanticVersion"]),
        .testTarget(
            name: "DebugKitTests",
            dependencies: ["DebugKit"]),
        .executableTarget(name: "testapp",
                          dependencies: [
                            "DebugKit", .product(name: "ArgumentParser", package: "swift-argument-parser")
                          ]
                         )
    ]
)
