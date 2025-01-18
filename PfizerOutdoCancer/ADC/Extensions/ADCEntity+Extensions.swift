import RealityKit

/// The extension that enables entities to updates its materials.
extension Entity {
    
    public func updateMaterial(name: String?, _ update: (inout Material) -> Void) {
        guard let name else { return }
        
        // Call recursive function to all child entities.
        for child in children {
            if child.name == name {
                child.updateMaterial(name: name, update)
            }
        }

        // Apply the new values to the component material.
        if var comp = components[ModelComponent.self] {
            comp.materials = comp.materials.map { material in
                var copy = material
                update(&copy)
                return copy
            }
            components.set(comp)
        }
    }

    
    /// Finds all materials in a component, and update them with the custom closure.
    public func updateMaterials(_ update: (inout Material) -> Void) {
        // Call recursive function to all child entities.
        for child in children {
            child.updateMaterials(update)
        }

        // Apply the new values to the component material.
        if var comp = components[ModelComponent.self] {
            comp.materials = comp.materials.map { material in
                var copy = material
                update(&copy)
                return copy
            }
            components.set(comp)
        }
    }
    
    func findModelEntity(named name: String, in entity: Entity? = nil) -> ModelEntity? {
        let entity = entity ?? self
        
        if entity.name == name, let modelEntity = entity as? ModelEntity {
            return modelEntity
        } else {
            for child in entity.children {
                if let result = findModelEntity(named: name, in: child) {
                    return result
                }
            }
        }
        return nil
    }
    
    func findModelEntity(named name: String, from ancestor: String, in entity: Entity? = nil, foundAncestor: Bool = false) -> ModelEntity? {
        let entity = entity ?? self

        if entity.name == name && foundAncestor, let modelEntity = entity as? ModelEntity {
            return modelEntity
        } else {
            var didFoundAncestor = foundAncestor
            
            if entity.name == ancestor {
                didFoundAncestor = true
            }
            
            for child in entity.children {
                if let result = findModelEntity(named: name, from: ancestor, in: child, foundAncestor: didFoundAncestor) {
                    return result
                }
            }
        }
        return nil
    }
    

}
