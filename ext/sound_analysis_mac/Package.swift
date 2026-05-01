// swift-tools-version: 6.0

import PackageDescription

let package = Package(
    name: "SoundAnalysisMac",
    platforms: [.macOS(.v12)],
    products: [
        .library(
            name: "SoundAnalysisMac",
            type: .dynamic,
            targets: ["SoundAnalysisMac"]
        ),
    ],
    targets: [
        .target(
            name: "SoundAnalysisMac"
        ),
    ]
)
