import SwiftUI
import RealityKit
import RealityKitContent

extension AttackCancerViewModel {
    // MARK: - ADC Setup
    func setADCTemplate(_ template: Entity, dataModel: ADCDataModel) {
        print("\n=== Setting ADC Template ===")
        print("Current ADC Recipe:")
        print("- Antibody Color: \(String(describing: dataModel.selectedADCAntibody ?? -1))")
        print("- Linker Color: \(String(describing: dataModel.selectedLinkerType ?? -1))")
        print("- Payload Color: \(String(describing: dataModel.selectedPayloadType ?? -1))")
        
        // Find and apply antibody color
        if let antibody = template.findModelEntity(named: "ADC_complex") {
            if let antibodyColor = dataModel.selectedADCAntibody,
               let modelComponent = antibody.components[ModelComponent.self] {
                if modelComponent.materials.first is ShaderGraphMaterial {
                    antibody.updateShaderGraphColor(parameterName: "Basecolor_Tint", color: .adc[antibodyColor])
                    print("✅ Applied antibody color: \(antibodyColor)")
                }
            }
        }
        
        // Find and apply linker colors (all 4)
        for i in 1...4 {
            let offsetName = "linker0\(i)_offset"
            if let linker = template.findModelEntity(named: "linker", from: offsetName) {
                if let linkerColor = dataModel.selectedLinkerType {
                    // old PBR shader
                    linker.updatePBRDiffuseColor(.adc[linkerColor])
                    // new shaderGraph material
                    linker.updateShaderGraphColor(parameterName: "Basecolor_Tint", color: .adc[linkerColor])
                    print("✅ Applied linker color \(linkerColor) to \(offsetName)")
                }
            }
        }
        
        // Find and apply payload colors (all 4 sets of inner/outer)
        for i in 1...4 {
            let offsetName = "linker0\(i)_offset"
            if let inner = template.findModelEntity(named: "InnerSphere", from: offsetName),
               let outer = template.findModelEntity(named: "OuterSphere", from: offsetName) {
                if let payloadColor = dataModel.selectedPayloadType {
                    inner.updatePBREmissiveColor(.adcEmissive[payloadColor])
                    outer.updateShaderGraphColor(parameterName: "glowColor", color: .adc[payloadColor])
                    print("✅ Applied payload color \(payloadColor) to \(offsetName)")
                }
            }
        }
        
        adcTemplate = template
        print("✅ ADC template set successfully with color recipe applied")
    }
    
    // MARK: - ADC Spawning
    func spawnADC(from position: SIMD3<Float>, targetPoint: Entity, forCellID cellID: Int) async {
        guard let template = adcTemplate,
              let root = rootEntity else {
            return
        }
        
        totalADCsDeployed += 1
        print("✅ ADC #\(totalADCsDeployed) Launched (Total Taps: \(totalTaps))")
        
        // Set the flag for first ADC fired
        if !hasFirstADCBeenFired {
            hasFirstADCBeenFired = true
        }
        
        // Clone the template (colors will be cloned with it)
        let adc = template.clone(recursive: true)
        
        // Update ADCComponent properties
        guard var adcComponent = adc.components[ADCComponent.self] else { return }
        adcComponent.targetCellID = cellID
        adcComponent.startWorldPosition = position  // Use the hand position
        adc.components[ADCComponent.self] = adcComponent
        
        // Set initial position
        adc.position = position
        
        // Add to scene
        root.addChild(adc)
        
        // Start movement
        ADCMovementSystem.startMovement(entity: adc, from: position, to: targetPoint)
    }
}
