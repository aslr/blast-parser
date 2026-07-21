// swift-tools-version: 6.2
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "blast-parser",
    platforms: [
        .macOS(.v15)
    ],
    products: [
        .executable(
            name: "blast-parser",
            targets: ["blast-parser"]
        ),
    ],
    dependencies: [
            .package(url: "https://github.com/apple/swift-argument-parser", from: "1.5.0"),
            .package(url: "https://github.com/apple/swift-crypto.git", from: "3.0.0"),
        ],
    targets: [
        .executableTarget(
            name: "blast-parser",
            dependencies: [
                .product(name: "ArgumentParser", package: "swift-argument-parser"),
                .product(name: "Crypto", package: "swift-crypto"),
            ],
        ),
        .testTarget(
            name: "blast-parserTests",
            dependencies: ["blast-parser"]
        ),
    ],
    swiftLanguageModes: [.v6]
)
