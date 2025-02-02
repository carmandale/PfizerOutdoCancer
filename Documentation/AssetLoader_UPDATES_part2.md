# AssetLoader_UPDATES_part2.md

## Overview

This document summarizes our ongoing refactor of the asset loading and management system in PfizerOutdoCancer. In this phase, we're transitioning from a preloading (load-all-at-startup) model to an on-demand asset loading system. The primary goals are to reduce memory usage, load assets only when needed, and release assets when they're no longer in use.

## What We've Done So Far

1. **On-Demand Asset Loading Implementation:**
   - We introduced new methods in `AssetLoadingManager.swift`:
     - `loadAsset(withName:category:)`: Checks if an asset is cached in `entityTemplates` and returns a clone if available. If not, it maps the logical key to the actual asset name (using a mapping layer) and loads the asset from the RealityKitContent bundle. The loaded asset is cached for future use.
     - `instantiateAsset(withName:category:)`: A wrapper around `loadAsset(withName:category:)` that simply returns a cloned instance.
   - A mapping layer was implemented via a private dictionary that translates logical keys (such as "intro_environment") to the actual resource names (e.g., "IntroEnvironment").

2. **Intro View and IntroViewModel Updates:**
   - In `IntroViewModel.swift`, the intro environment is now loaded using the new on-demand approach. Instead of relying on preloaded assets, we now call `instantiateAsset(withName: "intro_environment", category: AssetCategory.introEnvironment)` (with mapping) to load the environment on demand.
   - The intro view contains a portal for previewing the lab environment. However, the lab environment was previously loaded using legacy preloading methods. Moving forward, we plan to load the lab environment on demand as well.

3. **Root Entity Timing Issue:**
   - With the shift to on-demand loading, we've identified timing issues where the root entity (defined in `introState.introRootEntity`) might not be available when the asynchronous `.task` block executes in `IntroView.swift`.
   - To resolve this, we've added an `.onAppear` modifier in `IntroView.swift` that ensures the root entity is created immediately (by calling `setupIntroRoot()`) if it hasn't been already. This guarantees that the `.task` block can safely access the root entity and start environment setup on schedule.

## Current Challenges (Specific to IntroView)

- **No Root Entity Found in Task:**
  - The previous preloading system guaranteed that the root entity was already created. With the new on-demand system, there are instances where the `.task` block finds that `introState.introRootEntity` is nil. The solution is to ensure that the root entity is created as soon as the view appears (via `.onAppear`).

- **Lab Environment Not Found for Portal:**
  - The portal in the intro view relies on a lab environment to show a preview, but the legacy method `getLaboratory()` no longer works with the new on-demand approach. We will need to update this part to load the lab environment on demand using methods similar to the intro environment.

- **Portal Not Found:**
  - Because of the lab environment issue, the portal setup in `IntroViewModel` fails, leading to errors like "Portal not found." Addressing the lab environment loading is part of our next steps.

## Next Steps

1. **Ensure Consistent Root Entity Creation:**
   - Update `IntroView.swift` to use an `.onAppear` modifier that calls `setupIntroRoot()` if necessary, ensuring that the root entity is ready before environment setup begins.

2. **Update Lab Environment Loading:**
   - Modify the method in `IntroViewModel.swift` that sets up the portal to load the lab environment on demand (using a pattern similar to the intro environment) so that the portal can be correctly created.

3. **Final Integration and Testing:**
   - Once these modifications are complete, the next step is to test the system on target hardware to verify that all assets are loaded and released as expected, and that the intro view and portal function without errors.

## Conclusion

This refactor (Part 2) is part of our broader initiative to transition to an on-demand asset management system. It aims to ensure that the intro view correctly loads assets while handling the timing and resource constraints inherent in an on-demand model. We are focusing on mitigating errors related to missing root entities and unavailable lab environments. Future updates will address lab environment loading and further optimizations to the asset lifecycle management. 