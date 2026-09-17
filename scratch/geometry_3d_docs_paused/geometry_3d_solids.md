```@meta
CurrentModule = EuclideanGeometry
```

# 3D Geometry: Polyhedra & Solids

[`EGPolyhedron`](@ref) is the flat-faced-solid sibling of
[`EGPolygon`](@ref), one dimension up: a closed 3D solid bounded by planar
polygon [`faces`](@ref) instead of straight `sides`. `volume`/
`surface_area`/`centroid` are defined *once*, generically, on
`EGPolyhedron` itself — the divergence-theorem analogue of `EGPolygon`'s
Green's-theorem walk over `sides`. `EGCylinder3`/`EGCone3` are covered
separately at the end: a curved lateral surface makes "polyhedron" a
genuine misnomer for them, and their measures have such simple closed
forms that routing them through the generic `faces` machinery would add
complexity for no benefit.

## The generic `faces`-based machinery

Every concrete constructor below builds `faces` with consistent
**outward** orientation automatically — regardless of the order you give
the defining points in, so you never need to think about winding order
yourself:

```@example geo3d
using EuclideanGeometry

t = EGTetrahedron3(EGPoint(0.0, 0.0, 0.0), EGPoint(1.0, 0.0, 0.0), EGPoint(0.0, 1.0, 0.0), EGPoint(0.0, 0.0, 1.0))
volume(t), centroid(t), length(faces(t))
```

```@example geo3d
# reordering the 4 defining points arbitrarily gives the exact same solid
t2 = EGTetrahedron3(EGPoint(0.0, 0.0, 1.0), EGPoint(0.0, 0.0, 0.0), EGPoint(1.0, 0.0, 0.0), EGPoint(0.0, 1.0, 0.0))
volume(t2) ≈ volume(t)
```

`surface_area(t)` sums the area of each face, via the same Newton-free
Newell's-method `area(::EGPolygon{3})` every 3D-embedded flat polygon
already uses.

## `EGParallelepiped3`, `box3`, `cube3`

The general parallelepiped is a vertex + 3 edge vectors (not necessarily
perpendicular) — the direct analogue of [`EGQuadrilateral`](@ref):

```@example geo3d
pp = EGParallelepiped3(EGPoint(0.0, 0.0, 0.0), EGVector(2.0, 0.0, 0.0), EGVector(0.0, 3.0, 0.0), EGVector(0.0, 0.0, 4.0))
volume(pp), length(vertices(pp))
```

The 8 vertices are derived from `origin`/`u`/`v`/`w`, not stored. An
axis-aligned rectangular box ("ortoedro") and a cube are just the special
cases where the 3 edges are mutually perpendicular (and, for a cube, equal)
— named constructors, not separate types, the same way
[`rectangle_on_segment`](@ref)/[`square_on_segment`](@ref) are named
special cases of `EGQuadrilateral` rather than their own struct:

```@example geo3d
box3(EGPoint(0.0, 0.0, 0.0), 2.0, 3.0, 4.0) == pp
cube3(EGPoint(1.0, 1.0, 1.0), 5.0)
```

## `EGPyramid3`: any polygonal base

```@example geo3d
base_sq = EGStraightNgon([EGPoint(-1.0, -1.0, 0.0), EGPoint(1.0, -1.0, 0.0), EGPoint(1.0, 1.0, 0.0), EGPoint(-1.0, 1.0, 0.0)])
pyr = EGPyramid3(EGPoint(0.0, 0.0, 3.0), base_sq)
volume(pyr)  # (1/3) * base_area(4) * height(3)
```

[`EGTetrahedron3`](@ref) is exactly the special case of a pyramid over a
triangular base — kept as its own dedicated type (rather than folded into
`EGPyramid3`) the same way `EGTriangle` stays its own type distinct from a
general `EGStraightNgon` in 2D. A pyramid's centroid sits `1/4` of the way
from the base's own centroid up to the apex:

```@example geo3d
centroid(pyr)[3]  # 0.75 = 3 * (1/4)
```

## `EGPrism3`: base + translation

```@example geo3d
prism = EGPrism3(base_sq, EGVector(0.0, 0.0, 5.0))
volume(prism), surface_area(prism)
```

The top face is `translate(base, v)`, computed on demand — an oblique
prism (`v` not perpendicular to the base) works exactly the same way as a
right one.

## `EGGeneralPolyhedron3`: the fully general case

```@example geo3d
gp = EGGeneralPolyhedron3(collect(faces(t)))  # rebuild the tetrahedron from its own faces
volume(gp) ≈ volume(t)
```

Unlike the named constructors above, `faces` here is taken as given —
**assumed** already outward-oriented, the same "assumed correct" convention
[`EGStraightNgon`](@ref)'s "assumed simple" already uses, not validated at
construction time.

## Regular polyhedra

```@example geo3d
tet = regular_tetrahedron3(EGPoint(0.0, 0.0, 0.0), 4.0)  # all 6 edges = 4.0
oct = regular_octahedron3(EGPoint(0.0, 0.0, 0.0), 4.0)   # 8 equilateral triangular faces
volume(tet), volume(oct)
```

The cube is [`cube3`](@ref) above. The dodecahedron and icosahedron are
**not** implemented — their faces aren't as simple to hand-enumerate from
vertex coordinates as the tetrahedron/octahedron/cube's are, and building
them properly needs a 3D convex hull algorithm this package doesn't have
(the 2D [`convex_hull`](@ref) doesn't generalize to 3D) — left for a later
phase.

## Transforming solids

`rotate`/`translate`/`homothety`/`reflection` all work on every type on
this page:

```@example geo3d
axis = EGLine(EGPoint(0.0, 0.0, 0.0), EGPoint(0.0, 0.0, 1.0))
volume(rotate(t, pi / 3, axis)) ≈ volume(t)
volume(homothety(t, 2.0, EGPoint(0.0, 0.0, 0.0))) ≈ volume(t) * 8
```

A negative-ratio `homothety` is orientation-reversing in 3D (see
[3D Geometry: Points, Lines & Planes](@ref)) — `volume` stays correct
either way (it's built from a signed decomposition, absolute-valued at the
end), same as `area(::EGPolygon)`'s own `abs(total)`.

## Curved-surface solids: `EGCylinder3`, `EGCone3`

Deliberately minimal, by design: a right circular cylinder/cone is fully
determined by 2 points and a radius — nothing else is stored (the caps,
height, axis direction are all derived on demand):

```@example geo3d
cyl = EGCylinder3(EGPoint(0.0, 0.0, 0.0), EGPoint(0.0, 0.0, 10.0), 2.0)
volume(cyl), surface_area(cyl), height(cyl)
```

```@example geo3d
c1, c2 = caps(cyl)  # the two EGCircle3 caps, computed on demand
c1.r, c2.r
```

```@example geo3d
cone = EGCone3(EGPoint(0.0, 0.0, 9.0), EGPoint(0.0, 0.0, 0.0), 3.0)
volume(cone), slant_height(cone)
```

A cone's centroid sits `1/4` of the way from the base to the apex — exactly
the same fraction as [`EGPyramid3`](@ref)'s, since a cone is precisely the
`n -> ∞` limit of a pyramid over a regular `n`-gon base:

```@example geo3d
centroid(cone)
```

### Distance via the "meridian profile" trick

`distance(p, cyl; mode=)`/`distance(p, cone; mode=)` follow the same
`:region`/`:boundary` convention as [`EGSphere3`](@ref), computed by
projecting `p` into `(axial, radial)` coordinates and reusing
`distance(::EGPoint, ::EGPolygon; mode)` on the solid's own flat *meridian
profile* — a rectangle for the cylinder, a right triangle for the cone —
rather than re-deriving the "capped cylinder" case analysis by hand
(valid because both are surfaces of revolution):

```@example geo3d
distance(EGPoint(0.0, 0.0, 5.0), cyl), distance(EGPoint(0.0, 0.0, 5.0), cyl; mode=:boundary)
```

One subtlety this trick has to get right: the profile's "inner" edge
(radius `0`, i.e. the solid's own axis) is **not** a physical boundary, so
it's deliberately excluded from the distance-to-boundary computation —
otherwise points near the axis would incorrectly register as "close to the
boundary."
