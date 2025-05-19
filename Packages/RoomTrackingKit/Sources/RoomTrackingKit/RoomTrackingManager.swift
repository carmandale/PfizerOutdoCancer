import ARKit
import Foundation
import simd
/// Manages a room-tracking ARKit session.
@MainActor
public final class RoomTrackingManager {
    private var arSession = ARKitSession()
    private var roomProvider = RoomTrackingProvider()

    /// Called whenever the provider outputs a new `RoomAnchor`.
    public var roomAnchorUpdateHandler: ((RoomAnchor) -> Void)?

    /// Called when the provider's `DataProviderState` changes.
    public var stateChangeHandler: ((DataProviderState) -> Void)?

    public init() {}

    /// Starts the ARKit session and begins collecting room updates.
    public func startTracking() async throws {
        guard RoomTrackingProvider.isSupported else { return }
        try await arSession.run([roomProvider])

        Task { await processAnchorUpdates() }
        Task { await monitorProviderState() }
    }

    /// Stops the ARKit session and resets the provider.
    public func stopTracking() {
        arSession.stop()
        arSession = ARKitSession()
        roomProvider = RoomTrackingProvider()
    }

    // MARK: - Private helpers
    private func processAnchorUpdates() async {
        for await update in roomProvider.anchorUpdates {
            roomAnchorUpdateHandler?(update.anchor)
        }
    }

    private func monitorProviderState() async {
        for await event in arSession.events {
            switch event {
            case .dataProviderStateChanged(let providers, let newState, _):
                guard providers.contains(where: { $0 === roomProvider }) else { continue }
                stateChangeHandler?(newState)
            default:
                break
            }
        }
    }
}
