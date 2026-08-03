## Physics Scales

*7 Mar 2026*

These are physics scales and measurements mentioned in RealityKit documentation.

> RealityKit’s physics simulations work best if the size and mass ratios don’t exceed one order of magnitude.
>
> - The largest object in your scene should be no more than 10 times the size of the smallest object.
> - The heaviest object in your scene should be no more than 10 times the mass of your lightest object.
>
> Additionally, the physics simulation works best if the smallest dimension of each object is at least 0.05 units in size and the largest dimension of each object is no more than 10 units in size. If you need objects outside of this range, create objects that are inside this range and then scale the physics origin at runtime

[Avoid extreme differences in size and mass](https://developer.apple.com/documentation/realitykit/designing-scene-hierarchies-for-efficient-physics-simulation).

> Water has a density of about 1000 kg/m³ and steel has a density of 7800 kg/m³. When setting the mass of an object, keep in mind that real-world objects aren’t always completely solid, and can be hollow. Densities of less than 1000 kg/m³ work well in most scenarios.

[Increase density instead of mass](https://developer.apple.com/documentation/realitykit/designing-scene-hierarchies-for-efficient-physics-simulation).