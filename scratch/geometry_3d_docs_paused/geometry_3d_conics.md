```@meta
CurrentModule = EuclideanGeometry
```

# 3D Conics & Quadric Surfaces

A conic (circle, ellipse, parabola, hyperbola) is a fundamentally *planar*
curve — so each 3D conic type here stores, in addition to its usual
shape parameters, an explicit supporting plane (a `normal` vector, plus an
in-plane reference direction `u` for the ones that need an orientation).
Quadric surfaces (the last section) are the genuinely 3D-only family —
they have no 2D curve to generalize from at all.

## `EGCircle3`

[`EGCircle3`](@ref) already exists as the minimal `(center, r, normal)`
building block earlier pages use for sphere/plane intersections. This page
covers the rest of its API:

```@example geo3d
using EuclideanGeometry

c = EGCircle3(EGPoint(0.0, 0.0, 5.0), 3.0, EGVector(0.0, 0.0, 1.0))
p = point_on_circle3(c, pi / 4)
is_on_circle3(p, c), p[3]  # stays in the supporting plane (z = 5)
```

`point_on_circle3` picks an arbitrary (but fixed) in-plane reference
direction internally, since a circle — unlike an ellipse — has no
distinguished axis of its own.

## `EGEllipse3`, `EGHyperbola3`, `EGParabola3`

Each stores `normal` (the supporting plane) and, for the ellipse/hyperbola,
`u` (the direction of the `a` semi-axis) — `u` is auto-orthogonalized
against `normal` and normalized, so it only needs to be *approximately*
in-plane:

```@example geo3d
e = EGEllipse3(EGPoint(1.0, 1.0, 1.0), 5.0, 3.0, EGVector(0.0, 0.0, 1.0), EGVector(1.0, 0.0, 0.0))
area(e), point_on_ellipse3(e, 0.7)
```

Some 2D constructors carry over with **no extra argument** needed, because
the given points already pin down a unique plane on their own:

```@example geo3d
f1, f2, p_on = EGPoint(-3.0, 0.0, 0.0), EGPoint(3.0, 0.0, 0.0), EGPoint(0.0, 4.0, 0.0)
eb = EGEllipse3(f1, f2, p_on)  # bifocal-through-point: f1, f2, p_on determine the plane
is_on_ellipse3(p_on, eb)
```

Others are genuinely **underdetermined** in 3D and need an explicit
`normal` that the 2D version never needed — two foci alone only pin down
the focal *axis*, not which of the infinitely many planes containing it
the ellipse lies in:

```@example geo3d
ec = EGEllipse3(f1, f2, 5.0, EGVector(0.0, 0.0, 1.0))  # bifocal + axis: normal required
ec.b
```

`EGParabola3(focus, directrix)` is always well-determined without an extra
argument (a point and a line in 3D always span a unique plane, unless the
point already lies on the line):

```@example geo3d
par = EGParabola3(EGPoint(0.0, 1.0, 0.0), EGLine(EGPoint(-5.0, -1.0, 0.0), EGPoint(5.0, -1.0, 0.0)))
vertex(par), focal_parameter(par)
```

`EGHyperbola3` follows the ellipse's exact same pattern (`foci`,
`asymptotes`, bifocal constructors with/without an explicit `normal`).
`distance(p, conic)` for all three reuses the 2D Newton-solver machinery
directly — it operates on scalar local `(lx,ly)` coordinates already, and
an orthonormal 3D embedding preserves distances, so the same numerics give
the exact 3D answer:

```@example geo3d
distance(e.center, e)  # 3.0 = min(a,b), same Newton solve as the 2D case
```

`orthoptic` also carries over: the ellipse/hyperbola versions return an
[`EGCircle3`](@ref) in the same plane; the parabola's is, as in 2D, exactly
its own directrix.

## Conic arcs

`EGCircularArc3`, `EGEllipticArc3`, `EGParabolicArc3`, `EGHyperbolicArc3`
mirror their 2D counterparts exactly — `measure`, `arc_length`,
`point_on_arc`, `reverse`, `Base.in`, and the transform quartet all work
the same way:

```@example geo3d
u0 = point_on_circle3(c, 0.0)
u90 = point_on_circle3(c, pi / 2)
arc = EGCircularArc3(c, u0, u90)
measure(arc), arc_length(arc)
```

```@example geo3d
ell = EGEllipse3(EGPoint(0.0, 0.0, 0.0), 5.0, 3.0, EGVector(0.0, 0.0, 1.0), EGVector(1.0, 0.0, 0.0))
earc = EGEllipticArc3(ell, point_on_ellipse3(ell, 0.2), point_on_ellipse3(ell, 2.0))
arc_length(earc) > distance(earc.p1, earc.p2)  # the arc is always longer than its chord
```

Same closed/open-curve distinction as 2D governs `reverse`: circular/elliptic
arcs swap to the *complementary* arc; parabolic/hyperbolic arcs (open
curves) just reverse the parametrization direction over the same points.

## Curved regions: sector, segment, annular sector

[`EGCircularSector3`](@ref), [`EGCircularSegment3`](@ref) and
[`EGAnnularSector3`](@ref) are the 3D analogues of
[`EGCircularSector2`](@ref)/`EGCircularSegment2`/`EGAnnularSector2` — each
one lives entirely in its own circle's plane, so `area`/`perimeter`/
`centroid` are computed by projecting into a 2D frame local to that plane
and delegating to the already-verified 2D formulas (exact, since an
orthonormal frame change preserves distances/angles/areas):

```@example geo3d
sec = EGCircularSector3(c, u0, u90)
area(sec), perimeter(sec)
```

```@example geo3d
seg = EGCircularSegment3(c, u0, u90)
asec = EGAnnularSector3(EGCircularArc3(c, u0, u90), 1.0)
area(seg), area(asec)
```

```@example geo3d
c.center in sec, on_plane(centroid(sec), plane(c))
```

## Quadric surfaces

Unlike everything above, quadric surfaces are **genuinely 3D-only** — a
saddle shape or a two-sheeted hyperboloid has no 2D curve it generalizes
from at all. The API here is deliberately minimal: constructors, a
parametrization, membership, and the transform quartet — no
`intersection`/`distance` yet (a substantial undertaking per pair of
quadrics, left for a later phase).

### `EGEllipsoid3`

```@example geo3d
ell3d = EGEllipsoid3(EGPoint(0.0, 0.0, 0.0), 3.0, 4.0, 5.0, EGVector(1.0, 0.0, 0.0), EGVector(0.0, 1.0, 0.0))
volume(ell3d)  # (4/3)πabc, exact
```

`surface_area` has no elementary closed form for a general ellipsoid at
all (it's a genuine elliptic integral) — `surface_area(::EGEllipsoid3)`
uses **Thomsen's approximation** instead, explicitly documented as
approximate (accurate to within about 1.06% relative error), unlike every
other `area`/`perimeter`/`surface_area` in this package:

```@example geo3d
sphere_like = EGEllipsoid3(EGPoint(0.0, 0.0, 0.0), 2.0, 2.0, 2.0, EGVector(1.0, 0.0, 0.0), EGVector(0.0, 1.0, 0.0))
surface_area(sphere_like) ≈ 4pi * 2.0^2  # a sphere is the one case where Thomsen's formula happens to be exact
```

### `EGParaboloid3`

The elliptic paraboloid `z = (x/a)² + (y/b)²` in its own local frame:

```@example geo3d
par3d = EGParaboloid3(EGPoint(0.0, 0.0, 0.0), 2.0, 3.0, EGVector(0.0, 0.0, 1.0), EGVector(1.0, 0.0, 0.0))
is_on_paraboloid3(point_on_paraboloid3(par3d, 1.5, 0.8), par3d)
```

### `EGHyperboloid3`: one sheet or two

`(x/a)² + (y/b)² - (z/c)² = 1` (`sheets=1`, one connected surface) or `=
-1` (`sheets=2`, two disjoint sheets) — genuinely different topology, not
just a sign flip:

```@example geo3d
h1 = EGHyperboloid3(EGPoint(0.0, 0.0, 0.0), 2.0, 3.0, 4.0, EGVector(1.0, 0.0, 0.0), EGVector(0.0, 1.0, 0.0); sheets=1)
h2 = EGHyperboloid3(EGPoint(0.0, 0.0, 0.0), 2.0, 3.0, 4.0, EGVector(1.0, 0.0, 0.0), EGVector(0.0, 1.0, 0.0); sheets=2)
point_on_hyperboloid3(h1, 0.7, 1.2)  # one connected surface: `branch` is irrelevant
```

For `sheets=2`, [`point_on_hyperboloid3`](@ref) needs a `branch = ±1` to
pick which of the two disjoint sheets — the same convention
[`point_on_hyperbola`](@ref) already uses for its two branches:

```@example geo3d
point_on_hyperboloid3(h2, 0.5, 0.3; branch=1), point_on_hyperboloid3(h2, 0.5, 0.3; branch=-1)
```

### `EGHyperbolicParaboloid3`: the saddle

`z = (x/a)² - (y/b)²` — opens upward along one axis and downward along the
perpendicular one, the purest "genuinely 3D" quadric (it's doubly-ruled by
two *different* families of straight lines, a fact with no 2D analogue at
all):

```@example geo3d
hp = EGHyperbolicParaboloid3(EGPoint(0.0, 0.0, 0.0), 2.0, 3.0, EGVector(0.0, 0.0, 1.0), EGVector(1.0, 0.0, 0.0))
point_on_hyperbolic_paraboloid3(hp, 2.0, 0.0), point_on_hyperbolic_paraboloid3(hp, 0.0, 2.0)
```
