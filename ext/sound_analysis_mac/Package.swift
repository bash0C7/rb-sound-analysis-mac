// swift-tools-version: 6.4

import PackageDescription

let package = Package(
    name: "SoundAnalysisMac",
    platforms: [.macOS(.v27)],
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
