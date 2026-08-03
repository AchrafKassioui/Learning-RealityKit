## FOV& Hit Detection

*1 Feb 2026*

When the camera field of view orientation is set to horizontal, ARView hit detection no longer works.

```swift
func createCamera() {
    let camera = Entity()
    camera.name = "Camera"
    var perspective = PerspectiveCameraComponent()
    /// Use vertical FOV for ARView hit detection
    /// ARView `entity(at:)` doesn't work with `.horizontal`
    perspective.fieldOfViewOrientation = .horizontal
    perspective.fieldOfViewInDegrees = 60
    camera.components.set(perspective)
}

override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
    for touch in touches {
        let hits = entities(at: touch.location(in: self))
        guard let hitEntity = hits.first(where: { $0.name != "Camera" }) else {
            print("No entity hit")
            return
        }

        print(hitEntity.name)
    }
}
```

ARView hit detection methods such as `entity(at:)` and `entities(at:)` seem to only work when `fieldOfViewOrientation` is set to `.vertical`.