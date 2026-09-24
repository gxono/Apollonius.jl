```@meta
CurrentModule = Apollonius
```

# Circles

[`APCircle2`](@ref) is a center and a radius, `c.center` and `c.r`. Some of
what follows is a method *on* a circle (`area`, `rotate`, ...); the rest
(tangency, power of a point, radical axes, inversion) is a function *of*
one or more circles.

A point on the circumference works instead of the radius, when that's the
more natural thing on hand: `APCircle2(center, through)` is exactly
`APCircle2(center, distance(center, through))`:

```@example geo
using Apollonius

APCircle2(APPoint(0.0, 0.0), APPoint(3.0, 4.0))   # radius 5, same as APCircle2(APPoint(0.0, 0.0), 5.0)
```

```@raw html
<img src="../assets/img/circles/circle_cp.svg" alt="" style="width:100%; max-width: 700px;">
```

Three points on the circumference work too: `APCircle2(p1, p2, p3)` is
their circumcircle, computed directly (the same formula
[`circumcenter`](@ref) uses on an [`APTriangle`](@ref), without needing to
build one first):

```@example geo
APCircle2(APPoint(0.0, 0.0), APPoint(4.0, 0.0), APPoint(0.0, 3.0))
```

```@raw html
<img src="../assets/img/circles/circle_3p.svg" alt="" style="width:100%; max-width: 700px;">
```

A diameter works too. [`circle_with_diameter`](@ref) takes the two ends, or the
segment itself, and builds the circle centered at its midpoint. By Thales'
theorem, every other point of the circle sees the segment under a right
angle:

```@example geo
d = APSegment(APPoint(0.0, 0.0), APPoint(6.0, 2.0))
c_d = circle_with_diameter(d)
c_d == circle_with_diameter(d.p1, d.p2), c_d.center, c_d.r
```

```@example geo
p_d = point_on(c_d, 1.0)
angle_measure_at(p_d, d.p1, d.p2) ≈ pi / 2
```

```@raw html
<img src="../assets/img/circles/circle_diameter.svg" alt="A segment, the circle that has it as a diameter, and a point of the circle that sees the segment under a right angle" style="width:100%; max-width: 700px;">
```

It throws an `ArgumentError` if the three points are (or are too close
to) collinear, same as [`affine_map`](@ref) does for its three source
points. There's no finite circle through them in that case.

[`antipode`](@ref)`(p, c)` is the point of `c` diametrically opposite
`p`: `c.center` is the midpoint of `p` and its antipode, which is just
`reflection(p, c.center)` under the hood.

```@example geo
c0 = APCircle2(APPoint(0.0, 0.0), 5.0)
antipode(APPoint(5.0, 0.0), c0)   # [-5.0, 0.0], on the far side of c0.center
```

## Power of a point and tangent lines

The [`power_of_point`](@ref) of `p` with respect to a circle `c` is
`distance(p, c.center)^2 - c.r^2`: negative inside the circle, zero on it,
positive outside. Its square root, when `p` is outside, is exactly the
length of a tangent segment from `p` to the circle. That's
[`tangent_length`](@ref). [`tangent_points`](@ref) and [`tangent_lines`](@ref)
give the two actual points/lines of tangency.

```@example geo
using Apollonius

c = APCircle2(APPoint(0.0, 0.0), 5.0)
p = APPoint(13.0, 0.0)

power_of_point(p, c)     # 144.0 = 13² - 5²
tangent_length(c, p)     # 12.0  = sqrt(144)
pts = tangent_points(c, p)
```

```@raw html
<img src="../assets/img/circles/circle_tanp.svg" alt="" style="width:100%; max-width: 700px;">
```

This is the classic *tangent from an external point* construction: `pts[1]`
and `pts[2]` are the two points where a line through `p` just touches the
circle, and `power_of_point(p, c)` is nothing but the square of that
tangent length either way.

## Radical axis, radical center and radical circle

Two circles that don't share a center have a **radical axis**: the locus of
points whose power is equal with respect to both. [`radical_axis`](@ref)
always exists (even for circles that don't meet) and is perpendicular to
the line joining their centers. "Don't share a center" is checked with a
scale-aware tolerance (`atol`, like elsewhere in the package), not bare
equality: two circles can be mathematically concentric yet have centers
that only agree up to floating-point roundoff (this comes up for, e.g.,
[`orthic_axis`](@ref) of an equilateral triangle, whose circumcircle and
nine-point circle are concentric), and a bare `==` would miss that and
return a wildly wrong axis instead of throwing. Three circles have three pairwise radical
axes, and those three lines always meet at a single point, the
[`radical_center`](@ref); [`radical_circle`](@ref) is centered there,
orthogonal to all three (only defined when that common power is
non-negative).

```@example geo
c1 = APCircle2(APPoint(0.0, 0.0), 3.0)
c2 = APCircle2(APPoint(8.0, 0.0), 2.0)
c3 = APCircle2(APPoint(3.0, 6.0), 4.0)

ra = radical_axis(c1, c2)
rc = radical_center(c1, c2, c3)
rcirc = radical_circle(c1, c2, c3)
```

```@raw html
<img src="../assets/img/circles/circle_radical.svg" alt="" style="width:100%; max-width: 700px;">
```

[`radical_circle`](@ref) is itself one instance of a more general idea:
[`orthogonal_circle`](@ref) builds a circle orthogonal to a given one,
either centered at a chosen point outside it, or passing through two
chosen points. Two circles are orthogonal when the tangent lines at
either of their crossing points are perpendicular, equivalently when
`distance(c1.center, c2.center)^2 == c1.r^2 + c2.r^2`:

```@example geo
oc1 = orthogonal_circle(c1, APPoint(13.0, 0.0))   # centered at that point, radius = tangent length
distance(c1.center, oc1.center)^2 ≈ c1.r^2 + oc1.r^2
```

```@example geo
oc2 = orthogonal_circle(c1, APPoint(8.0, 3.0), APPoint(-4.0, 6.0))   # through both points instead
distance(c1.center, oc2.center)^2 ≈ c1.r^2 + oc2.r^2
```

The two-point form builds on the classical inversive-geometry fact that
the circle through `p1`, `p2` and the [`invert`](@ref) of `p1` in `c1`
is orthogonal to `c1`. It throws an `ArgumentError` for the two
configurations that fact can't resolve on its own (`p1`/`p2` sitting
exactly on `c1`, or forming an exact inverse pair): those have genuine
solutions too, just not from this one construction.

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
<img src="../assets/img/circles/inversion_line.svg" alt="" style="width:100%; max-width: 700px;">
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
<img src="../assets/img/circles/inversion_segment.svg" alt="" style="width:100%; max-width: 700px;">
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
<img src="../assets/img/circles/inversion_triangle.svg" alt="" style="width:100%; max-width: 700px;">
```

In the first example, none of the triangle's sides passes through the inversion center, so all three become circular arcs. If one side does lie on a line through the center, that side stays straight; the other two still become arcs.

```@raw html
<img src="../assets/img/circles/inversion_triangle2.svg" alt="" style="width:100%; max-width: 700px;">
```

Same rule for any straight-sided polygon: each side inverts on its own, straight if its line passes through the center, an arc otherwise, so the result can freely mix both.

A circular arc inverts to another arc of the image circle (or to a straight
segment, if its own circle passes through the inversion center); an
ellipse, a hyperbola, a parabola, or an arc of one, generally does not
invert to another conic at all, so `invert` gives back a sampled
[`APParametricCurve2`](@ref) for those instead:

```@example geo
invert(APEllipse2(APPoint(4.0, 0.0), 2.0, 1.0), APPoint(0.0, 0.0)) isa APParametricCurve2
```

```@raw html
<img src="../assets/img/circles/inversion_ngon.svg" alt="" style="width:100%; max-width: 700px;">
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

## Similitude centers and common tangents

Two circles have two centers of similitude: the [`external_similitude_center`](@ref)
(where their external common tangents meet) and the
[`internal_similitude_center`](@ref) (where the internal ones, the ones
that cross between the circles, meet). [`external_tangent_lines`](@ref)
and [`internal_tangent_lines`](@ref) return those tangent lines directly,
each as `APLine(p1, p2)` with `p1`/`p2` the actual points of tangency on
`c1`/`c2` respectively (not the similitude center, even though every one
of these lines does pass through it):

```@example geo
external_similitude_center(c1, c2)   # [24.0, 0.0]
internal_similitude_center(c1, c2)   # [4.8, 0.0]
ext = external_tangent_lines(c1, c2)
int = internal_tangent_lines(c1, c2)
distance(ext[1].p1, c1.center), distance(ext[1].p2, c2.center)   # (c1.r, c2.r)
```

```@raw html
<img src="../assets/img/circles/similitude_center.svg" alt="" style="width:100%; max-width: 700px;">
```

The external center is far from both circles here because `c1` and `c2`
have fairly close radii. The closer two radii are, the further out the
external center sits, reaching infinity (parallel tangents) when the radii
are exactly equal (in which case [`external_similitude_center`](@ref)
throws, since there is no finite point to return).

These similitude centers are also exactly the points used by the
Apollonius/tangent-circle constructions (see
[Tangency & Apollonius Problems](@ref)), since a circle tangent to two
given circles is related to them by a homothety centered at one of these
two points. Applied to a triangle's own circumcircle and incircle, they
land on two more named triangle centers: `external_similitude_center(circumcircle(t),
incircle(t))` is Kimberling X(56), and `internal_similitude_center(circumcircle(t),
incircle(t))` is X(55) (see [Triangles & Triangle Centers](@ref)).

[`tangent_parallel`](@ref) gives the two tangent lines to a circle parallel to a given line: the tangents at the two ends of the diameter perpendicular to it. In each returned line, the first point is the point of tangency:

```@example geo
t1, t2 = tangent_parallel(c, APLine(APPoint(0.0, 3.0), APPoint(1.0, 4.0)))
```

```@raw html
<img src="../assets/img/circles/tangent_parallel.svg" alt="" style="width:100%; max-width: 700px;">
```

## Choosing among the intersections

[`intersection`](@ref) returns a `Vector` of the points where two objects
meet, and the order is fixed for the two most common pairs:

* line and circle: in the direction of the line, from `l.p1` towards `l.p2`;
* two circles: the first point is on the left when going from the first
  center to the second, the second is on the right.

For any other pair, do not rely on the order: pick the point you want by
where it is, with [`nearest_point`](@ref)`(points, p)`, or as "the other
one" with [`other_intersection`](@ref)`(a, b, known)`. The second is the
usual case of a line through a point of a circle: it returns the second
intersection, or `nothing` when the line is tangent there.

```@example geo
c = APCircle2(APPoint(0.0, 0.0), 5.0)
l = APLine(APPoint(-5.0, 0.0), APPoint(0.0, 3.0))          # goes through (-5, 0), a point of c
other_intersection(l, c, APPoint(-5.0, 0.0))                # the second point where l meets c
```

```@example geo
pts = intersection(c, APCircle2(APPoint(6.0, 0.0), 5.0))   # two points, above and below the x-axis
nearest_point(pts, APPoint(3.0, 10.0))                      # the upper one
```

[`angle_measure_intersection`](@ref)`(c1, c2)` is the measure of the angle at which two circles cross,
between `0` (they touch) and `π/2` (they are orthogonal), or `nothing` when
they do not meet.

```@example geo
c1 = APCircle2(APPoint(0.0, 0.0), 5.0)
angle_measure_intersection(c1, orthogonal_circle(c1, APPoint(13.0, 0.0))) ≈ pi / 2
```

```@raw html
<img src="../assets/img/circles/intersection_choice.svg" alt="Choosing the second point where a line meets a circle, and the nearest point of two circles' intersection" style="width:100%; max-width: 700px;">
```

!!! warning "The order of the intersections is fixed for two cases only"
    A line and a circle give their points along the line, and two circles give the point on the left first. For any other pair the order is not specified: choose with [`nearest_point`](@ref) or [`other_intersection`](@ref).

## How two circles (or a line and a circle) relate

[`circles_position`](@ref) and [`line_circle_position`](@ref) classify the
relationship between two circles, or a line and a circle, as a `Symbol`
rather than a single boolean, useful when you need to distinguish, say,
"tangent" from "disjoint" from "one contains the other" in one call instead
of chaining several predicates:

```@example geo
circles_position(APCircle2(APPoint(0.0, 0.0), 5.0), APCircle2(APPoint(2.0, 0.0), 3.0))   # :tangent_int
line_circle_position(APLine(APPoint(0.0, 5.0), APPoint(1.0, 5.0)), APCircle2(APPoint(0.0, 0.0), 5.0))   # :tangent
```

```@raw html
<img src="../assets/img/circles/circle_positions.svg" alt="The six relative positions of two circles, with the symbol circles_position returns for each" style="width:100%; max-width: 700px;">
```

`circles_position` returns one of `:identical`, `:concentric`,
`:disjoint_ext`, `:tangent_ext`, `:secant`, `:tangent_int` or
`:disjoint_int`; `line_circle_position` returns one of `:disjoint`,
`:tangent` or `:secant`.

```@raw html
<img src="../assets/img/circles/line_circle_positions.svg" alt="A line and a circle, disjoint, tangent and secant" style="width:100%; max-width: 700px;">
```

## Chords, diameters and offset circles

[`chord`](@ref)`(c, θ1, θ2)` is the segment between the points of a circle at two
polar angles, and [`diameter`](@ref)`(c, angle)` the one through the point at
`angle` and its [`antipode`](@ref). [`offset_circle`](@ref)`(c, d)` is the
concentric circle whose radius is `c.r + d`, the counterpart of
[`offset_line`](@ref) (a negative `d` shrinks it, and it must stay positive):

```@example geo
c_o = APCircle2(APPoint(0.0, 0.0), 3.0)
chord(c_o, 0.5, 2.4), diameter(c_o, 5.0)
```

```@example geo
offset_circle(c_o, 1.0), offset_circle(c_o, -1.0)
```

```@raw html
<img src="../assets/img/circles/chord_diameter.svg" alt="A circle with a chord, a diameter and the two circles offset by plus and minus one" style="width:100%; max-width: 700px;">
```


## Circular arcs

[`APCircularArc2`](@ref) is the arc of a circle between two of its points,
traversed **counterclockwise** from the first to the second. Fixing the
direction like this is what makes the two points unambiguous, since
otherwise there'd be two different arcs (the short way and the long way
around) that a bare pair of points couldn't tell apart.

```@example geo
p1, p2 = APPoint(8.0, 0.0), APPoint(0.0, 2.0)
arc = APCircularArc2(c, p1, p2)

measure(arc)        # π/2: the swept angle, counterclockwise from p1 to p2
arc_length(arc)      # c.r * measure(arc)
```

```@example geo
point_on(arc, 0.0) ≈ p1   # t=0 is p1, t=1 is p2
midpoint(arc)                   # point_on(arc, 0.5)
```

```@raw html
<img src="../assets/img/circles/arc.svg" alt="" style="width:100%; max-width: 700px;">
```

`APCircularArc2(center, r, p1, p2)` builds the same arc straight from the
circle's raw center and radius, without an `APCircle2` in hand first
(`APCircularArc2(center, p1, p2)`, with no `r`, is the same thing again
with `r` taken to be `distance(center, p1)`):

```@example geo
APCircularArc2(c.center, c.r, p1, p2) == arc
```

Swapping `p1` and `p2` gives the *complementary* arc (the other `3/4` of
this circle here), not the same arc traversed backwards. `APCircularArc2`
only ever sweeps counterclockwise, so which points is `p1` and which is
`p2` is exactly what picks one of the two candidate arcs. [`reverse`](@ref)
does exactly that swap:

```@example geo
reverse(arc) == APCircularArc2(c, p2, p1), measure(reverse(arc)) ≈ 2pi - measure(arc)
```

This is the fix for a common gotcha: if `arc` gets built from points that
already live in a mirrored coordinate space (e.g. after
[`@prepare_to_picture`](@ref)'s default `flip=true`, see
[Drawing with Luxor.jl](@ref)), the "counterclockwise" sweep comes out
backwards, since it's computed straight from the `(x, y)` values with no
idea they're mirrored; `reverse` corrects that after the fact (building
the arc *before* the flip and letting the whole object pass through
`@prepare_to_picture` handles it automatically instead, the same as for
[`APAngle2`](@ref)).

Ellipses have the exact same arc type, [`APEllipticArc2`](@ref), and the
exact same convention (`reverse` included); see
[Conics: Ellipse, Parabola & Hyperbola](@ref).

`APCircularArc2` is also what [`interstices`](@ref) (see
[Tangency & Apollonius Problems](@ref)) builds a curvilinear triangle's
three sides out of.

[`rand`](@ref) draws a uniformly random point on a circle or a circular
arc's own boundary (see [Points, Lines & Rays](@ref) for the general
story across every shape); for a full circle or a circular arc this is
exact, uniform in arc length, not just in angle or parameter:

```@example geo
p = rand(c)
isapprox(distance(p, c.center), c.r; atol=1e-9)   # exactly on the circle, every time
in(rand(arc), arc)                                # exactly on this arc, not just the full circle
```

An `APCircularArc2` also intersects `APLine`/`APSegment`/`APRay`, a full
`APCircle2`, or another circular arc; see
[Intersecting an arc](@ref) for the general story (including the arc
types below).

!!! warning "An arc always runs counterclockwise"
    [`APCircularArc2`](@ref)`(circle, p1, p2)` sweeps counterclockwise from `p1` to `p2`. Swapping the two points gives the complementary arc, and `reverse` does the same.

### Compass arcs

In a ruler-and-compass construction the second end of an arc is rarely
a point you already have: you set the compass to a radius and swing it
through some measure or distance. [`arc_with_measure`](@ref)`(center, p, m)`
and [`arc_with_length`](@ref)`(center, p, len)` build exactly that: the arc
of the circle centered at `center` through `p`, starting at `p` and
sweeping a given measure (radians) or arc length. A negative value sweeps
clockwise, and since an `APCircularArc2` always runs counterclockwise from
`p1` to `p2`, that case comes back with `p` stored as `arc.p2`:

```@example geo
tick = arc_with_measure(c.center, p1, pi / 6)
measure(tick) ≈ pi / 6, tick.p1 ≈ p1
```

```@example geo
back = arc_with_length(c.center, p1, -1.0)   # 1 unit of arc length, clockwise
arc_length(back) ≈ 1.0, back.p2 ≈ p1
```

When the arc is given by polar angles instead of points,
`APCircularArc2(center, r, θ1, θ2)` builds it from the two angles
(counterclockwise by default, `ccw=false` for clockwise).
[`semicircle`](@ref)`(center, p)` is the half circle starting at `p`, and
[`extend_arc`](@ref)`(arc, δ)` lengthens an arc by `δ` radians at each end
(a negative `δ` shortens it), always on the same circle:

```@example geo
quarter = APCircularArc2(c.center, c.r, 0.0, pi / 2)
half = semicircle(c.center, p1)
measure(quarter) ≈ pi / 2, measure(half) ≈ pi, measure(extend_arc(quarter, 0.1)) ≈ pi / 2 + 0.2
```

```@raw html
<img src="../assets/img/circles/compass_arcs.svg" alt="Arcs swept from a point of a circle by a given angle and by a given length" style="width:100%; max-width: 700px;">
```

[`compass_trace`](@ref), the arc centered on a point that a compass leaves
on paper, and the constructions built on it are on the
[Compass & Ruler Constructions](@ref) page.

### Arcs from other data

[`arc_through_points`](@ref)`(a, b, c)` is the arc from `a` to `c` that passes
through `b`. Arcs run counterclockwise, so when `a → b → c` goes clockwise the
result has `c` as its first point. [`arc_with_radius`](@ref)`(a, b, r)` is the
arc of radius `r` that goes counterclockwise from `a` to `b`: the short one by
default, and the long one with `large=true`:

```@example geo
arc_through_points(APPoint(0.0, 0.0), APPoint(2.0, 1.5), APPoint(4.0, 0.0))
```

```@example geo
a_r, b_r = APPoint(7.0, 0.0), APPoint(10.0, 0.0)
measure(arc_with_radius(a_r, b_r, 2.0)), measure(arc_with_radius(a_r, b_r, 2.0; large=true))
```

```@raw html
<img src="../assets/img/circles/arcs_from_data.svg" alt="An arc through three points, and the short and the long arc of radius 2 between two points" style="width:100%; max-width: 700px;">
```


## Circular sectors, segments and annuli

An arc alone is just a curve; closing it up gives a genuine region: a
finite-area [`APPolygon`](@ref) whose `sides` mix straight segments with
the arc itself. [`APCircularSector2`](@ref), [`APCircularSegment2`](@ref)
and [`APAnnularSector2`](@ref) are the three classical ways to do this
(`APCircularSector2(circle, p1, p2)` is shorthand for
`APCircularSector2(APCircularArc2(circle, p1, p2))`, and likewise for the
other two. Each also takes the circle's raw `center`/`r` directly
instead, e.g. `APCircularSector2(center, r, p1, p2)`):

* **[`APCircularSector2`](@ref)**, the "pie slice": bounded by the two
  radii `circle.center -> p1`, `circle.center -> p2`, and the arc between
  them.
* **[`APCircularSegment2`](@ref)**, the "cap": bounded by the arc and the
  straight chord `[p1, p2]` instead of the two radii.
* **[`APAnnularSector2`](@ref)**, the "ring slice": the region between
  `arc` and the corresponding arc of a smaller, concentric circle
  (`r_inner`), closed off by the two radial segments between them. This is
  Luxor's own `sector(center, innerradius, outerradius, ...)` shape,
  represented here as a real `APPolygon`.

```@example geo
sec = APCircularSector2(arc)
area(sec)        # r² * measure(arc) / 2
perimeter(sec)    # the two radii (2r) plus the arc length
```

```@example geo
seg = APCircularSegment2(arc)
area(seg)        # r² * (measure(arc) - sin(measure(arc))) / 2
perimeter(seg)    # the arc length plus the chord [p1, p2]
```

```@example geo
asec = APAnnularSector2(arc, 2.0)   # inner radius 2.0
area(asec)        # outer sector area minus inner sector area
```

```@raw html
<img src="../assets/img/circles/sec_ann.svg" alt="" style="width:100%; max-width: 700px;">
```

None of these three formulas is hand-derived per type. Every one comes
for free from the generic, sides-based `area`/`perimeter` every
[`APPolygon`](@ref) shares (see [`APPolygon`](@ref)'s own docstring), and
none needs to special-case whether `arc` sweeps less or more than half the
circle (a "minor" vs "major" arc), since `measure(arc)` is already the
specific directed angle for *this* arc.

Both `APCircularSector2` and `APCircularSegment2` have a `Base.in` matching
their shape: inside the circle *and* on the correct side (angularly, for
a sector; of the chord, for a segment):

```@example geo
c.center in sec, c.center in seg   # the center is in the sector, but not this segment
```

## Transforming arcs, sectors and segments

`rotate`, `reflection` and `homothety` all work on an [`APCircularArc2`](@ref)
(and, by delegating to it, on an [`APCircularSector2`](@ref)/[`APCircularSegment2`](@ref)/[`APAnnularSector2`](@ref)
too). `rotate` and `homothety` never reverse orientation (even `homothety`
with a negative ratio, a point reflection through the center, is really just
a 180° rotation), so `p1`/`p2` transform pointwise with no surprises:

```@example geo
rotate(arc, 2pi / 3)
homothety(arc, -2.0)   # negative k: still no swap needed
```

```@raw html
<img src="../assets/img/circles/arc_rot_hom.svg" alt="" style="width:100%; max-width: 700px;">
```

Reflecting about an `APPoint` is likewise a point reflection: no
swap. Reflecting about an `APLine`, however, is a true mirror: it *does*
reverse orientation, so `reflection(::APCircularArc2, ::APLine)` also swaps
`p1` and `p2` internally, keeping the result's own `p1 -> p2` sweep
counterclockwise like every other `APCircularArc2`:

```@example geo
reflection(arc, APPoint(1.0, 1.0))                     # point reflection: p1/p2 not swapped
reflection(arc, APLine(APPoint(0.0, 0.0), APPoint(1.0, 1.0)))  # line reflection: p1/p2 swapped
```

```@raw html
<img src="../assets/img/circles/arc_cen_axi.svg" alt="" style="width:100%; max-width: 700px;">
```

Without that swap, the reflected endpoints alone would trace out the arc's
*complementary* 3/4-of-the-circle instead of its true mirror image.

## The gap between three mutually tangent circles

Three circles that are pairwise tangent (each coin-touching-coin, or one
containing the other two) leave a curvilinear-triangle gap between them.
[`interstices`](@ref) finds it (or, when one circle encloses the other
two, *both* gaps, one on each side):

```@example geo
u1 = APCircle2(APPoint(0.0, 0.0), 1.0)
u2 = APCircle2(APPoint(2.0, 0.0), 1.0)
u3 = APCircle2(APPoint(1.0, sqrt(3)), 1.0)

gap = only(interstices(u1, u2, u3))
area(gap), perimeter(gap)
```

```@raw html
<img src="../assets/img/circles/circle_gap.svg" alt="" style="width:100%; max-width: 700px;">
```

The result is an [`APInterstice2`](@ref): a specific 3-arc
[`APPolygon`](@ref) built by finding the circle(s) tangent to all three
(the classical `CCC` Apollonius problem, see
[Tangency & Apollonius Problems](@ref)) and picking out the facing arc on
each of `u1`/`u2`/`u3`.

```@example geo
gap isa APInterstice2
```

## General curvilinear polygons

[`APCurvilinearTriangle2`](@ref), [`APCurvilinearQuadrilateral2`](@ref) and
[`APCurvilinearNgon2`](@ref) generalize [`APInterstice2`](@ref) beyond "3
arcs from mutually tangent circles": each is a closed region bounded by
*any* mix of straight ([`APSegment`](@ref)) and curved
([`APCircularArc2`](@ref), `APEllipticArc2`, `APParabolicArc2`,
`APHyperbolicArc2`) sides, built directly from those sides rather than
derived from circles:

| Type | Number of sides |
|:-----|:-----------------|
| [`APCurvilinearTriangle2`](@ref) | 3 |
| [`APCurvilinearQuadrilateral2`](@ref) | 4 |
| [`APCurvilinearNgon2`](@ref) | any number ≥ 3, given as a vector |

```@example geo
circ = APCircle2(APPoint(0.0, 0.0), 3.0)
arc = APCircularArc2(circ, APPoint(0.0, 3.0), APPoint(-3.0, 0.0))
rad1 = APSegment(APPoint(0.0, 3.0), APPoint(0.0, 0.0))
rad2 = APSegment(APPoint(0.0, 0.0), APPoint(-3.0, 0.0))

ct = APCurvilinearTriangle2(rad1, arc, rad2)   # one curved side, two straight
area(ct), perimeter(ct)
```

```@raw html
<img src="../assets/img/circles/cur_pol.svg" alt="" style="width:100%; max-width: 700px;">
```

This is exactly what [`APCircularSector2`](@ref) computes for the same
three sides. Building it directly like this is only necessary when the
sides don't come from a common circle/ellipse/etc. in the first place
(e.g. after inverting or affine-mapping a region whose sides were
originally circular, see [Affine Maps](@ref) and
[Inversion, polar lines and poles](@ref)):

```@example geo
eq = APEllipse2(APPoint(6.0, 0.0), 2.0, 1.0, 0.0)
earc = APEllipticArc2(eq, APPoint(8.0, 0.0), APPoint(6.0, 1.0))
s1 = APSegment(APPoint(0.0, 3.0), APPoint(6.0, 1.0))
s2 = APSegment(APPoint(-3.0, 0.0), earc.p1)
cq = APCurvilinearQuadrilateral2(earc, s1, arc, s2)
area(cq) > 0   # a genuine 4-sided mixed straight/circular/elliptic region
```

```@raw html
<img src="../assets/img/circles/cur_pol_cua.svg" alt="" style="width:100%; max-width: 700px;">
```

[`APCurvilinearNgon2`](@ref)`(sides)` is the same idea for any number of
sides ≥ 3, given as a plain vector instead of one positional argument per
side, useful when the side count isn't fixed ahead of time:

```@example geo
cn = APCurvilinearNgon2([rad1, arc, rad2])   # the same 3 sides as ct above
cn == APCurvilinearNgon2(rad1, arc, rad2)   # one side per argument also works, same as the vector form
area(cn) ≈ area(ct), perimeter(cn) ≈ perimeter(ct)   # same sides, same region either way
```

`rotate`, `reflection`, `homothety` and `translate` all transform every
side independently and reassemble the result, the same generic,
sides-based machinery every [`APPolygon`](@ref) shares (see
[`APCurvilinearNgon2`](@ref)'s own worked example above, via `invert`,
for the *n*-sided case built from an arbitrary vector of sides).

## Open chains: `APPolyline2` and `APCurvilinearPolyline2`

[`APPolyline2`](@ref) is [`APSegment`](@ref) generalized to any number of
points: an open chain through a list of vertices, joined by straight
sides. It's the open counterpart of [`APStraightNgon`](@ref) (which
always closes back to its first vertex; this never does), so it's an
[`APCurve`](@ref), not an [`APPolygon`](@ref), so it has no area and no interior:

```@example geo
zigzag = APPolyline2(APPoint(0.0, 0.0), APPoint(2.0, 3.0), APPoint(4.0, 0.0), APPoint(6.0, 3.0))
length(zigzag), arc_length(zigzag)
```

[`APCurvilinearPolyline2`](@ref) is the curved-sided counterpart, built
from a plain vector of sides the same way [`APCurvilinearNgon2`](@ref)
is, except it stays open (the last side doesn't have to close back to the
first) and its sides are taken in the order given rather than
auto-reordered: each side's own endpoint must match the next side's own
start, or the constructor throws:

```@example geo
open_chain = APCurvilinearPolyline2([reverse(rad1), arc])   # a straight side into a curved one
arc_length(open_chain) ≈ distance(rad1[1], rad1[2]) + arc_length(arc)
```

Both support the usual `rotate`/`homothety`/`reflection`/`translate`
quartet (each vertex or side transformed independently and reassembled),
[`reverse`](@ref) (runs the chain back to front), `p in pl`/
`distance(p, pl)` (nearest-side membership/distance, not "inside a
region" the way [`APPolygon`](@ref)'s `in` works), and indexing/length/
iteration the same as [`APSegment`](@ref)/[`APLine`](@ref):

```@example geo
reverse(zigzag)[1] == vertices(zigzag)[end]
```

```@raw html
<img src="../assets/img/circles/open_chains.svg" alt="An open polyline and an open chain made of a straight side and an arc" style="width:100%; max-width: 700px;">
```

## Rounding a corner

An [`APCurvilinearPolyline2`](@ref) chains segments and arcs end to end. A
classic use is rounding the corner of a polyline: the two sides that meet at a
corner are cut short, and a circular arc of a given radius, tangent to both,
joins the cuts. The center of that arc is on the bisector of the corner, at the
distance from the corner where the circle just touches the two sides.

[`fillet`](@ref)`(a, v, b, r)` finds that arc: it returns a `NamedTuple` with
the arc that faces the corner, its center and the two points of contact `t1`
and `t2`. The arc runs counterclockwise, so its endpoints are `t1` and `t2`
when the corner turns left and `t2` and `t1` when it turns right.

```@example geo
fa, fv, fb = APPoint(0.0, 0.0), APPoint(6.0, 0.0), APPoint(4.0, 5.0)
fr = 1.0
ff = fillet(fa, fv, fb, fr)
distance(ff.center, APLine(fv, fa)) ≈ fr ≈ distance(ff.center, APLine(fv, fb))
```

[`round_corners`](@ref)`(shape, r)` rounds every corner of a convex polygon, giving an
[`APCurvilinearNgon2`](@ref), or every interior corner of a polyline, giving an
[`APCurvilinearPolyline2`](@ref). All the interior corners of a polyline must
turn the same way. When they turn right, the chain is traversed from the end,
so that they turn left, which is the direction an arc runs.

```@example geo
sq_rc = APStraightNgon([APPoint(0.0, 0.0), APPoint(4.0, 0.0), APPoint(4.0, 4.0), APPoint(0.0, 4.0)])
rc_sq = round_corners(sq_rc, 1.0)
length(sides(rc_sq)), area(rc_sq)
```

```@raw html
<img src="../assets/img/circles/round_corners.svg" alt="A pentagon and a polyline with their corners rounded, the originals dashed" style="width:100%; max-width: 700px;">
```
