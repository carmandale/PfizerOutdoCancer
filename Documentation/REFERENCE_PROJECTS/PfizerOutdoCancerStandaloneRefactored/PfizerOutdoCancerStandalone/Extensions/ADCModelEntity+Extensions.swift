import UIKit
import RealityKit

extension ModelEntity {
    func updatePBRDiffuseColor(_ color: UIColor) {
        if var pbrMaterials = self.model?.materials as? [PhysicallyBasedMaterial],
           !pbrMaterials.isEmpty {
//            print("ITR..ModelEntity.updatePBRDiffuseColor(color: \(color))")
            var pbr = pbrMaterials[0]
            if let existingTexture = pbr.baseColor.texture {
                pbr.baseColor = .init(tint: color, texture: existingTexture)
            } else {
                pbr.baseColor.tint = color
            }
            pbrMaterials[0] = pbr
            self.model?.materials = pbrMaterials
        } else {
            print("ITR..❌ Error: ModelEntity.updatePBRDiffuseColor():  materials array is empty")
        }
    }
    
    func updatePBREmissiveColor(_ color: UIColor) {
//        print("ITR..ModelEntity.updatePBREmissiveColor(color: \(color))")
        if var pbrMaterials = self.model?.materials as? [PhysicallyBasedMaterial],
           !pbrMaterials.isEmpty {
            var pbr = pbrMaterials[0]
            pbr.emissiveColor.color = color
            pbrMaterials[0] = pbr
            self.model?.materials = pbrMaterials
        } else {
            print("ITR..❌ Error: ModelEntity.updatePBREmissiveColor(color: \(color)):  materials array is empty")
        }
    }
    
    func updateShaderGraphColor(parameterName: String, color: UIColor) {
//        print("ITR..ModelEntity.updateShaderGraphColor(color: \(color))")
        if let materials = self.model?.materials as? [ShaderGraphMaterial],
           !materials.isEmpty,
            var material = materials.first{
            try? material.setParameter(name: parameterName, value: .color(color))
            self.model?.materials = [material]
        } else {
            print("ITR..❌ Error: ModelEntity.updateShaderGraphColor(color: \(color)):  materials array is empty")
        }
    }
    
}
