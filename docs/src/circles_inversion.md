```@meta
CurrentModule = Apollonius
```

# Circles: Inversion

The circles and points from [Circles: Basics](@ref):

```@example geo
using Apollonius

c = APCircle2(APPoint(0.0, 0.0), 5.0)
p = APPoint(13.0, 0.0)
c1 = APCircle2(APPoint(0.0, 0.0), 3.0)
c2 = APCircle2(APPoint(8.0, 0.0), 2.0)
nothing # hide
```

## Inversion, polar lines and poles

Inversion in a circle `c` sends a point `p` to the point on ray `c.center
→ p` at distance `k²/distance(p, c.center)` from the center (`k = c.r` by
default): points outside `c` go inside and vice versa, and points on `c`
are fixed. [`invert`](@ref) does this for a point, and for everything else
on this page: a line (usually inverts to an `APCircle2` through the
center), a circle (inverts to another `APCircle2`, or an `APLine` if it
passes through the inversion center), a segment or a ray (see below), a
triangle, a quadrilateral, a straight n-gon, a polyline, and every conic
arc. `invert` also takes the circle of inversion directly instead of a
center and a radius `k`.

```@example geo
invert(APPoint(10.0, 0.0), c)   # [2.5, 0.0]: 5²/10 = 2.5
```

[`invert_neg`](@ref) gives the *negative-ratio* inversion instead: the
same image, point-reflected through the inversion circle's own center
(i.e. on ray `p -> O` rather than `O -> p`):

```@example geo
invert_neg(APPoint(10.0, 0.0), c)   # [-2.5, 0.0]: the mirror image of the positive one
```

`invert`/`invert_neg` also take just `center` (and, as a keyword, `k`) to
build a reusable one-argument function, the same convenience
[`rotate`](@ref)/[`homothety`](@ref)/etc. have (see
[Affine Maps](@ref)), except this returns a plain closure rather than an
[`APAffineMap`](@ref), since circle inversion isn't an affine
transformation at all:

```@example geo
inv5 = invert(APPoint(0.0, 0.0); k=5.0)   # p -> invert(p, APPoint(0.0,0.0); k=5.0)
inv5(APLine(APPoint(2.0, 0.0), APPoint(2.0, 1.0))) isa APCircle2
map(inv5, [APLine(APPoint(2.0, 0.0), APPoint(2.0, 1.0)), APLine(APPoint(-3.0, 0.0), APPoint(-3.0, 1.0))])
```

```@raw html
<img src="../assets/img/circles/inversion_line.svg" alt="The circle of inversion, two lines, and the circle each line inverts to, both passing through the inversion center" style="width:100%; max-width: 700px;">
```

## Midcircles: swapping two circles by inversion

A **midcircle** of `c1` and `c2` is a circle `M` such that inverting in
`M` sends `c1` to `c2` (and, since inversion is its own inverse, `c2`
back to `c1`). [`midcircle`](@ref) builds it, for two circles or for a
circle and a line (a line is the "infinite-radius" case: inverting a
circle in a midcircle centered on it always gives back a line, never a
circle):

```@example geo
c4 = APCircle2(APPoint(8.0, 0.0), 2.0)
m1 = only(midcircle(c1, c4))
invert(c1, m1.center; k=m1.r) ≈ c4
```

```@raw html
<img src="../assets/img/circles/midcircle.svg" alt="Two circles and the midcircle that swaps them by inversion" style="width:100%; max-width: 700px;">
```

```@example geo
l4 = APLine(APPoint(-10.0, 5.0), APPoint(10.0, 5.0))
m2 = only(midcircle(c1, l4))
invert(c1, m2.center; k=m2.r) ≈ l4
```

```@raw html
<img src="../assets/img/circles/midcircle_line.svg" alt="A circle, a line and the midcircle that swaps them" style="width:100%; max-width: 700px;">
```

How many midcircles there are, and where, depends on how `c1` and `c2`
relate ([`circles_position`](@ref)): one when they're externally disjoint
or tangent (centered at the [`external_similitude_center`](@ref)), two
when they cross (one at each similitude center, both through the two
crossing points), and one when one sits properly inside the other
(centered at the [`internal_similitude_center`](@ref)). A circle and a
line follow the same three-way split (disjoint, tangent, secant), read
against the line instead of a second circle.

## Inverting a segment, a ray, a triangle or a polygon

A straight side doesn't generally stay straight under inversion: it only
does when the *line* it lies on passes through the inversion center
(then it inverts to another `APSegment`, on that same line); otherwise it
inverts to an arc of the circle its line inverts to: specifically the
arc that does *not* pass through the center, since that point is the image
of the line's own point at infinity, which a finite segment never reaches.
[`invert(::APSegment, ::APCircle2)`](@ref) returns whichever of the two
applies, as a `Union{APSegment,APCircularArc2}`. A ray reaches that point at
infinity at one end, so its image is instead an arc that *does* end at the
inversion center, via [`invert(::APRay, ::APCircle2)`](@ref):

```@example geo
invert(APSegment(APPoint(1.0, 0.5), APPoint(2.0, 1.0)), APPoint(0.0, 0.0))    # an APCircularArc2
invert(APSegment(APPoint(0.5, -1.5), APPoint(1.5, -1.0)), APPoint(0.0, 0.0))  # an APSegment: this line passes through (0,0)
```

```@raw html
<img src="../assets/img/circles/inversion_segment.svg" alt="Two segments and their images under inversion, one becoming a circular arc and the other staying a straight segment, along with the circle of inversion" style="width:100%; max-width: 700px;">
```

Since a triangle's, a quadrilateral's or a straight n-gon's sides invert
independently like this, their image is generally a mix of straight and
curved sides, not representable as another polygon of the same kind.
[`invert(::APTriangle, ::APCircle2)`](@ref) and its `APQuadrilateral`/
`APStraightNgon` siblings return an [`APCurvilinearNgon2`](@ref) instead: a
closed region bounded by any mix of `APSegment` and `APCircularArc2` sides,
each inverted independently and reconnected in order, regardless of the order
each side comes back in (`area`/`perimeter`/etc. walk the sides themselves to
find how they connect).

```@example geo
t2 = APTriangle(APPoint(1.5, 1.5), APPoint(3.0, 0.5), APPoint(1.0, -1.0))
cp = invert(t2, APPoint(0.0, 0.0))
area(cp), perimeter(cp)
```

```@raw html
<img src="../assets/img/circles/inversion_triangle.svg" alt="A triangle and the circle of inversion, with the triangle's image under inversion having all three sides curved into arcs" style="width:100%; max-width: 700px;">
```

In the first example, none of the triangle's sides passes through the inversion center, so all three become circular arcs. If one side does lie on a line through the center, that side stays straight; the other two still become arcs.

```@raw html
<img src="../assets/img/circles/inversion_triangle2.svg" alt="A triangle and the circle of inversion, with the triangle's image under inversion having one straight side, since that side's line passes through the center, and two curved arcs" style="width:100%; max-width: 700px;">
```

Same rule for any straight-sided polygon: each side inverts on its own, straight if its line passes through the center, an arc otherwise, so the result can freely mix both.

```@raw html
<img src="../assets/img/circles/inversion_ngon.svg" alt="A hexagon and the circle of inversion, with the hexagon's image under inversion bounded by a mix of curved arcs" style="width:100%; max-width: 700px;">
```

A circular arc inverts to another arc of the image circle (or to a straight
segment, if its own circle passes through the inversion center); an
ellipse, a hyperbola, a parabola, or an arc of one, generally does not
invert to another conic at all, so `invert` gives back a sampled
[`APParametricCurve2`](@ref) for those instead:

```@example geo
invert(APEllipse2(APPoint(4.0, 0.0), 2.0, 1.0), APPoint(0.0, 0.0)) isa APParametricCurve2
```

`area`/`perimeter` are the same generic, sides-based [`APPolygon`](@ref)
formulas every closed shape in the package shares (a straight side's own
contribution reduces to the standard shoelace-formula edge term);
`rotate`, `reflection` and `homothety` all work on an `APCurvilinearNgon2`
too, transforming each side independently.

[`polar_line`](@ref) and [`pole`](@ref) are the projective dual of this:
the polar of `p` with respect to `c` is the line through the two tangent
points from `p` (when `p` is outside `c`), and `pole` is its inverse,
recovering `p` from that line.

```@example geo
pl = polar_line(c, p)   # the line through pts[1] and pts[2] above
pole(c, pl)              # back to p = APPoint(13.0, 0.0)
```

```@raw html
<img src="../assets/img/circles/polar_line.svg" alt="The polar line of a point outside a circle, through the two tangent points from it, and the pole of another line recovered by the inverse construction" style="width:100%; max-width: 700px;">
```

!!! details "See script"
    ```julia
    using Apollonius, Luxor
    import Luxor: julia_red, julia_blue, julia_green, julia_purple
    import Apollonius: rotate, translate, distance, midpoint

    lxm = @prepare_to_picture! width=500 height=240 margin=20 begin
        c = APCircle2(APPoint(0.0, 0.0), 5.0)
        p = APPoint(13.0, 0.0)
        pts = tangent_points(c, p)
        pl = polar_line(c, p)

        l2 = APLine(APPoint(-6.0, 6.0), APPoint(4.0, 6.0))
        q = pole(c, l2)
    end


    begin
    Drawing(lxm.width, lxm.height, :svg)
    origin(); fontsize(15)

    gsave()
    setline(1); setdash("dash")
    sethue(julia_green)
    path([APSegment(p, pts[1]), APSegment(p, pts[2])], action=:stroke)
    grestore()

    sethue(julia_blue)
    path(c, action=:stroke)
    path(l2, action=:stroke)

    sethue(julia_purple)
    path(pl, action=:stroke)

    sethue(julia_red)
    label("p", :E, p)
    label("polar of p", :N, midpoint(pts...))
    label("l", :N, l2.p2)
    label("pole of l", :S, q)

    sethue("white"); path(pts, action=:fillpreserve); sethue(julia_green); strokepath()
    sethue("white"); path([p], action=:fillpreserve); sethue(julia_blue); strokepath()
    sethue("white"); path([q], action=:fillpreserve); sethue(julia_purple); strokepath()

    finish()
    preview()
    end
    ```
