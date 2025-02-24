import Foundation
import os.log

extension Logger {
    /// Logger for audio-related messages
    static let audio = Logger(subsystem: "com.groovejones.PfizerOutdoCancer", category: "Audio")
    
    /// Log an audio-related message
    static func audio(_ message: String) {
        #if DEBUG
        Logger.audio.debug("🔊 \(message)")
        #endif
    }
    
    /// Log an audio-related warning
    static func audioWarning(_ message: String) {
        Logger.audio.warning("⚠️ \(message)")
    }
    
    /// Log an audio-related error
    static func audioError(_ message: String) {
        Logger.audio.error("❌ \(message)")
    }
} 