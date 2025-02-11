# ADCOptimizedImmersive+Audio Documentation

This file is an extension of the `ADCOptimizedImmersive` struct, handling the audio aspects of the immersive experience.

## `ADCOptimizedImmersive` Extension (Audio)

*   **Purpose:** Manages the loading, preparation, and playback of audio resources, including sound effects (pop sound) and voice-overs (VO).
*   **Key Features:**
    *   **Audio Resource Properties:**
        *   `popAudioFileResource`, `vo1Audio`, `vo2Audio`, `vo3Audio`, `vo4Audio`, `completionAudio`, `niceJobAudio`:  Store `AudioFileResource` instances for various sound effects and voice-overs.
    *   **Audio Entity Properties:**
        *   `popAudioEntity`: An entity used as the source for the pop sound effect, configured for spatial audio.
        *   `voiceOverAudioEntity`: An entity used as the source for voice-overs, also configured for spatial audio.
    *   **Audio Playback Controller Properties:**
        *   `currentVOController`:  Keeps track of the currently playing voice-over controller.
        *   `popAudioPlaybackController`:  Keeps track of the pop sound playback controller.
    *   **Audio Preparation Function:**
        *   `prepareAudioEntities()`: Asynchronously loads audio resources from USDA files and sets up the `popAudioEntity` and `voiceOverAudioEntity` with appropriate `SpatialAudioComponent` configurations.
    *   **Sound Attachment Function:**
        *   `attachPopSoundToTarget(_:)`: Attaches the `popAudioEntity` to a specified target entity, ensuring the sound plays from the correct location in 3D space.
    *   **Sound Playback Functions:**
        *   `playPopSound()`: Plays the pop sound effect.
        *   `playSpatialAudio(step:)`: Plays the appropriate voice-over for a given step in the ADC building process, including handling for the completion sound sequence in step 3.  This function also manages the `voiceOverProgress` in the `ADCDataModel`.
        *   `playVO1()`, `playVO2()`, `playVO3()`, `playVO4()`:  Individual functions to play specific voice-over clips (these are less preferred than `playSpatialAudio`).

This extension encapsulates the audio-related logic for the immersive scene, providing a structured way to manage and play sounds, including spatial audio effects and voice-overs synchronized with the application's state. The use of asynchronous loading and preparation ensures that audio resources are handled efficiently without blocking the main thread. 