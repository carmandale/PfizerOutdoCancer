import SwiftUI

struct HitCounterView: View {
    @Environment(AppModel.self) private var appModel: AppModel
    let hits: Int
    let requiredHits: Int
    let isDestroyed: Bool
    private let lineWidth: CGFloat = 12
    private let fontSize: CGFloat = 75
    
    var progress: CGFloat {
        CGFloat(hits) / CGFloat(requiredHits)
    }
    
    var body: some View {
        if !isDestroyed && hits < requiredHits {
            ZStack {
                // Background circle
                Circle()
                    .stroke(lineWidth: lineWidth)
                    .opacity(0.2)
                    .foregroundColor(.gray)
                    .frame(width: 120, height: 120)
                
                // Progress circle
                Circle()
                    .trim(from: 0, to: progress)
                    .stroke(style: StrokeStyle(lineWidth: lineWidth, lineCap: .round))
                    .foregroundColor(.blue)
                    .rotationEffect(.degrees(-90))
                    .animation(.linear(duration: 0.5), value: hits)
                    .frame(width: 120, height: 120)
                
                // Hit counter
//                Text("\(hits)")
//                    .font(.system(size: fontSize))
//                    .foregroundColor(.white)
                Text("Hope Meter")
                    .font(.system(size: fontSize))
                    .foregroundColor(.white)
            }
            .frame(width: 160, height: 160)
            .padding(30)
            .background(.clear)
            .onChange(of: hits) { _, newValue in
                if newValue >= requiredHits {
                    appModel.gameState.cellsDestroyed += 1
                }
            }
        }
    }
}

#Preview(windowStyle: .automatic) {
    HitCounterView(hits: 3, requiredHits: 8, isDestroyed: false)
        .environment(AppModel())
}
