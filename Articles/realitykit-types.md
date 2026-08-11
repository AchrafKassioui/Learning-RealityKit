# Scene Type

*9 Feb 2026*

Both SwiftUI and RealityKit have a `Scene` type. In SwiftUI, `Scene` is used in the app entry point:

```swift
import SwiftUI

@main
struct MyApp: App {
    /// Scene type
    var body: some Scene {
        WindowGroup {
            HomeView()
        }
    }
}
```

In RealityKit, `Scene` is where content lives. The type is used in many places, for example to create a system:

```swift
import RealityKit

class MySystem: System {
    
    /// Init with a reference to the scene
    required init(scene: Scene) {
        
    }
    
}
```

If the file imports both RealityKit and SwiftUI, then the `Scene` type will require disambiguation. Use the module name as a prefix:

```swift
import SwiftUI
import RealityKit

class MySystem: System {
    
    /// Disambiguate the Scene type
    required init(scene: RealityKit.Scene) {
        
    }
    
}
```

I find it remarkable that the same generic `Scene` term is used in both frameworks without prefixes. Traditional Apple framework prefix their types, for example `SKScene` for a SpriteKit scene, or `UIView` for a UIKit view.

Are these prefix-free types destined to merge? Are they the last expected occurrence of `Scene` in an Apple framework?