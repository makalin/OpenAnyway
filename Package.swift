// swift-tools-version: 6.0

import PackageDescription

let package = Package(
    name: "OpenAnyway",
    platforms: [
        .macOS(.v13)
    ],
    products: [
        .executable(name: "OpenAnyway", targets: ["OpenAnyway"]),
        .executable(name: "openanyway", targets: ["OpenAnywayCLI"]),
        .library(name: "OpenAnywayCore", targets: ["OpenAnywayCore"])
    ],
    targets: [
        .target(
            name: "OpenAnywayCore"
        ),
        .executableTarget(
            name: "OpenAnyway",
            dependencies: ["OpenAnywayCore"],
            resources: [
                .process("Resources")
            ]
        ),
        .executableTarget(
            name: "OpenAnywayCLI",
            dependencies: ["OpenAnywayCore"]
        ),
        .testTarget(
            name: "OpenAnywayCoreTests",
            dependencies: ["OpenAnywayCore"]
        )
    ]
)
