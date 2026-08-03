## Systems

*23 Dec 2025*

To create a system:

```swift
class MySystem: System {
    
    /// Note how the Scene uses the full module name "RealityKit.Scene"
    /// instead of just "Scene". That is to avoid confusion with SwiftUI's Scene.
    required init(scene: RealityKit.Scene) {
        
    }
    
    func update(context: SceneUpdateContext) {
        // Do work
    }
    
}
```

Once the System class is defined, we do not create instances of the class. Instead, we register the system somewhere in the code base. Typically, a system would be registered before RealityKit content is added. For example in the ARView setup code:

```swift
struct RepresentableARView: UIViewRepresentable {
    func makeUIView(context: Context) -> ARView {
        let arView = ARView(frame: .zero)

        /// Register a custom system
        OfflineSystem.registerSystem()
    }
    
    func updateUIView(_ uiView: ARView, context: Context) {}
}
```

Once registered, the system will work in all scenes of the code base. Like a System, a Scene is a type that we don't instantiate ourselves. A Scene is instantiated anywhere RealityKit content would live: in ARView, RealityView, or RealityRenderer.