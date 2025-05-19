#if canImport(ARKit) && canImport(MultipeerConnectivity)
import Foundation
import ARKit
import RoomTrackingKit

@Observable
@MainActor
final class RoomTrackingManager {
    private let shareService: RoomShareService
    private var anchors: [UUID: RoomAnchor] = [:]

    init(shareService: RoomShareService = RoomShareService()) {
        self.shareService = shareService
        self.shareService.receivedAnchorHandler = { [weak self] shared in
            Task { await self?.createAnchor(from: shared) }
        }
    }

    func lock(anchor: RoomAnchor) {
        anchors[anchor.id] = anchor
        let shared = SharedRoomAnchor(identifier: anchor.id, transform: anchor.originFromAnchorTransform)
        shareService.broadcast(anchor: shared)
    }

    private func createAnchor(from shared: SharedRoomAnchor) {
        guard anchors[shared.identifier] == nil else { return }
        let anchor = RoomAnchor(transform: shared.transform)
        anchors[shared.identifier] = anchor
    }
}
#else
final class RoomTrackingManager {
    init() {}
    func lock(anchor: Any) {}
}
#endif
