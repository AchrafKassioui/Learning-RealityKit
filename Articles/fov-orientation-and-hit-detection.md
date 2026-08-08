# FOV Orientation & Hit Detection

*1 Feb 2026*

ARView has convenience methods to do hit detection such as `entity(at:)` and `entities(at:)`. However, they only work if the camera field of view orientation is vertical. To do hit detection with any FOV orientation, a custom ray cast is needed.

https://github.com/user-attachments/assets/e1ccddd5-15ed-41ee-aa1f-8c2204674725

<video src="../Media/RealityKit-FOV-Orientation-Hit-Detection.mov" width="33%" controls=""></video>

The video shows custom hit detection working regardless of FOV and orientation, unlike the built-in `entity(at:)`.

Below is a full implementation of hit detection that works with any perspective camera. It converts ARView touch position into normalized screen coordinates, constructs a ray using the camera's FOV and orientation, transforms that ray into world space, and passes it to `Scene.raycast`.

```swift
/**
 
 # FOV Orientation & Hit Detection
 
 Achraf Kassioui
 Created 15 July 2026
 Updated 6 Aug 2026
 
 */
import SwiftUI
import RealityKit

// MARK: SwiftUI

struct FOVOrientationView: View {
    @State private var fieldOfView: Float = 60 /// Degrees
    @State private var fieldOfViewIsHorizontal = true
    @State private var useCustomHitDetection = false
    
    init() {
        FOVCameraRequestComponent.registerComponent()
        FOVCameraSystem.registerSystem()
    }
    
    var body: some View {
        ZStack(alignment: .bottom) {
            FOVOrientationRepresentable(
                fieldOfView: fieldOfView,
                fieldOfViewIsHorizontal: fieldOfViewIsHorizontal,
                useCustomHitDetection: useCustomHitDetection
            )
            .ignoresSafeArea()
            
            VStack(spacing: 12) {
                Toggle("Horizontal FOV", isOn: $fieldOfViewIsHorizontal)
                
                Toggle("Custom Hit Detection", isOn: $useCustomHitDetection)
                
                HStack {
                    Text("FOV")
                    
                    Slider(value: $fieldOfView, in: 1...120)
                    
                    Text("\(Int(fieldOfView))°")
                        .monospacedDigit()
                        .frame(width: 40, alignment: .trailing)
                }
            }
            .padding()
            .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 12))
            .padding()
        }
    }
}

#Preview {
    FOVOrientationView()
}

// MARK: Representable

struct FOVOrientationRepresentable: UIViewRepresentable {
    let fieldOfView: Float
    let fieldOfViewIsHorizontal: Bool
    let useCustomHitDetection: Bool
    
    func makeUIView(context: Context) -> FOVOrientationARView {
        let view = FOVOrientationARView(frame: .zero)
        update(view)
        return view
    }
    
    func updateUIView(_ view: FOVOrientationARView, context: Context) {
        update(view)
    }
    
    private func update(_ view: FOVOrientationARView) {
        /// Update hit detection mode
        view.useCustomHitDetection = useCustomHitDetection
        
        /// Update camera entity
        view.camera.components.set(
            FOVCameraRequestComponent(
                fieldOfView: fieldOfView,
                fieldOfViewIsHorizontal: fieldOfViewIsHorizontal
            )
        )
    }
}

// MARK: Camera System

struct FOVCameraRequestComponent: Component {
    let fieldOfView: Float
    let fieldOfViewIsHorizontal: Bool
}

class FOVCameraSystem: System {
    
    static let query = EntityQuery(where: .has(FOVCameraRequestComponent.self))
    
    required init(scene: RealityKit.Scene) {}
    
    func update(context: SceneUpdateContext) {
        for entity in context.entities(matching: Self.query, updatingSystemWhen: .rendering) {
            guard let request = entity.components[FOVCameraRequestComponent.self],
                  var camera = entity.components[PerspectiveCameraComponent.self] else {
                entity.components.remove(CameraRequestComponent.self)
                continue
            }
            
            /// Apply the requested camera configuration.
            camera.fieldOfViewInDegrees = request.fieldOfView
            camera.fieldOfViewOrientation = request.fieldOfViewIsHorizontal ? .horizontal : .vertical
            
            entity.components.set(camera)
            
            /// Remove the transient request component.
            entity.components.remove(CameraRequestComponent.self)
        }
    }
    
}

// MARK: ARView

class FOVOrientationARView: ARView {
    
    let camera = Entity()
    private var highlightedEntity: ModelEntity?
    private var modelBeforeHighlight: ModelComponent?
    var useCustomHitDetection = true
    
    // MARK: Init
    
    required init(frame: CGRect) {
        super.init(frame: frame)
        
        cameraMode = .nonAR
        automaticallyConfigureSession = false
        environment.background = .color(.darkGray)
        
        setupScene()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: Content
    
    private func setupScene() {
        /// Root
        let anchor = AnchorEntity()
        scene.addAnchor(anchor)
        
        /// Camera
        var perspective = PerspectiveCameraComponent()
        perspective.fieldOfViewInDegrees = 60
        camera.components.set(perspective)
        camera.look(at: .zero, from: [0, 0, 2], relativeTo: nil)
        anchor.addChild(camera)
        
        let boxSize: SIMD3<Float> = [0.15, 0.6, 1]
        let boxShape = ShapeResource.generateBox(size: boxSize)
        
        /// Red box
        let redBox = ModelEntity(
            mesh: .generateBox(size: boxSize, cornerRadius: 0.03),
            materials: [SimpleMaterial(color: .systemRed, isMetallic: false)]
        )
        redBox.name = "Red Box"
        redBox.position = [-0.2, 1, 0]
        
        redBox.components.set(CollisionComponent(shapes: [boxShape]))
        anchor.addChild(redBox)
        
        /// Blue box
        let blueBox = ModelEntity(
            mesh: .generateBox(size: boxSize, cornerRadius: 0.03),
            materials: [SimpleMaterial(color: .systemBlue, isMetallic: false)]
        )
        blueBox.name = "Blue Box"
        blueBox.position = [0.2, -1, 0]
        
        blueBox.components.set(CollisionComponent(shapes: [boxShape]))
        anchor.addChild(blueBox)
    }
    
    // MARK: Touch
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let touch = touches.first else { return }
        
        let touchLocation = touch.location(in: self)
        let hitEntity: Entity?
        
        if useCustomHitDetection {
            hitEntity = customHitTest(screenPoint: touchLocation, view: self, cameraEntity: camera).first?.entity
        } else {
            hitEntity = entity(at: touchLocation)
        }
        
        guard let hitEntity = hitEntity as? ModelEntity else {
            print("No entity hit")
            return
        }
        
        print("Hit \(hitEntity.name)")
        
        /// Highlight when the touch begins.
        highlightedEntity = hitEntity
        modelBeforeHighlight = hitEntity.model
        
        hitEntity.model?.materials = [
            SimpleMaterial(color: .systemYellow, isMetallic: false)
        ]
    }
    
    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        restoreHighlightedEntity()
    }
    
    override func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent?) {
        restoreHighlightedEntity()
    }
    
    /// Restores entity model.
    private func restoreHighlightedEntity() {
        if let modelBeforeHighlight {
            highlightedEntity?.model = modelBeforeHighlight
        }
        
        highlightedEntity = nil
        modelBeforeHighlight = nil
    }
    
}

// MARK: Custom Hit Detection
/**
 
 Casts a ray through a screen point using the supplied perspective camera.
 Unlike ARView hit detection, this handles both FOV orientations.
 
 */
func customHitTest(screenPoint: CGPoint, view: ARView, cameraEntity: Entity, mask: CollisionGroup = .all) -> [CollisionCastHit] {
    guard view.bounds.width > 0,
          view.bounds.height > 0,
          let camera = cameraEntity.components[PerspectiveCameraComponent.self] else {
        return []
    }
    
    let viewWidth = Float(view.bounds.width)
    let viewHeight = Float(view.bounds.height)
    let aspectRatio = viewWidth / viewHeight
    
    /// Convert UIKit coordinates into normalized device coordinates.
    let normalizedX = 2 * Float(screenPoint.x) / viewWidth - 1
    let normalizedY = 1 - 2 * Float(screenPoint.y) / viewHeight
    
    let halfFieldOfView = camera.fieldOfViewInDegrees * .pi / 360
    let tangentHalfWidth: Float
    let tangentHalfHeight: Float
    
    /// The field of view angle applies to the selected screen axis.
    switch camera.fieldOfViewOrientation {
    case .vertical:
        tangentHalfHeight = tan(halfFieldOfView)
        tangentHalfWidth = tangentHalfHeight * aspectRatio
        
    case .horizontal:
        tangentHalfWidth = tan(halfFieldOfView)
        tangentHalfHeight = tangentHalfWidth / aspectRatio
        
    @unknown default:
        print("Unsupported field of view orientation")
        return []
    }
    
    /// RealityKit cameras look along their local negative Z axis.
    let cameraDirection = normalize(
        SIMD3<Float>(
            normalizedX * tangentHalfWidth,
            normalizedY * tangentHalfHeight,
            -1
        )
    )
    
    /// Transform the camera space ray direction into world space.
    let worldDirection = cameraEntity.orientation(relativeTo: nil).act(cameraDirection)
    let worldOrigin = cameraEntity.position(relativeTo: nil)
    
    /// Return every collision shape intersected by the ray, nearest first.
    return view.scene.raycast(
        origin: worldOrigin,
        direction: worldDirection,
        length: 1_000, /// 1km
        query: .all,
        mask: mask,
        relativeTo: nil
    )
}

```
