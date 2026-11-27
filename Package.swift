// swift-tools-version: 6.2

import PackageDescription

let package = Package(
    name: "DSL",
    products: [
        .library(
            name: "DSL",
            targets: ["DSL"]
        ),
        .library(
            name: "Provenance",
            targets: ["Provenance"]
        ),
    ],
    dependencies: [
        .package(url: "https://github.com/swift-lco/Primitives.git", branch: "master"),
    ],
    targets: [
        // No dependencies: StructuredContent is used far below the web stack.
        .target(
            name: "DSL"
        ),
        .target(
            name: "Provenance",
            dependencies: [
                "DSL",
                .product(name: "Primitives", package: "Primitives"),
            ]
        ),
    ]
)
