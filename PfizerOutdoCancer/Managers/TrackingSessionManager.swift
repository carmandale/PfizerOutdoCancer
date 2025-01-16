import SwiftUI
import RealityKit

@Observable
@MainActor
final class TrackingSessionManager {
    private let session = SpatialTrackingSession()
    private(set) var isInitialized = false
    private var headAnchor: AnchorEntity?
    private var markerEntity: ModelEntity?
    
    func initialize(content: RealityViewContent) async throws {
        guard !isInitialized else { return }
        
        let configuration = SpatialTrackingSession.Configuration(
            tracking: [.world]
        )
        
        if let unavailableCapabilities = await session.run(configuration) {
            print("Warning: Some tracking capabilities unavailable - \(unavailableCapabilities)")
            throw TrackingError.capabilitiesUnavailable(unavailableCapabilities)
        }
        
        headAnchor = AnchorEntity(.head)
        headAnchor?.anchoring.trackingMode = .continuous
        content.add(headAnchor!) // Add to scene
        
        // Store the marker reference
        markerEntity = ModelEntity(mesh: .generateSphere(radius: 0.1))
        markerEntity?.model?.materials = [SimpleMaterial(color: .red, isMetallic: false)]
        headAnchor?.addChild(markerEntity!)
        
        isInitialized = true
        print("✅ Spatial tracking session initialized with head anchor added to scene")
    }
    
    func getHeadPosition() -> SIMD3<Float>? {
        let position = headAnchor?.position(relativeTo: nil)
        let markerPosition = markerEntity?.position(relativeTo: nil)
        print("📏 Head Position from anchor: \(String(describing: position))")
        print("📏 Marker Position from anchor: \(String(describing: markerPosition))")
        return position
    }
}

// MARK: - Errors
extension TrackingSessionManager {
    enum TrackingError: Error {
        case capabilitiesUnavailable(SpatialTrackingSession.UnavailableCapabilities)
        case notInitialized
    }
} 