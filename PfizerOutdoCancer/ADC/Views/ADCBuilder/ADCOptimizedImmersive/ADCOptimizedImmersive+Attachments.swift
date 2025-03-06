import SwiftUI
import RealityKit
import RealityKitContent
import OSLog

extension ADCOptimizedImmersive {
//        func calculateMainViewPosition() -> SIMD3<Float> {
////        let cameraPosition = cameraEntity.position(relativeTo: nil)
////         let antibodyPosition = antibodyEntity?.position(relativeTo: nil) ?? [0, 0, defaultZPosition]  
////        
////        return SIMD3<Float>(
////            antibodyPosition.x + -0.5,
////            antibodyPosition.y + 0,
////            antibodyPosition.z + 0
////        )
//        // calculateRadialPosition(cameraPosition: cameraPosition, 
//        //                              antibodyPosition: antibodyPosition, 
//        //                              angleDegrees: -35, 
//        //                              yOffset: antibodyPosition.y, 
//        //                              radiusOffset: 0.1)
//    }
    
   func calculateTargetLinkerPosition() -> SIMD3<Float> {
        let antibodyPosition = antibodyEntity?.position(relativeTo: nil) ?? SIMD3<Float>(0, 0, defaultZPosition)
       
       // Return position 0.5 meters to the right of the antibody
       return SIMD3<Float>(
           antibodyPosition.x + linkerAttachmentOffset.x,  // 0.5 meters to the right
           antibodyPosition.y + linkerAttachmentOffset.y,        // same height
           antibodyPosition.z + linkerAttachmentOffset.z         // same depth
       )
   }
   func calculateTargetPayloadsPosition() -> SIMD3<Float> {
       
    //    let cameraPosition = cameraEntity.position(relativeTo: nil)
        let antibodyPosition = antibodyEntity?.position(relativeTo: nil) ?? [0, 0, defaultZPosition]
       
       return SIMD3<Float>(
           antibodyPosition.x + payloadAttachmentOffset.x,  // 0.5 meters to the right
           antibodyPosition.y + payloadAttachmentOffset.y,        // same height
           antibodyPosition.z + payloadAttachmentOffset.z         // same depth
       )
    //    calculateRadialPosition(cameraPosition: cameraPosition, antibodyPosition: antibodyPosition, angleDegrees: 35, yOffset: antibodyPosition.y, radiusOffset: 0.1)

   }
    
    func setAntibodyAttachmentPosition() {
        
        // let cameraPosition = cameraEntity.position(relativeTo: nil)
        // let antibodyPosition = antibodyEntity?.position(relativeTo: nil) ?? [0, 1.5, defaultZPosition]
        
        // let newPosition = calculateRadialPosition(cameraPosition: cameraPosition, antibodyPosition: antibodyPosition, angleDegrees: 35, yOffset: antibodyPosition.y, radiusOffset: 0.1)
        // adcAttachmentEntity?.position = newPosition
    }
    
    func setLinkerAttachmentPosition() {
        if let linkerAttachmentEntity = linkerAttachmentEntity,
           let linkerEntity = linkerEntity {
            // Get the world position of the linker entity
            let linkerPosition = linkerEntity.position(relativeTo: nil)
            // Set the attachment position with offset
            linkerAttachmentEntity.position = linkerPosition + linkerAttachmentOffset
        }
    }
    
    // func calculateRadialPosition(cameraPosition camera: SIMD3<Float>, antibodyPosition antibody: SIMD3<Float>, angleDegrees: Float, yOffset: Float, radiusOffset: Float = 0.0) -> SIMD3<Float>  {
    //      let c: SIMD3<Float> = [camera.x,0,camera.z]
    //      let a: SIMD3<Float> = [antibody.x ,0,antibody.z]

    //      let directionVector = a - c
    //      let radius = length(directionVector)
    //      let normalizedAC = directionVector.adcNormalized

    //      let aAngleRadians = atan2(normalizedAC.z, normalizedAC.x)
    //      let aAngleDegrees = aAngleRadians * 180 / .pi

    //      let newAngleDegrees = (aAngleDegrees + angleDegrees)
    //      let newAngleRadians = newAngleDegrees * .pi / 180

    //      let x = (radius + radiusOffset) * cos(newAngleRadians)
    //      let z = (radius + radiusOffset) * sin(newAngleRadians)

    //      let b: SIMD3<Float> = [x,yOffset,z] + c
        
    //      return b
    // }
    
    
    func updateADC() {
//        os_log(.debug, "ITR..updateADC() called")
        mainViewEntity.isEnabled = shouldAddMainViewAttachment
        if shouldAddMainViewAttachment {
            //Calculate the new position of mainViewEntity
            // mainViewEntity.position = calculateMainViewPosition()
        }
        if (dataModel.adcBuildStep == 0) {
            if let adcAttachmentEntity {
                if shouldAddADCAttachment {
                    mainEntity?.addChild(adcAttachmentEntity)
                    
//                    if let antibodyEntity {
//                        self.adcAttachmentEntity?.position = antibodyEntity.position(relativeTo: nil) + antibodyAttachmentOffset
//                    }
                    // setAntibodyAttachmentPosition()
                    
                } else {
                    mainEntity?.removeChild(adcAttachmentEntity)
                }
            }
            self.linkerAttachmentEntity?.isEnabled = false
            if let payloadAttachmentEntity { payloadEntity?.removeChild(payloadAttachmentEntity) }
        }
        if (dataModel.adcBuildStep == 1) {
            // if let adcAttachmentEntity { mainEntity?.removeChild(adcAttachmentEntity) }
            setLinkerAttachmentPosition()
            if shouldAddLinkerAttachment {
                self.linkerAttachmentEntity?.isEnabled = true

            } else {
                self.linkerAttachmentEntity?.isEnabled = false
            }
            if let payloadAttachmentEntity { payloadEntity?.removeChild(payloadAttachmentEntity) }
        }
        if (dataModel.adcBuildStep == 2) {
            // if let adcAttachmentEntity { mainEntity?.removeChild(adcAttachmentEntity) }
            self.linkerAttachmentEntity?.isEnabled = false
            if let payloadAttachmentEntity {
                if shouldAddPayloadAttachment {
                    payloadEntity?.addChild(payloadAttachmentEntity)
                } else {
                    payloadEntity?.removeChild(payloadAttachmentEntity)
                }
            }
        }
    }
    
    func setupAttachments(attachments: RealityViewAttachments) {
        Logger.debug("=== Setting up Attachments ===")
        Logger.debug("mainEntity exists: \(mainEntity != nil)")
        Logger.debug("mainEntity position: \(mainEntity?.position(relativeTo: nil) ?? .zero)")
        
        if let viewAttachment = attachments.entity(for: ADCUIAttachments.mainADCView) {
            viewAttachment.name = ADCUIAttachments.mainADCView
//            viewAttachment.scale = SIMD3<Float>(0.6, 0.6, 0.6)
            viewAttachment.scale = .one
            //  viewAttachment.components[BillboardComponent.self] = BillboardComponent()
            mainViewEntity.addChild(viewAttachment)
            Logger.debug("✅ Added mainADCView to mainViewEntity")
        } else {
            Logger.error("❌ Could not find mainADCView attachment")
        }
        
        // Handle coaching overlay - attach to mainEntity which is our headTrackingRoot equivalent
        if let coachingViewAttachment = attachments.entity(for: ADCUIAttachments.coachingOverlay) {
            Logger.debug("✅ Found coaching overlay attachment")
            Logger.debug("Coaching attachment initial position: \(coachingViewAttachment.position)")
            Logger.debug("Coaching attachment initial scale: \(coachingViewAttachment.scale)")
            
            // Position it exactly like the tutorial alert in AttackCancerView
            coachingViewAttachment.position = SIMD3<Float>(0, -0.25, 0.25)
            
            // Make sure it's visible by setting opacity and isEnabled
            coachingViewAttachment.isEnabled = true
            
            // Add to the main entity, which is our headTrackingRoot equivalent
            mainEntity?.addChild(coachingViewAttachment)
            Logger.debug("✅ Added coaching overlay to mainEntity at position (0, -0.25, 0.25)")
            Logger.debug("Coaching overlay is now child of: \(coachingViewAttachment.parent?.name ?? "unknown")")
            Logger.debug("Coaching overlay world position: \(coachingViewAttachment.position(relativeTo: nil))")
        } else {
            Logger.error("❌ Could not find coaching overlay attachment")
        }
    }
}
