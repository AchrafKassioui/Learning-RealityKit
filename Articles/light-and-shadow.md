# Light & Shadow

*Created 22 Dec 2025, updated 11 Aug 2026*

## Environment Lighting

By default, `ARView` and `RealityView` apply image-based lighting (IBL) to their content. IBL uses an environment map, commonly known as HDRI, to illuminate and reflect the surrounding environment on virtual objects. 

https://github.com/user-attachments/assets/a5d864e2-b6bf-44d4-a7b3-e23b9c372716

<video src="../Media/RealityKit-IBL.mov" width="33%" controls=""></video>

`RealityRenderer` however does not apply any IBL by default. Non-emissive materials will appear black unless a light source is added.

In order to unify the environment lighting across all RealityKit renderers, we can use `ImageBasedLightComponent` and `ImageBasedLightReceiverComponent`. The first component holds the image. The second component specifies which entity tree is lit by the image. Example:

```swift
func setupIBL(holder: Entity, receiver: Entity) {
    Task {
        do {
            let iblResource = try await EnvironmentResource(named: "IBL007")
            var iblComponent = ImageBasedLightComponent(source: .single(iblResource))
            /// Whether the IBL inherits the rotation of the entity.
            iblComponent.inheritsRotation = true
            holder.components.set(iblComponent)
            receiver.components.set(ImageBasedLightReceiverComponent(imageBasedLight: holder))
        } catch {
            print(error)
        }
    }
}
```

```swift
RealityView { content in
    let anchor = AnchorEntity()
    content.add(anchor)

    setupIBL(holder: anchor, receiver: anchor)
}
```

`ARView` also has an environment property which we can use to specify IBL for that specific view:

```swift
class MyARView: ARView {
    
    required init(frame: CGRect) {
        super.init(frame: frame)
        
        Task {
            do {
                let environmentResource = try await EnvironmentResource(named: "black")
                /// ARView `environment` property
                environment.lighting.resource = environmentResource
            } catch {
                print("Could not load environment resource: \(error)")
            }
        }
        
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
}
```

## Environment Resource

What is "IBL007"? It's the name of the HDRI image used in this example, downloaded from [Leonid Altman](https://leonidaltman.gumroad.com/l/26-Free-Studio-HDRI-Maps)'s free pack. In order to create IBL resources for Xcode, follow the [excellent Twitter thread](https://x.com/AtarayoSD/status/1838133380455727451) by Yasuhito Nagatomo, and see the [documentation](https://developer.apple.com/documentation/realitykit/environmentresource):

> To add an environment resource to your Xcode project, make a folder with a name that ends in `.skybox` and place a single image inside. Ensure that the image is an environment map of equirectangular projection, also known as a *latitude-longitude projection*. Drag the folder into the Project navigator. In the options pane, choose to create a folder reference (not a group), and add the folder to your app’s targets. At build time, Xcode compiles the image for use as an environment resource and inserts the result into the app bundle.
>
> RealityKit supports the same input formats as Image I/O, such as `.png` and `.jpg` However, to achieve rich, vibrant lighting, use a `.exr` or `.hdr` format, which support a wide dynamic range.

Xcode project navigator would look like this:

<img src="../Media/Xcode-Skybox-Folder.png" alt="Xcode-Skybox-Folder" style="width:50%;" />

When I need a scene with no environment lighting, I use a [completely black environment resource](../Media/black.jpg).

## Dynamic Lights

In addition to IBL, we can add up to eight light sources in a RealityKit scene. These lights are called dynamic lights and are of three types: point light, directional light, and spot light. Here is an example with [directional light](https://developer.apple.com/documentation/realitykit/directionallightcomponent):

```swift
/// Create an entity that will hold the light
let lightEntity = Entity()
/// Choose from the available lighting components
let directionalLight = DirectionalLightComponent(
    color: .white,
    intensity: 1000
)
lightEntity.components.set(directionalLight)
/// Position the light
lightEntity.look(at: [0, 0, 0], from: [3, 5, -2], relativeTo: nil)
/// Add to the scene
content.add(lightEntity)
```

https://github.com/user-attachments/assets/be655d2a-4861-4503-9cdc-cea9072e8620

<video src="../Media/RealityKit-DirectLight.mov" width="33%" controls=""></video>

## Shadows

Lights don't cast shadows by default. In order to cast shadows, an additional component must be added to the light entity:

```swift
/// Use the corresponding shadow component for each type of light
let shadowComponent = DirectionalLightComponent.Shadow()
lightEntity.components.set(shadowComponent)
```

https://github.com/user-attachments/assets/a96ce3be-a61f-41a6-8ab0-cca566f6f556

<video src="../Media/RealityKit-Shadows.mov" width="33%" controls=""></video>

A specific entity can be excluded from casting shadows using `DynamicLightShadowComponent`:

```swift
let entityDoesNotCastShadow = ModelEntity()
entityDoesNotCastShadow.components.set(DynamicLightShadowComponent(castsShadow: false))
```

The quality of the shadows can be tweaked with `maximumDistance`:

```swift
var shadowComponent = DirectionalLightComponent.Shadow()
shadowComponent.shadowProjection = .automatic(maximumDistance: 2)
```

Increasing the value allows more distant objects from the camera to cast shadows, but at the expense of quality and precision. If your design allows, you can dynamically change that value to match the camera distance from your main content.

https://github.com/user-attachments/assets/147f8c67-0388-4b1a-967f-568c2009994d

<video src="../Media/RealityKit-ShadowDistance.mp4" width="33%" controls=""></video>

## Links

- Download the full scene code [here](../Code/LightAndShadow.swift), the HDRI image [here](../Media/HDRI_007_1024x512.exr), and the teapot model [here](../Media/teapot.usdz).
- Shuichi Tsutsumi, [Teapot USDZ model](https://github.com/shu223/ARKit-Sampler/blob/master/usdz/teapot.usdz).
- Related [StackOverflow question](https://stackoverflow.com/questions/77930684/realitykit-incorrect-shadows-with-directional-light) this article answers.