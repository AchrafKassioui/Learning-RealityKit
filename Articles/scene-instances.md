# Scene Instances

*4 Feb 2026*

[Apple Documentation](https://developer.apple.com/documentation/realitykit/scene):

> You don’t create a `Scene` instance directly. Instead, you get the one and only scene associated with a view from the scene property of an `ARView` instance.

Unlike with SpriteKit, RealityKit scenes aren't created by the user. They are created and managed by the system. But who creates them? Can there be more than one scene at once? If I need to access the scene to perform an entity query or retrieve some data, how do I pass the right scene?

We can test this by creating a system, an ARView, and a RealityRenderer instance. Both ARView and RealityRenderer must have some instance of Scene in order to do RealityKit things. In the system's init, we can log the scene ID:

```swift
class TestSystem: System {
    
    required init(scene: RealityKit.Scene) {
        print(scene.id)
    }
    
}
```

We then register the system (outside ARView):

```swift
struct TestView: View {
    var body: some View {
        ZStack {
            //.. ARView here
        }
        .onAppear {
            TestSystem.registerSystem()
        }
}
```

Then, we create a RealityRenderer instance and update it:

```swift
let renderer = try RealityRenderer()
try renderer.update(timestep)
```

We observe  this:

- When ARView appears, a scene ID is logged
- When RealityRenderer starts updating, a *different* scene ID is logged
- If the ARView is somehow hidden then displayed again, a new scene ID is logged when ARView appears

Within the same app, there can be more than one scene instances. Registered systems will init once for every scene, and update every frame of every scene.

In my projects architecture, I was tempted to store a static reference to the scene inside a system, like this:

```swift
class TestSystem: System {

	private static weak var _scene: Scene?
    
    required init(scene: Scene) {
        Self._scene = scene
    }
    
    static func doSomething() {
        /// I wanted a reference to the scene here
        print(_scene)
    }
    
}
```

But that is not a good pattern. Not only will the scene instance change depending on context, but system's init is called lazily, so we cannot rely on the existence of `_scene` inside a static function of the system. Instead, I now pass a reference to the scene wherever it's needed:

```swift
class PhysicsSystem: System {
    
    required init(scene: Scene) {

    }
    
    /// Scene passed as an argument
    static func fixedUpdate(deltaTime: TimeInterval, in scene: Scene) {
        
    }
    
}
```

This enforces the architecture to be explicit about which scene is used along the whole callers' chain.