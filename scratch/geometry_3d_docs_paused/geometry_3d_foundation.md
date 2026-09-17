```@meta
CurrentModule = EuclideanGeometry
```

# 3D Geometry: Points, Lines & Planes

Everything on this page and the next few lives in 3D — `EGPoint`/`EGVector`
with 3 coordinates instead of 2. The package's whole type hierarchy
(`EGObject`, `EGCurve`, `EGSet`, `EGPolygon`, ...) was built `{Dim,T}`-generic
from the start, so `EGPoint(1.0, 2.0, 3.0)`, `EGSegment`, `EGLine` and
`EGRay` already work in 3D with **zero new code** — this page covers what's
genuinely new: [`EGPlane3`](@ref) (the 3D analogue of a line — a flat,
unbounded, no-interior-of-its-own locus, one dimension up) and
[`EGSphere3`](@ref), plus the handful of predicates/transforms that only
make sense once there's a third dimension to work with.

## Points, lines, segments, rays: already there

```@example geo3d
using EuclideanGeometry

p = EGPoint(1.0, 2.0, 3.0)
v = EGVector(0.0, 0.0, 1.0)
p + v, norm(v), dot(EGVector(1.0, 0.0, 0.0), EGVector(0.0, 1.0, 0.0))
```

```@example geo3d
l = EGLine(EGPoint(0.0, 0.0, 0.0), EGPoint(1.0, 1.0, 1.0))
s = EGSegment(EGPoint(0.0, 0.0, 0.0), EGPoint(4.0, 0.0, 0.0))
direction(l), midpoint(s)
```

`projection(p, l)` (orthogonal case) and `EGBoundingBox` also already work
unchanged in 3D — both are plain dot-product/componentwise formulas with no
2D assumption baked in.

## `EGPlane3`: the 3D analogue of a line

```@example geo3d
xy = EGPlane3(EGPoint(0.0, 0.0, 0.0), EGVector(0.0, 0.0, 1.0))  # point + normal
xy2 = EGPlane3(EGPoint(0.0, 0.0, 0.0), EGPoint(1.0, 0.0, 0.0), EGPoint(0.0, 1.0, 0.0))  # 3 points
xy == xy2
```

`normal` is normalized on construction regardless of what you pass in.
`distance`, `side_of_plane`, `projection`, `reflection` and `on_plane` all
work the way you'd expect from the 2D `EGLine` versions:

```@example geo3d
p = EGPoint(1.0, 2.0, 3.0)
distance(p, xy), side_of_plane(p, xy), on_plane(EGPoint(5.0, -3.0, 0.0), xy)
```

```@example geo3d
projection(p, xy), reflection(p, xy)
```

## `EGSphere3`

```@example geo3d
sph = EGSphere3(EGPoint(0.0, 0.0, 0.0), 5.0)
volume(sph), surface_area(sph)  # (4/3)πr³, 4πr² — the 3D analogues of area/perimeter
```

```@example geo3d
on_sphere(EGPoint(3.0, 4.0, 0.0), sph), distance(EGPoint(10.0, 0.0, 0.0), sph)
```

Like [`distance(::EGPoint, ::EGPolygon)`](@ref), `distance(p, sph; mode=)`
takes `:region` (the default — `0.0` from inside) or `:boundary` (always
the distance to the surface):

```@example geo3d
inside_pt = EGPoint(1.0, 0.0, 0.0)
distance(inside_pt, sph), distance(inside_pt, sph; mode=:boundary)
```

## Skew lines: the genuinely new 3D case

Two lines in 2D are always either parallel or crossing. In 3D there's a
third possibility with no 2D analogue at all: **skew** — not parallel, and
not coplanar either, so they never meet.

```@example geo3d
l1 = EGLine(EGPoint(0.0, 0.0, 0.0), EGPoint(1.0, 0.0, 0.0))
l2 = EGLine(EGPoint(0.0, 0.0, 1.0), EGPoint(0.0, 1.0, 1.0))
line_line_position(l1, l2)  # :skew
```

[`line_line_position`](@ref) returns one of `:coincident`, `:parallel`,
`:intersecting` or `:skew`. `intersection(l1, l2)` returns an empty
`Vector{EGPoint{3,Float64}}` for both `:parallel` and `:skew` (same
"no single answer" convention `intersection(::EGLine,::EGLine)` already
uses for 2D parallel lines) — use `line_line_position` first if you need
to tell those two apart:

```@example geo3d
distance(l1, l2)  # 1.0 — the constant shortest gap between the two skew lines
```

[`is_coplanar`](@ref)`(a, b, c, d)` is the 3D analogue of
[`is_collinear`](@ref), and is what `line_line_position` uses internally to
distinguish `:intersecting` from `:skew`.

## Plane ↔ plane, line ↔ plane

```@example geo3d
xz = EGPlane3(EGPoint(0.0, 0.0, 0.0), EGVector(0.0, 1.0, 0.0))
iline = intersection(xy, xz)
iline isa EGLine
```

Unlike every 2D `intersection`, this one does **not** return a
`Vector{EGPoint}` — two planes generically meet in a whole line, not a
finite set of points, so `intersection(::EGPlane3,::EGPlane3)` returns
`nothing` (parallel/coincident) or an `EGLine{3,Float64}` directly:

```@example geo3d
z5 = EGPlane3(EGPoint(0.0, 0.0, 5.0), EGVector(0.0, 0.0, 1.0))
intersection(xy, z5), distance(xy, z5)
```

`intersection`/`distance` also work between an `EGLine`/`EGSegment`/`EGRay`
and an `EGPlane3`, with the finite/half-infinite versions filtered from the
infinite-line case:

```@example geo3d
crossing = EGSegment(EGPoint(0.0, 0.0, -1.0), EGPoint(0.0, 0.0, 1.0))
intersection(crossing, xy), distance(crossing, xy)
```

## Two spheres meet in a circle, not points

```@example geo3d
s1 = EGSphere3(EGPoint(0.0, 0.0, 0.0), 5.0)
s2 = EGSphere3(EGPoint(6.0, 0.0, 0.0), 5.0)
circ = intersection(s1, s2)
circ isa EGCircle3
```

Another break from the `Vector{EGPoint}` convention, for the same reason as
plane-plane intersection: two spheres generically meet in a whole circle.
`intersection(::EGSphere3,::EGSphere3)` returns `nothing` (disjoint or
concentric), a single `EGPoint` (externally/internally tangent), or an
[`EGCircle3`](@ref) (the general case) — see
[3D Conics & Quadric Surfaces](@ref) for what you can do with that circle.
`intersection(::EGLine,::EGSphere3)`/`(::EGSegment,...)`/`(::EGRay,...)`, on
the other hand, stay `Vector{EGPoint}`-returning (0/1/2 points), exactly
like the 2D line-circle case.

## Rotating in 3D: Rodrigues' formula, about an axis

2D `rotate(p, angle, center)` has an implicit axis (perpendicular to the
plane, through `center`). In 3D there's no such default — you give the
whole axis, as an `EGLine`:

```@example geo3d
axis = EGLine(EGPoint(0.0, 0.0, 0.0), EGPoint(0.0, 0.0, 1.0))
rotate(EGPoint(1.0, 0.0, 0.0), pi / 2, axis)
```

This works on `EGPoint`, `EGVector` (direction only), `EGSegment`,
`EGLine`, `EGRay`, and every 3D shape in the later pages. `translate`,
`homothety` and `reflection(p, about::EGPlane3)` all already generalize the
same way (`reflection(p, about::EGLine)` is deliberately **not** offered in
3D — see its own docstring for why "mirror across a line" isn't a
well-defined isometry once the line's orthogonal complement is a whole
plane rather than a single direction).

### A 3D-only wrinkle: negative homothety reverses orientation

A 2D homothety's linear part is `k²·I` as a determinant check — always
positive, so a 2D homothety (even with `k < 0`) never reverses
orientation. In 3D, the determinant is `k³` — genuinely *negative* for
`k < 0`. This has a real, visible consequence: types that track a
meaningful orientation (like [`EGDihedralAngle3`](@ref), in
[3D Unbounded Sets](@ref)) swap their defining points under a negative-`k`
homothety in 3D, exactly as they would under a true reflection — something
that never happens for their 2D counterparts.

## Composable transforms: `EGAffineMap3`

The 2D `EGAffineMap`/`rotation_map`/`homothety_map`/`reflection_map`/
`affine_map` family all have 3D siblings, chosen by the `Dim` of the
point/line/plane you pass — same function names throughout:

```@example geo3d
rm = rotation_map(pi / 2, axis)
tm = translation_map(EGVector(1.0, 2.0, 3.0))
composed = rm ∘ tm
composed(EGPoint(0.0, 0.0, 0.0))
```

```@example geo3d
src = (EGPoint(0.0, 0.0, 0.0), EGPoint(1.0, 0.0, 0.0), EGPoint(0.0, 1.0, 0.0), EGPoint(0.0, 0.0, 1.0))
dst = (EGPoint(2.0, 3.0, 5.0), EGPoint(3.0, 3.0, 5.0), EGPoint(2.0, 4.0, 5.0), EGPoint(2.0, 3.0, 6.0))
affine_map(src, dst)  # 4 non-coplanar point correspondences (3 non-collinear ones in 2D)
```
