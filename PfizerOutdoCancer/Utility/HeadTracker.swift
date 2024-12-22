import SwiftUI
import RealityKit
import ARKit
import RealityKitContent

@MainActor
class HeadTracker: ObservableObject {
    let arSession = ARKitSession()
    let worldTracking = WorldTrackingProvider()
    
    // Configuration
    struct Configuration {
        var heightOffset: Float = 0.0
        var collisionRadius: Float = 0.1
    }
    var config = Configuration()
    
    // Tracking entities
    private var headCollisionEntity: ModelEntity?
    
    @Published var isTracking: Bool = false
    
    // Initial placement
    func getInitialHeadAnchor() -> AnchorEntity {
        let anchor = AnchorEntity(.head)
        anchor.anchoring.trackingMode = .once
        return anchor
    }
    
    // Continuous tracking setup
    func setupCollisionTracking() -> ModelEntity {
        let collisionEntity = ModelEntity(
            mesh: .generateBox(size: config.collisionRadius),
            materials: [SimpleMaterial(color: .clear, isMetallic: false)]
        )
        collisionEntity.name = "HeadCollisionSphere"
        
        collisionEntity.components.set(InputTargetComponent())
        // collisionEntity.components.set(RealityKitContent.GestureComponent())
        
        collisionEntity.collision = CollisionComponent(
            shapes: [.generateSphere(radius: config.collisionRadius)],
            mode: .default,
            filter: CollisionFilter(
                group: CollisionGroup(rawValue: 1),
                mask: .all
            )
        )
        
        // let physicsBody = PhysicsBodyComponent(
        //     shapes: [.generateSphere(radius: config.collisionRadius)],
        //     mass: 1.0,
        //     mode: .static
        // )
        // collisionEntity.components.set(physicsBody)
        collisionEntity.components.set(RealityKitContent.MicroscopeViewerComponent())
        
        self.headCollisionEntity = collisionEntity
        return collisionEntity
    }
    
    func startTracking() async {
        guard WorldTrackingProvider.isSupported else {
            print("HeadTracker: WorldTrackingProvider not supported")
            return
        }
        
        do {
            try await arSession.run([worldTracking])
            isTracking = true
            print("HeadTracker: Started tracking")
        } catch {
            print("Error: \(error). Head-position mode will still work.")
        }
    }
    
    func stopTracking() {
        Task {
            arSession.stop()
            headCollisionEntity?.removeFromParent()
            headCollisionEntity = nil
            isTracking = false
        }
    }
    
    // Update collision entity position
    func updateHeadPosition() {
        guard let transform = worldTracking.queryDeviceAnchor(atTimestamp: CACurrentMediaTime())?.originFromAnchorTransform else {
            if isTracking {
                print("HeadTracker: Failed to get head position")
            }
            return
        }
        headCollisionEntity?.transform = Transform(matrix: transform)
        
        // Debug position
        // if let entity = headCollisionEntity {
        //     print("\n=== Head Tracker Update ===")
        //     print("Entity Name: \(entity.name)")
        //     print("World Position: \(entity.position(relativeTo: nil))")
        //     print("Local Position: \(entity.position)")
        //     print("Has Collision Component: \(entity.components[CollisionComponent.self] != nil)")
        // }
    }
} 
