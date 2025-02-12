import SwiftUI
import RealityKit
import RealityKitContent

struct NavToggleView: View {
    @Environment(AppModel.self) private var appModel
    @Environment(\.openWindow) private var openWindow
    
    private let size: CGFloat = 60
    private let iconSize: CGFloat = 24
    
    var body: some View {
        Button(action: {
            openWindow(id: AppModel.navWindowId)
            appModel.isNavWindowOpen.toggle()
        }, label: {
            ZStack {
                Circle()
                    .fill(.ultraThinMaterial)
                    .frame(width: size, height: size)
                
                Image(systemName: "sidebar.left")
                    .font(.system(size: iconSize))
                    .fontWeight(.bold)
                    .shadow(radius: 2)
            }
        })
        .buttonStyle(ScalableButtonStyle())
        .glassBackgroundEffect()
        .hoverEffect { effect, isActive, proxy in
            effect
                .animation(.easeInOut(duration: 0.2)) {
                    $0.scaleEffect(isActive ? AppModel.UIConstants.buttonExpandScale : 1.0)
                }
        }
        .opacity(appModel.isNavWindowOpen ? 0 : 1)
    }
}

//#Preview {
//    NavToggleView()
//        .environment(AppModel())
//}
