// swift-tools-version:5.7
import PackageDescription

let package = Package(
    name: "ScrollSwitcher",
    platforms: [
        .macOS(.v12)
    ],
    targets: [
        .executableTarget(
            name: "ScrollSwitcher",
            path: "Sources"
        )
    ]
)
