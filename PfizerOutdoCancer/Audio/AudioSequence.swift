import Foundation

/// Represents an element in an audio sequence
struct AudioSequenceElement {
    /// The resource ID of the sound to play
    let resourceID: String
    
    /// How long to pause after playing this sound (in seconds)
    let pauseAfterSeconds: TimeInterval
    
    /// Optional gain adjustment for this specific element (nil uses source default)
    let gain: Float?
    
    /// Whether this sound should loop
    let loop: Bool
    
    /// Initialize a sequence element with default values
    init(resourceID: String, pauseAfterSeconds: TimeInterval = 0.0, gain: Float? = nil, loop: Bool = false) {
        self.resourceID = resourceID
        self.pauseAfterSeconds = pauseAfterSeconds
        self.gain = gain
        self.loop = loop
    }
}

/// Represents a sequence of audio elements to be played in order
struct AudioSequence {
    /// The elements to play in sequence
    let elements: [AudioSequenceElement]
    
    /// Whether the sequence is currently playing
    var isPlaying: Bool = false
    
    /// The current position in the sequence
    var currentIndex: Int = 0
    
    /// Initialize a sequence with an array of elements
    init(elements: [AudioSequenceElement]) {
        self.elements = elements
    }
    
    /// Convenience initializer from simple tuples
    init(_ elements: [(sound: String, pauseAfter: TimeInterval)]) {
        self.elements = elements.map { 
            AudioSequenceElement(resourceID: $0.sound, pauseAfterSeconds: $0.pauseAfter)
        }
    }
} 