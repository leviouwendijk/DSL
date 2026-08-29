// swift-tools-version: 6.2

import PackageDescription

let package = Package(
    name: "DSL",
    products: [
        .library(
            name: "DSL",
            targets: ["DSL"]
        ),
    ],
    targets: [
        .target(
            name: "DSL"
        ),
    ]
)
