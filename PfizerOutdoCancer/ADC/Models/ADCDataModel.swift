import Foundation
import RealityKit
import SwiftUI

@Observable
class ADCDataModel {
    // Positioning state
    var isRootSetupComplete = false
    var isEnvironmentSetupComplete = false
    var isHeadTrackingRootReady = false
    var shouldUpdateHeadPosition = false
    var isPositioningComplete = false

    var showMainView = false
    
    var isReadyForInteraction: Bool {
        isRootSetupComplete && 
        isEnvironmentSetupComplete && 
        isHeadTrackingRootReady
    }
    
    // coaching overlay
    var isCoachingOverlayPresent: Bool = false
    
    // New Step State Management
    struct StepState {
        var colorSelected: Bool = false
        var checkmarkClicked: Bool = false
        var voPlayed: Bool = false
    }
    
    var stepStates: [StepState] = [
        StepState(), // Antibody
        StepState(), // Linker
        StepState(), // Payload
    ]
    
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
    
    // Voice-over progress tracking
    public var voiceOverProgress: Double = 0.0
    let voiceOverDurations: [Int: TimeInterval] = [
        0: 21.0,  // VO1
        1: 22.0,  // VO2
        2: 30.0,  // VO3
        3: 16.0   // VO4
    ]
    
    // Updated Navigation Control
    var canMoveForward: Bool {
        if isVOPlaying { return false }
        
        let nextStep = adcBuildStep + 1
        if nextStep >= stepStates.count { return true }
        
        // If VO hasn't played for next step, require current step completion
        if !stepStates[nextStep].voPlayed {
            return stepStates[adcBuildStep].checkmarkClicked
        }
        
        // If VO has played for next step, allow navigation
        return true
    }
    
    var canMoveBack: Bool {
        return adcBuildStep > 0 && !isVOPlaying
    }
    
    var isCurrentStepComplete: Bool {
        guard adcBuildStep < stepStates.count else { return true }
        
        switch adcBuildStep {
        case 0:  // Antibody
            return selectedADCAntibody != nil && stepStates[0].checkmarkClicked
        case 1:  // Linker
            return selectedLinkerType != nil && 
                   linkersWorkingIndex == 3 && 
                   stepStates[1].checkmarkClicked
        case 2:  // Payload
            return selectedPayloadType != nil && 
                   payloadsWorkingIndex == 3 && 
                   stepStates[2].checkmarkClicked
        default:
            return true
        }
    }
    
    // VO Management
    func markVOCompleted(for step: Int) {
        // Only mark steps 0-2 in stepStates
        guard step < stepStates.count else { return }
        stepStates[step].voPlayed = true
        
        // Maintain compatibility with existing antibody flags
        if step == 0 {
            antibodyVOCompleted = true
        }
    }
    
    func shouldPlayVO(for step: Int) -> Bool {
        guard step < stepStates.count else { return false }
        return !stepStates[step].voPlayed
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
        Logger.info("\n=== Starting ADCDataModel Cleanup ===")
        
        // 1. Stop any active systems/audio first
        isVOPlaying = false
        voiceOverProgress = 0.0
        
        // 2. Reset all selections (user choices)
        selectedADCAntibody = nil
        selectedADCLinker = nil
        selectedADCPayload = nil
        selectedLinkerType = nil
        selectedPayloadType = nil
        
        // 3. Reset working indices and counters
        linkersWorkingIndex = 0
        payloadsWorkingIndex = 0
        placedLinkerCount = 0
        placedPayloadCount = 0
        
        // 4. Reset build step and state flags
        adcBuildStep = 0
        hasInitialVOCompleted = false
        antibodyVOCompleted = false
        antibodyStepCompleted = false
        showSelector = false
        manualStepTransition = false
        
        // 5. Reset step states array
        stepStates = [StepState(), StepState(), StepState()]
        
        // 6. Reset positioning and environment state
        isRootSetupComplete = false
        isEnvironmentSetupComplete = false
        isHeadTrackingRootReady = false
        shouldUpdateHeadPosition = false
        isPositioningComplete = false

        showMainView = false
        
        Logger.info("""
        🧹 ADCDataModel Cleanup Complete:
        ├─ Stopped active systems
        ├─ Reset all selections and counters
        ├─ Reset build step and flags
        ├─ Reset step states
        ├─ Reset positioning state
        └─ Ready for new session
        """)
    }
    
    // MARK: - Setup Methods
    func setupRoot() -> Entity {
        // Reset state tracking first
        isRootSetupComplete = false
        isEnvironmentSetupComplete = false
        isHeadTrackingRootReady = false
        isPositioningComplete = false
        
        Logger.info("🔄 Starting new ADC session: tracking states reset")
        Logger.info("📱 ADCDataModel: Setting up root")
        
        let root = Entity()
        root.name = "MainEntity"
        root.position = AppModel.PositioningDefaults.building.position
        
        root.components.set(PositioningComponent(
            offsetX: 0,
            offsetY: 0,
            offsetZ: -1.0,
            needsPositioning: false,
            shouldAnimate: false,
            animationDuration: 0.0
        ))
        
        Logger.info("""
        
        ✅ Root Setup Complete
        ├─ Root Entity: \(root.name)
        ├─ Position: \(root.position(relativeTo: nil))
        └─ Positioning: Ready for explicit updates
        """)
        
        isRootSetupComplete = true
        isHeadTrackingRootReady = true
        return root
    }
}

public enum ADCUIAttachments {
    static let adcSelectorView = "adcSelectorAttachment"
    static let linkerSelectorView = "linkerSelectorAttachment"
    static let payloadSelectorView = "payloadSelectorAttachment"
    static let mainADCView = "mainADCView"
    static let coachingOverlay = "coachingOverlay"
}
