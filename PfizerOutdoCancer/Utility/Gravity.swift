import RealityKit

struct Gravity: ForceEffectProtocol {
    var parameterTypes: PhysicsBodyParameterTypes { [.position, .distance] }
    var forceMode: ForceMode { .force }
    
    var gravityMagnitude: Float = 0.1
    var minimumDistance: Float = 0.2
    
    func update(parameters: inout ForceEffectParameters) {
        guard let distances = parameters.distances,
              let positions = parameters.positions else { return }
        
        for index in 0..<parameters.physicsBodyCount {
            let distance = distances[index]
            let position = positions[index]
            
            guard distance > minimumDistance else { continue }
            
            let force = computeForce(position: position, distance: distance)
            parameters.setForce(force, index: index)
        }
    }
    
    func computeForce(position: SIMD3<Float>, distance: Float) -> SIMD3<Float> {
        let towardsCenter = normalize(position) * -1
        return towardsCenter * gravityMagnitude / pow(distance, 2)
    }
}