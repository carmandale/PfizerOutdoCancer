//
//  Entity+Find.swift
//  PfizerOutdoCancer
//
//  Created by Dale Carman on 05.02.25.
//

import RealityKit

extension Entity {
    /// Recursively searches for a component of the specified type in the entity hierarchy.
    func findComponent<T>(ofType type: T.Type) -> T? where T: Component {
        // Check if the component exists on this entity.
        if let component = self.components[ type ] {
            return component
        }
        // Otherwise, search the parent recursively.
        return self.parent?.findComponent(ofType: type)
    }
}
