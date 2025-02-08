// ADCMovementSystem+Math.swift

import RealityKit
import Foundation
import RealityKitContent

@MainActor
extension ADCMovementSystem {
    
    internal static func mix(_ a: Float, _ b: Float, t: Float) -> Float {
        return a * (1 - t) + b * t
    }
    
    internal static func mix(_ a: SIMD3<Float>, _ b: SIMD3<Float>, t: Float) -> SIMD3<Float> {
        return a * (1 - t) + b * t
    }
    
    internal static func smoothstep(_ edge0: Float, _ edge1: Float, _ x: Float) -> Float {
        let t = max(0, min((x - edge0) / (edge1 - edge0), 1))
        return t * t * (3 - 2 * t)
    }
    
    /// Quadratic Bézier point calculation: B(t) = (1-t)²P₀ + 2(1-t)tP₁ + t²P₂
    static func quadraticBezierPoint(_ p0: SIMD3<Float>,
                                     _ p1: SIMD3<Float>,
                                     _ p2: SIMD3<Float>,
                                     t: Float) -> SIMD3<Float> {
        let mt = 1 - t
        return mt * mt * p0 + 2 * mt * t * p1 + t * t * p2
    }
    
    /// Given a quadratic Bézier curve, sample it to build a lookup table of cumulative arc lengths.
    static func buildLookupTableForQuadraticBezier(start: SIMD3<Float>, control: SIMD3<Float>, end: SIMD3<Float>, samples: Int) -> [Float] {
        var lookup: [Float] = [0.0]
        var previousPoint = start
        for i in 1...samples {
            let t = Float(i) / Float(samples)
            let point = quadraticBezierPoint(start, control, end, t: t)
            let segmentLength = simd_distance(point, previousPoint)
            let cumulative = lookup.last! + segmentLength
            lookup.append(cumulative)
            previousPoint = point
        }
        return lookup
    }
    
    /// Given the traveled distance and a lookup table, interpolate the corresponding parameter t.
    static func lookupParameter(forDistance distance: Float, lookup: [Float]) -> Float {
        guard let totalLength = lookup.last, totalLength > 0 else { return 0 }
        let d = simd_clamp(distance, 0, totalLength)
        for i in 1..<lookup.count {
            if lookup[i] >= d {
                let t0 = Float(i - 1) / Float(lookup.count - 1)
                let t1 = Float(i) / Float(lookup.count - 1)
                let d0 = lookup[i - 1]
                let d1 = lookup[i]
                let segmentFraction = (d - d0) / (d1 - d0)
                return t0 + segmentFraction * (t1 - t0)
            }
        }
        return 1.0
    }
    
    /// Calculates complete path metrics (for legacy or debugging purposes).
    static func calculatePathMetrics(
        start: SIMD3<Float>,
        control: SIMD3<Float>,
        end: SIMD3<Float>
    ) -> (length: Float, initialDirection: SIMD3<Float>, controlPoint: SIMD3<Float>) {
        let pathLength = quadraticBezierLength(start, control, end)
        let initialDerivative = 2 * (control - start)
        let initialDirection = normalize(initialDerivative)
        return (pathLength, initialDirection, control)
    }
    
    /// Quadratic Bézier curve length using Gauss–Legendre quadrature.
    static func quadraticBezierLength(_ p0: SIMD3<Float>, _ p1: SIMD3<Float>, _ p2: SIMD3<Float>) -> Float {
        let weights: [Float] = [0.236926885056189, 0.478628670499366, 0.568888888888889, 0.478628670499366, 0.236926885056189]
        let nodes: [Float] = [0.046910077030668, 0.230765344947158, 0.5, 0.769234655052842, 0.953089922969332]
        
        return nodes.enumerated().reduce(0) { acc, pair in
            let t = pair.element
            let derivative = 2 * ((1 - t) * (p1 - p0) + t * (p2 - p1))
            return acc + weights[pair.offset] * simd_length(derivative)
        } * 0.5
    }
    
    internal static func validateQuaternion(_ quat: simd_quatf) -> Bool {
        if quat.vector.x.isNaN || quat.vector.y.isNaN || quat.vector.z.isNaN || quat.vector.w.isNaN {
            return false
        }
        let length = sqrt(quat.vector.x * quat.vector.x +
                          quat.vector.y * quat.vector.y +
                          quat.vector.z * quat.vector.z +
                          quat.vector.w * quat.vector.w)
        return abs(length - 1.0) < 0.001
    }
    
    static func calculateOrientation(progress: Float,
                                     direction: SIMD3<Float>,
                                     deltaTime: TimeInterval,
                                     currentOrientation: simd_quatf,
                                     entity: Entity) -> simd_quatf {
        // Validate inputs
        guard validateOrientationCalculation(entity: entity,
                                          progress: progress,
                                          direction: direction,
                                          currentOrientation: currentOrientation) else {
            return currentOrientation
        }
        
        // Handle protein complex spin animation
        if let proteinComplex = entity.findEntity(named: "antibodyProtein_complex"),
           let adcComponent = entity.components[ADCComponent.self] {
            let worldSpinAxis = currentOrientation.act([-1, 0, 0])
            let spinRotation = simd_quatf(angle: Float(deltaTime) * adcComponent.proteinSpinSpeed, axis: worldSpinAxis)
            proteinComplex.orientation = spinRotation * proteinComplex.orientation
        }
        
        // Early return if we don't have the necessary components
        guard let adcComponent = entity.components[ADCComponent.self],
              let targetID = adcComponent.targetEntityID else {
            return currentOrientation
        }
        
        // Find target entity
        let query = EntityQuery(where: .has(AttachmentPoint.self))
        guard let targetEntity = entity.scene?.performQuery(query).first(where: { $0.id == Entity.ID(targetID) }) else {
            return currentOrientation
        }
        
        // Compute landing orientation and blend factor
        let landingOrientation = computeLandingOrientation(for: entity, with: targetEntity)
        let blendFactor = computeBlendFactor(progress: progress)
        
        // Debug state if needed
        // #if DEBUG
        // debugPrintOrientationState(
        //     progress: progress,
        //     blendFactor: blendFactor,
        //     currentOrientation: currentOrientation,
        //     targetOrientation: landingOrientation
        // )
        // #endif
        
        if blendFactor > 0 {
            // Blend between flight orientation and landing orientation
            let flightOrientation = simd_quatf(from: [0, 0, 1], to: direction)
            let intermediateOrientation = safeSlerp(from: flightOrientation, to: landingOrientation, t: blendFactor)
            
            // Add subtle banking based on progress
            let bankAngle = computeBankingAngle(progress: progress, blendFactor: blendFactor)
            let bankRotation = simd_quatf(angle: bankAngle, axis: [1, 0, 0])
            
            // Combine orientations
            let targetOrientation = bankRotation * intermediateOrientation
            
            // Smoothly interpolate from current to target orientation
            return safeSlerp(from: currentOrientation, to: targetOrientation, t: Float(deltaTime) * rotationSmoothingFactor)
        } else {
            // Standard flight orientation when not near target
            let flightOrientation = simd_quatf(from: [0, 0, 1], to: direction)
            
            // Add banking during normal flight
            let bankAngle = computeBankingAngle(progress: progress, blendFactor: 0)
            let bankRotation = simd_quatf(angle: bankAngle, axis: [1, 0, 0])
            
            // Combine orientations
            let targetOrientation = bankRotation * flightOrientation
            
            // Smoothly interpolate from current to target orientation
            return safeSlerp(from: currentOrientation, to: targetOrientation, t: Float(deltaTime) * rotationSmoothingFactor)
        }
    }
    
    // MARK: - Landing Orientation Helpers
    
    /// Ensures a quaternion is normalized and valid
    internal static func normalizeQuaternion(_ quat: simd_quatf) -> simd_quatf {
        if !validateQuaternion(quat) {
            // Create identity quaternion manually (w=1, xyz=0)
            return simd_quatf(vector: SIMD4<Float>(0, 0, 0, 1))
        }
        return quat
    }
    
    /// Safely normalizes a vector, returning a default up vector if normalization fails
    internal static func safeNormalize(_ vector: SIMD3<Float>, defaultVector: SIMD3<Float> = SIMD3<Float>(0, 1, 0)) -> SIMD3<Float> {
        let vectorLength = length(vector)
        
        // Check for near-zero length or NaN components
        if vectorLength < 1e-6 || vector.x.isNaN || vector.y.isNaN || vector.z.isNaN {
            #if DEBUG
            print("⚠️ Vector normalization failed:")
            print("Vector: \(vector)")
            print("Length: \(vectorLength)")
            print("Using default vector: \(defaultVector)")
            #endif
            return defaultVector
        }
        
        return vector / vectorLength
    }
    
    /// Computes surface normal from a point on the surface to the center
    internal static func computeSurfaceNormal(surfacePoint: SIMD3<Float>, center: SIMD3<Float>) -> SIMD3<Float> {
        let vector = surfacePoint - center
        
        #if DEBUG
        print("Surface Normal Calculation:")
        print("Vector: \(vector)")
        print("Vector Length: \(length(vector))")
        #endif
        
        return safeNormalize(vector)
    }
    
    /// Safely interpolates between two quaternions with validation
    internal static func safeSlerp(from start: simd_quatf, to end: simd_quatf, t: Float) -> simd_quatf {
        guard validateQuaternion(start) && validateQuaternion(end) else {
            return start
        }
        return simd_slerp(start, end, t)
    }
    
    // MARK: - Easing and Blending
    
    /// Smooth easing function for orientation blending
    internal static func smoothEaseInOut(_ x: Float) -> Float {
        let t = simd_clamp(x, 0, 1)
        return t * t * (3 - 2 * t)
    }
    
    /// Exponential ease out for smoother deceleration
    internal static func expEaseOut(_ x: Float) -> Float {
        return x == 1 ? 1 : 1 - pow(2, -10 * x)
    }
    
    /// Computes blend factor for landing orientation transition
    internal static func computeBlendFactor(progress: Float, startBlend: Float = 0.8) -> Float {
        if progress < startBlend {
            return 0
        }
        let rawFactor = (progress - startBlend) / (1 - startBlend)
        return smoothEaseInOut(rawFactor)
    }
    
    /// Computes banking angle based on progress and blend factor
    internal static func computeBankingAngle(progress: Float, blendFactor: Float) -> Float {
        let baseAngle = sin(progress * .pi * 2)
        return (1 - blendFactor) * maxBankAngle * baseAngle
    }
    
    // MARK: - Landing Orientation
    
    /// Computes a landing orientation that aligns the ADC with the antigen's surface normal
    internal static func computeLandingOrientation(for adc: Entity, with target: Entity) -> simd_quatf {
        // Get the antigen (two levels up from attachment point)
        guard let antigenOffset = target.parent,
              let antigen = antigenOffset.parent,
              let scene = antigen.scene,
              let cell = findParentCancerCell(for: antigen, in: scene) else {
            print("⚠️ No parent cell found for target - using target orientation")
            return target.orientation(relativeTo: nil)
        }
        
        // Compute world positions using the antigen position instead of attachment point
        let antigenWorldPos = antigen.position(relativeTo: nil)
        let cellWorldPos = cell.position(relativeTo: nil)
        
        // #if DEBUG
        // print("\n=== Landing Orientation Debug ===")
        // print("Antigen Entity: \(antigen.name)")
        // print("Antigen World Position: \(antigenWorldPos)")
        // print("Cell World Position: \(cellWorldPos)")
        // print("Vector between positions: \(antigenWorldPos - cellWorldPos)")
        // #endif
        
        // Compute surface normal and validate
        let normal = computeSurfaceNormal(surfacePoint: antigenWorldPos, center: cellWorldPos)
        
        // #if DEBUG
        // print("Computed Normal: \(normal)")
        // print("Normal length: \(length(normal))")
        // print("Has NaN?: \(normal.x.isNaN || normal.y.isNaN || normal.z.isNaN)")
        // #endif
        
        guard !normal.x.isNaN && !normal.y.isNaN && !normal.z.isNaN else {
            print("⚠️ Invalid surface normal computed - using target orientation")
            return target.orientation(relativeTo: nil)
        }
        
        // Base rotation to align ADC's up vector with surface normal
        let baseRotation = simd_quatf(from: SIMD3<Float>(0, 1, 0), to: normal)
        guard validateQuaternion(baseRotation) else {
            print("⚠️ Invalid base rotation - using target orientation")
            return target.orientation(relativeTo: nil)
        }
        
        // Add randomized rotation around the normal for variety
        let randomAngle = Float.random(in: -Float.pi/8 ... Float.pi/8)
        let randomRotation = simd_quatf(angle: randomAngle, axis: normal)
        
        // Combine rotations and validate
        let finalOrientation = normalizeQuaternion(randomRotation * baseRotation)
        if !validateQuaternion(finalOrientation) {
            print("⚠️ Invalid final orientation - using target orientation")
            return target.orientation(relativeTo: nil)
        }
        
        return finalOrientation
    }
    
    /// Computes the complete landing transform including position offset
    internal static func computeLandingTransform(for adc: Entity, with target: Entity) -> Transform {
        var transform = Transform()
        
        // // Set orientation
        // transform.rotation = computeLandingOrientation(for: adc, with: target)
        
        // // Set position with slight offset along the surface normal
        // if let cell = target.parent {
        //     let normal = computeSurfaceNormal(
        //         surfacePoint: target.position(relativeTo: nil),
        //         center: cell.position(relativeTo: nil)
        //     )
        //     transform.translation = SIMD3<Float>(0, -0.08, 0) // Slight offset for visual appeal
        // } else {
        //     transform.translation = .zero
        // }
        
        // Create a pitch rotation of -90 degrees (i.e. -π/2 radians) around the X axis.
        let pitchRotation = simd_quatf(angle: -Float.pi/2, axis: SIMD3<Float>(1, 0, 0))
        
        // Generate a random yaw rotation between 0 and 360 degrees (0 to 2π radians) around the Y axis.
        let randomYawAngle = Float.random(in: 0 ..< (2 * Float.pi))
        let yawRotation = simd_quatf(angle: randomYawAngle, axis: SIMD3<Float>(0, 1, 0))
        
        // Combine the rotations. (Multiplication order matters:
        // here, yawRotation * pitchRotation means that the ADC first gets pitched -90°,
        // then rotated randomly around its new up axis.)
        transform.rotation = yawRotation * pitchRotation
        
        // Optionally, add a slight translation offset along the local Y axis.
        // (This offset can be adjusted to fine-tune the "lily pad" visual.)
        transform.translation = SIMD3<Float>(0, -0.08, 0)
        
        // Set the scale to uniform 1.
        transform.scale = SIMD3<Float>(1, 1, 1)

        return transform
    }
    
    // MARK: - Validation and Debugging
    
    /// Validates all inputs for orientation calculation
    internal static func validateOrientationCalculation(entity: Entity,
                                                      progress: Float,
                                                      direction: SIMD3<Float>,
                                                      currentOrientation: simd_quatf) -> Bool {
        // Check for NaN values in direction vector
        if direction.x.isNaN || direction.y.isNaN || direction.z.isNaN {
            print("⚠️ Invalid direction vector in orientation calculation")
            return false
        }
        
        // Validate current orientation
        if !validateQuaternion(currentOrientation) {
            print("⚠️ Invalid current orientation in calculation")
            return false
        }
        
        // Validate progress value
        if progress.isNaN || progress < 0 || progress > 1 {
            print("⚠️ Invalid progress value: \(progress)")
            return false
        }
        
        // Validate entity has required components
        if entity.components[ADCComponent.self] == nil {
            print("⚠️ Entity missing ADC component")
            return false
        }
        
        return true
    }
    
    /// Debug function to print orientation state
    internal static func debugPrintOrientationState(progress: Float,
                                                  blendFactor: Float,
                                                  currentOrientation: simd_quatf,
                                                  targetOrientation: simd_quatf) {
        print("""
        === ADC Orientation State ===
        Progress: \(String(format: "%.3f", progress))
        Blend Factor: \(String(format: "%.3f", blendFactor))
        Current Orientation: \(currentOrientation)
        Target Orientation: \(targetOrientation)
        Quaternion Lengths:
          Current: \(sqrt(simd_dot(currentOrientation.vector, currentOrientation.vector)))
          Target: \(sqrt(simd_dot(targetOrientation.vector, targetOrientation.vector)))
        ========================
        """)
    }
    
    /// Validates transform for landing
    internal static func validateLandingTransform(_ transform: Transform) -> Bool {
        // Check position
        if transform.translation.x.isNaN || transform.translation.y.isNaN || transform.translation.z.isNaN {
            print("⚠️ Invalid landing position")
            return false
        }
        
        // Check rotation
        if !validateQuaternion(transform.rotation) {
            print("⚠️ Invalid landing rotation")
            return false
        }
        
        // Check scale (should be uniform)
        if transform.scale.x != transform.scale.y || transform.scale.y != transform.scale.z {
            print("⚠️ Non-uniform scale in landing transform")
            return false
        }
        
        return true
    }
}