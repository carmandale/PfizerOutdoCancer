import Foundation
import simd

/// The type alias to create a new name for `SIMD3<Float>`.
typealias Float3 = SIMD3<Float>

/// The type alias to create a new name for `SIMD4<Float>`.
typealias Float4 = SIMD4<Float>

/// The type alias to create a new name for `simd_float4x4`.
typealias Float4x4 = simd_float4x4

extension Float3 {
    /// The initializer of a `Float3` from a `Float4`.
    init(_ float4: Float4) {
        self.init()
        x = float4.x
        y = float4.y
        z = float4.z
    }
    
    func length() -> Float {
        sqrt(x * x + y * y + z * z)
    }
    
    func normalized() -> Float3 {
        self * 1 / length()
    }
}

extension Float4 {
    func toFloat3() -> Float3 {
        Float3(self)
    }
}

extension Float4x4 {
    func translation() -> Float3 {
        columns.3.toFloat3()
    }
    
    func forward() -> Float3 {
        columns.2.toFloat3().normalized()
    }
}