# VisionStack Project Summary

## Overview
VisionStack is a demonstration project for Apple Vision Pro that showcases hand tracking, scene understanding, and spatial interactions. The application allows users to place and stack 3D cubes in an immersive space using hand gestures, specifically using the left hand as a pointer and the right hand as a trigger.

## Key Features

### 1. Hand Tracking
- Uses ARKit's HandTrackingProvider for precise finger tracking
- Tracks index fingertip positions for both hands
- Visualizes fingertip positions with small cyan spheres

### 2. Scene Understanding
- Implements ARKit's SceneReconstructionProvider
- Creates mesh entities of the environment
- Enables physical interactions between placed objects and real-world surfaces

### 3. Immersive Space Integration
- Combines windowed UI with immersive experiences
- Seamless transition between standard and immersive views
- Toggle functionality to enter/exit immersive mode

## Technical Implementation

### Core Architecture
The project follows the MVVM (Model-View-ViewModel) pattern and is built using:
- SwiftUI for user interface
- RealityKit for 3D content
- ARKit for spatial awareness and hand tracking

### Key Components

#### HandTrackingViewModel
```swift
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
}
```

#### Cube Placement System
```swift
func placeCube() async {
    guard let leftFingerPosition = fingerEntities[.left]?.transform.translation else {return}
    
    let placementLocation = leftFingerPosition + SIMD3<Float>(0, -0.05, 0)
    
    let entity = ModelEntity(
        mesh: .generateBox(size: 0.1),
        materials: [SimpleMaterial(color: .systemBlue, isMetallic: false)],
        collisionShape: .generateBox(size: SIMD3<Float>(repeating: 0.1)),
        mass: 1.0
    )
}
```

### Interactive Features

#### Drag Rotation
The project includes a custom drag rotation modifier that allows users to:
- Rotate 3D objects with intuitive gestures
- Set rotation limits for pitch and yaw
- Implement smooth animations using spring physics

```swift
func dragRotation(
    yawLimit: Angle? = nil,
    pitchLimit: Angle? = nil,
    sensitivity: Double = 10,
    axRotateClockwise: Bool = false,
    axRotateCounterClockwise: Bool = false
) -> some View
```

## User Interface

### Main Components
1. Windowed Interface
   - Instructions display
   - Interactive 3D model preview
   - Toggle button for immersive mode

2. Immersive Space
   - Full spatial environment
   - Hand tracking visualization
   - Physical cube placement and stacking

## Required Permissions
The app requires two key privacy permissions:
- NSHandTrackingUsageDescription
- NSWorldSensingUsageDescription

## Development Notes

### Best Practices Implemented
1. Separation of concerns using MVVM
2. Asynchronous operations for performance
3. Physics-based interactions
4. Proper resource management
5. Smooth animations and transitions

### Performance Considerations
- Efficient mesh handling for scene reconstruction
- Optimized physics calculations
- Smooth hand tracking updates
- Memory management for 3D assets

## Future Enhancements
Potential areas for expansion:
1. Multiple object types beyond cubes
2. Advanced physics interactions
3. Multi-user support
4. Custom gesture recognition
5. Enhanced visual feedback

## Conclusion
VisionStack demonstrates the capabilities of visionOS for spatial computing, particularly in:
- Hand tracking precision
- Environmental understanding
- Physical interactions
- Immersive experiences

The project serves as an excellent reference for developers looking to implement similar features in their visionOS applications.
