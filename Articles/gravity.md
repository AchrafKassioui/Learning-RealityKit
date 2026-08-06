## Gravity

*4 Oct 2025*

In RealityKit physics, gravity is enabled by default. To toggle gravity, we must use `PhysicsSimulationComponent`, configure it, and add it to the root entity of the simulation. Example with RealityView:

```swift
RealityView { content in
    /// The parent of the simulated entities
    let rootEntity = AnchorEntity()

    /// Configure gravity
    var physicsSimulationComponent = PhysicsSimulationComponent()
    physicsSimulationComponent.gravity = [0, -10, 0] /// 10m/s² on the Y axis
    rootEntity.components.set(physicsSimulationComponent)
    content.add(rootEntity)

    let box = ModelEntity()
    let floor = ModelEntity()
    /// Configure the entities...
    rootEntity.addChild(box)
    rootEntity.addChild(floor)
}
```

We can have multiple independent simulations. Each entity with a `PhysicsSimulationComponent` defines its own independent simulation island. Entities that are children of different simulation roots cannot interact with each other.

The `PhysicsSimulationComponent` can set other properties, such as joints solver iterations and physics speed.

Below is a full sample that changes the gravity of a simulation with an onscreen slider, using RealityView, a transient request component, and a gravity system.

https://github.com/user-attachments/assets/58c9008a-a31b-439f-94ab-d4103a008484

<video src="../Media/RealityKit-Gravity.mov" width="33%" controls=""></video>

```swift
import SwiftUI
import RealityKit
import Combine

// MARK: SwiftUI

struct GravityView: View {
    @State private var gravityY: Double = 0
    @State private var rootEntity = Entity()
    
    init() {
        GravityRequestComponent.registerComponent()
        GravitySystem.registerSystem()
    }
    
    var body: some View {
        ZStack(alignment: .bottom) {
            RealityView { content in
                /// Root of the local physics simulation.
                var physicsSimulation = PhysicsSimulationComponent()
                physicsSimulation.gravity = [0, Float(gravityY), 0]
                rootEntity.components.set(physicsSimulation)
                content.add(rootEntity)
                
                /// Camera
                let camera = Entity()
                camera.components.set(PerspectiveCameraComponent())
                camera.look(
                    at: [0, 0.5, 0],
                    from: [3, 2, 4],
                    relativeTo: nil
                )
                rootEntity.addChild(camera)
                
                /// Floor
                let floorSize: SIMD3<Float> = [10, 1, 10]
                let floorShape = ShapeResource.generateBox(size: floorSize)
                
                let floor = ModelEntity(
                    mesh: .generateBox(size: floorSize),
                    materials: [SimpleMaterial(color: .white, isMetallic: false)]
                )
                floor.components.set(CollisionComponent(shapes: [floorShape]))
                floor.components.set(PhysicsBodyComponent(mode: .static))
                floor.position = [0, -0.5, 0]
                
                rootEntity.addChild(floor)
                
                /// Sphere
                let sphereRadius: Float = 0.1
                let sphereShape = ShapeResource.generateSphere(radius: sphereRadius)
                
                let sphere = ModelEntity(
                    mesh: .generateSphere(radius: sphereRadius),
                    materials: [SimpleMaterial(color: .systemBlue, isMetallic: false)]
                )
                sphere.components.set(CollisionComponent(shapes: [sphereShape]))
                
                var physicsBody = PhysicsBodyComponent(
                    shapes: [sphereShape],
                    density: 1,
                    mode: .dynamic
                )
                physicsBody.isContinuousCollisionDetectionEnabled = true
                sphere.components.set(physicsBody)
                
                sphere.components.set(GroundingShadowComponent(castsShadow: true))
                
                sphere.position = [0, 1.5, 0]
                
                rootEntity.addChild(sphere)
                
            } update: { _ in
                /// Set a transient request component on the entity to update
                rootEntity.components.set(GravityRequestComponent(gravityY: Float(gravityY)))
            }
            .realityViewCameraControls(.orbit)
            .ignoresSafeArea()
            .background(.black)
            
            HStack {
                Text("Gravity")
                
                Slider(value: $gravityY, in: -9.8...1, step: 0.1)
                
                Text(
                    String(
                        format: "%.1f m/s²",
                        locale: Locale(identifier: "en_US_POSIX"),
                        gravityY
                    )
                )
                .monospacedDigit()
                .frame(width: 85, alignment: .trailing)
            }
            .padding()
            .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 12))
            .padding()
        }
    }
}

// MARK: Gravity ECS

struct GravityRequestComponent: TransientComponent {
    let gravityY: Float
}

class GravitySystem: System {
    
    let willSimulate: Cancellable
    
    required init(scene: RealityKit.Scene) {
        willSimulate = scene.subscribe(to: PhysicsSimulationEvents.WillSimulate.self, { event in
            Self.fixedUpdate(scene: scene, root: event.simulationRootEntity)
        })
    }
    
    static func fixedUpdate(scene: RealityKit.Scene, root: Entity?) {
        guard let rootEntity = root,
              let request = rootEntity.components[GravityRequestComponent.self],
              var physicsSimulation = rootEntity.components[PhysicsSimulationComponent.self] else {
            return
        }
        
        /// Apply gravity.
        physicsSimulation.gravity = [0, request.gravityY, 0]
        rootEntity.components.set(physicsSimulation)
        
        /// Remove the transient request component.
        rootEntity.components.remove(GravityRequestComponent.self)
    }
    
}

#Preview {
    GravityView()
}

```