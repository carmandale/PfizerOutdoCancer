Below is a high‐level Refactor Plan document for IntroView.swift. It summarizes how to transition away from ad-hoc timers and direct animation calls in the RealityView “make” closure, toward a modern, async/await pattern. It also outlines a more modular structure for loading assets, setting up entities, and orchestrating your sequence of animations and transitions.

1. Overall Refactor Goals
	•	Remove Timer-based animations (e.g., transitionTimer, portalFadeTimer, portalScaleTimer, etc.) and replace them with Swift Concurrency (Task.sleep) or concurrency-based animation calls.
	•	Do not animate directly inside the RealityView “make” closure. Instead, use a .task (or .onAppear) block at the SwiftUI view level to load and animate the scene.
	•	Store your Entities in @State so that they can be added to the RealityView when they become available.
	•	Use async/await to chain animations (if needed), or run them concurrently (async let) to keep the code clean.
	•	Use TimelineView only for truly per-frame or continuous effects (e.g., the tunnel “twirl” effect, if it must update every frame).

2. Proposed Data & State Structure

Declare all the relevant Entities and states as @State or @StateObject in IntroView, instead of local variables or older Timer properties. For example:

@State private var rootEntity: Entity? = nil
@State private var introEnvironment: Entity? = nil
@State private var portalWarp: Entity? = nil
@State private var portal: Entity? = nil

@State private var showTitleText = false
@State private var shouldDimSurroundings = false

(You can remove the old transitionTimer / portalFadeTimer / portalScaleTimer / titleTextTimer.)

3. Load and Setup in .task

Move your loading code (like instantiateEntity("intro_environment")) into a .task or .onAppear block. For instance:

.body {
    RealityView { content, attachments in
        // Create & add root entity if available
        if let rootEntity {
            content.add(rootEntity)
        }
        
        // Add the environment if loaded
        if let introEnvironment {
            rootEntity?.addChild(introEnvironment)
        }
        
        // Add the portal if loaded
        if let portal {
            rootEntity?.addChild(portal)
        }
        
        // Possibly other attachments...
    }
    .task {
        await loadAndSetupEntities()
        await runAnimationSequence()
    }
    // .preferredSurroundingsEffect, etc.
}

loadAndSetupEntities()

Create an async function that handles your initialization logic:

private func loadAndSetupEntities() async {
    // 1) Create root entity
    let root = Entity()
    root.components.set(
        PositioningComponent(offsetX: 0, offsetY: -1.5, offsetZ: -1.0)
    )
    rootEntity = root
    
    // 2) Load intro environment
    guard let environment = await appModel.assetLoadingManager.instantiateEntity("intro_environment") else {
        print("Failed to load intro environment")
        return
    }
    introEnvironment = environment
    
    // 3) Find portal warp, set initial opacity
    if let warp = environment.findEntity(named: "sh0100_v01_portalWarp2") {
        portalWarp = warp
        warp.opacity = 0.0
    }
    
    // 4) Create portal
    let p = await PortalManager.createPortal(
        appModel: appModel,
        environment: environment,
        portalPlaneName: "Plane_001"
    )
    portal = p
    p.opacity = 0.0
    // position, etc.
}

4. Orchestrate Animations in a Separate Async Function

private func runAnimationSequence() async {
    // 1) Fade in portal warp after X seconds
    try? await Task.sleep(for: .seconds(24))
    if let warp = portalWarp {
        await warp.fadeOpacity(to: 1.0, duration: 10.0)
    }
    
    // 2) Animate portal fade at 103s
    try? await Task.sleep(for: .seconds(103 - 24))  // adjust as needed
    if let p = portal {
        await p.fadeOpacity(to: 1.0, duration: 10.0)
    }
    
    // 3) Scale the portal plane
    if let plane = portal?.findEntity(named: "portalPlane") {
        try? await Task.sleep(for: .seconds(7)) // if needed
        await plane.animateXScale(from: 0, to: 1.0, duration: 15.0)
    }
    
    // 4) Show SwiftUI text
    try? await Task.sleep(for: .seconds(7))
    withAnimation {
        showTitleText = true
    }
    
    // 5) Dim surroundings after 5 seconds
    // or do that earlier if you want:
    try? await Task.sleep(for: .seconds(5))
    withAnimation(.easeInOut(duration: 20.0)) {
        shouldDimSurroundings = true
    }
    
    // 6) Transition to phase .lab after 134 seconds
    try? await Task.sleep(for: .seconds(134 - ???)) // depends on your timeline
    await appModel.transitionToPhase(.lab)
}

The above is just an example “timeline.” You can reorder or parallelize with async let if some animations can run concurrently.

5. Handle the Tunnel “Twirl” in TimelineView(.animation)

Your old code was doing something like:

.update { content, attachments in
    let elapsed = context.date.timeIntervalSince(start)
    // ...
    // update material parameter
}

You can keep this if it truly needs per-frame updates. But if the tunnel effect is just a “fade from 0 → 1 over X seconds,” consider using the same concurrency approach (like a single fade). If you do need it to be dynamic or driven by real-time, TimelineView(.animation) is the right place.

6. Remove Old Timer References

Anywhere you have:

// Portal fade-in (103s)
self.portal?.fadeOpacity(to: 1.0, duration: 10.0, delay: portalStart)

// Timer.scheduledTimer(withTimeInterval: portalStart + 7.0) { ... }

…convert to concurrency steps in your .task code. This eliminates scattered Timer objects, which can cause memory or synchronization issues.

7. Optional: Keep .onDisappear for Cleanup

You might still keep .onDisappear to do last-minute teardown, but you no longer need to invalidate() timers—because you aren’t using them. The .task automatically cancels if the user leaves the view early. That means your animations will stop gracefully.

.onDisappear {
    // Possibly do final cleanup or set states to nil
}

8. Summary of the New Structure
	1.	Entities: Declared in @State.
	2.	RealityView: Minimal “make” closure—just add the root entity and any child entities you have. No animation in there.
	3.	.task:
	•	Runs loadAndSetupEntities() to load all assets.
	•	Calls runAnimationSequence() to orchestrate the timeline in an async manner (fades, scales, transitions).
	4.	Tunnel Twirl: If it’s truly per-frame, keep it in TimelineView(.animation). If it’s just a timed fade, move it to concurrency.
	5.	No Timers: Replaced by concurrency sleeps (Task.sleep).
	6.	No or minimal .onAppear code—just use .task to handle the logic.
	7.	No more manual invalidation of timers. SwiftUI concurrency takes care of cancelation when the view goes away.

This ensures a simpler, more maintainable IntroView that aligns with Apple’s recommended patterns for SwiftUI + RealityKit in modern iOS/visionOS.