import RealityKit
import SwiftUI
import ARKit

@Observable
final class HandTrackingManager {
    // MARK: - Properties
    private weak var trackingManager: TrackingSessionManager?
    
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
    
    init(trackingManager: TrackingSessionManager? = nil) {
        self.trackingManager = trackingManager
    }
    
    func configure(with trackingManager: TrackingSessionManager) {
        print("\n=== Configuring Hand Tracking Manager ===")
        print("Previous Manager: \(self.trackingManager != nil)")
        print("New Manager: \(trackingManager)")
        self.trackingManager = trackingManager
    }
    
    // MARK: - Setup
    func setupContentEntity() -> Entity {
        print("\n=== Setting Up Hand Tracking Content ===")
        print("Content Entity Parent: \(contentEntity.parent?.name ?? "none")")
        print("Existing Children: \(contentEntity.children.count)")
        
        // Add finger entities to content
        for entity in fingerEntities.values {
            entity.scale = .one * 0.02  // Make sure debug spheres are visible
            entity.components.set(ModelComponent(
                mesh: .generateSphere(radius: 1),
                materials: [SimpleMaterial(color: .blue, isMetallic: false)]
            ))
            entity.isEnabled = true  // Make sure entities start enabled
            contentEntity.addChild(entity)
            print("✅ Added finger entity to content")
        }
        
        print("Setting up closure component")
        // Set up hand tracking updates using ClosureComponent
        contentEntity.components.set(ClosureComponent(closure: { [weak self] deltaTime in
            guard let self = self else {
                print("❌ Self reference lost in hand tracking closure")
                return
            }
            
            // Update left hand
            if let leftAnchor = self.leftHandAnchor,
               let leftHandSkeleton = leftAnchor.handSkeleton {
                let indexTip = leftHandSkeleton.joint(.indexFingerTip)
                
                if indexTip.isTracked {
                    let originFromIndex = leftAnchor.originFromAnchorTransform * indexTip.anchorFromJointTransform
                    self.fingerEntities[.left]?.setTransformMatrix(originFromIndex, relativeTo: nil)
                    print("📍 Left hand index tip tracked")
                }
            }
            
            // Update right hand
            if let rightAnchor = self.rightHandAnchor,
               let rightHandSkeleton = rightAnchor.handSkeleton {
                let indexTip = rightHandSkeleton.joint(.indexFingerTip)
                
                if indexTip.isTracked {
                    let originFromIndex = rightAnchor.originFromAnchorTransform * indexTip.anchorFromJointTransform
                    self.fingerEntities[.right]?.setTransformMatrix(originFromIndex, relativeTo: nil)
                    print("📍 Right hand index tip tracked")
                }
            }
        }))
        
        print("✅ Hand tracking content setup complete")
        print("Final Children Count: \(contentEntity.children.count)")
        return contentEntity
    }
    
    // MARK: - Helper Methods
    
    /// Gets the current position of a specified hand's index finger
    /// - Parameter chirality: Which hand to get the position for
    /// - Returns: The world space position of the index finger, if available
    func getFingerPosition(_ chirality: HandAnchor.Chirality) -> SIMD3<Float>? {
        let position = fingerEntities[chirality]?.transform.translation
        print("\n=== Getting \(chirality) Hand Position ===")
        print("Entity Exists: \(fingerEntities[chirality] != nil)")
        print("Entity Enabled: \(fingerEntities[chirality]?.isEnabled ?? false)")
        print("Entity In Scene: \(fingerEntities[chirality]?.parent != nil)")
        print("Position: \(String(describing: position))")
        return position
    }
    
    /// Gets the distance between thumb and index finger for a hand
    /// - Parameter chirality: Which hand to check
    /// - Returns: Distance between thumb and index finger if both are tracked, nil otherwise
    func getPinchDistance(_ chirality: HandAnchor.Chirality) -> Float? {
        print("\n=== Getting \(chirality) Hand Pinch Distance ===")
        guard let anchor = chirality == .left ? leftHandAnchor : rightHandAnchor,
              let skeleton = anchor.handSkeleton else {
            print("❌ No hand skeleton available")
            return nil
        }
        
        let thumb = skeleton.joint(.thumbTip)
        let index = skeleton.joint(.indexFingerTip)
        
        guard thumb.isTracked && index.isTracked else {
            print("❌ Thumb or index finger not tracked")
            return nil
        }
        
        let thumbTransform = anchor.originFromAnchorTransform * thumb.anchorFromJointTransform
        let indexTransform = anchor.originFromAnchorTransform * index.anchorFromJointTransform
        
        let thumbPos = SIMD3<Float>(
            thumbTransform.columns.3.x,
            thumbTransform.columns.3.y,
            thumbTransform.columns.3.z
        )
        let indexPos = SIMD3<Float>(
            indexTransform.columns.3.x,
            indexTransform.columns.3.y,
            indexTransform.columns.3.z
        )
        let distance = simd_length(thumbPos - indexPos)
        print("📏 Pinch distance: \(distance)")
        return distance
    }
    
    /// Calculate distance between two 3D points
    private func distance(_ a: SIMD3<Float>, _ b: SIMD3<Float>) -> Float {
        let diff = a - b
        return sqrt(diff.x * diff.x + diff.y * diff.y + diff.z * diff.z)
    }
    
    func updateHandAnchors(left: HandAnchor?, right: HandAnchor?) {
        print("\n=== Updating Hand Anchors ===")
        print("Left Hand: \(left != nil ? "Present" : "Nil")")
        print("Right Hand: \(right != nil ? "Present" : "Nil")")
        print("Content Entity in Scene: \(contentEntity.parent != nil)")
        print("Left Entity in Scene: \(fingerEntities[.left]?.parent != nil)")
        print("Right Entity in Scene: \(fingerEntities[.right]?.parent != nil)")
        
        leftHandAnchor = left
        rightHandAnchor = right
    }
    
    /// Gets the forward direction vector for a hand
    /// - Parameter chirality: Which hand to get the direction for
    /// - Returns: A normalized direction vector in world space, or nil if hand is not tracked
    func getHandDirection(_ chirality: HandAnchor.Chirality) -> SIMD3<Float>? {
        let handAnchor = chirality == .left ? leftHandAnchor : rightHandAnchor
        
        guard let handAnchor = handAnchor,
              handAnchor.isTracked,
              let handSkeleton = handAnchor.handSkeleton else {
            return nil
        }
        
        // Get wrist and palm center joints
        let wrist = handSkeleton.joint(.wrist)
        let middleKnuckle = handSkeleton.joint(.middleFingerKnuckle)
        
        guard wrist.isTracked && middleKnuckle.isTracked else {
            return nil
        }
        
        // Transform joint positions to world space
        let originFromAnchor = handAnchor.originFromAnchorTransform
        let wristTransform = originFromAnchor * wrist.anchorFromJointTransform
        let knuckleTransform = originFromAnchor * middleKnuckle.anchorFromJointTransform
        
        // Get positions from transforms
        let wristPosition = SIMD3<Float>(wristTransform.columns.3.x,
                                       wristTransform.columns.3.y,
                                       wristTransform.columns.3.z)
        let knucklePosition = SIMD3<Float>(knuckleTransform.columns.3.x,
                                         knuckleTransform.columns.3.y,
                                         knuckleTransform.columns.3.z)
        
        // Calculate and normalize direction
        let direction = normalize(knucklePosition - wristPosition)
        return direction
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