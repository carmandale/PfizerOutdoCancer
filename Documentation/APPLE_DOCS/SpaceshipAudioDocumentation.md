@Documentation

# Spaceship Audio Overview

This document explains how the Spaceship sample project, found in the “CreatingASpaceshipGame” reference, handles loading and playing audio in RealityKit. It also details best practices and recommended setups for a visionOS app that wants to incorporate similar audio functionality.

---

## 1. Overview: Custom Audio Generation with AudioUnit

• The sample implements a custom AUAudioUnit (Audio Unit) named “AudioUnitTurbine.”  
• Located in “AudioUnitTurbine.h” and “AudioUnitTurbine.mm,” this AU generates real-time, procedural turbine audio.  
• Within Swift code, the engine calls:
  1. allocateRenderResources() to prepare the Audio Unit.  
  2. internalRenderBlock to capture the audio render callback.  
  3. prepareAudio(configuration:audioUnit:) to attach the render block to RealityKit’s audio pipeline.

This approach lets developers feed custom audio directly into RealityKit’s 3D rendering engine, achieving interactive, procedural sound.

---

## 2. Attaching Spatial Audio to Entities

• The sample shows that for each portion of the spaceship requiring spatial audio (e.g., engine noises, exhaust sounds), the code attaches a child entity with a SpatialAudioComponent.  
• For example, an “AudioSource-EngineTurbine” entity is created and parented to the spaceship. This child entity is assigned:
  ```swift
  audioSource.components.set(SpatialAudioComponent(directivity: .beam(focus: 0.25)))
  ```
  - Directivity focuses the audio in front of the source.  
  - This child entity effectively acts as a 3D sound emitter.

• By positioning these audio source entities in different locations (e.g., left engine, right engine), the 3D audio pipeline automatically panning and attenuation based on the user’s head position and rotation.

---

## 3. Bridging Audio into the Scene via prepareAudio

• Every entity that needs custom audio calls a bridging function similar to:
  ```swift
  let audioController = try entity.prepareAudio(configuration: config, audioUnit: myAudioUnit)
  ```
  This:  
  1. Sets the output format (e.g., 48kHz, mono).  
  2. Allocates resources on the AU.  
  3. Passes the AU’s internalRenderBlock to RealityKit.  

• Once set up, RealityKit automatically invokes your audio unit’s render block every frame, mixing it spatially based on the entity’s current position in the scene.

---

## 4. Recommended Setup

Below is a distilled set of best practices and steps for adding 3D audio to your own visionOS app:

1. **Structure Your Audio as a Custom AU (Optional)**  
   - If you need procedural audio (like dynamic engine noise), build an AUAudioUnit that implements your custom generation code.  
   - Keep it self-contained and define a bridging class to allocate and configure it.

2. **Use prepareAudio(...)**  
   - In RealityKit, call prepareAudio(...) on the entity that should emit the audio.  
   - Ensure you set the correct AVAudioFormat before calling allocateRenderResources() on your audio unit.

3. **Attach a SpatialAudioComponent**  
   - Create (or use the same) entity that has the 3D position in your scene.  
   - Add a SpatialAudioComponent for the desired directivity or spread. Example:
     ```swift
     entity.components.set(SpatialAudioComponent(directivity: .beam(focus: 0.25)))
     ```
   - This instructs RealityKit to apply 3D audio transformations with head tracking, attenuation, and panning.

4. **Parent the Audio Source to the Relevant Entity**  
   - If the sound is meant to come from the left engine, create a child entity and position it at the left engine location.  
   - This ensures your 3D audio tracks with the correct in-world location.

5. **Manage Playback**  
   - realityKit’s “AudioGeneratorController” can be paused, resumed, or updated.  
   - For simpler scenarios, rely on the ongoing procedural render block. For triggered audio (like a sound effect), store references to your controller(s) and call play() or stop() as needed.

6. **Performance and Memory**  
   - Procedural audio with a custom Audio Unit can be CPU-intensive. Keep an eye on your rendering performance.  
   - Only allocate render resources when needed; free them when not in use.

---

## 5. Additional Tips

1. **Handling Startup Delays**  
   - If your audio relies on real-time data, consider deferring playback until your RealityView or immersive space is fully active.

2. **Multiple Audio Sources**  
   - It’s common to have one or more child entities for different engines, weapons, or ambient effects. Each can have its own SpatialAudioComponent and custom or pre-recorded audio source.

3. **Testing with Head Movement**  
   - Because RealityKit applies head tracking, test in a device or simulator that simulates head motion, ensuring correct directional attenuation as you “move around” the source.

4. **Consider Reverb and Environmental Effects**  
   - RealityKit supports additional effects (like reverb or occlusion), which can further immerse the user in the 3D environment if the scene context calls for it.

---

## 6. Example Flow

Below is a brief representation of how Spaceship sets up its engine audio:

1. A custom “Turbine” AU is included in “AudioUnitTurbine.”  
2. A child entity “AudioSource-EngineTurbine” is created under the main spaceship entity.  
3. That child entity is given a SpatialAudioComponent(...) for directivity.  
4. The code calls prepareAudio(configuration:..., audioUnit:...) to let RealityKit handle real-time data from the AudioUnitTurbine.  
5. The user experiences engine noise emanating from the correct 3D location in the scene.

---

## Conclusion

The Spaceship reference sample demonstrates a robust method for building interactive, positionally accurate, and potentially procedural audio in visionOS. By:

- Creating a custom audio unit (optional).  
- Parenting specialized audio source entities to your 3D objects.  
- Using RealityKit’s built-in “prepareAudio(...)” and SpatialAudioComponent.  

You can replicate similar immersive audio for your own experiences. This approach integrates neatly with Apple’s best practices for 3D audio in visionOS, ensuring consistent, high-fidelity results. 