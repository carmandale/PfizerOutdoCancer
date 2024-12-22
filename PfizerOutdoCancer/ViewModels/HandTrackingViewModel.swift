import RealityKit
import SwiftUI
import ARKit

@Observable
class HandTrackingViewModel {
    // MARK: - Properties
    
    /// The ARKit session for hand tracking
    private let session = ARKitSession()
    
    /// The provider instance for hand tracking
    private let handTracking = HandTrackingProvider()
    
    /// Root entity containing all hand-tracked content
    private var contentEntity = Entity()
    
    /// The most recent hand anchors
    private(set) var leftHandAnchor: HandAnchor?
    private(set) var rightHandAnchor: HandAnchor?
    
    /// Entities representing finger positions for spawning
    private let fingerEntities: [HandAnchor.Chirality: ModelEntity] = [
        .left: .createFingertip(),
        .right: .createFingertip()
    ]
    
    // MARK: - Setup
    
    /// Sets up and returns the content entity with finger visualization
    func setupContentEntity() -> Entity {
        // Add finger entities to content
        for entity in fingerEntities.values {
            contentEntity.addChild(entity)
        }
        
        // Start the ARKit session
        runSession()
        
        // Set up hand tracking updates using ClosureComponent
        contentEntity.components.set(ClosureComponent(closure: { [weak self] deltaTime in
            guard let self = self else { return }
            
            // Update left hand
            if let leftAnchor = self.leftHandAnchor,
               let leftHandSkeleton = leftAnchor.handSkeleton {
                let indexTip = leftHandSkeleton.joint(.indexFingerTip)
                
                if indexTip.isTracked {
                    let originFromIndex = leftAnchor.originFromAnchorTransform * indexTip.anchorFromJointTransform
                    self.fingerEntities[.left]?.setTransformMatrix(originFromIndex, relativeTo: nil)
                }
            }
            
            // Update right hand
            if let rightAnchor = self.rightHandAnchor,
               let rightHandSkeleton = rightAnchor.handSkeleton {
                let indexTip = rightHandSkeleton.joint(.indexFingerTip)
                
                if indexTip.isTracked {
                    let originFromIndex = rightAnchor.originFromAnchorTransform * indexTip.anchorFromJointTransform
                    self.fingerEntities[.right]?.setTransformMatrix(originFromIndex, relativeTo: nil)
                }
            }
        }))
        
        return contentEntity
    }
    
    // MARK: - Session Management
    
    /// Starts the ARKit session with hand tracking
    private func runSession() {
        Task {
            do {
                try await session.run([handTracking])
                print("Hand tracking session started successfully")
                
                // Start collecting hand tracking anchors
                for await update in handTracking.anchorUpdates {
                    switch update.anchor.chirality {
                    case .left:
                        leftHandAnchor = update.anchor
                    case .right:
                        rightHandAnchor = update.anchor
                    }
                }
            } catch {
                print("Failed to start hand tracking session: \(error)")
            }
        }
    }
    
    // MARK: - Helper Methods
    
    /// Gets the current position of a specified hand's index finger
    /// - Parameter chirality: Which hand to get the position for
    /// - Returns: The world space position of the index finger, if available
    func getFingerPosition(_ chirality: HandAnchor.Chirality) -> SIMD3<Float>? {
        return fingerEntities[chirality]?.transform.translation
    }
    
    /// Gets the distance between thumb and index finger for a hand
    /// - Parameter chirality: Which hand to check
    /// - Returns: Distance between thumb and index finger if both are tracked, nil otherwise
    func getPinchDistance(_ chirality: HandAnchor.Chirality) -> Float? {
        let handAnchor = chirality == .left ? leftHandAnchor : rightHandAnchor
        
        guard handAnchor?.isTracked == true else { return nil }
        
        let thumbTip = handAnchor?.handSkeleton?.joint(.thumbTip)
        let indexTip = handAnchor?.handSkeleton?.joint(.indexFingerTip)
        
        guard ((thumbTip?.isTracked) != nil) && ((indexTip?.isTracked) != nil) else { return nil }
        
        let originFromAnchor = handAnchor!.originFromAnchorTransform
        let thumbTransform = thumbTip?.anchorFromJointTransform
        let indexTransform = indexTip?.anchorFromJointTransform
        
        let originFromThumb = originFromAnchor * thumbTransform!
        let originFromIndex = originFromAnchor * indexTransform!
        
        // Get positions from transforms
        let thumbPosition = SIMD3<Float>(originFromThumb.columns.3.x, 
                                       originFromThumb.columns.3.y, 
                                       originFromThumb.columns.3.z)
        let indexPosition = SIMD3<Float>(originFromIndex.columns.3.x, 
                                       originFromIndex.columns.3.y, 
                                       originFromIndex.columns.3.z)
        
        // Calculate distance
        return distance(thumbPosition, indexPosition)
    }
    
    /// Calculate distance between two 3D points
    private func distance(_ a: SIMD3<Float>, _ b: SIMD3<Float>) -> Float {
        let diff = a - b
        return sqrt(diff.x * diff.x + diff.y * diff.y + diff.z * diff.z)
    }
}

// MARK: - ModelEntity Extensions

private extension ModelEntity {
    /// Creates a visualization for the fingertip
    static func createFingertip() -> ModelEntity {
        let entity = ModelEntity(
            mesh: .generateSphere(radius: 0.005),
            materials: [SimpleMaterial(color: .cyan, isMetallic: false)]
        )
        entity.components.set(OpacityComponent(opacity: 0.6))
        return entity
    }
}
