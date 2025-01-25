import SwiftUI
import RealityKit
import OSLog

@MainActor
class ADCAudioStorage {
    private var rootEntity: Entity?
    private var popAudioEntity: Entity?
    private var voiceOverEntity: Entity?
    
    private var popAudioController: AudioPlaybackController?
    private var voiceOverController: AudioPlaybackController?
    private var voiceOverFadeTask: Task<Void, Error>?
    
    private var popAudioResource: AudioFileResource?
    private var voiceOver1Resource: AudioFileResource?
    private var voiceOver2Resource: AudioFileResource?
    private var voiceOver3Resource: AudioFileResource?
    private var voiceOver4Resource: AudioFileResource?
    
    enum VoiceOver {
        case voiceOver1
        case voiceOver2
        case voiceOver3
        case voiceOver4
    }
    
    func prepareAudio(for rootEntity: Entity) async throws {
        self.rootEntity = rootEntity
        
        // Create audio entities
        let popSource = Entity()
        popSource.name = "PopSource"
        popSource.components.set(SpatialAudioComponent(directivity: .beam(focus: 1.0)))
        rootEntity.addChild(popSource)
        self.popAudioEntity = popSource
        
        let voiceOverSource = Entity()
        voiceOverSource.name = "VoiceOverSource"
        voiceOverSource.components.set(SpatialAudioComponent(directivity: .beam(focus: 1.0)))
        rootEntity.addChild(voiceOverSource)
        self.voiceOverEntity = voiceOverSource
        
        // Load audio resources
        do {
            popAudioResource = try await AudioFileResource(named: "/Root/bubblepop_mp3")
            voiceOver1Resource = try await AudioFileResource(named: "/Root/BuildADC_VO_1_mp3")
            voiceOver2Resource = try await AudioFileResource(named: "/Root/BuildADC_VO_2_mp3")
            voiceOver3Resource = try await AudioFileResource(named: "/Root/BuildADC_VO_3_mp3")
            voiceOver4Resource = try await AudioFileResource(named: "/Root/BuildADC_VO_4_mp3")
        } catch {
            os_log(.error, "ITR..ADCAudioStorage: ❌ Failed to load audio resources: \(error.localizedDescription)")
            throw error
        }
    }
    
    func cleanup() {
        popAudioController?.stop()
        voiceOverController?.stop()
        voiceOverFadeTask?.cancel()
        
        popAudioEntity?.removeFromParent()
        voiceOverEntity?.removeFromParent()
        
        popAudioEntity = nil
        voiceOverEntity = nil
        rootEntity = nil
    }
    
    func playPopSound(at position: SIMD3<Float>) {
        guard let popAudioEntity = popAudioEntity,
              let popAudioResource = popAudioResource else {
            os_log(.error, "ITR..ADCAudioStorage: ❌ Pop sound resources not ready")
            return
        }
        
        os_log(.debug, "ITR..ADCAudioStorage: 🔊 SYSTEM 2 - Playing at position \(position)")
        popAudioEntity.position = position
        popAudioController?.stop()
        popAudioController = popAudioEntity.prepareAudio(popAudioResource)
        popAudioController?.play()
    }
    
    func playVoiceOver(_ voiceOver: VoiceOver) async {
        guard let voiceOverEntity = voiceOverEntity else {
            os_log(.error, "ITR..ADCAudioStorage: ❌ Voice over entity not ready")
            return
        }
        
        // Get the appropriate resource
        let resource: AudioFileResource? = switch voiceOver {
        case .voiceOver1: voiceOver1Resource
        case .voiceOver2: voiceOver2Resource
        case .voiceOver3: voiceOver3Resource
        case .voiceOver4: voiceOver4Resource
        }
        
        guard let resource = resource else {
            os_log(.error, "ITR..ADCAudioStorage: ❌ Voice over resource not ready")
            return
        }
        
        // Stop any current playback
        voiceOverController?.stop()
        voiceOverFadeTask?.cancel()
        
        // Start new playback
        voiceOverController = voiceOverEntity.prepareAudio(resource)
        voiceOverController?.play()
    }
}
