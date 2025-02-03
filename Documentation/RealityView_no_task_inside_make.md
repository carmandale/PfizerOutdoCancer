Yes, having a Task block inside a RealityView immersive scene’s make closure can be problematic, depending on what you’re trying to achieve. Here’s why:

1. make is Called Once, While Task is Asynchronous
	•	The make closure in RealityView is responsible for constructing the scene and is only called once when the view is created.
	•	If you launch a Task inside make, it runs asynchronously and may lead to race conditions or unexpected behavior.

2. Potentially Blocking the Main Thread
	•	RealityView expects make to return quickly, as it’s part of the SwiftUI view lifecycle.
	•	If you run a long asynchronous operation inside make, it could delay rendering the scene, making the experience feel sluggish.

3. Scene Updates Should Happen Outside make
	•	If the Task modifies entities in the scene (e.g., loading assets, fetching data, or adding elements dynamically), those updates should typically be handled in the update closure or in a @State/@Observable object outside of make.

4. Losing Reference to Entities
	•	If you create entities inside make and then modify them inside the Task, you may run into issues where those changes don’t properly persist because RealityView does not continuously track async updates inside make.

Better Approach

Instead of placing a Task inside make, you can:
	1.	Use a ViewModel (@Observable) to manage asynchronous tasks and update the scene when data loads.
	2.	Perform async operations in update rather than make.
	3.	Use an onAppear in SwiftUI to trigger background tasks that modify the scene.

Example

struct MyImmersiveView: View {
    @State private var model = MyViewModel() // Handles async work

    var body: some View {
        RealityView { content in
            let rootEntity = Entity()
            content.add(rootEntity)

            // Don't launch a Task here, let the ViewModel handle async work
            model.loadAssets(rootEntity: rootEntity)
        }
    }
}

@Observable
class MyViewModel {
    func loadAssets(rootEntity: Entity) {
        Task {
            let newEntity = await fetchModelEntity()
            await MainActor.run {
                rootEntity.addChild(newEntity)
            }
        }
    }

    private func fetchModelEntity() async -> Entity {
        // Simulate async asset loading
        return Entity()
    }
}

When is Task Inside make Acceptable?

If you’re doing something trivial and self-contained (like a simple delay for animation), it might be okay, but for anything that affects the scene state or involves external async operations, move it out of make.

Let me know if you need help refactoring your code for best practices!