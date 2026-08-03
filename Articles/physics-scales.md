# Physics Scales

*7 Mar 2026*

In any physics engine, scales and magnitudes must be kept within some range. For example, an engine could simulate objects sized from 10cm to 10m, but no less or no more. A similar constraint applies to how large a single physics world can be: 1km across, or 100km across, and so on.

## RealityKit Documentation

RealityKit documentation mentions some of these ranges.

In [Designing scene hierarchies for efficient physics simulation](https://developer.apple.com/documentation/realitykit/designing-scene-hierarchies-for-efficient-physics-simulation):

> RealityKit’s physics simulations work best if the size and mass ratios don’t exceed one order of magnitude.
>
> - The largest object in your scene should be no more than 10 times the size of the smallest object.
> - The heaviest object in your scene should be no more than 10 times the mass of your lightest object.
>
> Additionally, the physics simulation works best if the smallest dimension of each object is at least 0.05 units in size and the largest dimension of each object is no more than 10 units in size. If you need objects outside of this range, create objects that are inside this range and then scale the physics origin at runtime

And:

> Water has a density of about 1000 kg/m³ and steel has a density of 7800 kg/m³. When setting the mass of an object, keep in mind that real-world objects aren’t always completely solid, and can be hollow. Densities of less than 1000 kg/m³ work well in most scenarios.

## Spacing Constraint

In my use of RealityKit physics engine, which is based on PhysX, I found a limitation when arranging physics bodies across adjacent planes.

Bodies placed on adjacent XY planes could collide when the distance between their collision shapes was less than ~4 cm. This became a problem when I overlaid flat entities across multiple depths.

Leaving more space between the planes prevented the collisions. Another option is to use collision filters so that bodies on adjacent planes cannot collide, although that may not suit every design.