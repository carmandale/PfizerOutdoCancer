import SwiftUI
import RealityKit

extension ModelEntity {
    /// Apply ADC color to entities using PBR material (antibody and linker)
    func applyADCColor(_ colorIndex: Int) {
//        updatePBRDiffuseColor(.adc[colorIndex])
        updateShaderGraphColor(parameterName: "Basecolor_Tint", color: .adc[colorIndex])
    }
    
    /// Apply ADC color to payload entities, handling both inner (PBR) and outer (ShaderGraph) spheres
    func applyPayloadColor(_ colorIndex: Int, isInner: Bool) {
        if isInner {
            updatePBREmissiveColor(.adcEmissive[colorIndex])
        } else {
            updateShaderGraphColor(parameterName: "glowColor", color: .adc[colorIndex])
        }
    }
}
