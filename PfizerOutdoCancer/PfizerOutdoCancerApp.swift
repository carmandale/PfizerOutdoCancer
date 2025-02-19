//
//  PfizerOutdoCancerApp.swift
//  PfizerOutdoCancer
//
//  Created by Dale Carman on 12/20/24.
//

import SwiftUI
import RealityKitContent
import os

@main
struct PfizerOutdoCancerApp: App {
    // Change from @StateObject to @State
    @State private var appModel = AppModel()
    
    // for ADC view
    @State private var adcDataModel = ADCDataModel()
    
    @Environment(\.openImmersiveSpace) private var openImmersiveSpace
    @Environment(\.dismissImmersiveSpace) private var dismissImmersiveSpace
    @Environment(\.openWindow) private var openWindow
    @Environment(\.dismissWindow) private var dismissWindow
    @Environment(\.scenePhase) private var scenePhase
    
    @State private var immersionStyle: ImmersionStyle =
        .progressive(0.0...1.0, initialAmount: 0.5)
    
    var body: some Scene {
        // Now $appModel references will work correctly
        WindowGroup(id: AppModel.mainWindowId) {
            ContentView()
                .environment(appModel)
                .environment(adcDataModel)
                .onChange(of: scenePhase) { _, newPhase in
                    Task {
                        await handleScenePhaseChange(to: newPhase)
                    }
                }
        }
        .defaultSize(width: 800, height: 800)
        .windowStyle(.plain)
        .persistentSystemOverlays(appModel.currentPhase == .loading || appModel.currentPhase == .ready ? .visible : .hidden)
        .windowResizability(.contentSize)
        
        WindowGroup(id: AppModel.libraryWindowId) {
            if appModel.currentPhase == .lab || appModel.currentPhase == .intro {
            LibraryView()
                .environment(appModel)
                .environment(adcDataModel)
                .transition(Appear())
            }
        }
        .defaultSize(CGSize(width: 800, height: 600))

        .persistentSystemOverlays(appModel.isLibraryWindowOpen ? .visible : .hidden)


        WindowGroup(id: AppModel.navWindowId) {
            NavigationView()
                .environment(appModel)
                .environment(adcDataModel)
                .transition(Appear())
        }
        .windowStyle(.plain)
        .windowResizability(.contentSize)
        .defaultWindowPlacement { _, context in
            return WindowPlacement(.utilityPanel)
        }

        WindowGroup(id: AppModel.hopeMeterUtilityWindowId) {
            HopeMeterUtilityView()
                .environment(appModel)
                .environment(adcDataModel)
        }
        .windowStyle(.plain)
        .windowResizability(.contentSize)
        .defaultWindowPlacement { _, context in
            return WindowPlacement(.utilityPanel)
        }


        .onChange(of: appModel.currentPhase) { oldPhase, newPhase in
            if oldPhase == newPhase { return }
            if newPhase != .lab {
                dismissWindow(id: AppModel.libraryWindowId)
            }
        }
        
        
        
        
        
        // MARK: Immersive Views
        Group {

            ImmersiveSpace(id: "IntroSpace") {
                if appModel.currentPhase == .intro || appModel.currentPhase == .ready {
                    IntroView()
//                        .preferredSurroundingsEffect(.ultraDark)
                        .environment(appModel)
                        .environment(adcDataModel)
                        .upperLimbVisibility(.visible)
                        .onAppear {
                            // After 3 seconds, animate immersion to full (100%) over 5 seconds
                            DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
                                withAnimation(.easeInOut(duration: 5)) {
                                    immersionStyle = .progressive(0.0...1.0, initialAmount: 1.0)
                                }
                            }
                        }
                        .onAppear {
                            appModel.immersiveSpaceState = .open
                        }
                        .onDisappear {
                            if appModel.immersiveSpaceDismissReason == .manual {
                                // We dismissed it, just update state
                                appModel.immersiveSpaceState = .closed
                            } else {
                                // System dismissed it (Digital Crown), clean up
                                Task {
                                    await cleanupAppState()
                                }
                            }
                            // Reset for next time
                            appModel.immersiveSpaceDismissReason = nil
                        }
                }
                
            }
//            .immersionStyle(selection: $appModel.introStyle, in: .progressive)
//            .immersionStyle(selection: $immersionStyle,
//                                in: .progressive(0.0...1.0, initialAmount: 0.5))
            .immersionStyle(selection: $appModel.introStyle, in: .mixed)
            

            ImmersiveSpace(id: "OutroSpace") {
                if appModel.currentPhase == .outro {
                    OutroView()
                        .environment(appModel)
                        .environment(adcDataModel)
                        .onAppear {
                            appModel.immersiveSpaceState = .open
                        }
                        .onDisappear {
                            if appModel.immersiveSpaceDismissReason == .manual {
                                // We dismissed it, just update state
                                appModel.immersiveSpaceState = .closed
                            } else {
                                // System dismissed it (Digital Crown), clean up
                                print("I am in the outro space in the onDisappear else block and think that I have been dismissed")
                                 Task {
                                     await cleanupAppState()
                                 }
                            }
                            // Reset for next time
                            appModel.immersiveSpaceDismissReason = nil
                        }
                }
                
            }
            .immersionStyle(selection: $appModel.outroStyle, in: .mixed)

            
                ImmersiveSpace(id: "LabSpace") {
                    if appModel.currentPhase == .lab  {
                        LabView()
                            .environment(appModel)
                            .environment(adcDataModel)
                            .onAppear {
                                appModel.immersiveSpaceState = .open
                            }
                            .onDisappear {
                                if appModel.immersiveSpaceDismissReason == .manual {
                                    // We dismissed it, just update state
                                    appModel.immersiveSpaceState = .closed
                                } else {
                                    // System dismissed it (Digital Crown), clean up
                                    Task {
                                        await cleanupAppState()
                                    }
                                }
                                // Reset for next time
                                appModel.immersiveSpaceDismissReason = nil
                            }
                    }
                    
                }
                .immersionStyle(selection: $appModel.labStyle, in: .full)
                .upperLimbVisibility(.visible)
            
            
            ImmersiveSpace(id: "BuildingSpace") {
                if appModel.currentPhase == .building && !appModel.isBuilderInstructionsOpen {
                    ADCOptimizedImmersive()
                        .environment(appModel)
                        .environment(adcDataModel)
                        .onAppear {
                            appModel.immersiveSpaceState = .open
                        }
                        .onDisappear {
                            if appModel.immersiveSpaceDismissReason == .manual {
                                // We dismissed it, just update state
                                appModel.immersiveSpaceState = .closed
                            } else {
                                // System dismissed it (Digital Crown), clean up
                                Task {
                                    // Ensure builder instructions are closed first
                                    // appModel.isBuilderInstructionsOpen = false
                                    await cleanupAppState()
                                }
                            }
                            // Reset for next time
                            appModel.immersiveSpaceDismissReason = nil
                        }
                }
                
            }
            .immersionStyle(selection: $appModel.buildingStyle, in: .mixed)

            ImmersiveSpace(id: "AttackSpace") {
                if appModel.currentPhase == .playing || appModel.currentPhase == .completed {
                    AttackCancerView()
                        .environment(appModel)
                        .environment(adcDataModel)
                        .onAppear {
                            appModel.immersiveSpaceState = .open
                        }
                        .onDisappear {
                            if appModel.immersiveSpaceDismissReason == .manual {
                                // We dismissed it, just update state
                                appModel.immersiveSpaceState = .closed
                            } else {
                                // System dismissed it (Digital Crown), clean up
                                Task {
                                    await cleanupAppState()
                                }
                            }
                            // Reset for next time
                            appModel.immersiveSpaceDismissReason = nil
                        }
                }
                
            }
            .immersionStyle(selection: $appModel.attackStyle, in: .progressive)
            .upperLimbVisibility(.visible)
            
            // MARK: PHASE CHANGE
            // Single onChange handler for phase transitions
            .onChange(of: appModel.currentPhase) { oldPhase, newPhase in
                if oldPhase == newPhase { return }

                Task {
                    if oldPhase.needsImmersiveSpace && !newPhase.shouldKeepPreviousSpace {
                        if appModel.immersiveSpaceState == .open {
                            appModel.immersiveSpaceDismissReason = .manual
                            await dismissImmersiveSpace()
                            os_log(.debug, "🧹 **onChange Function**: Immersive space dismissed successfully.")
                            appModel.immersiveSpaceState = .closed
                        }
                    }

                    await handleWindowsForPhase(newPhase)

                    if newPhase.needsImmersiveSpace && !newPhase.shouldKeepPreviousSpace {
                        if newPhase == .playing || newPhase == .outro {
                            // Add a short delay to allow asset preloading and state updates to settle.
                            try? await Task.sleep(nanoseconds: 150_000_000) // 150ms delay
                            print("Transitioning into \(newPhase); delay elapsed. Proceeding to open immersive space.")
                        }
                        let result = await openImmersiveSpace(id: newPhase.spaceId)
                        print("openImmersiveSpace result for \(newPhase): \(result)")
                    }
                    if newPhase == .building {
                        // Explicitly set the immersive space state to closed so that manual launch works.
                        appModel.immersiveSpaceState = .closed
                    }
                }
            }

        }
        
        
    }

    init() {
        print("🏁 PfizerOutdoCancerApp init starting...")
        
        // Set AppModel before registering the system
        print("📲 Setting AppModel in PositioningSystem...")
        PositioningSystem.setAppModel(appModel)
        
        print("📝 Registering components and systems...")
        /// Register components and systems
        RealityKitContent.AttachmentPoint.registerComponent()
        RealityKitContent.CancerCellComponent.registerComponent()
        RealityKitContent.CancerCellStateComponent.registerComponent()
        RealityKitContent.MovementComponent.registerComponent()
        RealityKitContent.UIAttachmentComponent.registerComponent()
        RealityKitContent.ADCComponent.registerComponent()
        // RealityKitContent.BreathingComponent.registerComponent()
        RealityKitContent.CellPhysicsComponent.registerComponent()
        RealityKitContent.MicroscopeViewerComponent.registerComponent()
    //        RealityKitContent.GestureComponent.registerComponent()
        RealityKitContent.AntigenComponent.registerComponent()
        RealityKitContent.InteractiveDeviceComponent.registerComponent()
        
        // Register UI sync components and system
        HitCountComponent.registerComponent()
        UIStateSyncSystem.registerSystem()

        // Register new CancerCellMovementData component
        CancerCellMovementData.registerComponent()
        CancerCellSpeedBoostSystem.registerSystem()

        /// Register systems
        AttachmentSystem.registerSystem()
        // BreathingSystem.registerSystem()
        CancerCellSystem.registerSystem()
        MovementSystem.registerSystem()
        UIAttachmentSystem.registerSystem()
        ADCMovementSystem.registerSystem()
        UIStabilizerSystem.registerSystem()
        AntigenSystem.registerSystem()
        // SwirlingSystem.registerSystem()
        // TraceComponent.registerComponent()
        // TraceSystem.registerSystem()
        RotationComponent.registerComponent()
        RotationSystem.registerSystem()

        // Add PositioningSystem registration
        print("⚙️ Registering PositioningSystem...")
        PositioningSystem.registerSystem()
        PositioningComponent.registerComponent()
        
        // Add ClosureSystem registration
        ClosureSystem.registerSystem()
        ClosureComponent.registerComponent()
        
        // Add HeadTracking FollowSystem
        FollowSystem.registerSystem()
        FollowComponent.registerComponent()
        
        
        
        // for ADC Builder
        ADCGestureComponent.registerComponent()
        ADCCameraSystem.registerSystem()
        ADCBillboardSystem.registerSystem()
        ADCSimpleBillboardSystem.registerSystem()
        ADCProximitySystem.registerSystem()
        
        print("✅ PfizerOutdoCancerApp init completed")
    }
    
    // Helper function to handle window management
    @MainActor
    private func handleWindowsForPhase(_ phase: AppPhase) async {
        print("🎯 Managing windows for phase: \(phase)")
        print("📊 Before state update - nav window open: \(appModel.isNavWindowOpen)")
        
        // First, update model state
        switch phase {
        case .loading:
            // Make sure loading window is open
            if !appModel.isMainWindowOpen {
                openWindow(id: AppModel.mainWindowId)
                appModel.isMainWindowOpen = true
            }
            
        case .ready:
            if !appModel.isMainWindowOpen {
                openWindow(id: AppModel.mainWindowId)
                appModel.isMainWindowOpen = true
            }
            if appModel.isNavWindowOpen {
                dismissWindow(id: AppModel.navWindowId)
                appModel.isNavWindowOpen = false
            }
            
        case .intro: break
            // Handle other windows
//            if !appModel.isNavWindowOpen {
//                openWindow(id: AppModel.navWindowId)
//                appModel.isNavWindowOpen = true
//            }
        case .outro:
            if appModel.isNavWindowOpen {
                dismissWindow(id: AppModel.navWindowId)
                appModel.isNavWindowOpen = false
            }
        case .playing:
            // Explicitly dismiss nav window first
            if appModel.isNavWindowOpen {
                dismissWindow(id: AppModel.navWindowId)
                appModel.isNavWindowOpen = false
            }
            // No need for default case handling
//            return  // Add explicit return to prevent falling through to default
//            openWindow(id: AppModel.mainWindowId)
            
        case .completed:
            // if !appModel.isNavWindowOpen {
            //     openWindow(id: AppModel.navWindowId)
            //     appModel.isNavWindowOpen = true
            // }
            dismissWindow(id: AppModel.hopeMeterUtilityWindowId)
            appModel.isHopeMeterUtilityWindowOpen = false
//            openWindow(id: AppModel.mainWindowId)
            
        case .lab: break

//            if !appModel.isNavWindowOpen {
//                openWindow(id: AppModel.navWindowId)
//                appModel.isNavWindowOpen = true
//            }
        case .building:
            if appModel.isNavWindowOpen {
                print("closing nav window")
                dismissWindow(id: AppModel.navWindowId)
                appModel.isNavWindowOpen = false
            }
        default:
            if !appModel.isMainWindowOpen {
                openWindow(id: AppModel.mainWindowId)
                appModel.isMainWindowOpen = true
            }
            if appModel.isNavWindowOpen {
                dismissWindow(id: AppModel.navWindowId)
                appModel.isNavWindowOpen = false
            }
        }
        
        // // Show/hide hope meter utility window based on phase
        // if phase == .playing {
        //     openWindow(id: AppModel.hopeMeterUtilityWindowId)
        // } else {
        //     dismissWindow(id: AppModel.hopeMeterUtilityWindowId)
        // }

        
        // Always dismiss the completed window if not in completed phase
//        if phase != .completed {
//            dismissWindow(id: AppModel.gameCompletedWindowId)
//        }
        
        print("📊 Window states after update:")
        print("  Main: \(appModel.isMainWindowOpen)")
        print("  Debug: \(appModel.isNavWindowOpen)")
        print("  Library: \(appModel.isLibraryWindowOpen)")
        print("  Builder: \(appModel.isBuilderWindowOpen)")
        print("  Phases:")
        print("    AppPhase: \(appModel.currentPhase)")
        print("    ScenePhase: \(scenePhase)")
        print("    LoadingPhase: \(appModel.assetLoadingManager.loadingState)")
    }

    // MARK: - App State Management
    private func cleanupAppState() async {
        print("🧹 Cleaning up app state")
        Logger.info("""
        
        === Cleaning Up App State ===
        ├─ Current Phase: \(appModel.currentPhase)
        ├─ Immersive Space: \(appModel.immersiveSpaceState)
        └─ Tracking Active: \(appModel.trackingManager.worldTrackingProvider.state)
        """)
        
        // 1. Stop tracking first to ensure clean provider state
        await appModel.trackingManager.stopTracking()
        
        do {
            // Wait for tracking to fully stop with verification
            try await appModel.trackingManager.waitForCleanup()
            if !appModel.trackingManager.verifyProviderState(expectRunning: false) {
                Logger.error("❌ Tracking cleanup verification failed during app state cleanup")
            }
        } catch {
            Logger.error("❌ Tracking cleanup failed during app state cleanup: \(error)")
        }

        // 2. Close immersive space if open
        if appModel.immersiveSpaceState == .open {
            appModel.immersiveSpaceDismissReason = .manual
            if let activeSpace = appModel.currentImmersiveSpace {
                Logger.debug("""
                
                === Attempting to dismiss Immersive Space ===
                Current Phase: \(appModel.currentPhase)
                Active Space: \(String(describing: activeSpace))
                """)
            }
            
            await dismissImmersiveSpace()
            Logger.debug("=== Finished Dismiss Attempt ===\n")
            appModel.immersiveSpaceState = .closed
        }

        // 3. Wait briefly to ensure cleanup completes
        try? await Task.sleep(for: .milliseconds(100))
        
        // 4. Reset state
        appModel.immersiveSpaceState = .closed
        appModel.immersiveSpaceDismissReason = nil
        
        Logger.info("""
        
        === App State Cleanup Complete ===
        ├─ Immersive Space: \(appModel.immersiveSpaceState)
        └─ Tracking State: \(appModel.trackingManager.worldTrackingProvider.state)
        """)
    }

    // MARK: - Scene Phase Management
    private func handleScenePhaseChange(to newPhase: ScenePhase) async {
        Logger.info("""
        
        === Scene Phase Change ===
        ├─ To: \(newPhase)
        ├─ Current App Phase: \(appModel.currentPhase)
        └─ Tracking State: \(appModel.trackingManager.worldTrackingProvider.state)
        """)
        
        switch newPhase {
        case .background:
            // 1. Stop tracking and cleanup
            await cleanupAppState()
            
            // 2. Clean up game state if needed
            if appModel.currentPhase == .playing {
                await appModel.gameState.tearDownGame()
            }
            
        case .inactive:
            // No additional cleanup needed
            break
            
        case .active:
            // 1. Ensure previous cleanup is complete
            try? await Task.sleep(for: .milliseconds(200))
            
            // 2. Always transition to intro with fresh tracking
            await appModel.transitionToPhase(.loading, adcDataModel: adcDataModel)
            
        @unknown default:
            break
        }
    }
}
