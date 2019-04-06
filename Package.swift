// swift-tools-version:5.0

import PackageDescription

let package = Package(
    name: "VideoCapture",
    products: [
        .library(name: "VideoCapture", targets: ["VideoCapture"]),
    ],
    targets: [
        .target(
            name: "VideoCapture",
            dependencies: []
        ),
    ]
)
