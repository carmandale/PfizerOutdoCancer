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
                    Task {
                        switch newPhase {
                        case .background:
                            // Save state if needed
                            if appModel.immersiveSpaceState == .open {
                                await dismissImmersiveSpace()
                            }
                            appModel.immersiveSpaceState = .closed
                            
                        case .active:
                            // If we're coming back from background, show debug navigation
//                            openWindow(id: AppModel.debugNavigationWindowId)
//                            appModel.isDebugWindowOpen = true
                            // Reset to a known good state
                            await appModel.transitionToPhase(.ready)
                            
                        default:
                            break
                        }
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
        .defaultWindowPlacement { _, context in
            if let mainWindow = context.windows.first {
                return WindowPlacement(.leading(mainWindow))
            }
            return WindowPlacement(.none)
        }

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
//        .onChange(of: appModel.isDebugWindowOpen) { wasOpen, isDebugWindowOpen in
//            print("🪟 Debug window state changed: \(wasOpen) -> \(isDebugWindowOpen)")
//            if isDebugWindowOpen {
//                openWindow(id: AppModel.debugNavigationWindowId)
//            } else {
//                dismissWindow(id: AppModel.debugNavigationWindowId)
//            }
//        }

//        WindowGroup(id: AppModel.gameCompletedWindowId) {
//            CompletedView()
//                .environment(appModel)
//                .environment(adcDataModel)
//        }
//        .windowStyle(.plain)
//        .windowResizability(.contentSize)


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
            if !appModel.isLoadingWindowOpen {
            appModel.isLoadingWindowOpen = true
            }
            
        case .intro:
            // Handle other windows
            if appModel.isLibraryWindowOpen {
                dismissWindow(id: AppModel.libraryWindowId)
                appModel.isLibraryWindowOpen = false
            }
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
            // Then handle other windows
            if appModel.isLibraryWindowOpen {
                dismissWindow(id: AppModel.libraryWindowId)
            appModel.isLibraryWindowOpen = false
            }
            // No need for default case handling
            return  // Add explicit return to prevent falling through to default
            
        case .completed:
            if appModel.isLibraryWindowOpen {
                dismissWindow(id: AppModel.libraryWindowId)
            appModel.isLibraryWindowOpen = false
            }
            if !appModel.isDebugWindowOpen {
                openWindow(id: AppModel.debugNavigationWindowId)
                appModel.isDebugWindowOpen = true
            }
            openWindow(id: AppModel.mainWindowId)
            
        case .lab:
            if !appModel.isLibraryWindowOpen {
                openWindow(id: AppModel.libraryWindowId)
            appModel.isLibraryWindowOpen = true
            }
            if !appModel.isDebugWindowOpen {
                openWindow(id: AppModel.debugNavigationWindowId)
                appModel.isDebugWindowOpen = true
            }
        case .building:
            // Close library and debug windows if open
            if appModel.isLibraryWindowOpen {
                print("closing library window")
                dismissWindow(id: AppModel.libraryWindowId)
                appModel.isLibraryWindowOpen = false
            }
            if appModel.isDebugWindowOpen {
                print("closing debug window")
                dismissWindow(id: AppModel.debugNavigationWindowId)
                appModel.isDebugWindowOpen = false
            }
            // Don't open main window here - it's handled by ADCBuilderViewerButton
        default:
        if appModel.isLibraryWindowOpen {
            dismissWindow(id: AppModel.libraryWindowId)
                appModel.isLibraryWindowOpen = false
            }
        }
        
        // Always dismiss the completed window if not in completed phase
//        if phase != .completed {
//            dismissWindow(id: AppModel.gameCompletedWindowId)
//        }
    }

}
