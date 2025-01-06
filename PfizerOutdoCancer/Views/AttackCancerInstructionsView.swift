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
    
    var body: some View {
        var adcEntity = Entity()
        
        NavigationStack {
            VStack {
//                Spacer()
                VStack {
                    RealityView { content in
                        let root = appModel.gameState.setupRoot()
                        content.add(root)

                        await appModel.gameState.setupIBL(in: root)

                        // Use the template from gameState (already has colors applied)
                        if let template = appModel.gameState.adcTemplate {
                            // Debug summary of selected colors
                            os_log(.debug, "ADC Color Summary:")
                            os_log(.debug, "- Antibody Color: \(dataModel.selectedADCAntibody ?? -1)")
                            os_log(.debug, "- Linker Color: \(dataModel.selectedLinkerType ?? -1)")
                            os_log(.debug, "- Payload Color: \(dataModel.selectedPayloadType ?? -1)")
                            
                            adcEntity = template.clone(recursive: true)
                            adcEntity.components.set(RotationComponent())
                            root.addChild(adcEntity)
                        }
                    }
                }
//                Spacer()
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
                    .padding(.horizontal, 120)
//                    .frame(maxWidth: 800)
                    
                    // Start button
                    Button(action: {
                        // Navigate to the game
                        dismiss()
                        print("🎮 Game Content Setup Complete - Starting Hope Meter")
                        appModel.startHopeMeter()
                    }) {
                        Text("Attack Cancer!")
                            .font(.title2)
                            .fontWeight(.bold)
                            .padding()
                            .frame(width: 200)
    //                        .background(.blue)
                            .foregroundColor(.white)
                            // .clipShape(RoundedRectangle(cornerRadius: 15))
                    }
                    .padding(60)
                    
                }
//                .padding(120)
//                .frame(maxWidth: 800)
            }
//            .frame(maxWidth: 800)
            
            
        }
        .frame(minWidth: 800)
        .frame(minHeight: 800)

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
                    .fixedSize(horizontal: false, vertical: true)
                    .lineLimit(nil)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }
}

//#Preview {
//    AttackCancerInstructionsView()
//        .environment(AppModel())
//}
