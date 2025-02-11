# ADC Math Extensions Documentation

This file provides extensions to `SIMD3<Float>` to add utility functions for common 3D math operations used in the ADC project.

## `SIMD3<Float>` Extension

*   **Purpose:** Extends the `SIMD3<Float>` type (a 3D vector with Float components) with helper methods for distance calculations, normalization, and finding collinear points.
*   **Key Features:**
    *   `distance(from:)`: Calculates the Euclidean distance between two `SIMD3<Float>` points.
    *   `printed`: Returns a formatted string representation of the vector.
    *   `adcNormalized`: Returns a normalized version of the vector (unit length).
    *   `static let x`, `static let up`, `static let z`: Provides convenient static vectors for the X, Y, and Z axes.
    *   `static func magnitude(pointA:pointB:)`: Calculates the magnitude (length) of the vector between two points.
    *   `normalize(to:)`: Calculates the normalized (unit) vector pointing from the current vector to another vector.
    *   `findCollinearPoint(to:distance:)`: Finds a point that lies on the line defined by the current vector and another vector, at a specified distance from the current vector.

These extensions provide a set of useful math operations that are commonly needed when working with 3D vectors, simplifying calculations related to position, direction, and distance. The `findCollinearPoint` function is particularly useful for positioning objects along a line. 