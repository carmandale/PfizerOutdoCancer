import Foundation
import RealityKit
import SwiftUI

@Observable
class ADCDataModel {
    // Color selections for ADC components
    var selectedADCAntibody: Int? = nil
    public var selectedADCLinker: Int? = nil
    public var selectedADCPayload: Int? = nil
    
    var selectedLinkerType: Int? = nil
    var selectedPayloadType: Int? = nil
    
    public var linkersWorkingIndex: Int = 0
    public var payloadsWorkingIndex: Int = 0
    
    public var adcBuildStep = 0
    
    var placedLinkerCount: Int = 0
    var placedPayloadCount: Int = 0
    
    public var isVOPlaying = false
    public var hasInitialVOCompleted = false
    public var antibodyVOCompleted = false
    public var antibodyStepCompleted = false
    public var showSelector = false
    
    public var manualStepTransition: Bool = false
    
    var isCurrentStepComplete: Bool {
        switch adcBuildStep {
        case 0:
            return selectedADCAntibody != nil
        case 1:
            return selectedLinkerType != nil && linkersWorkingIndex == 3
        case 2:
            return selectedPayloadType != nil && payloadsWorkingIndex == 3
        default:
            return true
        }
    }
    
    // Fill all linker positions with currently selected linker type
    func fillAllLinkers() {
        // set condition if VO is finished  
        guard let selectedType = selectedLinkerType else { return }
        selectedADCLinker = selectedType
        placedLinkerCount = 4
        linkersWorkingIndex = 4
        
        // Move to next step
        adcBuildStep = 2
        // selectedPayloadType = nil
    }
    
    // Fill all payload positions with currently selected payload type
    func fillAllPayloads() {
        guard let selectedType = selectedPayloadType else { return }
        selectedADCPayload = selectedType
        placedPayloadCount = 4
        payloadsWorkingIndex = 4
        
        // Move to next step
        adcBuildStep = 3
    }
    
    func getADCImageName() -> String {
        if let index = selectedADCAntibody {
            return "antibody\(index)"
        } else {
            return "antibody3"
        }
    }
    func getLinkerImageName() -> String {
        if let index = selectedLinkerType {
            return "linkers\(index)"
        } else {
            return "linkers3"
        }
    }
    func getPayloadImageName() -> String {
        if let index = selectedPayloadType {
            return "payload\(index)"
        } else {
            return "payload3"
        }
    }
    
    // MARK: - Cleanup
    func cleanup() {
        // Reset selections
        selectedADCAntibody = nil
        selectedADCLinker = nil
        selectedADCPayload = nil
        selectedLinkerType = nil
        selectedPayloadType = nil
        
        // Reset indices
        linkersWorkingIndex = 0
        payloadsWorkingIndex = 0
        
        // Reset build step
        adcBuildStep = 0
        
        // Reset counters
        placedLinkerCount = 0
        placedPayloadCount = 0
        
        // Reset flags
        isVOPlaying = false
        hasInitialVOCompleted = false
        showSelector = false
    }
}

public enum ADCUIAttachments {
    static let adcSelectorView = "adcSelectorAttachment"
    static let linkerSelectorView = "linkerSelectorAttachment"
    static let payloadSelectorView = "payloadSelectorAttachment"
    static let mainADCView = "mainADCView"
}
