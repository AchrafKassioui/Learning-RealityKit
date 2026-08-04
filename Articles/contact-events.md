# Contact Events

*13 Feb 2026*

RealityKit has many event-based APIs. Contact events are events emitted by the physics engine when two physics bodies set to collide do actually collide. Contact events are of different kinds, such as contact began and contact ended.

Below are two tests to understand contact detection in RealityKit:

- A test file that demonstrates how to emit contact events between entities that can visually overlap.
- A test that clarifies the order, within the update loop, with which contact events are delivered.

## Sensor Entities

In RealityKit, entities emit contact events only if their CollisionFilter mask include each other. For example:

```swift
absolute minmal code that demsonsatrte coollision filter setup of two contacting enreitiers
```

What if I need to detect intersection without having physical collision? ContactDetection.swift demonstrates a solution:

- Create a sensor entity parented to the entity with the physics body.
- The sensor entity has a collision component but no physics body component.
- Configure collision filters as needed.

https://github.com/user-attachments/assets/9f50492d-2dab-4e9d-b252-3782cadaf706

<video src="../Media/RealityKit Sensor Entity.mov" width="33%" controls=""></video>

[Watch the sensor collision video](../Media/RealityKit Sensor Entity.mov)

## Contact Event Order

In the context of game development and interactive apps that are built around the update loop, it's crucial to understand the order of events. For example, some code must run strictly before or after the physics engine simulate one step.

I'm interested in knowing when contact events are fired, relative to the physics step. We can establish that empirically by subscribing to both contact and physics simulation events, log them, and see what happens:

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

In this test, `CollisionEvents.Began` callbacks were delivered after `WillSimulate` and before `DidSimulate`. They occurred within the simulation-step interval.

To process all contacts delivered during one step, the callbacks can accumulate the events in a collection. That collection can then be processed in `DidSimulate`, after the current step, or in the following `WillSimulate`, immediately before the next step.
