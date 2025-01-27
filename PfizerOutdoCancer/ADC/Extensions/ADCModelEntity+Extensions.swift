import UIKit
import RealityKit
import os

extension ModelEntity {
    func updatePBRDiffuseColor(_ color: UIColor) {
        if var pbrMaterials = self.model?.materials as? [PhysicallyBasedMaterial],
           !pbrMaterials.isEmpty {
            var pbr = pbrMaterials[0]
            if let existingTexture = pbr.baseColor.texture {
                pbr.baseColor = .init(tint: color, texture: existingTexture)
            } else {
                pbr.baseColor.tint = color
            }
            pbrMaterials[0] = pbr
            self.model?.materials = pbrMaterials
            os_log(.debug, "ITR..updatePBRDiffuseColor(): ✅ Updated baseColor.tint to: \(String(describing: pbr.baseColor.tint))")
        } else {
            os_log(.error, "ITR..updatePBRDiffuseColor(): ❌ materials array is empty")
        }
    }
    
    func updatePBREmissiveColor(_ color: UIColor) {
        if var pbrMaterials = self.model?.materials as? [PhysicallyBasedMaterial],
           !pbrMaterials.isEmpty {
            var pbr = pbrMaterials[0]
            pbr.emissiveColor.color = color
            pbrMaterials[0] = pbr
            self.model?.materials = pbrMaterials
            os_log(.debug, "ITR..updatePBREmissiveColor(): ✅ Updated emissiveColor to: \(String(describing: pbr.emissiveColor.color))")
        } else {
            // For unplaced payloads with outline material, this is expected behavior
            os_log(.debug, "ITR..updatePBREmissiveColor(): ℹ️ Skipping color update - entity has outline material (normal for unplaced payload)")
        }
    }
    
    func updateShaderGraphColor(parameterName: String, color: UIColor) {
        if var materials = self.model?.materials {
            guard var shaderMaterial = materials[0] as? ShaderGraphMaterial else {
                os_log(.error, "ITR..updateShaderGraphColor(): ❌ Material is not ShaderGraphMaterial")
                return
            }
            
            do {
                try shaderMaterial.setParameter(name: parameterName, value: .color(color))
                materials[0] = shaderMaterial
                self.model?.materials = materials
                os_log(.debug, "ITR..updateShaderGraphColor(): ✅ Successfully updated \(parameterName) with color: \(String(describing: color))")
            } catch {
                // For unplaced payloads with outline material, this is expected behavior
                if error is ShaderGraphMaterial.Error {
                    os_log(.debug, "ITR..updateShaderGraphColor(): ℹ️ Parameter not found - entity has outline material (normal for unplaced payload)")
                } else {
                    os_log(.error, "ITR..updateShaderGraphColor(): ❌ Error setting parameter: \(error)")
                }
            }
        } else {
            // For unplaced payloads with outline material, this is expected behavior
            os_log(.debug, "ITR..updateShaderGraphColor(): ℹ️ Skipping color update - entity has outline material (normal for unplaced payload)")
        }
    }
    
    func updateShaderGraphValue(parameterName: String, value: Float) {
        if var materials = self.model?.materials {
            guard var shaderMaterial = materials[0] as? ShaderGraphMaterial else {
                os_log(.error, "ITR..updateShaderGraphColor(): ❌ Material is not ShaderGraphMaterial")
                return
            }
            
            do {
                try shaderMaterial.setParameter(name: parameterName, value: .float(value))
                materials[0] = shaderMaterial
                self.model?.materials = materials
                os_log(.debug, "ITR..updateShaderGraphColor(): ✅ Successfully updated \(parameterName) with color: \(String(describing: value))")
            } catch {
                os_log(.error, "ITR..updateShaderGraphColor(): ❌ Error setting parameter: \(error)")
            }
        } else {
            os_log(.error, "ITR..updateShaderGraphColor(): ❌ No materials found")
        }
    }
    
}
