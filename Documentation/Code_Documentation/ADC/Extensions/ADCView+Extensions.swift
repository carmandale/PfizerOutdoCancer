# ADC View Extensions Documentation

This file extends the `View` protocol in SwiftUI to add functionality for getting the size of a view.

## `View` Extension

*   **Purpose:** Provides a way to get the size (CGSize) of a SwiftUI view.
*   **Key Features:**
    *   `getSizeOfView(_:)`: This method uses a `GeometryReader` and a custom `PreferenceKey` (`SizePreferenceKey`) to get the size of the view. The size is passed to a closure provided as an argument.

This extension is useful for situations where you need to know the dimensions of a view, for example, to dynamically adjust layout or perform calculations based on the view's size. The use of a `PreferenceKey` allows the size information to be passed up the view hierarchy. 