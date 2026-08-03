## Scene Type

*9 Feb 2026*

Both SwiftUI and RealityKit have a `Scene` type. In SwiftUI, `Scene` is used in the app entry point:

```swift
import SwiftUI

@main
struct MyApp: App {
    var body: some Scene { /// Scene type
        WindowGroup {
            HomeView()
        }
    }
}
```

In RealityKit, `Scene` is where 3D content lives. RealityKit Scene is used in many places, for example to create a system:

```swift
import RealityKit

class MySystem: System {
    
    required init(scene: Scene) { /// Init with a reference to the scene
        
    }
    
}
```

If the code file imports both RealityKit and SwiftUI, then the Scene type will require disambiguation:

```swift
import SwiftUI
import RealityKit

class MySystem: System {
    
    required init(scene: RealityKit.Scene) { /// Disambiguate the Scene type
        
    }
    
}
```

I find it remarkable that the same generic Scene term is used in both frameworks without prefixes. Traditional Apple framework prefix their types, for example `SKScene` for a SpriteKit scene, or `UIView` for a UIKit view.

Are these prefix-free Scene destined to merge? Are they the last expected occurrence of `scene` in an Apple framework?