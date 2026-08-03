## Contact Events

*13 Feb 2026*

When are contact events fired relative to the physics simulation cycle? We can subscribe to contact and physics simulation events, log them, and see what happens:

```swift
contactBegan = scene.subscribe(to: CollisionEvents.Began.self) { event in
    print("🔴 CollisionEvents.Began")
}

willSimulate = scene.subscribe(to: PhysicsSimulationEvents.WillSimulate.self) { event in
    print("🟢 PhysicsSimulationEvents.WillSimulate")
}

didSimulate = scene.subscribe(to: PhysicsSimulationEvents.DidSimulate.self) { event in
    print("🟡 PhysicsSimulationEvents.DidSimulate")
}
```

The console prints something like this:

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

Contacts fire between `willSimulate` and `didSimulate`, i.e. during the physics step. In order to act and disambiguate through *all* contact events, events can be stored then processed in the **next** `willSimulate`.