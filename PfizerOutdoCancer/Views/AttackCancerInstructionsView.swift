//
//  AttackCancerInstructionsView.swift
//  ViewBuilder
//
//  Created by Dale Carman on 1/4/25.
//


import SwiftUI
import RealityKit
import OSLog

struct AttackCancerInstructionsView: View {
    @Environment(AppModel.self) private var appModel
    @Environment(ADCDataModel.self) var dataModel

    @Environment(\.dismiss) private var dismiss
    @Environment(\.openWindow) private var openWindow
    
    var body: some View {
        var adcEntity = Entity()
        
        NavigationStack {
            VStack {
//                Spacer()
                VStack {
                    RealityView { content in
                        print("\n=== AttackCancerInstructionsView Setup ===")
                        print("📱 Instructions View: Setting up root entity")
                        let root = appModel.gameState.setupRoot()
                        content.add(root)
                        
                        // Setup IBL
                        await appModel.gameState.setupIBL(in: root)
                        print("✅ Instructions View: IBL setup complete")
                        
                        // Use the template from gameState (already has colors applied)
                        if let template = appModel.gameState.adcTemplate {
                            print("✅ Instructions View: Found ADC template")
                            adcEntity = template.clone(recursive: true)
                            adcEntity.components.set(RotationComponent())
                            root.addChild(adcEntity)
                            print("✅ Instructions View: Added ADC to display")
                        } else {
                            print("❌ Instructions View: No ADC template available")
                        }
                        print("=== Instructions View Setup Complete ===\n")
                    }
                }
                VStack(spacing: 0) {
                    // Title
                    Text("Attack Cancer Instructions")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                        .padding(.bottom, 30)
                    
                    // Instructions sections
                    VStack(alignment: .leading, spacing: 20) {
                        instructionSection(
                            title: "Target Cancer Cells",
                            description: "Look at a floating cancer cell in your environment and use a spatial tap gesture to launch an ADC to attack it.",
                            systemImage: "target"
                        )
                        
                        instructionSection(
                            title: "Track Progress",
                            description: "Watch the hit counter above each cell. Some cells require multiple hits.",
                            systemImage: "chart.bar.fill"
                        )
                        
                        instructionSection(
                            title: "Hope Meter",
                            description: "Keep an eye on your Hope Meter on your left hand. You have a limited amount of time!",
                            systemImage: "gauge.medium"
                        )
                        
                        instructionSection(
                            title: "Victory",
                            description: "Destroy as many cancer cells as possible before the Hope Meter depletes to win.",
                            systemImage: "trophy.fill"
                        )
                    }
                    .padding(.bottom, 60)
                    .padding(.horizontal, 120)
                    // Start button
                    NavigationButton(
                        title: appModel.isTutorialStarted ? "Attack Cancer!" : "Start Tutorial",
                        action: {
                            if !appModel.isTutorialStarted {
                                print("🎓 Starting tutorial sequence...")
                                appModel.isTutorialStarted = true
                                appModel.isInstructionsWindowOpen = false
                            } else {
                                print("🎮 Tutorial complete - Starting game...")
                                appModel.startAttackCancerGame()
                                appModel.isInstructionsWindowOpen = false
                                if !appModel.isHopeMeterUtilityWindowOpen {
                                    openWindow(id: AppModel.hopeMeterUtilityWindowId)
                                }
                            }
                        },
                        font: .title,
                        scaleEffect: 1.2,
                        width: 200
                    )
                    .fontWeight(.bold)
                    .glassBackgroundEffect()
                    .hoverEffect { effect, isActive, proxy in
                        effect
                            .animation(.easeInOut(duration: 0.2)) {
                                $0.scaleEffect(isActive ? 1.1 : 1.0)
                            }
                    }
                    .padding(30)
                    .padding(.bottom, 30)
                }
                .padding(.bottom, 100)
                .transition(Appear())
            }
        }
        .frame(minWidth: 800)
        .frame(minHeight: 900)
        

    }
    
    private func instructionSection(title: String, description: String, systemImage: String) -> some View {
        HStack(alignment: .top, spacing: 15) {
            Image(systemName: systemImage)
                .font(.title)
                .foregroundColor(.blue)
                .frame(width: 30)
            
            VStack(alignment: .leading, spacing: 5) {
                Text(title)
                    .font(.title3)
                    .fontWeight(.semibold)
                    .fixedSize(horizontal: false, vertical: true)
                
                Text(description)
                    .font(.body)
                    .foregroundColor(.secondary)
                    .opacity(0.7)
                    .fixedSize(horizontal: false, vertical: true)
                    .lineLimit(nil)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }
}

//#Preview("Instruction View") {
//    @Previewable @State var isVisible: Bool = true
//    
//    VStack {
//        GroupBox {
//            Toggle("Visible", isOn: $isVisible.animation())
//        }
//        Spacer()
//        
//        if isVisible {
//            AttackCancerInstructionsView()
//                .environment(AppModel())
//                .environment(ADCDataModel())
//                .transition(Appear())
//        }
//        Spacer()
//    }
//    .padding()
//    
//}
