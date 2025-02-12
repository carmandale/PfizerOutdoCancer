import SwiftUI
import os

struct ADCView: View {
    @Environment(AppModel.self) private var appModel
    @Environment(ADCDataModel.self) var dataModel
    
    @Environment(\.dismissImmersiveSpace) private var dismissImmersiveSpace
    @Environment(\.openImmersiveSpace) private var openImmersiveSpace
    @Environment(\.openWindow) private var openWindow
    @Environment(\.dismissWindow) private var dismissWindow
    
    var body: some View {
        if appModel.isBuilderInstructionsOpen {
            VStack(spacing: 0) {
                // Header bar
                ZStack {
                    HStack {
                        Image("Pfizer_Logo_White_RGB")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 100)
                            .padding(.leading, 30)
                        Spacer()
                    }
                    HStack {
                        Spacer()
                        Text("Build Your ADC")
                            .font(.largeTitle)
                            .transition(.opacity.combined(with: .move(edge: .top)))
                            .animation(.easeInOut(duration: 0.3), value: dataModel.adcBuildStep)
                        Spacer()
                    }
                }
                .padding(.horizontal, 30)
                .frame(height: 100)
                .background(Color.black.opacity(0.4))
                
                // Content
                VStack(spacing: 0) {
                    // Instructions sections
                    VStack(alignment: .leading, spacing: 20) {
                        instructionSection(
                            title: "Design Your Antibody",
                            description: "Select and customize your antibody with a unique color that will target specific cancer cells.",
                            systemImage: "target"
                        )
                        
                        instructionSection(
                            title: "Connect the Linker",
                            description: "Choose and color your linker component that will connect the antibody to the payload.",
                            systemImage: "link"
                        )
                        
                        instructionSection(
                            title: "Add the Payload",
                            description: "Select and customize the payload that will be delivered to destroy cancer cells.",
                            systemImage: "pill.fill"
                        )
                        
                        instructionSection(
                            title: "Assemble Your ADC",
                            description: "Drag and connect your components to create a complete Antibody Drug Conjugate.",
                            systemImage: "arrow.triangle.merge"
                        )
                    }
                    .padding(.horizontal, 120)
                    .padding(.top, 30)
                    .padding(.bottom, 30)
                    
                    // Start button
                    NavigationButton(
                        title: "Start Building!",
                        action: {
                            Task { @MainActor in
                                switch appModel.immersiveSpaceState {
                                case .open:
                                    appModel.immersiveSpaceState = .inTransition
                                    os_log(.debug, "ADCView: Attempting to dismiss current immersive space.")
                                    await dismissImmersiveSpace()
                                    os_log(.debug, "ADCView: Immersive space dismissed. Waiting 300ms before opening new immersive space.")
                                    try? await Task.sleep(nanoseconds: 300_000_000) // 300ms delay
                                    os_log(.debug, "ADCView: Now trying to open immersive space with id: %@", AppModel.buildingSpaceId)
                                    switch await openImmersiveSpace(id: AppModel.buildingSpaceId) {
                                    case .opened:
                                        os_log(.debug, "ADCView: immersive space open returned .opened")
                                        appModel.isBuilderInstructionsOpen = false
                                        dismissWindow(id: AppModel.mainWindowId)
                                        appModel.isMainWindowOpen = false
                                    case .userCancelled, .error:
                                        fallthrough
                                    @unknown default:
                                        os_log(.error, "ADCView: immersive space open failed or unknown result; setting state to closed")
                                        appModel.immersiveSpaceState = .closed
                                    }
                                    
                                case .closed:
                                    appModel.immersiveSpaceState = .inTransition
                                    os_log(.debug, "ADCView: Immersive space currently closed. Attempting to open with id: %@", AppModel.buildingSpaceId)
                                    switch await openImmersiveSpace(id: AppModel.buildingSpaceId) {
                                    case .opened:
                                        os_log(.debug, "ADCView: immersive space open returned .opened")
                                        appModel.isBuilderInstructionsOpen = false
                                        dismissWindow(id: AppModel.mainWindowId)
                                        appModel.isMainWindowOpen = false
                                    case .userCancelled, .error:
                                        fallthrough
                                    @unknown default:
                                        os_log(.error, "ADCView: immersive space open failed for unknown reasons; setting state to closed")
                                        appModel.immersiveSpaceState = .closed
                                    }
                                    
                                case .inTransition:
                                    os_log(.debug, "ADCView: immersive space is currently in transition; ignoring user action.")
                                    break
                                }
                            }
                        },
                        font: .title,
                        scaleEffect: AppModel.UIConstants.buttonExpandScale
                    )
                    .fontWeight(.bold)
                    .padding(30)
                    // .padding(.bottom, 30)

                }
                .padding(.top, 30)
                .padding(.bottom, 30)
            }
            .frame(width: 800)
            .glassBackgroundEffect()
        }
    }
    
    private func instructionSection(title: String, description: String, systemImage: String) -> some View {
        HStack(alignment: .top, spacing: 15) {
            Image(systemName: systemImage)
                .font(.title)
                .foregroundColor(.blue)
                .frame(width: 30)
            
            VStack(alignment: .leading, spacing: 5) {
                Text(title)
                    .font(.title3)
                    .fontWeight(.semibold)
                    .fixedSize(horizontal: false, vertical: true)
                
                Text(description)
                    .font(.body)
                    .foregroundColor(.secondary)
                    .opacity(0.7)
                    .fixedSize(horizontal: false, vertical: true)
                    .lineLimit(nil)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }
}

// Custom transition combining move and fade
extension AnyTransition {
    static var moveAndFade: AnyTransition {
        .asymmetric(
            insertion: .move(edge: .trailing).combined(with: .opacity),
            removal: .scale.combined(with: .opacity)
        )
    }
}

//#Preview {
//    let appModel = AppModel()
//    appModel.isBuilderInstructionsOpen = true  // Set this to true to see the view
//    
//    return ADCView()
//        .environment(appModel)
//        .environment(ADCDataModel())
//        .frame(width: 400, height: 400)
//}
