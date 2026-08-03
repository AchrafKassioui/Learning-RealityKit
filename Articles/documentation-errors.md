# Documentation Errors

Below are errors and typos found in the [RealityKit official documentation](https://developer.apple.com/documentation/realitykit).

## ShaderGraphMaterial

7 Feb 2026

In [ShaderGraphMaterial](https://developer.apple.com/documentation/realitykit/shadergraphmaterial): the Overview section has presentation errors:

<img src="../Media/RealityKit - Documentation Issue - ShaderGraphMaterial.png" alt="RealityKit - Documentation Issue - ShaderGraphMaterial" style="width:100%;" />

**Update 3 Aug 2026**: Fixed after WWDC 2026.

## CollisionFilter

*1 Feb 2026*

```swift
let cameraShape = ShapeResource.generateSphere(radius: 0.1)
var cameraCollision = CollisionComponent(
    shapes: [cameraShape],
    filter: CollisionFilter(
        group: CollisionMasks.camera,
        mask: [CollisionMasks.content, CollisionMasks.ui] // option+click `mask`
    )
)
camera.components.set(cameraCollision)
```

Option+Click the mask parameter of CollisionFilter to bring up Xcode documentation. It reads:

> Collision filters are created for the collision group specified in the group parameter. The mask parameter defines which objects will collide with the objects that use this filter. Because CollisionGroup conforms to OptionSet, you can specify any combination of collision groups in the mask parameter by using the various OptionSet methods like CollisionGroup/union(_:), CollisionGroup/subtracting(_:), and CollisionGroup/intersection(_:). Entities from any group contained in mask will collide with entities using this filter, while those not contained by mask will not.
>
> To combine multiple groups into a filter, use the CollisionGroup/union(_:) method, like this:
>
> ```swift
> let groupA = CollisionGroup(rawValue: 1 << 0)
> let groupB = CollisionGroup(rawValue: 1 << 1)
> let groupC = CollisionGroup(rawValue: 1 << 2)
> 
> // Create a filter that collides with A and C, but not B
> let theFilter = CollisionFilter(group: groupA, mask: groupA.union(groupB))
> ```

The code contradicts its comment: the mask contains groups A and B rather than groups A and C. The example should be:

```swift
// Create a filter that collides with A and C, but not B
let theFilter = CollisionFilter(group: groupA, mask: groupA.union(groupC))
```
