// swift-tools-version:5.7

import PackageDescription

let package = Package(
    name: "VideoCapture",
    platforms: [.iOS(.v13)],
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
