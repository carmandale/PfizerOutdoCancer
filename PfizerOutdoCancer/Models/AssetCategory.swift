// AssetCategory.swift
public enum AssetCategory: String {
    // MARK: - Environment Cases
    case introEnvironment = "intro_environment"
    case attackCancerEnvironment = "attack_environment"
    case labEnvironment = "lab_environment"
    case outroEnvironment = "outro_environment"
    case buildADCEnvironment = "antibody_scene"
    
    // MARK: - Entity Cases
    case cancerCell = "cancer_cell"
    case adc = "adc"
    case labEquipment = "lab_equipment"
}

// MARK: - Asset Name Handling
extension AssetCategory {
    /// Creates an AssetCategory from an asset name
    /// - Parameter assetName: The name of the asset to categorize
    public init?(assetName: String) {
        // First try exact match with raw value
        if let category = AssetCategory(rawValue: assetName) {
            self = category
            return
        }
        
        // Then try prefix matching for environments
        if assetName.hasPrefix("intro_") {
            self = .introEnvironment
        } else if assetName.hasPrefix("attack_") {
            self = .attackCancerEnvironment
        } else if assetName.hasPrefix("lab_") || assetName == "assembled_lab" {
            self = .labEnvironment
        } else {
            // For specific entities
            switch assetName {
            case "cancer_cell": self = .cancerCell
            case "adc": self = .adc
            default: self = .labEquipment
            }
        }
    }
}
