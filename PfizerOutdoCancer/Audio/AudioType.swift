import Foundation

/// Defines the spatial behavior of audio sources
enum AudioType {
    /// 3D positioned, directional audio that changes based on listener position and orientation
    case spatial
    
    /// Non-directional background audio that's consistent regardless of listener position
    case ambient
    
    /// Stereo/surround channel-based audio without spatial positioning
    case channel
} 