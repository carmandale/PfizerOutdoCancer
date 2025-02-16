# Pfizer Outdo Cancer App Architecture

## Application Flow and Components

```mermaid
graph TB
    subgraph App["PfizerOutdoCancerApp"]
        AppModel["AppModel (@Observable)"]
        AppPhases["Application Phases"]
    end

    subgraph Phases["Game Phases"]
        Loading["Loading"]
        Intro["Intro"]
        Lab["Lab"]
        Building["Building"]
        Playing["Playing"]
        Completed["Completed"]
        Outro["Outro"]
    end

    subgraph Windows["Window Management"]
        MainWindow["Main Window"]
        IntroWindow["Intro Window"]
        LibraryWindow["Library Window"]
        BuilderWindow["Builder Window"]
        NavWindow["Navigation Window"]
        CompletedWindow["Completed Window"]
        HopeMeterWindow["Hope Meter Window"]
    end

    subgraph ImmersiveSpaces["Immersive Spaces"]
        IntroSpace["Intro Space"]
        OutroSpace["Outro Space"]
        LabSpace["Lab Space"]
        BuildingSpace["Building Space"]
        AttackSpace["Attack Space"]
    end

    subgraph ViewModels["View Models"]
        IntroVM["IntroViewModel"]
        LabVM["LabViewModel"]
        AttackVM["AttackCancerViewModel"]
    end

    subgraph Systems["RealityKit Systems"]
        ADCSystem["ADC Movement System"]
        CancerSystem["Cancer Cell System"]
        AttachSystem["Attachment System"]
        SpeedSystem["Speed Boost System"]
    end

    subgraph Components["RealityKit Components"]
        ADCComp["ADC Component"]
        CancerComp["Cancer Cell Component"]
    end

    AppModel --> AppPhases
    AppPhases --> Phases
    AppModel --> Windows
    AppModel --> ImmersiveSpaces
    AppModel --> ViewModels
    
    ViewModels --> Systems
    Systems --> Components

    Loading --> Intro
    Intro --> Lab
    Lab --> Building
    Building --> Playing
    Playing --> Completed
    Completed --> Outro

    style AppModel fill:#f9f,stroke:#333,stroke-width:2px
    style Systems fill:#bbf,stroke:#333,stroke-width:2px
    style Components fill:#bfb,stroke:#333,stroke-width:2px
    style ViewModels fill:#fbf,stroke:#333,stroke-width:2px
    style Windows fill:#fbb,stroke:#333,stroke-width:2px
    style ImmersiveSpaces fill:#bff,stroke:#333,stroke-width:2px
```

## Key Features

1. **State Management**
   - Uses `@Observable` for reactive state management
   - Centralized `AppModel` for app-wide state
   - Phase-based navigation system

2. **Window Management**
   - Multiple windows for different app sections
   - Utility windows for game mechanics
   - Navigation window for debug/development

3. **Immersive Spaces**
   - Dedicated spaces for different game phases
   - Smooth transitions between spaces
   - Asset management per space

4. **RealityKit Integration**
   - Entity Component System (ECS) architecture
   - Custom components for game objects
   - Specialized systems for movement and interactions

5. **UI/UX**
   - SwiftUI for 2D interfaces
   - RealityKit for 3D content
   - Smooth animations and transitions
   - Glass background effects

6. **Asset Management**
   - Dynamic asset loading/unloading
   - Phase-specific resource management
   - Memory optimization

## Architecture Notes

- The app follows a phase-based architecture where each phase (Intro, Lab, Building, etc.) has its own immersive space and UI components
- State management is handled through the `@Observable` AppModel
- RealityKit's ECS is used for 3D content and game mechanics
- Windows and views are managed through SwiftUI
- Asset loading is optimized per phase to manage memory usage
