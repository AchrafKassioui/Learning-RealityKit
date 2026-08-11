## Systems

*23 Dec 2025*

To create a system:

```swift
class MySystem: System {
    
    /// Note how Scene is prefixed with the module name "RealityKit".
    /// This avoids confusion with SwiftUI's Scene.
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

        /// Register
        MySystem.registerSystem()
    }
    
    func updateUIView(_ uiView: ARView, context: Context) {}
}
```

Or in the app entry point:

```swift
@main
struct MyApp: App {    
    init() {
        MySystem.registerSystem()
    }
    
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}
```

Once registered, systems will work in all scenes instantiated by the app. Like `System`, `Scene` is a type that we don't instantiate ourselves. A different Scene is instantiated wherever there is RealityKit content: in ARView, RealityView, or RealityRenderer.