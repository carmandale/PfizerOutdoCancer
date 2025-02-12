// CancerCellMovementData.swift
import RealityKit
import simd

/// A component to store the base movement data for a cancer cell.
public struct CancerCellMovementData: Component, Codable {
    public var baseLinearVelocity: SIMD3<Float>
    
    public init(baseLinearVelocity: SIMD3<Float>) {
        self.baseLinearVelocity = baseLinearVelocity
    }
}