import RealityKit

public struct HitCountComponent: Component {
    public var hitCount: Int
    public var requiredHits: Int
    public var isDestroyed: Bool
    
    public init(hitCount: Int = 0, requiredHits: Int, isDestroyed: Bool = false) {
        self.hitCount = hitCount
        self.requiredHits = requiredHits
        self.isDestroyed = isDestroyed
    }
} 