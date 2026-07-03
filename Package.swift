// swift-tools-version: 5.9

import PackageDescription

let package = Package(
    name: "CleanDrop",
    platforms: [
        .macOS(.v13)
    ],
    products: [
        .library(name: "CleanDrop", targets: ["CleanDrop"])
    ],
    targets: [
        .target(
            name: "CleanDrop",
            path: "CleanDrop",
            exclude: [
                "CleanDropApp.swift"
            ],
            resources: [
                .process("Resources")
            ]
        ),
        .testTarget(
            name: "CleanDropTests",
            dependencies: ["CleanDrop"],
            path: "CleanDropTests"
        )
    ]
)
