import ARKit
import Foundation
import simd

public final class RoomTrackingManager {
    private let anchorStore: RoomAnchorStore

    public init(store: RoomAnchorStore = RoomAnchorStore()) {
        self.anchorStore = store
    }

    /// Locks the current room transform and saves it to disk.
    /// - Parameter transform: Current world transform to persist.
    public func lock(transform: simd_float4x4) {
        try? anchorStore.save(transform: transform)
    }

    /// Loads a previously saved room transform if available.
    public func loadSavedTransform() -> simd_float4x4? {
        try? anchorStore.load()
    }
}
