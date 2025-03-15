import SwiftUI

/// A wrapper view that creates the animated text at the appropriate time
struct OutdoCancerWrapper: View {
    @Binding var showTitle: Bool
    
    // Use State to track our own internal view generation
    @State private var viewKey = UUID()
    
    var body: some View {
        ZStack {
            // Always present but invisible placeholder to maintain consistent layout
            Text("Let's Outdo Cancer")
                .font(.extraLargeTitle)
                .opacity(0)
            
            // Dynamic view generation using id() to force a new instance creation
            // when showTitle changes from false to true
            if showTitle {
                // We use the ID to force SwiftUI to create a new instance when showTitle changes
                // This ensures the animation gets triggered properly
                OutdoCancerTitleView()
                    .id(viewKey)
                    .onAppear {
                        // Using onAppear because we know this View is newly created
                        // when showTitle becomes true
                        viewKey = UUID() // New UUID ensures a fresh view if it's toggled again
                    }
            }
        }
        .frame(width: 600, height: 200)
    }
}

// Dedicated view that uses the WordByWordTransition
private struct OutdoCancerTitleView: View {
    var body: some View {
        Text("Let's Outdo Cancer")
            .font(.extraLargeTitle)
            .transition(WordByWordTransition(
                totalDuration: 2.0,
                elementDuration: 0.8,
                extraBounce: 0.2
            ))
    }
}
