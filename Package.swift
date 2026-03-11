// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "SwiftCode demo",
    platforms: [.iOS(.v17)],
    targets: [
        .executableTarget(name: "SwiftCode demo", path: "Sources")
    ]
)