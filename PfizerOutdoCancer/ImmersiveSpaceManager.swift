import SwiftUI

struct ImmersiveSpaceManager: View {
    @Environment(AppModel.self) private var appModel
    @Environment(\.dismissImmersiveSpace) private var dismissImmersiveSpace
    @Environment(\.openImmersiveSpace) private var openImmersiveSpace
    @Environment(\.dismissWindow) private var dismissWindow
    
    let spaceId: String
    let onOpened: (() async -> Void)?
    let onDismissed: (() async -> Void)?
    let windowsToClose: [String]
    @Binding var isTriggered: Bool
    
    init(
        spaceId: String,
        windowsToClose: [String] = [],
        isTriggered: Binding<Bool>,
        onOpened: (() async -> Void)? = nil,
        onDismissed: (() async -> Void)? = nil
    ) {
        self.spaceId = spaceId
        self.windowsToClose = windowsToClose
        self._isTriggered = isTriggered
        self.onOpened = onOpened
        self.onDismissed = onDismissed
    }
    
    var body: some View {
        EmptyView()
            .onChange(of: isTriggered) { _, newValue in
                if newValue {
                    Task {
                        await handleImmersiveSpace()
                        isTriggered = false
                    }
                }
            }
    }
    
    @MainActor
    private func handleImmersiveSpace() async {
        print("🎮 Handling immersive space transition for: \(spaceId)")
        switch appModel.immersiveSpaceState {
        case .open:
            print("📤 Dismissing current space")
            appModel.immersiveSpaceState = .inTransition
            await dismissImmersiveSpace()
            if let onDismissed = onDismissed {
                await onDismissed()
            }
            
        case .closed:
            print("📥 Opening new space: \(spaceId)")
            appModel.immersiveSpaceState = .inTransition
            switch await openImmersiveSpace(id: spaceId) {
            case .opened:
                print("✅ Space opened successfully")
                // Close specified windows
                for windowId in windowsToClose {
                    dismissWindow(id: windowId)
                }
                if let onOpened = onOpened {
                    await onOpened()
                }
                
            case .userCancelled:
                print("❌ User cancelled space opening")
                fallthrough
            case .error:
                print("❌ Error opening space")
                fallthrough
            @unknown default:
                appModel.immersiveSpaceState = .closed
            }
            
        case .inTransition:
            print("⏳ Space is in transition")
            break
        }
    }
}

// Extension for easy use in views
extension View {
    func manageImmersiveSpace(
        id spaceId: String,
        windowsToClose: [String] = [],
        isTriggered: Binding<Bool>,
        onOpened: (() async -> Void)? = nil,
        onDismissed: (() async -> Void)? = nil
    ) -> some View {
        self.background(
            ImmersiveSpaceManager(
                spaceId: spaceId,
                windowsToClose: windowsToClose,
                isTriggered: isTriggered,
                onOpened: onOpened,
                onDismissed: onDismissed
            )
        )
    }
} 