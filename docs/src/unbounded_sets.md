```@meta
CurrentModule = Apollonius
```

# Unbounded Regions: Half-Planes, Strips & Angles

Not every region in the package is bounded. [`APHalfPlane2`](@ref),
[`APStrip2`](@ref) and [`APAngle2`](@ref) are the three unbounded members
of the [`APSet`](@ref) family, genuine regions of the plane (they support
`in`, `distance`, and the usual transforms), but with infinite area, so
none of them is an [`APRegion`](@ref)/[`APPolygon`](@ref) and none has an
`area`/`perimeter`. `APAngle2` already has its own worked-example section;
see [Angles](@ref) on the [Points, Lines & Rays](@ref) page. This page
covers the other two.

| Type | Represents | Bounded by |
|:-----|:-----------|:-----------|
| [`APHalfPlane2`](@ref) | everything on one side of a line (that line included) | one [`APLine`](@ref) |
| [`APStrip2`](@ref) | the band between two parallel lines (both included) | two parallel [`APLine`](@ref)s |
| [`APAngle2`](@ref) | the infinite wedge between two rays from a shared vertex | two [`APRay`](@ref)s; see [Angles](@ref) |

Being unbounded, none of the three has a finite extent to report:
[`APBoundingBox`](@ref) returns the empty box for all three (see
[Bounding boxes](@ref) for what that means and why), they still get
`translate`/`rotate`/`homothety`/`reflection`ed normally, they just don't
contribute anything if mixed into a [`@boundingbox`](@ref)/
[`@to_luxor_picture`](@ref) block alongside bounded shapes.

## `APHalfPlane2`

A half-plane needs a boundary line and a choice of *which* side is
"inside". Two equivalent ways to say that:

```@example geo
using Apollonius

l = APLine(APPoint(0.0, 0.0), APPoint(0.0, 4.0))   # the y-axis

hp1 = APHalfPlane2(l, -1)                   # side = -1: right of p1->p2, see side_of_line
hp2 = APHalfPlane2(l, APPoint(1.0, 0.0))    # "whichever side this point is on", also -1
hp1 == hp2
```

`side = +1`/`-1` follows [`side_of_line`](@ref)'s own convention (left/right
of the line oriented `p1 -> p2`); the point-based form is usually easier to
reason about, since you rarely think in terms of left/right directly.
Passing a point *on* the boundary is an error: there's no side to pick:

```@example geo
try
    APHalfPlane2(l, APPoint(0.0, 2.0))    # on l itself
catch e
    e
end
```

`p in hp` is a **closed** test (the boundary line itself counts as
inside):

```@example geo
APPoint(1.0, 0.0) in hp1, APPoint(0.0, 0.0) in hp1, APPoint(-1.0, 0.0) in hp1
```

[`distance`](@ref)`(p, hp)` is `0.0` from anywhere inside, and the
perpendicular distance to the boundary from outside; pass
`mode=:boundary` to always get the distance to the boundary line, even
from inside:

```@example geo
distance(APPoint(1.0, 0.0), hp1), distance(APPoint(-3.0, 0.0), hp1)   # (0.0, 3.0): the second point is outside
```

```@example geo
distance(APPoint(1.0, 0.0), hp1; mode=:boundary)   # 1.0, even though the point is already inside
```

`rotate`/`homothety`/`translate` move the boundary and leave `side`
unchanged: a rotation or a homothety of any ratio is always
orientation-preserving in 2D, so "the same physical side" is still the
same `side` value afterward. `reflection` about a point is the same
story, but reflecting about a *line* is a true mirror: it reverses
orientation, so `side` flips too, otherwise the reflected half-plane would
describe the wrong side of its own (also reflected) boundary:

```@example geo
reflection(hp1, APPoint(1.0, 1.0)).side,                                       # point reflection: side unchanged (-1)
    reflection(hp1, APLine(APPoint(0.0, 0.0), APPoint(1.0, 1.0))).side          # line reflection: side flips (+1)
```

## `APStrip2`

The closed band between two **parallel** lines: think of it as an
`APHalfPlane2` closed off on both sides instead of just one:

```@example geo
l1 = APLine(APPoint(0.0, 0.0), APPoint(1.0, 0.0))
l2 = APLine(APPoint(0.0, 3.0), APPoint(1.0, 3.0))
s = APStrip2(l1, l2)

strip_width(s)   # 3.0: the perpendicular distance between the two lines
```

The constructor checks parallelism itself and throws if the two lines
aren't parallel: there's no sensible strip otherwise:

```@example geo
try
    APStrip2(l1, APLine(APPoint(0.0, 0.0), APPoint(1.0, 1.0)))
catch e
    e
end
```

`in`, `distance` and the transforms all work exactly like `APHalfPlane2`,
except a strip has no `side` bookkeeping to worry about: "the band
between two lines" doesn't depend on either line's own orientation, so
membership is simply recomputed fresh after any transform:

```@example geo
APPoint(0.5, 1.5) in s, APPoint(0.5, 5.0) in s
```

```@example geo
distance(APPoint(0.5, 5.0), s), distance(APPoint(0.5, 5.0), s; mode=:boundary)
```

```@example geo
s_rotated = rotate(s, pi / 4)
strip_width(s_rotated) ≈ strip_width(s)   # rotation preserves the perpendicular distance
```

See [Drawing with Luxor.jl](@ref) for how `APHalfPlane2`/`APStrip2` render
(as their boundary line(s), since the region itself is unbounded) and
[Affine Maps](@ref) for how a general [`APAffineMap`](@ref) applies to
both.
