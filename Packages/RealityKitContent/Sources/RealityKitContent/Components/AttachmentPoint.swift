import RealityKit

public struct AttachmentPoint: Component, Codable {
    public var isOccupied: Bool = false
    public var cellID: Int? = nil

    public init() {
    }
}
