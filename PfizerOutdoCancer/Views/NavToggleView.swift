import SwiftUI
import RealityKit
import RealityKitContent

struct NavToggleView: View {
    @Environment(AppModel.self) private var appModel
    @Environment(\.openWindow) private var openWindow
    
    var scaleEffect: CGFloat = 1.2
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
                    .shadow(radius: 2)
            }
        })
        .buttonStyle(.plain)
        .glassBackgroundEffect()
        .hoverEffect(.highlight)
        .hoverEffect { effect, isActive, proxy in
            effect.scaleEffect(!isActive ? 1.0 : scaleEffect)
        }
        .opacity(appModel.isNavWindowOpen ? 0 : 1)
    }
}

//#Preview {
//    NavToggleView()
//        .environment(AppModel())
//}
