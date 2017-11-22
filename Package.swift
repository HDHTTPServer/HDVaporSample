// swift-tools-version:4.0

import PackageDescription

let package = Package(
    name: "HDVaporSample",
    products: [
        .library(name: "App", targets: ["App"]),
        .executable(name: "Run", targets: ["Run"])
    ],
    dependencies: [
        .package(url: "git@github.com:HDHTTPServer/HDHTTPServer.git", .upToNextMajor(from: "0.0.1")),
        .package(url: "https://github.com/vapor/vapor.git", .upToNextMajor(from: "2.1.0")),
        .package(url: "https://github.com/vapor/fluent-provider.git", .upToNextMajor(from: "1.2.0")),
    ],
    targets: [
        .target(name: "App", dependencies: ["Vapor", "FluentProvider", "HDHTTPServer"],
                exclude: [
                    "Config",
                    "Public",
                    "Resources",
                ]),
        .target(name: "Run", dependencies: ["App", "HDHTTPServer"]),
        .testTarget(name: "AppTests", dependencies: ["App", "Testing"])
    ]
)

