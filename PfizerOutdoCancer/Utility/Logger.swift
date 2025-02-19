import Foundation
import os

/// A simple logging utility that wraps Apple's os_log API.
public struct Logger {
    private static let subsystem = Bundle.main.bundleIdentifier ?? "com.PfizerOutdoCancer.app"

    public static func info(_ message: String) {
        let log = OSLog(subsystem: subsystem, category: "INFO")
        os_log("%@", log: log, type: .info, message)
    }
    
    public static func debug(_ message: String) {
        let log = OSLog(subsystem: subsystem, category: "DEBUG")
        os_log("%@", log: log, type: .debug, message)
    }
    
    public static func error(_ message: String) {
        let log = OSLog(subsystem: subsystem, category: "ERROR")
        os_log("%@", log: log, type: .error, message)
    }
    
    public static func fault(_ message: String) {
        let log = OSLog(subsystem: subsystem, category: "FAULT")
        os_log("%@", log: log, type: .fault, message)
    }
    
    // New function for audio logging
    public static func audio(_ message: String) {
        let log = OSLog(subsystem: subsystem, category: "AUDIO")
        os_log("%@", log: log, type: .debug, message)
    }
} 