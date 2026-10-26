// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "CodePad",
    platforms: [.macOS(.v13)],
    products: [
        .executable(name: "CodePad", targets: ["CodePad"])
    ],
    targets: [
        .executableTarget(name: "CodePad")
    ]
)
