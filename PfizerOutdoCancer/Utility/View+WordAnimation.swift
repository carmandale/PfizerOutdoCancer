//import SwiftUI
//
//extension View {
//    /// Animates text word by word with a fade and upward movement
//    func animateWords(
//        text: String,
//        isAnimating: Bool = true,
//        startDelay: Double = 0.5,
//        wordDelay: Double = 0.3,
//        animationDuration: Double = 0.6
//    ) -> some View {
//        self.modifier(
//            WordAnimationModifier(
//                text: text,
//                isAnimating: isAnimating,
//                startDelay: startDelay,
//                wordDelay: wordDelay,
//                animationDuration: animationDuration
//            )
//        )
//    }
//}
//
//private struct WordAnimationModifier: ViewModifier {
//    let text: String
//    let isAnimating: Bool
//    let startDelay: Double
//    let wordDelay: Double
//    let animationDuration: Double
//    
//    @State private var words: [(word: String, opacity: Double, offset: Double)] = []
//    
//    init(text: String, isAnimating: Bool, startDelay: Double, wordDelay: Double, animationDuration: Double) {
//        self.text = text
//        self.isAnimating = isAnimating
//        self.startDelay = startDelay
//        self.wordDelay = wordDelay
//        self.animationDuration = animationDuration
//        
//        // Initialize words with starting values
//        let initialWords = text.split(separator: " ").map { 
//            (String($0), 0.0, 20.0)
//        }
//        _words = State(initialValue: initialWords)
//    }
//    
//    func body(content: Content) -> some View {
//        // Extract the font from the content if possible
//        let contentFont = (content as? Text)?.font ?? .body
//        
//        HStack(spacing: 8) {
//            ForEach(Array(words.enumerated()), id: \.offset) { index, word in
//                Text(word.word)
//                    .font(contentFont)
//                    .opacity(word.opacity)
//                    .offset(y: word.offset)
//            }
//        }
//        .onAppear {
//            guard isAnimating else {
//                words = words.map { ($0.word, 1.0, 0.0) }
//                return
//            }
//            
//            for (index, _) in words.enumerated() {
//                let delay = startDelay + (Double(index) * wordDelay)
//                
//                withAnimation(.easeOut(duration: animationDuration).delay(delay)) {
//                    words[index].opacity = 1.0
//                    words[index].offset = 0.0
//                }
//            }
//        }
//    }
//} 
