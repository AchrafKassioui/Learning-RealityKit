## Light & Shadow

*22 Dec 2025*

### Environment Lighting

By default, RealityKit applies an image based light (commonly known as HDRI, or skybox). In order to override the default lighting, apply a black image instead:

```swift
class MyARView: ARView {
    
    required init(frame: CGRect) {
        super.init(frame: frame)
        
        Task {
            let iblResource = try await EnvironmentResource(named: "black")
            environment.lighting.resource = iblResource
        }
    }
    
}
```

See Yasuhito Nagatomo [excellent Twitter thread](https://x.com/AtarayoSD/status/1838133380455727451) on how to create environment lighting resources for RealityKit.

With RealityRenderer, unlike with ARView and RealityView, no environment lighting is applied by default. In order to setup image based lighting on the scene, use `ImageBasedLightComponent` and `ImageBasedLightReceiverComponent` on the content's parent entity:

```swift
/// The parent entity of your content
let anchor = AnchorEntity()

let iblResource = try await EnvironmentResource(named: "IBL007")
let iblComponent = ImageBasedLightComponent(
    source: .single(iblResource),
    intensityExponent: 0 // default value
)
anchor.components.set(iblComponent)
anchor.components.set(ImageBasedLightReceiverComponent(imageBasedLight: anchor))
```

If you need to match the rendering of ARView and RealityRenderer, make sure to supply the same IBL to the content you pass.

### Dynamic Lights

You can light a scene by adding a light component to an entity:

```swift
let lightEntity = Entity()
/// Choose from the available lighting components
let directionalLight = DirectionalLightComponent(
    color: .white,
    intensity: 1000
)
/// Position the light accordingly
lightEntity.look(at: [0, 0, 0], from: [3, 5, -2], relativeTo: nil)
lightEntity.components.set(directionalLight)
anchor.addChild(lightEntity)
```

### Shadows

If you want the light source to cast shadows, add the corresponding shadow component to it:

```swift
let shadowComponent = DirectionalLightComponent.Shadow()
lightEntity.components.set(shadowComponent)
```

If you want to opt out an entity from casting shadows, use the `DynamicLightShadowComponent`:

```swift
let entityDoesNotCastShadow = Entity()
entityDoesNotCastShadow.components.set(DynamicLightShadowComponent(castsShadow: false))
```

If you want to improve the quality of the shadows, use the `maximumDistance` parameter of the shadow component. For example:

```swift
let shadowComponent = DirectionalLightComponent.Shadow(maximumDistance: 5)
```

A maximum distance of 5 means no shadow will be rendered if the camera is farther than 5 meters from the expected shadows. The greater that value is, the poorer the shadow quality is. A maximum distance of 50m will draw shadows that are 50 meters away, but shadows that 1 or 2 meters away from the camera will have a poor quality. If you restrict the distance to 2 meters, the shadow will be much better, but no shadows will be drawn for distant objects.

A trick I use is to update the maximum distance according to the camera distance. Inside update:

```swift
let camera = // get the camera entity
let light = // get the light entity

let shadow = DirectionalLightComponent.Shadow(maximumDistance: camera.position.y)
light.components.set(shadow)
```

The code above would work well for a top down camera, in a scene where all content

### Links

- Complete [this question on StackOverflow](https://stackoverflow.com/questions/77930684/realitykit-incorrect-shadows-with-directional-light).