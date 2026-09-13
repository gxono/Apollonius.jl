```@meta
CurrentModule = EuclideanGeometry
```

# 3D Unbounded Sets

The 3D peers of [`EGHalfPlane2`](@ref)/[`EGAngle2`](@ref)/[`EGStrip2`](@ref)
from [Unbounded Regions: Half-Planes, Strips & Angles](@ref) — each one
dimension up. `EGHalfSpace3` and `EGSlab3` follow their 2D counterparts
directly; `EGDihedralAngle3` (edge + 2 half-planes) and
`EGPolyhedralAngle3` (vertex + `n ≥ 3` rays, the "triedro" for `n = 3`)
are new *kinds* of unbounded set, not just dimension bumps, since neither
collapses onto a single 2D concept.

## `EGHalfSpace3`

```@example geo3d
using EuclideanGeometry

xy = EGPlane3(EGPoint(0.0, 0.0, 0.0), EGVector(0.0, 0.0, 1.0))
hs = EGHalfSpace3(xy, EGPoint(0.0, 0.0, 5.0))  # the upper half-space
EGPoint(0.0, 0.0, 3.0) in hs, EGPoint(0.0, 0.0, -3.0) in hs
```

`distance(p, hs; mode=)` follows the same `:region`/`:boundary` convention
as [`EGHalfPlane2`](@ref):

```@example geo3d
distance(EGPoint(0.0, 0.0, 3.0), hs), distance(EGPoint(0.0, 0.0, 3.0), hs; mode=:boundary)
```

A negative-ratio `homothety` genuinely flips which half-space you're in —
see [3D Geometry: Points, Lines & Planes](@ref) for why 3D homothety is
orientation-reversing at `k < 0`, unlike 2D:

```@example geo3d
hs2 = homothety(hs, -1.0, EGPoint(0.0, 0.0, 0.0))
EGPoint(0.0, 0.0, 3.0) in hs2  # false now -- the half-space flipped
```

## `EGSlab3`

```@example geo3d
z0 = EGPlane3(EGPoint(0.0, 0.0, 0.0), EGVector(0.0, 0.0, 1.0))
z5 = EGPlane3(EGPoint(0.0, 0.0, 5.0), EGVector(0.0, 0.0, 1.0))
slab = EGSlab3(z0, z5)
slab_width(slab), EGPoint(0.0, 0.0, 2.0) in slab
```

Throws an `ArgumentError` if the two planes aren't parallel — same
validation `EGStrip2` already does for its two lines.

## `EGDihedralAngle3`: the dihedral angle

An edge (`EGLine`) plus 2 points, one per half-plane — the direct analogue
of [`EGAngle2`](@ref) (a vertex + 2 rays), one dimension up:

```@example geo3d
edge = EGLine(EGPoint(0.0, 0.0, 0.0), EGPoint(0.0, 0.0, 1.0))
d = EGDihedralAngle3(edge, EGPoint(1.0, 0.0, 5.0), EGPoint(0.0, 1.0, -3.0))  # the z-offsets don't matter
rad2deg(measure(d)), is_direct(d)
```

`Base.in` tests the solid wedge between the two half-planes:

```@example geo3d
EGPoint(1.0, 1.0, 0.0) in d, EGPoint(-1.0, 0.0, 0.0) in d
```

### The 3D reflection/homothety wrinkle

In 2D, `reflection(::EGAngle2, about::EGPoint)` needs **no** swap of its
defining points (a 2D point reflection is secretly a rotation, so it's
orientation-*preserving*), while `reflection(::EGAngle2, about::EGLine)`
**does** swap them (a true mirror is orientation-*reversing*). In 3D, a
point reflection is itself genuinely orientation-reversing (it's an odd
number of composed mirror reflections) — so `EGDihedralAngle3` swaps its
defining points under **both** point- and plane-reflection:

```@example geo3d
rad2deg(measure(reflection(d, xy))), rad2deg(measure(reflection(d, EGPoint(0.0, 0.0, 0.0))))
```

Both come back at the *same* sign as `measure(d)` (not flipped) — the swap
is exactly what compensates to keep it that way, mirroring
[`EGAngle2`](@ref)'s own convention. The same reasoning makes `homothety`
swap the points too, but **only** when `k < 0`:

```@example geo3d
rad2deg(measure(homothety(d, -1.0, EGPoint(0.0, 0.0, 0.0)))), rad2deg(measure(homothety(d, 2.0, EGPoint(0.0, 0.0, 0.0))))
```

## `EGPolyhedralAngle3`: the solid angle (the "triedro" is `n = 3`)

A vertex plus `n ≥ 3` rays, each consecutive pair bounding one planar
face — the solid-angle generalization of `EGAngle2` to more than 2 rays.
`n = 3` is the classical **triedro** (trihedral angle, e.g. the corner of a
tetrahedron); there's no separate fixed-3 type, the same way
[`EGCurvilinearNgon2`](@ref) doesn't get one type per side count:

```@example geo3d
vertex = EGPoint(0.0, 0.0, 0.0)
rays = [EGPoint(1.0, 0.0, 0.0), EGPoint(0.0, 1.0, 0.0), EGPoint(0.0, 0.0, 1.0)]  # one octant corner
pa = EGPolyhedralAngle3(vertex, rays)
EGPoint(1.0, 1.0, 1.0) in pa, EGPoint(-1.0, -1.0, -1.0) in pa
```

[`solid_angle`](@ref) (in steradians) uses **Van Oosterom & Strackee's**
closed form, triangulated (fan from `rays[1]`) into `n - 2` triangles for
`n > 3`:

```@example geo3d
solid_angle(pa)  # π/2 -- one octant is exactly 1/8 of the full 4π steradians around a point
```

Throws an `ArgumentError` for fewer than 3 rays (a "digon" solid angle
isn't a thing):

```@example geo3d
try
    EGPolyhedralAngle3(vertex, rays[1:2])
catch e
    e
end
```
