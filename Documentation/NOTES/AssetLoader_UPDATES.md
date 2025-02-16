# Asset Loading Refactor Plan for VisionOS2

This document outlines the updated approach for asset management in our VisionOS2 application, moving from a preloading-everything model to an on-demand asset loading strategy. This refactor is designed to reduce memory pressure by loading assets only when needed and releasing them promptly when they are no longer in use.

## Overview

The current implementation is transitioning from a task-group based preloading system to an on-demand loading strategy. This transition is being done in phases to ensure stability and maintain critical functionality.

## Current Implementation Status

1. **Asset Loading:**
   - New on-demand methods implemented in `AssetLoadingManager.swift`:
     ```swift
     func instantiateAsset(withName:category:) async throws -> Entity
     func loadAsset(withName:category:) async throws -> Entity
     ```
   - Intro scene updated to use new methods
   - Lab scene still using legacy methods (pending update)

2. **Asset Cleanup:**
   - Cleanup is managed through `AssetLoadingManager` and triggered in `AppModel.transitionToPhase`
   - Current cleanup methods:
     ```swift
     // Current method (to be deprecated)
     func releaseIntroEnvironment() async
     
     // New methods being implemented
     func releaseAsset(withName: String) async
     func releaseAssets(for category: AssetCategory) async
     ```

3. **Phase Transitions:**
   - Asset cleanup is triggered in `AppModel.swift`'s `transitionToPhase`:
     ```swift
     func transitionToPhase(_ newPhase: AppPhase) async {
         // Clean up assets from the current phase before transitioning
         switch currentPhase {
         case .intro:
             if newPhase != .intro {
                 await assetLoadingManager.releaseAsset(withName: "intro_environment")
                 await assetLoadingManager.releaseAssets(for: .introEnvironment)
             }
         case .lab:
             if newPhase != .lab {
                 await assetLoadingManager.releaseAssets(for: .labEnvironment)
             }
         // Add other phases...
         }
     }
     ```

## Migration Plan

1. **Asset Release Strategy:**
   - Move all cleanup logic to `AssetLoadingManager`
   - Use `releaseAsset` and `releaseAssets` methods for all cleanup
   - Trigger cleanup during phase transitions in `AppModel`
   - Maintain essential assets in cache as needed

2. **Lab Scene Update:**
   - Update lab loading to use new on-demand API
   - Move lab cleanup from `LabViewModel` to `AssetLoadingManager`
   - Update lab cleanup to use new release methods
   - Ensure lab assembly logic works with on-demand loading

3. **Testing and Validation:**
   - Verify asset loading/release in phase transitions
   - Monitor memory usage patterns
   - Validate cleanup of non-essential assets
   - Ensure essential assets remain cached

## Best Practices

1. **Asset Loading:**
   - Load assets on-demand when needed
   - Cache templates for reuse
   - Use cloning for instances
   - Handle loading errors gracefully

2. **Asset Cleanup:**
   - Release assets during phase transitions
   - Clean up non-essential assets under memory pressure
   - Maintain essential assets in cache
   - Log cleanup operations for debugging

3. **Memory Management:**
   - Monitor cache size
   - Track asset dependencies
   - Handle memory warnings
   - Release unused assets promptly

## Implementation Notes

1. **Essential Assets:**
   - "assembled_lab" remains cached for portal preview
   - Core environment assets kept for active phase
   - Audio/VO assets can be released and reloaded

2. **Cleanup Triggers:**
   - Phase transitions
   - Memory pressure warnings
   - Manual cleanup calls
   - System cleanup events

## Next Steps

1. **Complete Release API Implementation:**
   - Implement `releaseAsset` and `releaseAssets` methods
   - Update phase transitions to use new methods
   - Deprecate environment-specific release methods

2. **Update Lab Scene:**
   - Convert to on-demand loading
   - Implement proper cleanup
   - Test with portal preview

3. **Documentation:**
   - Update API documentation
   - Add usage examples
   - Document cleanup patterns

## Conclusion

This refactor aims to establish a consistent, efficient asset management system. The transition is being done incrementally to maintain stability while improving memory usage and following visionOS best practices.