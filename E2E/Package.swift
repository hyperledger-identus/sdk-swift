// swift-tools-version: 5.7
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "e2e",
    platforms: [.iOS(.v15), .macOS(.v12)],
    products: [
        .library(
            name: "TestFramework",
            targets: ["TestFramework"]),
    ],
    dependencies: [
        .package(url: "https://github.com/apple/swift-openapi-generator", .upToNextMinor(from: "1.7.0")),
        .package(url: "https://github.com/apple/swift-openapi-runtime", .upToNextMinor(from: "1.8.0")),
        .package(url: "https://github.com/apple/swift-openapi-urlsession", .upToNextMinor(from: "1.0.2")),
        .package(url: "https://github.com/nschum/SwiftHamcrest", .upToNextMajor(from: "2.2.1")),
        .package(name: "edge-agent", path: "../")
    ],
    targets: [
        .target(
            name: "TestFramework",
            dependencies: [
                .product(name: "Hamcrest", package: "SwiftHamcrest")
            ],
            path: "TestFramework",
            resources: [
                .copy("Resources")
            ]
        ),
        .testTarget(
            name: "e2e-tests",
            dependencies: [
                .target(name: "TestFramework"),
                .product(name: "EdgeAgent", package: "edge-agent"),
                .product(name: "Domain", package: "edge-agent"),
                .product(name: "OpenAPIRuntime", package: "swift-openapi-runtime"),
                .product(name: "OpenAPIURLSession", package: "swift-openapi-urlsession"),
            ],
            path: "Tests",
            resources: [
                .copy("Resources")
            ],
            plugins: [
                .plugin(
                    name: "OpenAPIGenerator",
                    package: "swift-openapi-generator"
                )
            ]
        )
    ]
)
