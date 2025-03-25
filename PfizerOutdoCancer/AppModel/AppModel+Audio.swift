//
//  AppModel+Audio.swift
//  PfizerOutdoCancer
//
//  Created for UI sound effects
//

import Foundation
import SwiftUI
import OSLog
import AVFoundation

// MARK: - Audio Extension for AppModel
extension AppModel {
    
    // MARK: - Audio Setup and Loading
    
    /// Sets up and initializes the audio system
    @MainActor
    func setupAudioSystem() async {
        Logger.info("Setting up audio system")
        // Load all audio resources
        loadAVSounds()  // This is synchronous since it's using Bundle resources
    }
    
    /// Loads AVFoundation audio resources for UI sounds
    @MainActor
    func loadAVSounds() {
        Logger.info("Loading AVFoundation UI sound resources")
        
        // Find the sonic pulse sound in the app bundle Resources directory
        if let soundURL = Bundle.main.url(forResource: "Pfizer_Start_Sound", withExtension: "wav") {
            do {
                // Initialize AVAudioPlayer
                let audioPlayer = try AVAudioPlayer(contentsOf: soundURL)
                audioPlayer.prepareToPlay() // Pre-buffer the audio
                avAudioPlayers["startSound"] = audioPlayer
                Logger.info("✅ Successfully loaded sonic_pulse sound for AVAudioPlayer")
            } catch {
                Logger.error("❌ Failed to load sonic_pulse sound for AVAudioPlayer: \(error.localizedDescription)")
            }
        } else {
            Logger.error("❌ Could not find Sonic_Pulse_Hit_03.wav in app bundle")
        }

        // Load additional UI sounds
        if let soundURL = Bundle.main.url(forResource: "Menu_Select", withExtension: "wav") {
            do {
                let audioPlayer = try AVAudioPlayer(contentsOf: soundURL)
                audioPlayer.prepareToPlay()
                avAudioPlayers["menuSelect"] = audioPlayer
                Logger.info("✅ Successfully loaded Menu_Select sound for AVAudioPlayer")
            } catch {
                Logger.error("❌ Failed to load Menu_Select sound for AVAudioPlayer: \(error.localizedDescription)")
            }
        } else {
            Logger.error("❌ Could not find Menu_Select.wav in app bundle")
        }

        if let soundURL = Bundle.main.url(forResource: "Menu_Select2", withExtension: "wav") {
            do {
                let audioPlayer = try AVAudioPlayer(contentsOf: soundURL)
                audioPlayer.prepareToPlay()
                avAudioPlayers["menuSelect2"] = audioPlayer
                Logger.info("✅ Successfully loaded Menu_Select2 sound for AVAudioPlayer")
            } catch {
                Logger.error("❌ Failed to load Menu_Select2 sound for AVAudioPlayer: \(error.localizedDescription)")
            }
        } else {
            Logger.error("❌ Could not find Menu_Select2.wav in app bundle")
        }

        if let soundURL = Bundle.main.url(forResource: "clickPop", withExtension: "wav") {
            do {
                let audioPlayer = try AVAudioPlayer(contentsOf: soundURL)
                audioPlayer.prepareToPlay()
                avAudioPlayers["clickPop"] = audioPlayer
                Logger.info("✅ Successfully loaded clickPop sound for AVAudioPlayer")
            } catch {
                Logger.error("❌ Failed to load clickPop sound for AVAudioPlayer: \(error.localizedDescription)")
            }
        } else {
            Logger.error("❌ Could not find clickPop.wav in app bundle")
        }

        if let soundURL = Bundle.main.url(forResource: "clickPop2", withExtension: "wav") {
            do {
                let audioPlayer = try AVAudioPlayer(contentsOf: soundURL)
                audioPlayer.prepareToPlay()
                avAudioPlayers["clickPop2"] = audioPlayer
                Logger.info("✅ Successfully loaded clickPop2 sound for AVAudioPlayer")
            } catch {
                Logger.error("❌ Failed to load clickPop2 sound for AVAudioPlayer: \(error.localizedDescription)")
            }
        } else {
            Logger.error("❌ Could not find clickPop2.wav in app bundle")
        }
    }
    
    // MARK: - Sound Playback Methods
    
    /// Plays the start button sound when pressed
    @MainActor
    func playStartButtonSound() {
        Logger.info("Playing start button sound")
        if let player = avAudioPlayers["startSound"] {
            player.volume = 0.125 // 0.25
        }
        playAVSound(named: "startSound")
    }
    
    /// Plays the Menu Select sound
    @MainActor
    func playMenuSelectSound() {
        Logger.info("Playing Menu Select sound")
        if let player = avAudioPlayers["menuSelect"] {
            player.volume = 0.0625
        }
        playAVSound(named: "menuSelect")
    }
    
    /// Plays the Menu Select2 sound
    @MainActor
    func playMenuSelect2Sound() {
        Logger.info("Playing Menu Select2 sound")
        if let player = avAudioPlayers["menuSelect2"] {
            player.volume = 0.125
        }
        playAVSound(named: "menuSelect2")
    }
    
    /// Plays the clickPop sound
    @MainActor
    func playClickPopSound() {
        Logger.info("Playing clickPop sound")
        playAVSound(named: "clickPop")
    }
    
    /// Plays the clickPop2 sound
    @MainActor
    func playClickPop2Sound() {
        Logger.info("Playing clickPop2 sound")
        playAVSound(named: "clickPop2")
    }
    
    /// Plays a sound using AVAudioPlayer
    @MainActor
    private func playAVSound(named identifier: String) {
        guard let player = avAudioPlayers[identifier] else {
            Logger.info("⚠️ No AVAudioPlayer found for \(identifier), checking if we need to load")
            
            // Try to load on demand if not found
            loadAVSounds()
            return
        }
        
        // Ensure the player is ready to play from the beginning
        player.currentTime = 0
        
        // Play the sound
        if player.play() {
            Logger.info("✅ Successfully started AVAudioPlayer for \(identifier)")
        } else {
            Logger.error("❌ Failed to play AVAudioPlayer for \(identifier)")
        }
    }
}
