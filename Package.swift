// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "CIMenuBar",
    platforms: [.macOS(.v13)],
    targets: [
        .executableTarget(name: "CIMenuBar"),
        .testTarget(name: "CIMenuBarTests", dependencies: ["CIMenuBar"]),
    ]
)
