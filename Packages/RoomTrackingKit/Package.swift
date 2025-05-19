// swift-tools-version:6.0
import PackageDescription

let package = Package(
    name: "RoomTrackingKit",
    platforms: [
        .visionOS(.v2),
    ],
    products: [
        .library(name: "RoomTrackingKit", targets: ["RoomTrackingKit"])
    ],
    targets: [
        .target(name: "RoomTrackingKit", dependencies: []),
        .testTarget(name: "RoomTrackingKitTests", dependencies: ["RoomTrackingKit"])
    ]
)
