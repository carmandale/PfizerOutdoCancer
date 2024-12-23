import Foundation
import RealityKit
import SwiftUI

@Observable
class ADCDataModel {
    public var selectedADCAntibody: Int? = nil
    public var selectedADCLinker: Int? = nil
    public var selectedADCPayload: Int? = nil
    
    public var selectedLinkerType: Int? = nil
    public var selectedPayloadType: Int? = nil
    
    public var linkersWorkingIndex: Int = 0
    public var payloadsWorkingIndex: Int = 0
    
    public var adcBuildStep = 0
    
    var placedLinkerCount: Int = 0
    var placedPayloadCount: Int = 0
    
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
}

public enum ADCUIAttachments {
    static let adcSelectorView = "adcSelectorAttachment"
    static let linkerSelectorView = "linkerSelectorAttachment"
    static let payloadSelectorView = "payloadSelectorAttachment"
    static let mainADCView = "mainADCView"
}

public enum ADCUIViews {
    static let mainViewID = "MainView"
    static let immersiveSpaceID = "ImmersiveSpace"
}

