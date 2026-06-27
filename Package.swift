// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "Clipper",
    platforms: [
        .macOS(.v13)
    ],
    targets: [
        .executableTarget(
            name: "Clipper",
            path: "Sources/Clipper",
            linkerSettings: [
                .linkedFramework("ApplicationServices"),
            ]
        )
    ]
)
