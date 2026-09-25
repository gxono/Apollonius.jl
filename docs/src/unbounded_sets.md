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
see [Points, Lines & Rays: Angles](@ref). This page
covers the other two.

| Type | Represents | Bounded by |
|:-----|:-----------|:-----------|
| [`APHalfPlane2`](@ref) | everything on one side of a line (that line included) | one [`APLine`](@ref) |
| [`APStrip2`](@ref) | the band between two parallel lines (both included) | two parallel [`APLine`](@ref)s |
| [`APAngle2`](@ref) | the infinite wedge between two rays from a shared vertex | two [`APRay`](@ref)s; see [Angles](@ref) |

Being unbounded, none of the three has a finite extent to report:
[`APBoundingBox`](@ref) returns the empty box for all three (see
[Polygons: Bounding Boxes](@ref) for what that means and why), they still get
`translate`/`rotate`/`homothety`/`reflection`ed normally, they just don't
contribute anything if mixed into a [`@boundingbox`](@ref)/
[`@prepare_to_picture`](@ref) block alongside bounded shapes.

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

```@raw html
<img src="../assets/img/unbounded/halfplane.svg" alt="A half-plane bounded by a vertical line: points inside in purple, outside in gray, and the distance from one outside point to the boundary" style="width:100%; max-width: 700px;">
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

### From a point and a normal

`APHalfPlane2(p, normal)` builds the half-plane whose boundary passes through
`p` perpendicular to `normal`, on the side that `normal` points to:

```@example geo
hp_n = APHalfPlane2(APPoint(0.0, 1.0), APVector(0.0, 1.0))
APPoint(0.0, 2.0) in hp_n, APPoint(0.0, 0.0) in hp_n
```

### Clipping a line, segment or ray

[`intersection`](@ref)`(hp, obj)` for a line, a segment or a ray is not the
usual points-where-they-cross: `hp` is a region, and this is the part of
`obj` that lies *inside* it, in `obj`'s own type. A line crossing the
boundary comes back as a ray; a ray or a segment already fully inside comes
back unchanged; one fully outside, or a line parallel to the boundary on
the wrong side, comes back as `nothing`:

```@example geo
crossing = APLine(APPoint(-6.0, -3.0), APPoint(6.0, 3.0))
intersection(hp1, crossing)
```

```@raw html
<img src="../assets/img/unbounded/halfplane_clip.svg" alt="A half-plane's boundary, a line crossing it, and the ray that is the part of the line inside the half-plane, drawn over it in purple" style="width:100%; max-width: 700px;">
```

```@example geo
intersection(hp1, APLine(APPoint(2.0, -6.0), APPoint(2.0, 6.0))),    # parallel to the boundary, on the inside: the whole line
    intersection(hp1, APLine(APPoint(-2.0, -6.0), APPoint(-2.0, 6.0)))   # parallel, on the outside: nothing
```

A point works the same way, just without a range to clip: the point itself
if it's in `hp`, `nothing` otherwise. Both argument orders work, and see
[Points, Lines & Rays: Angles](@ref) for the same idea on an `APAngle2`,
including the one case (a *reflex* angle) where the result can be two
separate pieces instead of one.

The same clipping works against an [`APCircle2`](@ref) or [`APEllipse2`](@ref)
(or one of their arcs), in that curve's own type: a circle crossed by the
boundary comes back as an arc, not a `Vector` (a single line only ever
crosses a circle twice, so there's at most one piece to keep):

```@example geo
c = APCircle2(APPoint(0.0, 0.0), 3.0)
half_circle = intersection(hp1, c)
rad2deg(measure(half_circle))
```

```@raw html
<img src="../assets/img/unbounded/halfplane_clip_circle.svg" alt="A half-plane's boundary and a circle centered on it, with the half of the circle inside the half-plane drawn over it in purple" style="width:100%; max-width: 700px;">
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

```@raw html
<img src="../assets/img/unbounded/strip.svg" alt="A strip between two parallel lines, with points inside in purple and outside in gray" style="width:100%; max-width: 700px;">
```

```@example geo
s_rotated = rotate(s, pi / 4)
strip_width(s_rotated) ≈ strip_width(s)   # rotation preserves the perpendicular distance
```

See [Drawing with Luxor.jl](@ref) for how `APHalfPlane2`/`APStrip2` render
(as their boundary line(s), since the region itself is unbounded) and
[Affine Maps](@ref) for how a general [`APAffineMap`](@ref) applies to
both.

### From a line and a width

`APStrip2(l, width)` is the strip between `l` and the parallel line at distance
`width` on its left (on its right for a negative `width`), built with
[`offset_line`](@ref):

```@example geo
st_w = APStrip2(APLine(APPoint(0.0, 0.0), APPoint(1.0, 0.0)), 2.0)
APPoint(0.0, 1.0) in st_w, APPoint(0.0, 3.0) in st_w, strip_width(st_w)
```

### Clipping a line, segment or ray to the strip

The same idea as for a half-plane, above: `s` is a region, so
`intersection(s, obj)` is the part of `obj` inside the band, not crossing
points. A transversal line comes back as a segment,
clipped by each of `s`'s two boundary lines in turn:

```@example geo
crossing = APLine(APPoint(-6.0, -1.5), APPoint(6.0, 4.5))
intersection(s, crossing)
```

```@raw html
<img src="../assets/img/unbounded/strip_clip.svg" alt="A strip's two boundary lines, a line crossing the band, and the segment that is the part of the line inside the strip, drawn over it in purple" style="width:100%; max-width: 700px;">
```

A strip is bounded by two parallel lines, so unlike a half-plane or an
angle, clipping a line/segment/ray to a strip is always a single piece:
there's no way for it to leave and come back.

A closed curve, though, can: a circle or ellipse large enough to poke out
through *both* boundary lines comes back clipped into **two** disjoint arcs,
one on each side, so this case always returns a `Vector`:

```@example geo
big_circle = APCircle2(APPoint(3.0, 1.5), 4.0)
pieces = intersection(s, big_circle)
length(pieces), round.(rad2deg.(measure.(pieces)); digits=1)
```

```@raw html
<img src="../assets/img/unbounded/strip_clip_circle.svg" alt="A strip and a circle wider than the band, split into two disjoint arcs where the circle pokes out on each side, drawn over it in purple" style="width:100%; max-width: 700px;">
```
