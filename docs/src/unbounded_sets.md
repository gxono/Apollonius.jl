```@meta
CurrentModule = Apollonius
```

# Unbounded Regions: Half-Planes, Strips & Angles

Not every region in the package is bounded. [`APHalfPlane2`](@ref),
[`APStrip2`](@ref), [`APAngle2`](@ref) and [`APUnboundedPolygon2`](@ref) are
the four unbounded members of the [`APSet`](@ref) family, genuine regions of
the plane (they support `in`, `distance`, and the usual transforms), but
with infinite area, so none of them is an [`APRegion`](@ref)/[`APPolygon`](@ref)
and none has an `area`/`perimeter`. `APAngle2` already has its own
worked-example section; see [Points, Lines & Rays: Angles](@ref). This page
covers the other three.

| Type | Represents | Bounded by |
|:-----|:-----------|:-----------|
| [`APHalfPlane2`](@ref) | everything on one side of a line (that line included) | one [`APLine`](@ref) |
| [`APStrip2`](@ref) | the band between two parallel lines (both included) | two parallel [`APLine`](@ref)s |
| [`APAngle2`](@ref) | the infinite wedge between two rays from a shared vertex | two [`APRay`](@ref)s; see [Angles](@ref) |
| [`APUnboundedPolygon2`](@ref) | an unbounded region with a mix of straight and infinite sides | two [`APRay`](@ref)s and 0 or more [`APSegment`](@ref)s between them |

Being unbounded, none of the four has a finite extent to report:
[`APBoundingBox`](@ref) returns the empty box for all four (see
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

!!! details "See script"
    ```julia
    using Apollonius, Luxor
    import Luxor: julia_red, julia_blue, julia_green, julia_purple
    import Apollonius: rotate, translate, distance, midpoint

    lxm = @prepare_to_picture! width=500 height=260 margin=30 begin
        l = APLine(APPoint(0.0, 0.0), APPoint(0.0, 4.0))
        q = APPoint(1.0, 0.0)
        hp = APHalfPlane2(l, q)
        pts = [APPoint(x, y) for x in (-3.0, -1.0, 1.0, 3.0) for y in (-2.0, 0.0, 2.0)]
        far = APPoint(-3.0, 1.0)
        foot = projection(far, l)
    end


    begin
    Drawing(lxm.width, lxm.height, :svg)
    origin(); fontsize(15)
    inside = [p for p in pts if p in hp]
    outside = [p for p in pts if !(p in hp)]
    sethue(julia_blue)
    path(l, action=:stroke)
    gsave()
    setline(1); setdash("dash")
    sethue(julia_green)
    path(APSegment(far, foot), action=:stroke)
    grestore()
    sethue("gray80")
    sethue(julia_purple)
    sethue(julia_red)
    label("q", :N, q)
    sethue("white"); path([outside; far], action=:fillpreserve); sethue("gray80"); strokepath()
    sethue("white"); path(inside, action=:fillpreserve); sethue(julia_purple); strokepath()
    sethue("white"); path([q], action=:fillpreserve); sethue(julia_blue); strokepath()

    finish()
    preview()
    end
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

!!! details "See script"
    ```julia
    using Apollonius, Luxor
    import Luxor: julia_red, julia_blue, julia_green, julia_purple
    import Apollonius: rotate, translate, distance, midpoint

    lxm = @prepare_to_picture! width=500 height=240 margin=20 begin
        l = APLine(APPoint(0.0, -5.0), APPoint(0.0, 5.0))
        hp = APHalfPlane2(l, APPoint(1.0, 0.0))
        p1, p2 = APPoint(-6.0, -3.0), APPoint(6.0, 3.0)
        input = APLine(p1, p2)
        clipped = intersection(hp, input)
    end


    begin
    Drawing(lxm.width, lxm.height, :svg)
    origin()
    gsave()
    sethue("gray80"); setdash("dash")
    path(l, action=:stroke, extend=10)
    grestore()
    sethue(julia_blue)
    path(input, action=:stroke, extend=10)
    sethue(julia_purple); setline(3)
    path(clipped, action=:stroke, extend=10)

    finish()
    preview()
    end
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

!!! details "See script"
    ```julia
    using Apollonius, Luxor
    import Luxor: julia_red, julia_blue, julia_green, julia_purple
    import Apollonius: rotate, translate, distance, midpoint

    lxm = @prepare_to_picture! width=500 height=240 margin=20 begin
        l = APLine(APPoint(0.0, -5.0), APPoint(0.0, 5.0))
        hp = APHalfPlane2(l, APPoint(1.0, 0.0))
        c = APCircle2(APPoint(0.0, 0.0), 3.0)
        clipped = intersection(hp, c)
    end


    begin
    Drawing(lxm.width, lxm.height, :svg)
    origin()
    gsave()
    sethue("gray80"); setdash("dash")
    path(l, action=:stroke, extend=10)
    grestore()
    sethue(julia_blue)
    path(c, action=:stroke)
    sethue(julia_purple); setline(3)
    path(clipped, action=:stroke)

    finish()
    preview()
    end
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

!!! details "See script"
    ```julia
    using Apollonius, Luxor
    import Luxor: julia_red, julia_blue, julia_green, julia_purple
    import Apollonius: rotate, translate, distance, midpoint

    lxm = @prepare_to_picture! width=500 height=260 margin=30 begin
        l1 = APLine(APPoint(0.0, 0.0), APPoint(1.0, 0.0))
        l2 = APLine(APPoint(0.0, 3.0), APPoint(1.0, 3.0))
        s = APStrip2(l1, l2)
        pts = [APPoint(x, y) for x in (-3.0, 0.0, 3.0) for y in (-1.5, 1.5, 4.5)]
        far = APPoint(1.0, 4.5)
        foot = projection(far, l2)
    end


    begin
    Drawing(lxm.width, lxm.height, :svg)
    origin()
    inside = [p for p in pts if p in s]
    outside = [p for p in pts if !(p in s)]
    sethue(julia_blue)
    path([l1, l2], action=:stroke)
    gsave()
    setline(1); setdash("dash")
    sethue(julia_green)
    path(APSegment(far, foot), action=:stroke)
    grestore()
    sethue("gray80")
    sethue(julia_purple)
    sethue("white"); path([outside; far], action=:fillpreserve); sethue("gray80"); strokepath()
    sethue("white"); path(inside, action=:fillpreserve); sethue(julia_purple); strokepath()

    finish()
    preview()
    end
    ```

```@example geo
s_rotated = rotate(s, pi / 4)
strip_width(s_rotated) ≈ strip_width(s)   # rotation preserves the perpendicular distance
```

See [Drawing with Luxor.jl](@ref) for how `APHalfPlane2`/`APStrip2` render
(as their boundary line(s), since the region itself is unbounded),
[Drawing: Clipping, Dimensions & Reversing](@ref) for how to fill them up
to the edge of the picture instead, and [Affine Maps](@ref) for how a
general [`APAffineMap`](@ref) applies to
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

!!! details "See script"
    ```julia
    using Apollonius, Luxor
    import Luxor: julia_red, julia_blue, julia_green, julia_purple
    import Apollonius: rotate, translate, distance, midpoint

    lxm = @prepare_to_picture! width=500 height=240 margin=20 begin
        l1 = APLine(APPoint(-6.0, 0.0), APPoint(6.0, 0.0))
        l2 = APLine(APPoint(-6.0, 3.0), APPoint(6.0, 3.0))
        st = APStrip2(l1, l2)
        p1, p2 = APPoint(-6.0, -1.5), APPoint(6.0, 4.5)
        input = APLine(p1, p2)
        clipped = intersection(st, input)
    end


    begin
    Drawing(lxm.width, lxm.height, :svg)
    origin()
    gsave()
    sethue("gray80"); setdash("dash")
    path([l1, l2], action=:stroke, extend=10)
    grestore()
    sethue(julia_blue)
    path(input, action=:stroke, extend=10)
    sethue(julia_purple); setline(3)
    path(clipped, action=:stroke)

    finish()
    preview()
    end
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

!!! details "See script"
    ```julia
    using Apollonius, Luxor
    import Luxor: julia_red, julia_blue, julia_green, julia_purple
    import Apollonius: rotate, translate, distance, midpoint

    lxm = @prepare_to_picture! width=500 height=240 margin=20 begin
        l1 = APLine(APPoint(-6.0, 0.0), APPoint(6.0, 0.0))
        l2 = APLine(APPoint(-6.0, 3.0), APPoint(6.0, 3.0))
        st = APStrip2(l1, l2)
        c = APCircle2(APPoint(3.0, 1.5), 4.0)
        pieces = intersection(st, c)
    end


    begin
    Drawing(lxm.width, lxm.height, :svg)
    origin()
    gsave()
    sethue("gray80"); setdash("dash")
    path([l1, l2], action=:stroke, extend=10)
    grestore()
    sethue(julia_blue)
    path(c, action=:stroke)
    sethue(julia_purple); setline(3)
    foreach(pc -> path(pc, action=:stroke), pieces)

    finish()
    preview()
    end
    ```

## Intersecting two regions

[`intersection`](@ref) also works between two of `APAngle2`/`APHalfPlane2`/
`APStrip2` themselves: the region common to both, as whichever type it
collapses to, not necessarily one of these three. Two crossing half-planes
give an [`APAngle2`](@ref) (the wedge between their boundaries, on the side
each keeps):

```@example geo
hp_y0 = APHalfPlane2(APLine(APPoint(-5.0, 0.0), APPoint(5.0, 0.0)), APPoint(0.0, 1.0))   # y >= 0
wedge = intersection(hp1, hp_y0)
rad2deg(normalized_measure(wedge))
```

Two crossing strips give a bounded [`APQuadrilateral`](@ref) instead, since
all four boundaries end up finite on both ends:

```@example geo
s2 = APStrip2(APLine(APPoint(0.0, 0.0), APPoint(0.0, 1.0)), APLine(APPoint(4.0, 0.0), APPoint(4.0, 1.0)))
intersection(s, s2)
```

```@raw html
<img src="../assets/img/unbounded/region_intersect_strip_strip.svg" alt="Two crossing strips, with the parallelogram common to both drawn over them in purple" style="width:100%; max-width: 700px;">
```

!!! details "See script"
    ```julia
    using Apollonius, Luxor
    import Luxor: julia_red, julia_blue, julia_green, julia_purple
    import Apollonius: rotate, translate, distance, midpoint

    lxm = @prepare_to_picture! width=500 height=240 margin=20 begin
        l1 = APLine(APPoint(-6.0, 0.0), APPoint(6.0, 0.0))
        l2 = APLine(APPoint(-6.0, 3.0), APPoint(6.0, 3.0))
        s = APStrip2(l1, l2)
        l3 = APLine(APPoint(0.0, -5.0), APPoint(0.0, 5.0))
        l4 = APLine(APPoint(4.0, -5.0), APPoint(4.0, 5.0))
        s2 = APStrip2(l3, l4)
        q = intersection(s, s2)
    end


    begin
    Drawing(lxm.width, lxm.height, :svg)
    origin()
    gsave()
    sethue("gray80"); setdash("dash")
    path([l1, l2, l3, l4], action=:stroke, extend=10)
    grestore()
    sethue(julia_purple); setline(3)
    path(q, action=:stroke)

    finish()
    preview()
    end
    ```

A half-plane crossing a strip on only *one* side, though, is neither
bounded nor one of the three named types: it needs a fourth,
[`APUnboundedPolygon2`](@ref) (below).

```@example geo
intersection(hp1, s)
```

```@raw html
<img src="../assets/img/unbounded/region_intersect_halfplane_strip.svg" alt="A half-plane crossing a strip on one side: the result is bounded by both of the strip's rays and a segment of the half-plane's own boundary, drawn over them in purple" style="width:100%; max-width: 700px;">
```

!!! details "See script"
    ```julia
    using Apollonius, Luxor
    import Luxor: julia_red, julia_blue, julia_green, julia_purple
    import Apollonius: rotate, translate, distance, midpoint

    lxm = @prepare_to_picture! width=500 height=240 margin=20 begin
        p1, p2 = APPoint(0.0, -5.0), APPoint(0.0, 5.0)
        l = APLine(p1, p2)
        hp = APHalfPlane2(l, APPoint(1.0, 0.0))
        p3, p4 = APPoint(-6.0, 0.0), APPoint(6.0, 0.0)
        p5, p6 = APPoint(-6.0, 3.0), APPoint(6.0, 3.0)
        l1 = APLine(p3, p4)
        l2 = APLine(p5, p6)
        st = APStrip2(l1, l2)
        u = intersection(hp, st)
    end


    begin
    Drawing(lxm.width, lxm.height, :svg)
    origin()
    gsave()
    sethue("gray80"); setdash("dash")
    path(l, action=:stroke, extend=10)
    path([l1, l2], action=:stroke, extend=10)
    grestore()
    sethue(julia_purple); setline(3)
    path(u, action=:stroke, extend=10)

    finish()
    preview()
    end
    ```

See [Points, Lines & Rays: Angles](@ref) for the same idea against an
`APAngle2`, including the reflex case that can give up to two pieces
instead of one.

## `APUnboundedPolygon2`

The general shape an intersection of half-planes can produce when it's
unbounded but doesn't collapse to `APHalfPlane2`/`APStrip2`/`APAngle2`
either: two rays capping a chain of straight segments in between (zero or
more of them). It's rare to build one directly, since it's mostly what
[`intersection`](@ref) hands back above, but the constructor takes the two
rays and the interior vertices between them, in order:

```@example geo
u = APUnboundedPolygon2(APRay(APPoint(0.0, 3.0), APPoint(1.0, 3.0)), APPoint{2,Float64}[], APRay(APPoint(0.0, 0.0), APPoint(1.0, 0.0)))
vertices(u)   # ray1.origin, then the interior vertices, then ray2.origin
```

`in`/`distance`/the transforms all follow the same conventions as
`APHalfPlane2`/`APStrip2`/`APAngle2`:

```@example geo
APPoint(2.0, 1.5) in u, APPoint(-1.0, 1.5) in u, APPoint(2.0, 5.0) in u
```

```@example geo
distance(APPoint(-3.0, 1.5), u), distance(APPoint(2.0, 10.0), u; mode=:boundary)
```

Being unbounded, it has no `area`/`perimeter` and an empty
[`APBoundingBox`](@ref), the same as the other three; see
[Drawing with Luxor.jl](@ref) for how it renders (its actual boundary: the
two rays and the segments between them), [Drawing: Clipping, Dimensions &
Reversing](@ref) for how to fill it up to the edge of the picture instead,
and [Affine Maps](@ref) for how a
general [`APAffineMap`](@ref) applies to it.

## Clipping a bounded polygon

[`intersection`](@ref) also works between any of `APHalfPlane2`/`APStrip2`/
`APAngle2` and a straight-sided [`APPolygon`](@ref) (an [`APTriangle`](@ref),
[`APQuadrilateral`](@ref) or [`APStraightNgon`](@ref)): the part of the
polygon inside the region, in the tightest fitting type, not the points
where the region's boundary crosses the polygon's perimeter. Unlike a
line/segment/ray, the result is always *bounded* already, since the
polygon was:

```@example geo
t = APTriangle(APPoint(-2.0, 0.0), APPoint(4.0, 0.0), APPoint(1.0, 4.0))
intersection(hp1, t)
```

```@raw html
<img src="../assets/img/unbounded/halfplane_clip_polygon.svg" alt="A triangle crossed by a half-plane's boundary, with the quadrilateral piece inside the half-plane drawn over it in purple" style="width:100%; max-width: 700px;">
```

!!! details "See script"
    ```julia
    using Apollonius, Luxor
    import Luxor: julia_red, julia_blue, julia_green, julia_purple
    import Apollonius: rotate, translate, distance, midpoint

    lxm = @prepare_to_picture! width=500 height=240 margin=20 begin
        p1, p2 = APPoint(0.0, -5.0), APPoint(0.0, 5.0)
        l = APLine(p1, p2)
        hp = APHalfPlane2(l, APPoint(1.0, 0.0))
        t = APTriangle(APPoint(-2.0, 0.0), APPoint(4.0, 0.0), APPoint(1.0, 4.0))
        clipped = intersection(hp, t)
    end


    begin
    Drawing(lxm.width, lxm.height, :svg)
    origin()
    gsave()
    sethue("gray80"); setdash("dash")
    path(l, action=:stroke, extend=10)
    grestore()
    sethue(julia_blue)
    path(t, action=:stroke)
    sethue(julia_purple); setline(3)
    path(clipped, action=:stroke)

    finish()
    preview()
    end
    ```

An `APAngle2` works the same way but always comes back as a `Vector` (see
[Points, Lines & Rays: Angles](@ref) for why): 0 or 1 pieces for a convex
angle, or up to 2 for a *reflex* one, which can still split the polygon
into two disjoint pieces, the same way it can a line, segment, ray, circle,
ellipse or another region. Curved-sided polygons
([`APCircularSector2`](@ref) and similar) aren't supported yet.
