/**
 
 # Light & Shadow
 
 Achraf Kassioui
 Created 6 Aug 2026
 Updated 10 Aug 2026
 
 */
import SwiftUI
import RealityKit

// MARK: View

struct LightAndShadowView: View {
    @State private var rootEntity = Entity()
    @State private var lightEntity = Entity()
    @State private var cameraEntity = Entity()
    
    private let cameraPosition: SIMD3<Float> = [0, 0.6, 1.5]
    private let cameraTarget: SIMD3<Float> = [0, 0.3, 0]
    
    @State private var environmentLightIntensity: Double = 1
    @State private var directLightIntensity: Double = 0
    @State private var directLightColor: Color = .white
    @State private var shadowsAreEnabled = false
    @State private var shadowDistance: Double = 2
    
    private let labelWidth: CGFloat = 100
    private let sliderValueWidth: CGFloat = 50
    
    init() {
        LightingRequestComponent.registerComponent()
        LightingSystem.registerSystem()
    }
    
    var body: some View {
        ZStack() {
            RealityView { content in
                content.add(rootEntity)
                
                /// Add environment lighting request for the scene using the custom ECS.
                rootEntity.components.set(LightingRequestComponent(requests: [
                    .environmentLightIntensity(Float(environmentLightIntensity))
                ]))
                
                /// Camera
                cameraEntity.components.set(PerspectiveCameraComponent())
                cameraEntity.look(at: cameraTarget, from: cameraPosition, relativeTo: nil)
                rootEntity.addChild(cameraEntity)
                
                /// Directional light
                lightEntity.look(at: .zero, from: [3, 5, 1.5], relativeTo: nil)
                lightEntity.components.set(LightingRequestComponent(requests: [
                    .directLightIntensity(Float(directLightIntensity)),
                    .lightColor(DirectionalLightComponent.Color(directLightColor)),
                    .shadowsAreEnabled(shadowsAreEnabled),
                    .shadowDistance(Float(shadowDistance))
                ]))
                rootEntity.addChild(lightEntity)
                
                /// Floor
                var floorMaterial = PhysicallyBasedMaterial()
                floorMaterial.baseColor.tint = .systemBrown
                
                let floorMesh = MeshResource.generateBox(width: 1, height: 0.05, depth: 1, cornerRadius: 0.005)
                let floor = ModelEntity(mesh: floorMesh, materials: [floorMaterial])
                floor.position = [0, -0.025, 0]
                rootEntity.addChild(floor)
                
                /// Teapot
                guard let teapot = try? await ModelEntity(named: "teapot") else {
                    print("Could not load Teapot.usd")
                    return
                }
                
                var teapotMaterial = PhysicallyBasedMaterial()
                teapotMaterial.baseColor.tint = .white
                
                /// Optionally replace every material used by the imported mesh.
                if var modelComponent = teapot.model {
                    let materialCount = max(modelComponent.materials.count, 1)
                    modelComponent.materials = Array(repeating: teapotMaterial, count: materialCount)
                    //teapot.model = modelComponent
                }
                
                teapot.position = .zero
                teapot.transform.rotation = .init(angle: .pi, axis: [0, 1, 0])
                rootEntity.addChild(teapot)
            }
            .realityViewCameraControls(.orbit)
            .ignoresSafeArea()
            .background(Color(Material.Color.white))
            
            // MARK: Controls
            
            VStack {
                
                Spacer()
                
                VStack {
                    HStack {
                        Text("HDRI")
                            .frame(width: labelWidth, alignment: .leading)
                        
                        Slider(value: $environmentLightIntensity, in: 0...4, step: 0.1)
                            .onChange(of: environmentLightIntensity) { _, intensity in
                                /// Request ECS change.
                                var lightingRequestComponent = rootEntity.components[LightingRequestComponent.self] ?? LightingRequestComponent()
                                lightingRequestComponent.requests.append(.environmentLightIntensity(Float(intensity)))
                                rootEntity.components.set(lightingRequestComponent)
                            }
                        
                        Text(String(format: "%.1f", locale: Locale(identifier: "en_US_POSIX"), environmentLightIntensity))
                            .monospacedDigit()
                            .frame(width: sliderValueWidth, alignment: .trailing)
                    }
                    
                    HStack {
                        HStack(spacing: 8) {
                            Text("Light")
                            
                            Spacer()
                            
                            ColorPicker("Light Color", selection: $directLightColor, supportsOpacity: false)
                                .labelsHidden()
                                .onChange(of: directLightColor) { _, color in
                                    /// Request ECS change.
                                    var lightingRequestComponent = lightEntity.components[LightingRequestComponent.self] ?? LightingRequestComponent()
                                    lightingRequestComponent.requests.append(.lightColor(DirectionalLightComponent.Color(color)))
                                    lightEntity.components.set(lightingRequestComponent)
                                }
                        }
                        .frame(width: labelWidth)
                        
                        Slider(value: $directLightIntensity, in: 0...5000, step: 100)
                            .onChange(of: directLightIntensity) { _, intensity in
                                /// Request ECS change.
                                var lightingRequestComponent = lightEntity.components[LightingRequestComponent.self] ?? LightingRequestComponent()
                                lightingRequestComponent.requests.append(.directLightIntensity(Float(intensity)))
                                lightEntity.components.set(lightingRequestComponent)
                            }
                        
                        Text("\(Int(directLightIntensity.rounded()))")
                            .monospacedDigit()
                            .frame(width: sliderValueWidth, alignment: .trailing)
                    }
                    
                    Divider()
                    
                    Toggle("Shadows", isOn: $shadowsAreEnabled)
                        .onChange(of: shadowsAreEnabled) { _, isEnabled in
                            /// Request ECS change.
                            var lightingRequestComponent = lightEntity.components[LightingRequestComponent.self] ?? LightingRequestComponent()
                            lightingRequestComponent.requests.append(.shadowsAreEnabled(isEnabled))
                            
                            if isEnabled {
                                lightingRequestComponent.requests.append(.shadowDistance(Float(shadowDistance)))
                            }
                            
                            lightEntity.components.set(lightingRequestComponent)
                        }
                    
                    HStack {
                        Text("Distance")
                            .lineLimit(1)
                            .font(.system(size: 14))
                            .frame(width: labelWidth, alignment: .leading)
                        
                        Slider(value: $shadowDistance, in: 0...10, step: 0.1)
                            .onChange(of: shadowDistance) { _, distance in
                                /// Request ECS change.
                                var lightingRequestComponent = lightEntity.components[LightingRequestComponent.self] ?? LightingRequestComponent()
                                lightingRequestComponent.requests.append(.shadowDistance(Float(distance)))
                                lightEntity.components.set(lightingRequestComponent)
                            }
                        
                        Text(String(format: "%.1f", locale: Locale(identifier: "en_US_POSIX"), shadowDistance))
                            .monospacedDigit()
                            .frame(width: sliderValueWidth, alignment: .trailing)
                    }
                }
                .padding()
                .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 24))
            }
            .frame(maxWidth: 380)
            .padding()
        }
    }
}

#Preview {
    LightAndShadowView()
}

// MARK: Lighting Request

enum LightingRequest {
    case environmentLightIntensity(Float)
    case directLightIntensity(Float)
    case lightColor(DirectionalLightComponent.Color)
    case shadowsAreEnabled(Bool)
    case shadowDistance(Float)
}

struct LightingRequestComponent: Component {
    var requests: [LightingRequest] = []
}

// MARK: Lighting System

class LightingSystem: System {
    
    private static let lightingQuery = EntityQuery(where: .has(LightingRequestComponent.self))
    
    required init(scene: RealityKit.Scene) {}
    
    // MARK: Update
    
    func update(context: SceneUpdateContext) {
        for entity in context.entities(matching: Self.lightingQuery, updatingSystemWhen: .rendering) {
            guard let lightingRequestComponent = entity.components[LightingRequestComponent.self] else { continue }
            
            for request in lightingRequestComponent.requests {
                switch request {
                case .environmentLightIntensity(let intensity):
                    updateEnvironmentLight(on: entity, intensity: intensity)
                    
                case .directLightIntensity(let intensity):
                    var directionalLight = entity.components[DirectionalLightComponent.self] ?? DirectionalLightComponent(color: .white, intensity: 0)
                    
                    directionalLight.intensity = intensity
                    entity.components.set(directionalLight)
                    
                case .lightColor(let color):
                    var directionalLight = entity.components[DirectionalLightComponent.self] ?? DirectionalLightComponent(color: .white, intensity: 0)
                    
                    directionalLight.color = color
                    entity.components.set(directionalLight)
                    
                case .shadowsAreEnabled(let isEnabled):
                    if isEnabled {
                        entity.components.set(DirectionalLightComponent.Shadow())
                    } else {
                        entity.components.remove(DirectionalLightComponent.Shadow.self)
                    }
                    
                case .shadowDistance(let maximumDistance):
                    var shadowComponent = DirectionalLightComponent.Shadow()
                    shadowComponent.shadowProjection = .automatic(maximumDistance: 2)
                    if var shadow = entity.components[DirectionalLightComponent.Shadow.self] {
                        shadow.shadowProjection = .automatic(maximumDistance: maximumDistance)
                        entity.components.set(shadow)
                    }
                }
            }
            
            /// Remove transient component.
            entity.components.remove(LightingRequestComponent.self)
        }
    }
    
    // MARK: Update IBL
    
    private func updateEnvironmentLight(on entity: Entity, intensity: Float) {
        guard intensity > 0 else {
            /// A zero value disables image-based lighting.
            entity.components.set(ImageBasedLightComponent(source: .none))
            return
        }
        
        if var imageBasedLight = entity.components[ImageBasedLightComponent.self],
           case .single = imageBasedLight.source {
            /// RealityKit expresses IBL brightness as a base-two exponent.
            imageBasedLight.intensityExponent = log2(intensity)
            entity.components.set(imageBasedLight)
            return
        }
        
        Task {
            guard let environmentResource = try? await EnvironmentResource(named: "IBL007") else {
                print("Could not load environment resource")
                return
            }
            
            /// Apply image-based lighting to this entity and its descendants.
            entity.components.set(ImageBasedLightComponent(source: .single(environmentResource), intensityExponent: log2(intensity)))
            entity.components.set(ImageBasedLightReceiverComponent(imageBasedLight: entity))
        }
    }
    
}
