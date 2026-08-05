# FOV Orientation & Hit Detection

*1 Feb 2026*

ARView has convenience methods to do hit detection such as `entity(at:)` and `entities(at:)`. However, they only work if the camera FOV orientation is vertical.

To do hit detection with any FOV orientation, a custom ray cast is needed. Below is a full implementation of hit detection that works with any perspective camera.

https://github.com/user-attachments/assets/e1ccddd5-15ed-41ee-aa1f-8c2204674725

The video shows custom hit detection working regardless of FOV and orientation, unlike the built-in `entity(at:)`.

```swift
class RealityKitView: ARView {
    
    required init(frame: CGRect) {
        super.init(frame: frame)
        
        let anchor = AnchorEntity()
        scene.addAnchor(anchor)
        
        let camera = Entity()
        var perspective = PerspectiveCameraComponent()
        /// Use vertical FOV for ARView hit detection
        perspective.fieldOfViewOrientation = .horizontal
        camera.components.set(perspective)
        
        anchor.addChild(camera)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        for touch in touches {
            /// ARView `entity(at:)` doesn't work with `.horizontal`
            let hit = entity(at: touch.location(in: self))
        }
    }
    
}
```
