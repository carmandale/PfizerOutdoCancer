import SwiftUI

extension Text.Layout {
    /// A helper function for easier access to all runs in a layout.
    var flattenedRuns: some RandomAccessCollection<Text.Layout.Run> {
        self.flatMap { line in
            line
        }
    }

    /// A helper function for easier access to all run slices in a layout.
    var flattenedRunSlices: some RandomAccessCollection<Text.Layout.RunSlice> {
        flattenedRuns.flatMap(\.self)
    }
}

struct WordByWordTransition: Transition {
    var totalDuration: Double = 0.9
    var elementDuration: Double = 0.4
    var extraBounce: Double = 0.2
    
    static var properties: TransitionProperties {
        TransitionProperties(hasMotion: true)
    }
    
    func body(content: Content, phase: TransitionPhase) -> some View {
        let elapsedTime = phase.isIdentity ? totalDuration : 0
        let renderer = WordAnimationRenderer(
            elapsedTime: elapsedTime,
            elementDuration: elementDuration,
            totalDuration: totalDuration,
            extraBounce: extraBounce
        )
        
        content.transaction { transaction in
            if !transaction.disablesAnimations {
                transaction.animation = .linear(duration: totalDuration)
            }
        } body: { view in
            view.textRenderer(renderer)
        }
    }
}

struct WordAnimationRenderer: TextRenderer, Animatable {
    var elapsedTime: TimeInterval
    var elementDuration: TimeInterval
    var totalDuration: TimeInterval
    var extraBounce: Double
    
    var spring: Spring {
        .snappy(duration: elementDuration - 0.05, extraBounce: extraBounce)
    }
    
    var animatableData: Double {
        get { elapsedTime }
        set { elapsedTime = newValue }
    }
    
    func draw(layout: Text.Layout, in context: inout GraphicsContext) {
        for run in layout.flattenedRuns {
            let delay = elementDelay(count: run.count)
            
            for (index, slice) in run.enumerated() {
                let timeOffset = TimeInterval(index) * delay
                let elementTime = max(0, min(elapsedTime - timeOffset, elementDuration))
                
                var copy = context
                draw(slice, at: elementTime, in: &copy)
            }
        }
    }
    
    func draw(_ slice: Text.Layout.RunSlice, at time: TimeInterval, in context: inout GraphicsContext) {
        let progress = time / elementDuration
        let opacity = UnitCurve.easeIn.value(at: progress)
        let blurRadius = slice.typographicBounds.rect.height / 16 * UnitCurve.easeIn.value(at: 1 - progress)
        
        let translationY = spring.value(
            fromValue: slice.typographicBounds.descent,
            toValue: 0,
            initialVelocity: 0,
            time: time
        )
        
        context.translateBy(x: 0, y: translationY)
        context.addFilter(.blur(radius: blurRadius))
        context.opacity = opacity
        context.draw(slice)
    }
    
    func elementDelay(count: Int) -> TimeInterval {
        let count = TimeInterval(count)
        let remainingTime = totalDuration - count * elementDuration
        return max(remainingTime / (count + 1), (totalDuration - elementDuration) / count)
    }
}

struct EmphasisAttribute: TextAttribute {} 