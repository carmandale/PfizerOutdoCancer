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
        @State private var handTracking = HandTrackingViewModel()
        
        // for ADC view
        @State private var adcAppModel = ADCAppModel()
        @State private var adcDataModel = ADCDataModel()
        
        @Environment(\.openImmersiveSpace) private var openImmersiveSpace
        @Environment(\.dismissImmersiveSpace) private var dismissImmersiveSpace
        @Environment(\.dismissWindow) private var dismissWindow
        @Environment(\.openWindow) private var openWindow
        @Environment(\.scenePhase) private var scenePhase
        
        
        var body: some Scene {
            // MARK: - 2D LOADING WINDOW
                    WindowGroup(id: AppModel.mainWindowId) {
                        LoadingView()
                            .environment(appModel)
                            .task {
                                await appModel.startLoading()
                            }
                    }
                    .defaultSize(CGSize(width: 800, height: 600))
                    .windowStyle(.plain)
                    .windowResizability(.contentSize)

            WindowGroup(id: AppModel.debugNavigationWindowId) {
                DebugNavigationWindow()
                    .environment(appModel)
                    .frame(minWidth: 500, maxWidth: 1000, minHeight: 50, maxHeight: 100)
            }
            .windowResizability(.contentSize)
            .defaultWindowPlacement { _, context in
                return WindowPlacement(.utilityPanel)
            }

            WindowGroup(id: AppModel.gameCompletedWindowId) {
                CompletedView()
                    .environment(appModel)
            }
            .windowStyle(.plain)
            .windowResizability(.contentSize)

            WindowGroup(id: AppModel.libraryWindowId) {
                LibraryView()
                    .environment(appModel)
            }
            .defaultSize(CGSize(width: 800, height: 600))
            
            
            // MARK: Immersive Views
            Group {

                ImmersiveSpace(id: "IntroSpace") {
                    IntroView()
                        .environment(appModel)
                }
                .immersionStyle(selection: $appModel.introStyle, in: .mixed)

                ImmersiveSpace(id: "LabSpace") {
                    LabView()
                        .environment(appModel)
                }
                .immersionStyle(selection: $appModel.labStyle, in: .full)
                .upperLimbVisibility(.visible)
                
                ImmersiveSpace(id: "BuildingSpace") {
                    ADCOptimizedImmersive()
                        .environment(adcAppModel)
                        .environment(adcDataModel)
                        .environment(appModel)
                        .onAppear {
                            adcAppModel.immersiveSpaceState = .open
                        }
                        .onDisappear {
                            adcAppModel.immersiveSpaceState = .closed
                        }
                }
                .immersionStyle(selection: $appModel.buildingStyle, in: .mixed)

                ImmersiveSpace(id: "AttackSpace") {
                    AttackCancerView()
                        .environment(appModel)
                        .environment(handTracking)
                }
                .immersionStyle(selection: $appModel.attackStyle, in: .progressive)
                .upperLimbVisibility(.automatic)
                
                // MARK: PHASE CHANGE
                // Single onChange handler for phase transitions
                .onChange(of: appModel.currentPhase) { oldPhase, newPhase in
                    if oldPhase == newPhase { return }
                    print("SpawnAndAttrackApp: Phase change from \(oldPhase) to \(newPhase)")
                    
                    Task {
                        // Only dismiss existing space if the new phase doesn't need to keep it
                        if oldPhase.needsImmersiveSpace && !newPhase.shouldKeepPreviousSpace {
                            await dismissImmersiveSpace()
                            try? await Task.sleep(for: .seconds(0.5))
                        }
                        
                        // Handle window management
                        await handleWindowsForPhase(newPhase)
                        
                        // Then open new immersive space if needed
                        if newPhase.needsImmersiveSpace && !newPhase.shouldKeepPreviousSpace {
                            let spaceId = newPhase.spaceId
                            try? await Task.sleep(for: .seconds(0.3))
                            
                            switch await openImmersiveSpace(id: spaceId) {
                            case .opened:
                                print("Successfully opened space: \(spaceId)")
                            case .error:
                                print("Error opening space: \(spaceId)")
                                appModel.currentPhase = .error
                            case .userCancelled:
                                print("User cancelled opening space: \(spaceId)")
                                appModel.currentPhase = .error
                            @unknown default:
                                print("Unknown result opening space: \(spaceId)")
                                appModel.currentPhase = .error
                            }
                        }
                    }
                }
            }

            // Add ADC's main window
            WindowGroup(id: ADCUIViews.mainViewID) {
                ADCView()
                    .environment(adcAppModel)
                    .environment(adcDataModel)
            }
            // .defaultSize(CGSize(width: 800, height: 600))
            .windowStyle(.plain)
        }

        init() {
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
        }
        
        // Helper function to handle window management
        @MainActor
        private func handleWindowsForPhase(_ phase: AppPhase) async {
            print("🎯 Managing windows for phase: \(phase)")
            
            // Always handle loading window first if it's open
            if appModel.isLoadingWindowOpen && phase != .loading {
                print("📱 Dismissing loading window")
                dismissWindow(id: AppModel.mainWindowId)
                appModel.isLoadingWindowOpen = false
                try? await Task.sleep(for: .seconds(0.3))
            }
            
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
                if appModel.isDebugWindowOpen {
                    dismissWindow(id: AppModel.debugNavigationWindowId)
                    appModel.isDebugWindowOpen = false
                }
                if appModel.isLibraryWindowOpen {
                    dismissWindow(id: AppModel.libraryWindowId)
                    appModel.isLibraryWindowOpen = false
                }
                if appModel.isMainWindowOpen {
                    dismissWindow(id: AppModel.mainWindowId)
                    appModel.isMainWindowOpen = false
                }
                
            case .completed:
                if appModel.isLibraryWindowOpen {
                    dismissWindow(id: AppModel.libraryWindowId)
                    appModel.isLibraryWindowOpen = false
                }
                if !appModel.isDebugWindowOpen {
                    openWindow(id: AppModel.debugNavigationWindowId)
                    appModel.isDebugWindowOpen = true
                }
                openWindow(id: AppModel.gameCompletedWindowId)
                
            case .lab:
                if !appModel.isLibraryWindowOpen {
                    openWindow(id: AppModel.libraryWindowId)
                    appModel.isLibraryWindowOpen = true
                }
                if !appModel.isDebugWindowOpen {
                    openWindow(id: AppModel.debugNavigationWindowId)
                    appModel.isDebugWindowOpen = true
                }
                if appModel.isMainWindowOpen {
                    dismissWindow(id: AppModel.mainWindowId)
                    appModel.isMainWindowOpen = false
                }
                
            case .building:
                // Open ADC window
                openWindow(id: ADCUIViews.mainViewID)
                if appModel.isLibraryWindowOpen {
                    dismissWindow(id: AppModel.libraryWindowId)
                    appModel.isLibraryWindowOpen = false
                }
                if !appModel.isDebugWindowOpen {
                    openWindow(id: AppModel.debugNavigationWindowId)
                    appModel.isDebugWindowOpen = true
                }
                
            default:
                if appModel.isLibraryWindowOpen {
                    dismissWindow(id: AppModel.libraryWindowId)
                    appModel.isLibraryWindowOpen = false
                }
                if !appModel.isDebugWindowOpen {
                    openWindow(id: AppModel.debugNavigationWindowId)
                    appModel.isDebugWindowOpen = true
                }
                if appModel.isMainWindowOpen {
                    dismissWindow(id: AppModel.mainWindowId)
                    appModel.isMainWindowOpen = false
                }
            }
            
            // Always dismiss the completed window if not in completed phase
            if phase != .completed {
                dismissWindow(id: AppModel.gameCompletedWindowId)
            }
        }

    }
