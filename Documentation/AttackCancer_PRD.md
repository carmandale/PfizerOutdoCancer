# AttackCancer Feature - Product Requirements Document (PRD)

## Overview
The AttackCancer feature is designed for VisionOS 2 using RealityKit, SwiftUI, and ARKit. Built following Apple’s best practices and proven VisionOS 2 patterns, the system leverages a modern, declarative UI and a robust, component-based architecture utilizing RealityKit’s ECS design patterns and the new @Observable state management. The feature is primarily responsible for mounting an immersive simulation where a user can interact with cancer cells, observe their behavior, and manage their adsorption through ADC (Antibody-Drug Conjugate) mechanisms.

## Objectives
- **Immersive Experience:** Create a fully interactive and visually engaging experience on VisionOS 2.
- **Modular Architecture:** Use ECS (Entity-Component-System) design patterns to modularize game logic such as ADC movement, collision detection, spawning, notifications, and scene setup.
- **State Management:** Employ @Observable for managing state, ensuring reactiveness and a seamless UI update cycle.
- **Apple Best Practices:** Adhere strictly to VisionOS paradigms, avoiding iOS patterns, with careful distinction in animations and UI interactions.
- **Real-time Interactions:** Integrate ADC movement and Cancer Cell behavior with realistic mathematical models, retargeting logic, and utility functions for smooth animations and updates.

## Reviewed Components & Code Structure
### Views
- **AttackCancerView.swift:**
  - Implements the SwiftUI view layer using VisionOS 2 paradigms.
  - Uses declarative syntax to layout view components and integrates RealityKit views for augmented scenes.
  - Handles user interactions that are tied to ADC movement and scene updates.

### View Models
The `AttackCancerViewModel` is decomposed across several extensions which segregate responsibilities clearly:

- **ADC (AttackCancerViewModel+ADC.swift):**
  - Manages ADC-specific logic including state updates and animations related to ADC behavior.

- **Collisions (AttackCancerViewModel+Collisions.swift):**
  - Handles collision detection between ADC entities and cancer cells, notifying the system of impacts and deflections.

- **Notifications (AttackCancerViewModel+Notifications.swift):**
  - Provides user notifications and feedback, integrating with system-level alerts and view updates.

- **Scene Setup (AttackCancerViewModel+SceneSetup.swift):**
  - Initializes and configures the RealityKit scene, ensuring proper setup for the immersive experience.

- **Spawning (AttackCancerViewModel+Spawning.swift):**
  - Manages the logic for spawning both ADCs and cancer cells in the scene, ensuring balanced gameplay and interactive pacing.

### Systems
- **ADCMovementSystem.swift & Extensions:**
  - Implements the underlying movement mechanics for ADCs using specialized subsystems:
    - **Math:** Contains mathematical models and equations for path calculations and dynamics.
    - **Retargeting:** Provides functionality for dynamically readjusting ADC trajectories based on real-time collision data.
    - **Utils:** Houses general utility functions that support ADC movement and scene integration.

### Components
- **CancerCellComponent.swift:**
  - Defined in the RealityKitContent package, this component is central to the representation and behavior of cancer cells within the ECS framework.
  - Integrates seamlessly into the ADC movement system to simulate interactions with ADCs.

## Technical Approach
- **Architecture:**
  - Utilize RealityKit’s ECS design pattern to decouple systems and promote separation of concerns.
  - State is managed via SwiftUI’s new @Observable, ensuring that UI and RealityKit interactions remain in sync.

- **User Interface & Animations:**
  - The UI is built exclusively with VisionOS patterns; animations are tailored to the immersive environment, leveraging RealityKit’s robust animation frameworks and SwiftUI’s declarative processes.
  - Interactions are designed to be intuitive and responsive, maintaining high performance through effective use of entity systems.

- **Collision & Notification Handling:**
  - Collisions are detected using specialized logic in the view model’s collision extension. Notifications provide immediate user feedback to maintain engagement.

- **Spawning & Scene Management:**
  - The system dynamically spawns entities with proper distribution and utilizes scene setup logic to create aesthetically pleasing and functionally responsive environments.

## User Stories
1. **As a user**, I want to start an immersive simulation so that I can interact with ADCs and cancer cells in a realistic VisionOS 2 environment.
2. **As a system**, ADC entities should move smoothly, adjust trajectories dynamically based on collisions, and notify the user of significant impacts.
3. **As a developer**, the codebase must be modular, using clear separations for ADC movement, collision detection, notifications, scene setup, and spawning.

## Testing & Validation
- **Unit Testing:** Each module (ADC, Collisions, Notifications, SceneSetup, Spawning) should have clearly defined unit tests.
- **Integration Testing:** Validate the interactions between the view, view model, and underlying systems to ensure the state updates are reflected in the UI.
- **Performance Testing:** Ensure that the ECS setup performs efficiently on VisionOS 2 devices, particularly in real-time rendering and animation updates.

## Risks & Considerations
- **Versioning:** Close attention needed to align with VisionOS 2 updates and RealityKit ECS changes.
- **Complexity in State Management:** Ensure that state changes using @Observable are carefully managed to avoid race conditions or UI lag.
- **Component Interaction:** Testing path calculations and collision detection thoroughly to avoid unexpected behavior during high load or complex scenes.

## Conclusion
This PRD outlines the modular design and key functional elements of the AttackCancer feature built for VisionOS 2. By following Apple’s best practices, leveraging SwiftUI’s new state management, and adopting RealityKit’s ECS design, the system creates a highly engaging, interactive experience. The reviewed file structure demonstrates a strong separation of concerns and a scalable architecture, ensuring that the application is maintainable and extendable for future enhancements.

*End of Document*
