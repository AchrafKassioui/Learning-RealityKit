# Physics Speed

*29 Dec 2025*

Physics speed can be controlled with the `clock` property of `PhysicsSimulationComponent` using `CMTimebase`. Physics speed does not change the delta time between physics ticks. RealityKit physics timestep is fixed at 1/60s. What changes is how frequently those 60Hz ticks happen in real-world time.

```swift
/// The parent entity of the local simulation
let anchor = AnchorEntity()
scene.addAnchor(anchor)

/// Get the system's clock
let sourceClock = CMClock.hostTimeClock

/// Create a controllable timebase from source clock
/// A timebase can be paused, sped up, or slowed down
var timebase: CMTimebase?
let status = CMTimebaseCreateWithSourceClock(
    allocator: kCFAllocatorDefault, // Use default memory allocator
    sourceClock: sourceClock, // Base it on the host clock
    timebaseOut: &timebase // Output the created timebase
)

guard status == noErr, let physicsTimebase = timebase else {
    return print("\(self) - Physics Timebase creation failed")
}

/// Set the playback rate
/// - rate = 1.0: Real-time (default)
/// - rate = 0.5: Half speed (slow motion)
/// - rate = 2.0: Double speed (fast forward)
/// - rate = 0.0: Paused
///
/// Example with rate = 2.0:
/// In 1 real-world second, physics executes 120 steps (2× the normal 60)
/// Each step still simulates 1/60s of physics time
/// Result: 2 seconds of physics simulation in 1 real-world second
CMTimebaseSetRate(physicsTimebase, rate: 2.0)

/// Apply the custom timebase to physics simulation
var physicsSimulation = PhysicsSimulationComponent()
physicsSimulation.clock = physicsTimebase
anchor.components.set(physicsSimulation)

/// Now all physics bodies in this simulation will run at the specified speed
```
