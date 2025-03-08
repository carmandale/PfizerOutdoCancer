import Foundation
import os

/// A simple logging utility that wraps Apple's os_log API.
public struct Logger {
    private static let subsystem = Bundle.main.bundleIdentifier ?? "com.PfizerOutdoCancer.app"
    
    /// Log level enum to control logging verbosity
    public enum LogLevel: Int {
        case verbose = 0
        case debug = 1
        case info = 2
        case warning = 3
        case error = 4
        case fault = 5
        case none = 6
    }
    
    /// CONFIGURATION: Set the minimum log level here
    /// Change this single value to adjust logging verbosity
    public static var minimumLogLevel: LogLevel = .debug
    
    /// CONFIGURATION: Enable/disable specific subsystems
    /// Set to false to disable verbose tracking logs
    public static var enableTrackingLogs = false
    public static var enableAudioLogs = true
    
    /// CONFIGURATION: Progress logging options
    public static var enableDetailedProgressLogs = false
    /// Only log progress changes that exceed this threshold (0.0-1.0)
    public static var progressLogThreshold: Float = 0.05 // 5% changes
    
    // The last logged progress value, used to determine if we should log again
    private static var lastLoggedProgress: Float = 0.0
    
    /// Determines whether tracking logs should be displayed
    public static func shouldLogTracking() -> Bool {
        return enableTrackingLogs && minimumLogLevel.rawValue <= LogLevel.debug.rawValue
    }
    
    /// Check if a progress update should be logged based on configuration and threshold
    public static func shouldLogProgress(value: Float) -> Bool {
        if !enableDetailedProgressLogs && minimumLogLevel.rawValue > LogLevel.verbose.rawValue {
            // For progress changes, only log significant changes based on threshold
            // or if we explicitly enabled detailed progress logs
            let difference = abs(value - lastLoggedProgress)
            if difference < progressLogThreshold {
                return false
            }
            lastLoggedProgress = value
        }
        return true
    }
    
    public static func info(_ message: String) {
        guard minimumLogLevel.rawValue <= LogLevel.info.rawValue else { return }
        
        // Filter out high-frequency progress update logs unless they exceed threshold
        if message.contains("Progress") || message.contains("progress") || message.contains("🔄") {
            // Try to extract progress value from the message
            if let progressValue = extractProgressValue(from: message) {
                if !shouldLogProgress(value: progressValue) {
                    return
                }
            }
        }
        
        let log = OSLog(subsystem: subsystem, category: "INFO")
        os_log("%@", log: log, type: .info, message)
    }
    
    // Helper to extract progress values from log messages
    private static func extractProgressValue(from message: String) -> Float? {
        let progressPatterns = [
            #"progress: ([0-9]*\.?[0-9]+)"#,
            #"progress ([0-9]*\.?[0-9]+)"#,
            #"progress update: ([0-9]*\.?[0-9]+)"#,
            #"([0-9]*\.?[0-9]+)%"#
        ]
        
        for pattern in progressPatterns {
            if let range = message.range(of: pattern, options: .regularExpression) {
                let matched = message[range]
                if let numberStr = matched.split(whereSeparator: { ":%".contains($0) }).last,
                   let value = Float(numberStr) {
                    // If the value appears to be a percentage (0-100), normalize it
                    return value > 1.0 ? value / 100.0 : value
                }
            }
        }
        return nil
    }
    
    public static func debug(_ message: String) {
        guard minimumLogLevel.rawValue <= LogLevel.debug.rawValue else { return }
        let log = OSLog(subsystem: subsystem, category: "DEBUG")
        os_log("%@", log: log, type: .debug, message)
    }
    
    public static func error(_ message: String) {
        guard minimumLogLevel.rawValue <= LogLevel.error.rawValue else { return }
        let log = OSLog(subsystem: subsystem, category: "ERROR")
        os_log("%@", log: log, type: .error, message)
    }
    
    public static func fault(_ message: String) {
        guard minimumLogLevel.rawValue <= LogLevel.fault.rawValue else { return }
        let log = OSLog(subsystem: subsystem, category: "FAULT")
        os_log("%@", log: log, type: .fault, message)
    }
    
    // Verbose logging level for extremely detailed logs
    public static func verbose(_ message: String) {
        guard minimumLogLevel.rawValue <= LogLevel.verbose.rawValue else { return }
        let log = OSLog(subsystem: subsystem, category: "VERBOSE")
        os_log("%@", log: log, type: .debug, message)
    }
    
    // New function for audio logging
    public static func audio(_ message: String) {
        guard enableAudioLogs && minimumLogLevel.rawValue <= LogLevel.debug.rawValue else { return }
        let log = OSLog(subsystem: subsystem, category: "AUDIO")
        os_log("%@", log: log, type: .debug, message)
    }
    
    // Progress logging with threshold control
    public static func progress(_ message: String, value: Float? = nil) {
        guard minimumLogLevel.rawValue <= LogLevel.info.rawValue else { return }
        
        if let progressValue = value {
            if !shouldLogProgress(value: progressValue) {
                return
            }
        }
        
        let log = OSLog(subsystem: subsystem, category: "PROGRESS")
        os_log("%@", log: log, type: .info, message)
    }
} 