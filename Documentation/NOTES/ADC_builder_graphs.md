graph TD
    A[Enter Step 0] --> B[Play VO]
    B --> C{VO Finished?}
    C -->|Yes| D[antibodyVOCompleted = true]
    D --> E[Enable Interaction]
    E --> F[User Selects Color]
    F --> G[User Clicks Checkmark]
    G --> H[antibodyStepCompleted = true]
    H --> I[Move to Step 1]
    
    J[Return to Step 0] -->|If antibodyStepCompleted| K[Skip VO]
    K --> L[Allow Color Change]