import RealityKit

@MainActor
public struct UIAttachmentComponent: Component, Codable {
    public var attachmentID: Int = 0
    public var offset: SIMD3<Float> = SIMD3<Float>(0, 0.5, 0)
    
    public init(attachmentID: Int, offset: SIMD3<Float> = SIMD3<Float>(0, 0.5, 0)) {
        self.attachmentID = attachmentID
        self.offset = offset
    }
}
