## Gravity

*4 Oct 2025*

To change the gravity of the physics simulation:

- Create a root entity and give it a PhysicsSimulationComponent
- Tweak the values of that component
- Add the simulated entities as child of that root entity

```swift
RealityView { content in
    let rootEntity = Entity()
    var physicsSimulationComponent = PhysicsSimulationComponent()
    physicsSimulationComponent.gravity = [0, -10, 0]
    rootEntity.components.set(physicsSimulationComponent)
    content.add(rootEntity)

    let box = Entity()
    // configure the entity
    rootEntity.addChild(box)
}
```

Or with ARView:

```swift
let arView = ARView()        
arView.cameraMode = .nonAR
arView.automaticallyConfigureSession = false
arView.environment.background = .color(.gray)

// Simulation root
let anchor = AnchorEntity()
var physicsSimulation = PhysicsSimulationComponent()
physicsSimulation.gravity = [0, -9.81, 0] // Change gravity here
anchor.components.set(physicsSimulation)
arView.scene.addAnchor(anchor)

// Child entity
let ground = Entity()
//..
anchor.addChild(ground)
```

An entity that has a PhysicsSimulationComponent becomes the root of an independent physics simulation. Multiple root entities can be created. But entities from each simulation cannot interact within the simulation. 