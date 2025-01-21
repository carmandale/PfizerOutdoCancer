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
    // Change from @StateObject to @State
    @State private var appModel = AppModel()
    @State private var handTracking = HandTrackingViewModel()
    
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
                                // await handleWindowsForPhase(.ready)
                            }
                        case .inactive:
                            Task {
                                print("→ .inactive")
                                // Wait for cleanup to complete
                                try? await Task.sleep(nanoseconds: 100_000_000) // 100ms delay
                                // await cleanupAppState()
                                // if appModel.trackingManager.currentState == .paused {
                                //     appModel.trackingManager.stopTracking()
                                // }
                            }
                        case .active:
                            Task {
                                print("→ .active")
                                // Add small delay to ensure cleanup completes
                                try? await Task.sleep(nanoseconds: 200_000_000) // 200ms delay
                                if appModel.trackingManager.currentState == .paused {
                                    appModel.trackingManager.stopTracking()
                                }
                                await appModel.transitionToPhase(.ready)
                                // if !appModel.isMainWindowOpen {
                                //     openWindow(id: AppModel.mainWindowId)
                                //     appModel.isMainWindowOpen = true
                                // }
                            }
                        default:
                            break
                        }
                    }
                
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


        WindowGroup(id: AppModel.debugNavigationWindowId) {
            NavigationView()
                .environment(appModel)
                .environment(adcDataModel)
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
                        appModel.immersiveSpaceState = .closed
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
                        appModel.immersiveSpaceState = .closed
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
                        appModel.immersiveSpaceState = .closed
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
                        appModel.immersiveSpaceState = .closed
                    }
            }
            .immersionStyle(selection: $appModel.buildingStyle, in: .mixed)

            ImmersiveSpace(id: "AttackSpace") {
                AttackCancerView()
                    .environment(appModel)
//                    .environment(handTracking)
                    .environment(adcDataModel)
                    .onAppear {
                        appModel.immersiveSpaceState = .open
                    }
                    .onDisappear {
                        appModel.immersiveSpaceState = .closed
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
        print("📊 Before state update - Debug window open: \(appModel.isDebugWindowOpen)")
        
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
            if appModel.isDebugWindowOpen {
                dismissWindow(id: AppModel.debugNavigationWindowId)
                appModel.isDebugWindowOpen = false
            }
            
        case .intro:
            // Handle other windows
            if !appModel.isDebugWindowOpen {
                openWindow(id: AppModel.debugNavigationWindowId)
                appModel.isDebugWindowOpen = true
            }
        case .playing:
            // Explicitly dismiss debug window first
            if appModel.isDebugWindowOpen {
                dismissWindow(id: AppModel.debugNavigationWindowId)
                appModel.isDebugWindowOpen = false
            }
            // No need for default case handling
            return  // Add explicit return to prevent falling through to default
            
        case .completed:
            if !appModel.isDebugWindowOpen {
                openWindow(id: AppModel.debugNavigationWindowId)
                appModel.isDebugWindowOpen = true
            }
            dismissWindow(id: AppModel.hopeMeterUtilityWindowId)
            openWindow(id: AppModel.mainWindowId)
            
        case .lab:

            if !appModel.isDebugWindowOpen {
                openWindow(id: AppModel.debugNavigationWindowId)
                appModel.isDebugWindowOpen = true
            }
        case .building:
            if appModel.isDebugWindowOpen {
                print("closing debug window")
                dismissWindow(id: AppModel.debugNavigationWindowId)
                appModel.isDebugWindowOpen = false
            }
        default:
            if !appModel.isMainWindowOpen {
                openWindow(id: AppModel.mainWindowId)
                appModel.isMainWindowOpen = true
            }
            if appModel.isDebugWindowOpen {
                dismissWindow(id: AppModel.debugNavigationWindowId)
                appModel.isDebugWindowOpen = false
            }
        }
        
        // Show/hide hope meter utility window based on phase
        if phase == .playing {
            openWindow(id: AppModel.hopeMeterUtilityWindowId)
        } else {
            dismissWindow(id: AppModel.hopeMeterUtilityWindowId)
        }

        
        // Always dismiss the completed window if not in completed phase
//        if phase != .completed {
//            dismissWindow(id: AppModel.gameCompletedWindowId)
//        }
        
        print("📊 Window states after update:")
        print("  Main: \(appModel.isMainWindowOpen)")
        print("  Debug: \(appModel.isDebugWindowOpen)")
        print("  Library: \(appModel.isLibraryWindowOpen)")
        print("  Builder: \(appModel.isBuilderWindowOpen)")
        print("  Phases:")
        print("    AppPhase: \(appModel.currentPhase)")
        print("    ScenePhase: \(scenePhase)")
        print("    LoadingPhase: \(appModel.loadingState)")
    }
    
    // MARK: - App State Management
    private func cleanupAppState() async {
        print("🧹 Cleaning up app state")
        
        // 1. Close immersive space if open
        if appModel.immersiveSpaceState == .open {
            await dismissImmersiveSpace()
            appModel.immersiveSpaceState = .closed
        }
        
        // 2. Stop tracking
        appModel.trackingManager.stopTracking()
        
        // 3. Reset phase to ready
        await appModel.transitionToPhase(.ready)
        
        print("✅ App state cleanup completed")
    }
}
