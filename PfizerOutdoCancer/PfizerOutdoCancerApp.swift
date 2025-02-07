//
//  PfizerOutdoCancerApp.swift
//  PfizerOutdoCancer
//
//  Created by Dale Carman on 12/20/24.
//

import SwiftUI
import RealityKitContent

@main
struct PfizerOutdoCancerApp: App {
    @State private var appModel = AppModel()
    
    // for ADC view
    @State private var adcDataModel = ADCDataModel()
    
    @Environment(\.openImmersiveSpace) private var openImmersiveSpace
    @Environment(\.dismissImmersiveSpace) private var dismissImmersiveSpace
    @Environment(\.openWindow) private var openWindow
    @Environment(\.dismissWindow) private var dismissWindow
    @Environment(\.scenePhase) private var scenePhase
    
    var body: some Scene {
        // Now $appModel references will work correctly
        WindowGroup(id: AppModel.mainWindowId) {
            ContentView()
                .environment(appModel)
                .environment(adcDataModel)
                .onChange(of: scenePhase) { _, newPhase in
                        switch newPhase {
                        case .background:
                            Task {
                                print("→ .background")
                                // Stop tracking and close immersive space
                                await cleanupAppState()
                                
                                // Ensure game state is cleaned up
                                if appModel.currentPhase == .playing {
                                    appModel.gameState.tearDownGame()
                                }
                            }
                        case .inactive:
                            Task {
                                print("→ .inactive")
                                // No additional cleanup needed here
                            }
                        case .active:
                            Task {
                                print("→ .active")
                                // Add small delay to ensure cleanup completes
                                try? await Task.sleep(nanoseconds: 200_000_000) // 200ms delay
//                                print("I waited 200ms and I am still in the active state")
//                                print("I am in the \(appModel.currentPhase) phase")
//                                print("I am in the \(scenePhase) scene phase")
//                                print("not doing anything else until I figure this out")
                                // Always transition to ready state
                                 await appModel.transitionToPhase(.ready)
                            }
                        default:
                            break
                        }
                    }
//                .transition(Appear())
                
        }
        .defaultSize(width: 800, height: 800)
        .windowStyle(.plain)
        .persistentSystemOverlays(appModel.currentPhase == .loading || appModel.currentPhase == .ready || appModel.currentPhase == .building ? .visible : .hidden)
        .windowResizability(.contentSize)
        
        WindowGroup(id: AppModel.libraryWindowId) {
            if appModel.currentPhase == .lab {
            LibraryView()
                .environment(appModel)
                .environment(adcDataModel)
                .transition(Appear())
            }
        }
        .defaultSize(CGSize(width: 800, height: 600))
//        .defaultWindowPlacement { _, context in
//            if let mainWindow = context.windows.first {
//                return WindowPlacement(.leading(mainWindow))
//            }
//            return WindowPlacement(.none)
//        }
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
                IntroView()
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
            .immersionStyle(selection: $appModel.introStyle, in: .mixed)

            ImmersiveSpace(id: "OutroSpace") {
                OutroView()
                    .environment(appModel)
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
            .immersionStyle(selection: $appModel.outroStyle, in: .mixed)

            ImmersiveSpace(id: "LabSpace") {
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
            .immersionStyle(selection: $appModel.labStyle, in: .full)
            .upperLimbVisibility(.visible)
            
            ImmersiveSpace(id: "BuildingSpace") {
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
            .immersionStyle(selection: $appModel.buildingStyle, in: .mixed)

            ImmersiveSpace(id: "AttackSpace") {
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
            .immersionStyle(selection: $appModel.attackStyle, in: .progressive)
            .upperLimbVisibility(.visible)
            
            // MARK: PHASE CHANGE
            // Single onChange handler for phase transitions
            // .onChange(of: appModel.currentPhase) { oldPhase, newPhase in
            //     if oldPhase == newPhase { return }
                
            //     Task {
            //         // Ensure this runs on the main actor by either wrapping the Task as shown
            //         // or by calling a @MainActor function.
            //         await updateImmersiveSpace(for: newPhase, from: oldPhase)
            //         await handleWindowsForPhase(newPhase)
            //     }
            // }

            .onChange(of: appModel.currentPhase) { oldPhase, newPhase in
                if oldPhase == newPhase { return }
                
                Task {
                    if oldPhase.needsImmersiveSpace && !newPhase.shouldKeepPreviousSpace {
                        if appModel.immersiveSpaceState == .open {
                            appModel.immersiveSpaceDismissReason = .manual
                            await dismissImmersiveSpace()
                        }
                    }
                    
                    await handleWindowsForPhase(newPhase)
                    
                    if newPhase.needsImmersiveSpace && !newPhase.shouldKeepPreviousSpace {
                        await openImmersiveSpace(id: newPhase.spaceId)
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
        RealityKitContent.BreathingComponent.registerComponent()
        RealityKitContent.CellPhysicsComponent.registerComponent()
        RealityKitContent.MicroscopeViewerComponent.registerComponent()
    //        RealityKitContent.GestureComponent.registerComponent()
        RealityKitContent.AntigenComponent.registerComponent()
        RealityKitContent.InteractiveDeviceComponent.registerComponent()
        
        // Register UI sync components and system
        HitCountComponent.registerComponent()
        UIStateSyncSystem.registerSystem()

        /// Register systems
        AttachmentSystem.registerSystem()
        BreathingSystem.registerSystem()
        CancerCellSystem.registerSystem()
        MovementSystem.registerSystem()
        UIAttachmentSystem.registerSystem()
        ADCMovementSystem.registerSystem()
        UIStabilizerSystem.registerSystem()
        AntigenSystem.registerSystem()
        SwirlingSystem.registerSystem()
        TraceComponent.registerComponent()
        TraceSystem.registerSystem()
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
            
        case .intro:
            // Handle other windows
            if !appModel.isNavWindowOpen {
                openWindow(id: AppModel.navWindowId)
                appModel.isNavWindowOpen = true
            }
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
            
        case .lab:

            if !appModel.isNavWindowOpen {
                openWindow(id: AppModel.navWindowId)
                appModel.isNavWindowOpen = true
            }
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
        print("    LoadingPhase: \(appModel.loadingState)")
    }

    @MainActor
    func updateImmersiveSpace(for newPhase: AppPhase, from oldPhase: AppPhase) async {
        if oldPhase.needsImmersiveSpace && !newPhase.shouldKeepPreviousSpace {
            if appModel.immersiveSpaceState == .open {
                appModel.immersiveSpaceDismissReason = .manual
                await dismissImmersiveSpace()
            } else {
                await openImmersiveSpace(id: newPhase.spaceId)
            }
        }
    }
    
    // MARK: - App State Management
    private func cleanupAppState() async {
        print("🧹 Cleaning up app state")
        
        // 1. Stop any running game systems first
        if appModel.currentPhase == .playing {
            appModel.gameState.tearDownGame()
        }
        
        // 2. Close immersive space if open
        if appModel.immersiveSpaceState == .open {
            appModel.immersiveSpaceDismissReason = .manual
            await dismissImmersiveSpace()
            appModel.immersiveSpaceState = .closed
        }
        
        // 3. Stop tracking
        appModel.trackingManager.stopTracking()
        
        // 4. Reset phase to ready
        print("> Resetting to phase: READY")
        await appModel.transitionToPhase(.ready)
        
        print("✅ App state cleanup completed")
    }
}
