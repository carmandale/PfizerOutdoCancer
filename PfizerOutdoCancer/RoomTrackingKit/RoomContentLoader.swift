import Foundation
import RealityKit
import RealityKitContent

/// Utility responsible for loading room content models.
/// Models are loaded from the RealityKitContent bundle
/// via the AssetLoadingManager.
public struct RoomContentLoader {
    public init() {}

    /// Load a model entity from RealityKitContent.
    /// - Parameter name: The name of the `.usda` asset to load.
    /// - Returns: A `ModelEntity` ready to attach to a `RoomAnchor`.
    public func loadModel(named name: String) async throws -> ModelEntity {
        let entity = try await AssetLoadingManager.shared.loadAsset(
            withName: name,
            category: .labEnvironment
        )
        guard let model = entity as? ModelEntity else {
            throw AssetError.resourceNotFound
        }
        return model
    }
}
