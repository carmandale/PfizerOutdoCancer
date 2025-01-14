//
//  RotationHelpers.swift
//  PfizerOutdoCancer
//
//  Created by Dale Carman on 1/12/25.
//
import simd

public extension simd_quatf {
    // Return pitch, yaw, roll in radians
    func toEulerAngles() -> SIMD3<Float> {
        // Many ways to do this; here’s one typical approach
        print("extracting euler angles from quaternion")
        let ysqr = imag.y * imag.y

        // roll (x-axis rotation)
        let t0 = 2.0 * (real * imag.x + imag.y * imag.z)
        let t1 = 1.0 - 2.0 * (imag.x * imag.x + ysqr)
        let roll = atan2(t0, t1)

        // pitch (y-axis rotation)
        let t2 = 2.0 * (real * imag.y - imag.z * imag.x)
        let t2Clamped = max(min(t2, 1.0), -1.0)
        let pitch = asin(t2Clamped)

        // yaw (z-axis rotation)
        let t3 = 2.0 * (real * imag.z + imag.x * imag.y)
        let t4 = 1.0 - 2.0 * (ysqr + imag.z * imag.z)
        let yaw = atan2(t3, t4)

        // We'll define them as (pitch, yaw, roll) for clarity
        return [pitch, yaw, roll]
    }

    init(fromEuler angles: SIMD3<Float>) {
        let (pitch, yaw, roll) = (angles.x, angles.y, angles.z)
        let cy = cos(yaw * 0.5)
        let sy = sin(yaw * 0.5)
        let cr = cos(roll * 0.5)
        let sr = sin(roll * 0.5)
        let cp = cos(pitch * 0.5)
        let sp = sin(pitch * 0.5)

        self = simd_quatf(ix: sr * cp * cy - cr * sp * sy,
                          iy: cr * sp * cy + sr * cp * sy,
                          iz: cr * cp * sy - sr * sp * cy,
                          r:  cr * cp * cy + sr * sp * sy)
    }
}

public extension simd_quatf {
    /// Returns a rotation discarding pitch and roll, keeping only yaw
    func onlyYaw() -> simd_quatf {
        let e = self.toEulerAngles()  // (pitch, yaw, roll)
        return simd_quatf(fromEuler: [0, e.y, 0])
    }
}
