// swift-tools-version: 6.0

import PackageDescription

let package = Package(
    name: "AudioShelf",
    platforms: [
        .macOS(.v14)
    ],
    products: [
        .executable(name: "AudioShelf", targets: ["AudioShelf"])
    ],
    targets: [
        .target(
            name: "AudioShelfCore",
            path: "AudioShelfCore"
        ),
        .executableTarget(
            name: "AudioShelf",
            dependencies: ["AudioShelfCore"],
            path: "AudioShelf",
            exclude: ["AudioShelf.entitlements"]
        ),
        .executableTarget(
            name: "AudioShelfCoreChecks",
            dependencies: ["AudioShelfCore"],
            path: "Tests/CoreChecks"
        ),
        .testTarget(
            name: "AudioShelfTests",
            dependencies: ["AudioShelfCore"],
            path: "AudioShelfTests"
        )
    ],
    swiftLanguageModes: [.v5]
)
