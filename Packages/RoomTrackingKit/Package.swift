// swift-tools-version:6.0
import PackageDescription

let package = Package(
    name: "RoomTrackingKit",
    platforms: [
        .visionOS(.v2),
        .macOS(.v15),
        .iOS(.v18)
    ],
    products: [
        .library(name: "RoomTrackingKit", targets: ["RoomTrackingKit"])
    ],
    targets: [
        .target(name: "RoomTrackingKit", dependencies: []),
        .testTarget(name: "RoomTrackingKitTests", dependencies: ["RoomTrackingKit"])
    ]
)
