import SwiftUI
import RealityKit
import RealityKitContent

extension AttackCancerViewModel {
    // MARK: - Setup Functions
    func setupRoot() -> Entity {
        let root = Entity()
        rootEntity = root
        return root
    }
    
    func setupEnvironment(in root: Entity) async {
        // IBL
        do {
            try await IBLUtility.addImageBasedLighting(to: root, imageName: "metro_noord_2k")
        } catch {
            print("Failed to setup IBL: \(error)")
        }
        
        // Environment
        if let attackCancerScene = await appModel.assetLoadingManager.instantiateEntity("attack_cancer_environment") {
            root.addChild(attackCancerScene)
            setupCollisions(in: attackCancerScene)  // Restore to match backup
        }
    }
}
