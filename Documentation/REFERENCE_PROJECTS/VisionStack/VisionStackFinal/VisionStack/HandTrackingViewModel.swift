//
//  HandTrackingViewModel.swift
//  VisionStack
//
//  Created by Brian Advent on 23.03.24.
//

import RealityKit
import SwiftUI
import ARKit
import RealityKitContent

@MainActor class HandTrackingViewModel: ObservableObject {
    private let session = ARKitSession()
    private let handTracking = HandTrackingProvider()
    
    private let sceneReconstruction = SceneReconstructionProvider()
    
    private var contentEntity = Entity()
    
    private var meshEntities = [UUID : ModelEntity]()
    
    private let fingerEntities: [HandAnchor.Chirality: ModelEntity] = [
        .left: .createFingertip(),
        .right: .createFingertip()
    ]
    
    private var lastCubePlacementTime: TimeInterval = 0
    
    func setupContentEntity() -> Entity {
        for entity in fingerEntities.values {
            contentEntity.addChild(entity)
        }
        
        return contentEntity
    }
    
    func runSession () async {
        do {
            try await session.run([sceneReconstruction, handTracking])
        }catch {
            print ("failed to start session: \(error)")
        }
    }
    
    func processHandUpdates() async {
        for await update in handTracking.anchorUpdates {
            let handAnchor = update.anchor
            
            guard handAnchor.isTracked else { continue }
            
            let fingerTip = handAnchor.handSkeleton?.joint(.indexFingerTip)
            
            guard ((fingerTip?.isTracked) != nil ) else { continue }
            
            let originFromWrist = handAnchor.originFromAnchorTransform
            let wristFromIndex = fingerTip?.anchorFromJointTransform
            let originFromIndex = originFromWrist * wristFromIndex!
            
            fingerEntities[handAnchor.chirality]?.setTransformMatrix(originFromIndex, relativeTo: nil)
            
        }
    }
    
    func processReconstructionUpdates() async {
        for await update in sceneReconstruction.anchorUpdates {
            guard let shape = try? await ShapeResource.generateStaticMesh(from: update.anchor) else {continue}
            
            switch update.event {
            case .added:
                let entity = ModelEntity()
                entity.transform = Transform(matrix: update.anchor.originFromAnchorTransform)
                entity.collision = CollisionComponent(shapes: [shape], isStatic: true)
                entity.physicsBody = PhysicsBodyComponent()
                entity.components.set(InputTargetComponent())
                
                meshEntities[update.anchor.id] = entity
                
                contentEntity.addChild(entity)
            case .updated:
                guard let entiy = meshEntities[update.anchor.id] else { fatalError("...")}
                entiy.transform = Transform(matrix: update.anchor.originFromAnchorTransform)
                entiy.collision?.shapes = [shape]
            case .removed:
                meshEntities[update.anchor.id]?.removeFromParent()
                meshEntities.removeValue(forKey: update.anchor.id)
            }
        }
    }
    
    func placeCube() async {
        guard let leftFingerPosition = fingerEntities[.left]?.transform.translation else {return}
        
        let placementLocation = leftFingerPosition + SIMD3<Float>(0, -0.05, 0)
        
        let entity = ModelEntity(mesh: .generateBox(size: 0.1), materials: [SimpleMaterial(color: .systemBlue, isMetallic: false)], collisionShape: .generateBox(size: SIMD3<Float>(repeating: 0.1)), mass: 1.0)
        
        entity.setPosition(placementLocation, relativeTo: nil)
        
        entity.components.set(InputTargetComponent(allowedInputTypes: .indirect))
        entity.components.set(GroundingShadowComponent(castsShadow: true))
        
        let material = PhysicsMaterialResource.generate(friction: 0.8, restitution: 0.0)
        
        entity.components.set(PhysicsBodyComponent(shapes: entity.collision!.shapes, mass: 1.0, material: material, mode: .dynamic))
        
        contentEntity.addChild(entity)
        
    }
    
}
