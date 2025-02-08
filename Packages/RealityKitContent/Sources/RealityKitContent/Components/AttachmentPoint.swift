import RealityKit

public struct AttachmentPoint: Component, Codable {
    public var isOccupied: Bool = false
    public var isUntargeted: Bool = false  // For untargeted ADC spawn points
    public var cellID: Int? = nil

    public init() {
    }
}
