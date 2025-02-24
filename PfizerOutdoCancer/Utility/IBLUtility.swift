import RealityKit
import SwiftUI

enum IBLUtility {
    /// Adds Image-Based Lighting to a RealityKit scene
    /// - Parameters:
    ///   - root: The root entity to add the IBL to
    ///   - imageName: Name of the IBL image file (without extension)
    ///   - intensity: The intensity exponent of the IBL (default: 1.0)
    static func addImageBasedLighting(
        to root: Entity,
        imageName: String,
        intensity: Float = 1.0
    ) async throws {
        // Load the image-based lighting resource
        guard let iblURL = Bundle.main.url(forResource: imageName, withExtension: "exr") else {
            fatalError("Failed to load the Image-Based Lighting file: \(imageName).exr")
        }
        
        Logger.debug("IBL URL: \(iblURL)")
        
        let iblEnv = try await EnvironmentResource(fromImage: iblURL)
        
        // Set up image-based lighting
        let iblEntity = await Entity()
        var iblComp = ImageBasedLightComponent(source: .single(iblEnv), intensityExponent: intensity)
        iblComp.inheritsRotation = true
        await iblEntity.components.set(iblComp)
        
        // Add IBL receiver component to the root
        await root.components.set(ImageBasedLightReceiverComponent(imageBasedLight: iblEntity))
        await root.addChild(iblEntity)
    }
}
