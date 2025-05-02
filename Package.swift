// swift-tools-version: 5.7
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "EdgeAgentSDK",
    platforms: [.iOS(.v15), .macOS(.v13)],
    products: [
        .library(
            name: "Domain",
            targets: ["Domain"]
        ),
        .library(
            name: "Apollo",
            targets: ["Apollo"]
        ),
        .library(
            name: "Castor",
            targets: ["Castor"]
        ),
        .library(
            name: "Pollux",
            targets: ["Pollux"]
        ),
        .library(
            name: "Mercury",
            targets: ["Mercury"]
        ),
        .library(
            name: "Pluto",
            targets: ["Pluto"]
        ),
        .library(
            name: "Builders",
            targets: ["Builders"]
        ),
        .library(
            name: "EdgeAgent",
            targets: ["EdgeAgent"]
        ),
        .library(
            name: "Authenticate",
            targets: ["Authenticate"]
        ),
        .library(
            name: "EdgeAgentSDK",
            targets: [
                "EdgeAgentSDK",
            ]
        )
    ],
    dependencies: [
        .package(
            url: "https://github.com/apple/swift-log.git",
            from: "1.4.4"
        ),
        .package(url: "https://github.com/apple/swift-protobuf.git", from: "1.7.0"),
        .package(url: "https://github.com/beatt83/didcomm-swift.git", from: "0.1.10"),
        .package(url: "https://github.com/beatt83/jose-swift.git", from: "3.3.1"),
        .package(url: "https://github.com/beatt83/peerdid-swift.git", from: "3.0.1"),
        .package(url: "https://github.com/input-output-hk/anoncreds-rs.git", exact: "0.4.1"),
        .package(url: "https://github.com/hyperledger/identus-apollo.git", exact: "1.4.2"),
        .package(url: "https://github.com/KittyMac/Sextant.git", exact: "0.4.31"),
        .package(url: "https://github.com/kylef/JSONSchema.swift.git", exact: "0.6.0"),
        .package(url: "https://github.com/eu-digital-identity-wallet/eudi-lib-sdjwt-swift.git", from: "0.1.0"),
        .package(url: "https://github.com/1024jp/GzipSwift.git", exact: "6.0.0"),
        .package(url: "https://github.com/goncalo-frade-iohk/eudi-lib-ios-openid4vci-swift.git", from: "0.9.0")
    ],
    targets: [
        .target(
            name: "EdgeAgentSDK",
            dependencies: [
                "Domain",
                "Castor",
                "Apollo",
                "Mercury",
                "Pluto",
                "Pollux",
                "EdgeAgent"
            ],
            path: "EdgeAgentSDK/EdgeAgentSDK/Sources"
        ),
        .target(
            name: "Domain",
            path: "EdgeAgentSDK/Domain/Sources"
        ),
        .testTarget(
            name: "DomainTests",
            dependencies: ["Domain"],
            path: "EdgeAgentSDK/Domain/Tests"
        ),
        .target(
            name: "Apollo",
            dependencies: [
                "Domain",
                "Core",
                .product(name: "AnoncredsSwift", package: "anoncreds-rs"),
                .product(name: "ApolloLibrary", package: "identus-apollo")
            ],
            path: "EdgeAgentSDK/Apollo/Sources"
        ),
        .target(
            name: "Castor",
            dependencies: [
                "Domain",
                "Core",
                .product(name: "PeerDID", package: "peerdid-swift"),
                .product(name: "SwiftProtobuf", package: "swift-protobuf")
            ],
            path: "EdgeAgentSDK/Castor/Sources"
        ),
        .testTarget(
            name: "CastorTests",
            dependencies: ["Castor", "Apollo"],
            path: "EdgeAgentSDK/Castor/Tests"
        ),
        .target(
            name: "Pollux",
            dependencies: [
                "Domain",
                "Core",
                "jose-swift",
                "Sextant",
                "eudi-lib-sdjwt-swift",
                .product(name: "Gzip", package: "GzipSwift"),
                .product(name: "AnoncredsSwift", package: "anoncreds-rs"),
                .product(name: "JSONSchema", package: "JSONSchema.swift")
            ],
            path: "EdgeAgentSDK/Pollux/Sources"
        ),
        .testTarget(
            name: "PolluxTests",
            dependencies: ["Pollux", "Apollo", "Castor", "EdgeAgent"],
            path: "EdgeAgentSDK/Pollux/Tests"
        ),
        .target(
            name: "Mercury",
            dependencies: [
                "Domain",
                "Core",
                "didcomm-swift"
            ],
            path: "EdgeAgentSDK/Mercury/Sources"
        ),
        .testTarget(
            name: "MercuryTests",
            dependencies: ["Mercury"],
            path: "EdgeAgentSDK/Mercury/Tests"
        ),
        .target(
            name: "Pluto",
            dependencies: [
                "Domain",
                "Core"
            ],
            path: "EdgeAgentSDK/Pluto/Sources",
            resources: [.process("Resources/PrismPluto.xcdatamodeld")]
        ),
        .testTarget(
            name: "PlutoTests",
            dependencies: ["Pluto"],
            path: "EdgeAgentSDK/Pluto/Tests"
        ),
        .target(
            name: "Builders",
            dependencies: ["Domain", "Castor", "Pollux", "Mercury", "Pluto", "Apollo"],
            path: "EdgeAgentSDK/Builders/Sources"
        ),
        .target(
            name: "EdgeAgent",
            dependencies: [
                "Domain",
                "Builders",
                "Core",
                .product(name: "OpenID4VCI", package: "eudi-lib-ios-openid4vci-swift")
            ],
            path: "EdgeAgentSDK/EdgeAgent/Sources"
        ),
        .testTarget(
            name: "EdgeAgentTests",
            dependencies: ["EdgeAgent", "Core"],
            path: "EdgeAgentSDK/EdgeAgent/Tests"
        ),
        .target(
            name: "Authenticate",
            dependencies: ["Domain", "Builders", "Core"],
            path: "EdgeAgentSDK/Authenticate/Sources"
        ),
//        .testTarget(
//            name: "AuthenticateTests",
//            dependencies: ["Authenticate"],
//            path: "EdgeAgentSDK/Authenticate/Tests"
//        ),
//        Internal core components (ex: logging) not public distributed
        .target(
            name: "Core",
            dependencies: [
                "Domain",
                "jose-swift",
                .product(name: "Logging", package: "swift-log")
            ],
            path: "Core/Sources"
        )
    ]
)
