// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "PfizerOutdoCancer",
    platforms: [
        .visionOS(.v2)
    ],
    dependencies: [
        .package(path: "Packages/RoomTrackingKit")
    ],
    targets: [
        .testTarget(
            name: "RoomTrackingKitTests",
            dependencies: [
                .product(name: "RoomTrackingKit", package: "RoomTrackingKit")
            ],
            path: "Packages/RoomTrackingKit/Tests/RoomTrackingKitTests"
        )
    ]
)
