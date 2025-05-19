import SwiftUI
import RealityKit

/// Displays a model that is attached to the current `RoomAnchor` and allows
/// basic translation, rotation, and scale gestures before saving the final pose.
public struct RoomPlacementView: View {
    /// The anchor for the current room.
    @State private var roomAnchor: RoomAnchor?
    /// Entity that holds the loaded model.
    @State private var anchorEntity: AnchorEntity?

    public init() {}

    public var body: some View {
        RealityView { content in
            await setupAnchor(in: content)
        }
        .overlay(alignment: .bottom) {
            Button("Lock Position") {
                lockPosition()
            }
            .buttonStyle(.borderedProminent)
            .padding()
        }
    }

    /// Loads the model and creates an anchor entity if needed.
    private func setupAnchor(in content: RealityViewContent) async {
        guard anchorEntity == nil else { return }

        do {
            // Attempt to load a stored RoomAnchor, otherwise create a new one.
            let store = try await RoomAnchorStore()
            if let saved = try await store.anchors().first {
                roomAnchor = saved
            } else {
                roomAnchor = RoomAnchor(.origin)
            }

            guard let roomAnchor else { return }

            // Attach an AnchorEntity to the RoomAnchor and add gestures.
            let entity = AnchorEntity(anchor: roomAnchor)
            anchorEntity = entity
            content.add(entity)

            // Load a placeholder model from the RealityKitContent bundle.
            if let model = try? await Entity(named: "Immersive", in: realityKitContentBundle) {
                entity.addChild(model)
            }

            entity.installGestures([.translation, .rotation, .scale])
        } catch {
            print("Failed to setup anchor: \(error)")
        }
    }

    /// Saves the position of the current room anchor.
    private func lockPosition() {
        guard let roomAnchor else { return }

        Task {
            do {
                let store = try await RoomAnchorStore()
                try await store.save(roomAnchor)
            } catch {
                print("Failed to save RoomAnchor: \(error)")
            }
        }
    }
}

#Preview {
    RoomPlacementView()
}
