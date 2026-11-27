// swift-tools-version: 6.2

import PackageDescription

let package = Package(
    name: "DSLTests",
    platforms: [
        .macOS(.v13),
    ],
    products: [
        .executable(
            name: "t_dsl",
            targets: ["DSLTestFlows"]
        ),
    ],
    dependencies: [
        .package(url: "https://github.com/swift-tooling/Testing.git", branch: "master"),
        .package(path: ".."),
    ],
    targets: [
        .executableTarget(
            name: "DSLTestFlows",
            dependencies: [
                .product(name: "DSL", package: "DSL"),
                .product(name: "Provenance", package: "DSL"),
                .product(name: "Testing", package: "Testing"),
            ]
        ),
    ]
)
