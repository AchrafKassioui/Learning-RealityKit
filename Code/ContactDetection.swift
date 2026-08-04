/**
 
 # Contact Detection
 
 ✅ Reviewed.
 
 How to detect contact between entities that can intersect?
 In technical terms: if two entities have collision filters that exclude each other, do they still emit collision events when they overlap?
 Answer: no.
 
 ## Sensor Entities
 
 A solution is to make special trigger entities.
 
 - Create a sensor entity parented to the entity with the physics body.
 - The sensor entity has a collision component but no physics body component.
 - Configure its collision filter as needed.
 
 ## Trigger Volume
 
 RealityKit also has a TriggerVolume entity dedicated to this use case:
 https://developer.apple.com/documentation/realitykit/triggervolume
 Note: Trigger volumes do not contact each other.
 
 ## Setup
 
 In the experiment below:
 - Entities A and B do not collide with each other.
 - Entity A (red) has a child sensor entity, which is configured to detect collisions with the group of entity B.
 - Entity A changes color when its sensor detects contact with entity B.
 - The sensor entity can have any collision shape needed.
 
 Achraf Kassioui
 Created 3 Feb 2026
 Updated 4 Aug 2026
 
 */
import SwiftUI
import RealityKit
import Combine

// MARK: View

struct ContactDetectionView: View {
    var body: some View {
        ZStack {
            ContactDetectionRepresentable()
                .ignoresSafeArea()
            
            VStack {
                Text("Contact Detection")
                    .font(.headline)
                    .padding()
                    .background(.ultraThinMaterial)
                    .cornerRadius(8)
                Spacer()
                Text("Watch Xcode console for collision events")
                    .font(.caption)
                    .padding()
                    .background(.ultraThinMaterial)
                    .cornerRadius(8)
            }
            .padding()
        }
    }
}

#Preview {
    ContactDetectionView()
}

// MARK: Representable

struct ContactDetectionRepresentable: UIViewRepresentable {
    func makeUIView(context: Context) -> UIView {
        return ContactDetectionARView(frame: .zero)
    }
    
    func updateUIView(_ uiView: UIView, context: Context) { }
}

// MARK: ARView

class ContactDetectionARView: ARView {
    
    struct CollisionGroups {
        static let groupA = CollisionGroup(rawValue: 1 << 0)
        static let groupB = CollisionGroup(rawValue: 1 << 1)
        static let sensor = CollisionGroup(rawValue: 1 << 2)
        static let trigger = CollisionGroup(rawValue: 1 << 3)
    }
    
    private var anchor: AnchorEntity!
    private var entityA: ModelEntity!
    private var entityB: ModelEntity!
    
    private var normalMaterial: SimpleMaterial!
    private var glowMaterial: PhysicallyBasedMaterial!
    
    private let oscillationSpeed: Float = 0.5
    private let oscillationBound: Float = 0.6
    private var movingRight = true
    
    private var collisionBegan: Cancellable?
    private var collisionEnded: Cancellable?
    private var updateLoop: Cancellable?
    
    // MARK: Init
    
    required init(frame: CGRect) {
        super.init(frame: frame)
        
        //debugOptions = [.showPhysics]
        
        setupMaterials()
        setupScene()
        setupCollisionEvents()
        setupAnimation()
        
        createTriggerVolumesTest()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: Scene
    
    private func setupMaterials() {
        /// Normal material (red)
        normalMaterial = SimpleMaterial()
        normalMaterial.color = .init(tint: .systemRed)
        
        /// Glow material (emissive)
        glowMaterial = PhysicallyBasedMaterial()
        glowMaterial.baseColor = .init(tint: .systemRed)
        glowMaterial.emissiveColor = .init(color: .systemOrange)
        glowMaterial.emissiveIntensity = 2.0
    }
    
    private func setupScene() {
        environment.background = .color(.lightGray)
        
        /// Anchor
        anchor = AnchorEntity()
        anchor.name = "Anchor"
        scene.addAnchor(anchor)
        
        var simulation = PhysicsSimulationComponent()
        simulation.gravity = [0, 0, 0]
        anchor.components.set(simulation)
        
        /// Camera
        cameraMode = .nonAR
        let camera = PerspectiveCamera()
        camera.look(at: [0, 0, 0], from: [0, 0, 2], relativeTo: nil)
        anchor.addChild(camera)
        
        // MARK: Entity A
        
        let meshA = MeshResource.generateBox(size: 0.3, cornerRadius: 0.02)
        
        entityA = ModelEntity(mesh: meshA, materials: [normalMaterial])
        entityA.name = "EntityA"
        
        let shapeA = ShapeResource.generateBox(size: [0.3, 0.3, 0.3])
        
        let collisionA = CollisionComponent(
            shapes: [shapeA],
            filter: CollisionFilter(
                group: CollisionGroups.groupA,
                mask: []
            )
        )
        entityA.components.set(collisionA)
        
        var bodyA = PhysicsBodyComponent(shapes: [shapeA], mass: 1, mode: .dynamic)
        bodyA.isAffectedByGravity = false
        entityA.components.set(bodyA)
        entityA.components.set(PhysicsMotionComponent())
        
        anchor.addChild(entityA)
        entityA.position = [-0.5, 0, 0]
        
        // MARK: Sensor
        
        let sensorMesh = MeshResource.generateSphere(radius: 0.05)
        let sensorMaterial = SimpleMaterial(color: .white.withAlphaComponent(0.1), isMetallic: false)
        let sensorShape = ShapeResource.generateSphere(radius: 0.05)
        //sensorShape = ShapeResource.generateConvex(from: sensorMesh)
        
        let sensorA = ModelEntity(mesh: sensorMesh, materials: [sensorMaterial])
        sensorA.name = "SensorA"
        let sensorACollision = CollisionComponent(
            shapes: [sensorShape],
            filter: .init(
                group: CollisionGroups.sensor,
                mask: [CollisionGroups.groupA, CollisionGroups.groupB]
            ),
        )
        sensorA.components.set(sensorACollision)
        entityA.addChild(sensorA)
        sensorA.position = [0, 0.15, 0]
        
        // MARK: Entity B
        
        let meshB = MeshResource.generateBox(size: 0.3, cornerRadius: 0.02)
        var materialB = SimpleMaterial()
        materialB.color = .init(tint: .systemBlue)
        
        entityB = ModelEntity(mesh: meshB, materials: [materialB])
        entityB.name = "EntityB"
        
        var shapeB = ShapeResource.generateBox(size: [0.3, 0.3, 0.3])
        shapeB = ShapeResource.generateConvex(from: meshB)
        
        let collisionB = CollisionComponent(
            shapes: [shapeB],
            filter: CollisionFilter(
                group: CollisionGroups.groupB,
                mask: [CollisionGroups.sensor]
            )
        )
        entityB.components.set(collisionB)
        
        var bodyB = PhysicsBodyComponent(shapes: [shapeB], mass: 1, mode: .dynamic)
        bodyB.isAffectedByGravity = false
        entityB.components.set(bodyB)
        entityB.components.set(PhysicsMotionComponent())
        
        anchor.addChild(entityB)
        entityB.position = [0.5, 0.325, 0]
    }
    
    // MARK: Trigger Volumes
    /**
     
     Test to see if trigger volumes emit collision events between each other.
     They are visually invisible, but they are animated and set to intersect.
     If RealityKit reports contact between them, the collision subscription prints a message in the console.
     
     */
    private func createTriggerVolumesTest() {
        let trigger1 = TriggerVolume(
            shape: ShapeResource.generateSphere(radius: 0.1),
            filter: CollisionFilter(
                group: [Self.CollisionGroups.trigger],
                mask: [Self.CollisionGroups.trigger]
            )
        )
        trigger1.name = "Trigger1"
        anchor.addChild(trigger1)
        trigger1.position = [-0.5, -0.5, 0]
        trigger1.move(to: Transform(translation: [-0.05, -0.5, 0]), relativeTo: nil, duration: 1)
        
        let trigger2 = TriggerVolume(
            shape: ShapeResource.generateSphere(radius: 0.1),
            filter: CollisionFilter(
                group: [Self.CollisionGroups.trigger],
                mask: [Self.CollisionGroups.trigger]
            )
        )
        trigger2.name = "Trigger2"
        anchor.addChild(trigger2)
        trigger2.position = [0.5, -0.5, 0]
        trigger2.move(to: Transform(translation: [0.05, -0.5, 0]), relativeTo: nil, duration: 1)
    }
    
    // MARK: Events
    
    private func setupCollisionEvents() {
        collisionBegan = scene.subscribe(to: CollisionEvents.Began.self) { [weak self] event in
            guard let self else { return }
            
            print("🟢 CONTACT BEGAN: \(event.entityA.name) <-> \(event.entityB.name)")
            
            /// Check if sensor is involved
            if event.entityA.name == "SensorA" || event.entityB.name == "SensorA" {
                setGlow(true)
            }
        }
        
        collisionEnded = scene.subscribe(to: CollisionEvents.Ended.self) { [weak self] event in
            guard let self else { return }
            
            print("🔴 CONTACT ENDED: \(event.entityA.name) <-> \(event.entityB.name)")
            
            /// Check if sensor is involved
            if event.entityA.name == "SensorA" || event.entityB.name == "SensorA" {
                setGlow(false)
            }
        }
    }
    
    // MARK: Glow Effect
    
    private func setGlow(_ enabled: Bool) {
        if enabled {
            entityA.model?.materials = [glowMaterial]
        } else {
            entityA.model?.materials = []
            entityA.model?.materials = [normalMaterial]
        }
    }
    
    // MARK: Animation
    
    private func setupAnimation() {
        /// Periodic oscillation using velocity reversal
        updateLoop = scene.subscribe(to: SceneEvents.Update.self) { [weak self] event in
            guard let self else { return }
            
            let posA = entityA.position.x
            let posB = entityB.position.x
            
            /// Reverse direction at bounds
            if posA > oscillationBound || posB < -oscillationBound {
                setVelocities(aMovesRight: false)
            } else if posA < -oscillationBound || posB > oscillationBound {
                setVelocities(aMovesRight: true)
            }
        }
        
        /// Start moving
        setVelocities(aMovesRight: true)
    }
    
    private func setVelocities(aMovesRight: Bool) {
        let velocityA: SIMD3<Float> = aMovesRight ? [oscillationSpeed, 0, 0] : [-oscillationSpeed, 0, 0]
        let velocityB: SIMD3<Float> = aMovesRight ? [-oscillationSpeed, 0, 0] : [oscillationSpeed, 0, 0]
        
        if var motionA = entityA.components[PhysicsMotionComponent.self] {
            motionA.linearVelocity = velocityA
            entityA.components.set(motionA)
        }
        
        if var motionB = entityB.components[PhysicsMotionComponent.self] {
            motionB.linearVelocity = velocityB
            entityB.components.set(motionB)
        }
        
        movingRight = aMovesRight
    }
}
