# Contact Events

*13 Feb 2026*

RealityKit has many event-based APIs. Contact events are events emitted by the physics engine when two collision shapes intersect. Contact events are of different kinds, such as contact began and contact ended.

I'm interested in two aspects:

- How do I emit contact events between entities that have physics bodies without them actually colliding (pushing each other apart)?
- What is the order of contact event delivery, so I can organize logic within the update loop?

## Sensor Entities

In RealityKit, two entities can generate contact events when each entity's collision mask contains the other entity's collision group. For example:

```swift
let redEntity = Entity()
let blueEntity = Entity()

/// Bitmasks
let redGroup = CollisionGroup(rawValue: 1 << 0)
let blueGroup = CollisionGroup(rawValue: 1 << 1)

/// Collision shape
let shape = ShapeResource.generateBox(size: SIMD3(repeating: 0.2))

/// The red entity belongs to the red group and accepts contacts from the blue group.
redEntity.components.set(
    CollisionComponent(
        shapes: [shape],
        filter: CollisionFilter(group: redGroup, mask: blueGroup)
    )
)

/// The blue entity belongs to the blue group and accepts contacts from the red group.
blueEntity.components.set(
    CollisionComponent(
        shapes: [shape],
        filter: CollisionFilter(group: blueGroup, mask: redGroup)
    )
)
```

Contact events require a `CollisionComponent`. They do not require a `PhysicsBodyComponent`. In my projects, I have entities with physics bodies that are set to intersect with each other. So they wouldn't emit contact events. Yet I still need to detect when they intersect, in order to trigger some behavior. How to implement that?

The [ContactDetection](../Code/ContactDetection.swift) file demonstrates a full working solution:

- An invisible sensor child entity is added to a non colliding entity.
- The sensor entity has a collision component but no physics body component.
- The sensor entity collision filter is configured as needed.

https://github.com/user-attachments/assets/9f50492d-2dab-4e9d-b252-3782cadaf706

<video src="../Media/RealityKit-Sensor-Entity.mov" width="33%" controls=""></video>

In the video, we see a blue cube that intersects a hemisphere (the sensor), which emits an event, and triggers a color change on the red cube.

## Contact Event Order

In the context of game development and interactive apps that are built around the update loop, it's crucial to understand the order of events. For example, some code must run strictly before or after the physics engine simulate one step.

In which order are contact events delivered? We can find out empirically by subscribing to both contact and physics simulation events and logging them:

```swift
/// Event emitted when two bodies begin colliding
contactBegan = scene.subscribe(to: CollisionEvents.Began.self) { event in
    print("🔴 CollisionEvents.Began")
}

/// Event emitted before the physics engine computes a new step
willSimulate = scene.subscribe(to: PhysicsSimulationEvents.WillSimulate.self) { event in
    print("🟢 PhysicsSimulationEvents.WillSimulate")
}

/// Event emitted after the physics engine has completed one step
didSimulate = scene.subscribe(to: PhysicsSimulationEvents.DidSimulate.self) { event in
    print("🟡 PhysicsSimulationEvents.DidSimulate")
}
```

The console prints this:

```
🟢 PhysicsSimulationEvents.WillSimulate
🔴 CollisionEvents.Began
🔴 CollisionEvents.Began
🟡 PhysicsSimulationEvents.DidSimulate
🟢 PhysicsSimulationEvents.WillSimulate
🔴 CollisionEvents.Began
🔴 CollisionEvents.Began
🔴 CollisionEvents.Began
🔴 CollisionEvents.Began
🟡 PhysicsSimulationEvents.DidSimulate
🟢 PhysicsSimulationEvents.WillSimulate
🔴 CollisionEvents.Began
🔴 CollisionEvents.Began
🟡 PhysicsSimulationEvents.DidSimulate
🟢 PhysicsSimulationEvents.WillSimulate
🔴 CollisionEvents.Began
🔴 CollisionEvents.Began
🔴 CollisionEvents.Began
🔴 CollisionEvents.Began
🟡 PhysicsSimulationEvents.DidSimulate
```

In this test, `CollisionEvents.Began` callbacks were delivered after `WillSimulate` and before `DidSimulate`. They occurred within the simulation interval.

To process all contacts delivered during one step, the callbacks can accumulate the events in a collection. That collection can then be processed in `DidSimulate`, after the current step, or in the following `WillSimulate`, immediately before the next step.

## Update Order

When logic must run at a specific moment relative to the physics simulation, use `PhysicsSimulationEvents` rather than a rendering update callback such as `System.update(context:)`.

RealityKit has a `SystemUpdateCondition` to use with system update like this:

```swift
import RealityKit

class UpdateSystem: System {
    
    private static let query = EntityQuery(where: .has(MyComponent.self))
    
    required init(scene: RealityKit.Scene) {
        
    }
    
    func update(context: SceneUpdateContext) {
        // Note the `updatingSystemWhen`
        for entity in context.entities(matching: Self.query, updatingSystemWhen: .rendering) {
            // Update entity before rendering
        }
    }
    
}
```

The condition specifies what causes the system to update. But as of August 2026, the only available condition is `.rendering`. There is no other condition such as `.willSimulate`. Therefore the default system updates are rendering based.

In my physics-based projects, I create static fixed update functions, which are called by a `PhysicsSimulationEvents`:

```swift
import RealityKit
import Combine

class StartupSystem: System {
    
    /// Store the subscription
    private let willSimulate: Cancellable
    
    required init(scene: Scene) {
        // Subscribe to physics events
        willSimulate = scene.subscribe(to: PhysicsSimulationEvents.WillSimulate.self){ event in
            Self.fixedUpdate(deltaTime: event.deltaTime, in: scene)
        }
    }
    
    static func fixedUpdate(deltaTime: TimeInterval, in scene: Scene) {
        // Logic before each physics tick
    }
    
}
```

