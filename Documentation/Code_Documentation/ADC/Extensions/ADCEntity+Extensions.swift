# ADC Entity Extensions Documentation

This file extends the `Entity` class in RealityKit with helper methods for updating materials and finding child entities.

## `Entity` Extension

*   **Purpose:** Provides utility functions to simplify common operations on entities, particularly related to material updates and child entity retrieval.
*   **Key Features:**
    *   `updateMaterial(name:_:)`: Updates a specific material on a named child entity using a closure.  It searches recursively through the entity's children.
    *   `updateMaterials(_:)`: Updates all materials on the entity and its children using a closure. This allows for batch updates of material properties.
    *   `findModelEntity(named:in:)`: Recursively searches for a `ModelEntity` with a specific name within the entity's hierarchy.
    *   `findModelEntity(named:from:in:foundAncestor:)`: Recursively searches for a `ModelEntity` with a specific name, starting from a specified ancestor entity.

These extensions streamline common tasks like applying color changes to specific parts of a model or finding specific sub-components within a complex entity hierarchy. The recursive nature of the search functions makes them powerful for working with nested entities. 