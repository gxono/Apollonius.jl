```@meta
CurrentModule = EuclideanGeometry
```

# Circles

[`EGCircle2`](@ref) is a center and a radius, `c.center` and `c.r`. Some of
what follows is a method *on* a circle (`area`, `rotate`, ...); the rest —
tangency, power of a point, radical axes, inversion — is a function *of*
one or more circles.

## Power of a point and tangent lines

The [`power_of_point`](@ref) of `p` with respect to a circle `c` is
`distance(p, c.center)^2 - c.r^2`: negative inside the circle, zero on it,
positive outside. Its square root, when `p` is outside, is exactly the
length of a tangent segment from `p` to the circle — that's
[`tangent_length`](@ref). [`tangent_points`](@ref) and [`tangent_lines`](@ref)
give the two actual points/lines of tangency.

```@example geo
using EuclideanGeometry

c = EGCircle2(EGPoint(0.0, 0.0), 5.0)
p = EGPoint(13.0, 0.0)

power_of_point(p, c)     # 144.0 = 13² - 5²
tangent_length(c, p)     # 12.0  = sqrt(144)
pts = tangent_points(c, p)
```

This is the classic *tangent from an external point* construction: `pts[1]`
and `pts[2]` are the two points where a line through `p` just touches the
circle, and `power_of_point(p, c)` is nothing but the square of that
tangent length either way.

## Radical axis, radical center and radical circle

Two circles that don't share a center have a **radical axis**: the locus of
points whose power is equal with respect to both. [`radical_axis`](@ref)
always exists — even for circles that don't meet — and is perpendicular to
the line joining their centers. "Don't share a center" is checked with a
scale-aware tolerance (`atol`, like elsewhere in the package), not bare
equality — two circles can be mathematically concentric yet have centers
that only agree up to floating-point roundoff (this comes up for, e.g.,
[`orthic_axis`](@ref) of an equilateral triangle, whose circumcircle and
nine-point circle are concentric), and a bare `==` would miss that and
return a wildly wrong axis instead of throwing. Three circles have three pairwise radical
axes, and those three lines always meet at a single point, the
[`radical_center`](@ref); [`radical_circle`](@ref) is centered there,
orthogonal to all three (only defined when that common power is
non-negative).

```@example geo
c1 = EGCircle2(EGPoint(0.0, 0.0), 3.0)
c2 = EGCircle2(EGPoint(8.0, 0.0), 2.0)
c3 = EGCircle2(EGPoint(3.0, 6.0), 4.0)

ra = radical_axis(c1, c2)
rc = radical_center(c1, c2, c3)
rcirc = radical_circle(c1, c2, c3)
```

## Inversion, polar lines and poles

Inversion in a circle `c` sends a point `p` to the point on ray `c.center
→ p` at distance `k²/distance(p, c.center)` from the center (`k = c.r` by
default): points outside `c` go inside and vice versa, and points on `c`
are fixed. [`inversion`](@ref) does this for a point; [`invert`](@ref) has
methods for an `EGLine` (which usually inverts to an `EGCircle2` through the
center), an `EGCircle2` (which inverts to another `EGCircle2`, or an
`EGLine` if it passes through the inversion center), an [`EGSegment`](@ref)
(see below), an `EGTriangle`, and an `EGStraightNgon`.

```@example geo
inversion(EGPoint(10.0, 0.0), c)   # (2.5, 0.0): 5²/10 = 2.5
```

[`inversion_neg`](@ref) and [`invert_neg`](@ref) give the *negative-ratio*
inversion instead: the same image, point-reflected through the inversion
circle's own center (i.e. on ray `p -> O` rather than `O -> p`):

```@example geo
inversion_neg(EGPoint(10.0, 0.0), c)   # (-2.5, 0.0): the mirror image of the positive one
```

## Inverting a segment, triangle or polygon

A straight side doesn't generally stay straight under inversion: it only
does when the *line* it lies on passes through the inversion center
(then it inverts to another `EGSegment`, on that same line); otherwise it
inverts to an arc of the circle its line inverts to — specifically the
arc that does *not* pass through the center, since that point is the image
of the line's own point at infinity, which a finite segment never reaches.
[`invert(::EGSegment, ::EGPoint)`](@ref) returns whichever of the two
applies, as a `Union{EGSegment,EGCircularArc2}`:

```@example geo
invert(EGSegment(EGPoint(5.0, 2.0), EGPoint(8.0, 6.0)), EGPoint(0.0, 0.0))   # an EGCircularArc2
invert(EGSegment(EGPoint(3.0, 0.0), EGPoint(8.0, 0.0)), EGPoint(0.0, 0.0))   # an EGSegment: this line passes through (0,0)
```

Since an `EGTriangle`'s or `EGStraightNgon`'s sides invert independently
like this, their image is generally a mix of straight and curved sides —
not representable as another `EGTriangle`/`EGStraightNgon`.
[`invert(::EGTriangle, ::EGPoint)`](@ref) and
[`invert(::EGStraightNgon, ::EGPoint)`](@ref) return an
[`EGCurvilinearNgon2`](@ref) instead: a closed region bounded by any mix of
`EGSegment` and `EGCircularArc2` sides, each inverted independently and
reconnected in order.

```@example geo
t2 = EGTriangle(EGPoint(5.0, 2.0), EGPoint(9.0, 3.0), EGPoint(6.0, 8.0))
cp = invert(t2, EGPoint(0.0, 0.0))
area(cp), perimeter(cp)
```

`area`/`perimeter` are the same generic, sides-based [`EGPolygon`](@ref)
formulas every closed shape in the package shares (a straight side's own
contribution reduces to the standard shoelace-formula edge term);
`rotate`, `reflection` and `homothety` all work on an `EGCurvilinearNgon2`
too, transforming each side independently.

[`polar_line`](@ref) and [`pole`](@ref) are the projective dual of this:
the polar of `p` with respect to `c` is the line through the two tangent
points from `p` (when `p` is outside `c`) — and `pole` is its inverse,
recovering `p` from that line.

```@example geo
pl = polar_line(c, p)   # the line through pts[1] and pts[2] above
pole(c, pl)              # back to p = (13.0, 0.0)
```

## Similitude centers and common tangents

Two circles have two centers of similitude: the [`external_similitude_center`](@ref)
(where their external common tangents meet) and the
[`internal_similitude_center`](@ref) (where the internal ones — the ones
that cross between the circles — meet). [`external_tangent_lines`](@ref)
and [`internal_tangent_lines`](@ref) return those tangent lines directly.

```@example geo
external_similitude_center(c1, c2)   # (24.0, 0.0)
internal_similitude_center(c1, c2)   # (4.8, 0.0)
ext = external_tangent_lines(c1, c2)
int = internal_tangent_lines(c1, c2)
```

The external center is far from both circles here because `c1` and `c2`
have fairly close radii — the closer two radii are, the further out the
external center sits, reaching infinity (parallel tangents) when the radii
are exactly equal (in which case [`external_similitude_center`](@ref)
throws, since there is no finite point to return).

These similitude centers are also exactly the points used by the
Apollonius/tangent-circle constructions — see
[Tangency & Apollonius Problems](@ref) — since a circle tangent to two
given circles is related to them by a homothety centered at one of these
two points.

[`tangent_parallel`](@ref) gives the two tangent lines to a circle parallel
to a given line — the tangents at the two ends of the diameter
perpendicular to it:

```@example geo
t1, t2 = tangent_parallel(c, EGLine(EGPoint(0.0, 0.0), EGPoint(1.0, 1.0)))
```

## How two circles (or a line and a circle) relate

[`circles_position`](@ref) and [`line_circle_position`](@ref) classify the
relationship between two circles, or a line and a circle, as a `Symbol`
rather than a single boolean — useful when you need to distinguish, say,
"tangent" from "disjoint" from "one contains the other" in one call instead
of chaining several predicates:

```@example geo
circles_position(EGCircle2(EGPoint(0.0, 0.0), 5.0), EGCircle2(EGPoint(2.0, 0.0), 3.0))   # :tangent_int
line_circle_position(EGLine(EGPoint(0.0, 5.0), EGPoint(1.0, 5.0)), EGCircle2(EGPoint(0.0, 0.0), 5.0))   # :tangent
```

`circles_position` returns one of `:identical`, `:concentric`,
`:disjoint_ext`, `:tangent_ext`, `:secant`, `:tangent_int` or
`:disjoint_int`; `line_circle_position` returns one of `:disjoint`,
`:tangent` or `:secant`.

## Circular arcs

[`EGCircularArc2`](@ref) is the arc of a circle between two of its points,
traversed **counterclockwise** from the first to the second — fixing the
direction like this is what makes the two points unambiguous, since
otherwise there'd be two different arcs (the short way and the long way
around) that a bare pair of points couldn't tell apart.

```@example geo
p1, p2 = EGPoint(5.0, 0.0), EGPoint(0.0, 5.0)
arc = EGCircularArc2(c, p1, p2)

measure(arc)        # π/2: the swept angle, counterclockwise from p1 to p2
arc_length(arc)      # c.r * measure(arc)
```

```@example geo
point_on_arc(arc, 0.0) ≈ p1   # t=0 is p1, t=1 is p2
midpoint(arc)                   # point_on_arc(arc, 0.5)
```

Swapping `p1` and `p2` gives the *complementary* arc (the other `3/4` of
this circle here), not the same arc traversed backwards — `EGCircularArc2`
only ever sweeps counterclockwise, so which points is `p1` and which is
`p2` is exactly what picks one of the two candidate arcs. Ellipses have
the exact same arc type, [`EGEllipticArc2`](@ref), and the exact same
convention — see [Conics: Ellipse, Parabola & Hyperbola](@ref).

`EGCircularArc2` is also what [`interstices`](@ref) (see
[Tangency & Apollonius Problems](@ref)) builds a curvilinear triangle's
three sides out of.

## Circular sectors, segments and annuli

An arc alone is just a curve; closing it up gives a genuine region — a
finite-area [`EGPolygon`](@ref) whose `sides` mix straight segments with
the arc itself. [`EGCircularSector2`](@ref), [`EGCircularSegment2`](@ref)
and [`EGAnnularSector2`](@ref) are the three classical ways to do this
(`EGCircularSector2(circle, p1, p2)` is shorthand for
`EGCircularSector2(EGCircularArc2(circle, p1, p2))`, and likewise for the
other two):

* **[`EGCircularSector2`](@ref)** — the "pie slice": bounded by the two
  radii `circle.center -> p1`, `circle.center -> p2`, and the arc between
  them.
* **[`EGCircularSegment2`](@ref)** — the "cap": bounded by the arc and the
  straight chord `[p1, p2]` instead of the two radii.
* **[`EGAnnularSector2`](@ref)** — the "ring slice": the region between
  `arc` and the corresponding arc of a smaller, concentric circle
  (`r_inner`), closed off by the two radial segments between them —
  Luxor's own `sector(center, innerradius, outerradius, ...)` shape,
  represented here as a real `EGPolygon`.

```@example geo
sec = EGCircularSector2(arc)
area(sec)        # r² * measure(arc) / 2
perimeter(sec)    # the two radii (2r) plus the arc length
```

```@example geo
seg = EGCircularSegment2(arc)
area(seg)        # r² * (measure(arc) - sin(measure(arc))) / 2
perimeter(seg)    # the arc length plus the chord [p1, p2]
```

```@example geo
asec = EGAnnularSector2(arc, 2.0)   # inner radius 2.0
area(asec)        # outer sector area minus inner sector area
```

None of these three formulas is hand-derived per type — every one comes
for free from the generic, sides-based `area`/`perimeter` every
[`EGPolygon`](@ref) shares (see [`EGPolygon`](@ref)'s own docstring), and
none needs to special-case whether `arc` sweeps less or more than half the
circle (a "minor" vs "major" arc), since `measure(arc)` is already the
specific directed angle for *this* arc.

Both `EGCircularSector2` and `EGCircularSegment2` have a `Base.in` matching
their shape — inside the circle *and* on the correct side (angularly, for
a sector; of the chord, for a segment):

```@example geo
c.center in sec, c.center in seg   # the center is in the sector, but not this segment
```

## Transforming arcs, sectors and segments

`rotate`, `reflection` and `homothety` all work on an [`EGCircularArc2`](@ref)
(and, by delegating to it, on an [`EGCircularSector2`](@ref)/[`EGCircularSegment2`](@ref)/[`EGAnnularSector2`](@ref)
too). `rotate` and `homothety` never reverse orientation (even `homothety`
with a negative ratio, a point reflection through the center, is really just
a 180° rotation), so `p1`/`p2` transform pointwise with no surprises:

```@example geo
rotate(arc, pi / 3)
homothety(arc, -2.0)   # negative k: still no swap needed
```

Reflecting about an `EGPoint` is likewise a point reflection — no
swap. Reflecting about an `EGLine`, however, is a true mirror: it *does*
reverse orientation, so `reflection(::EGCircularArc2, ::EGLine)` also swaps
`p1` and `p2` internally, keeping the result's own `p1 -> p2` sweep
counterclockwise like every other `EGCircularArc2`:

```@example geo
reflection(arc, EGPoint(1.0, 1.0))                     # point reflection: p1/p2 not swapped
reflection(arc, EGLine(EGPoint(0.0, 0.0), EGPoint(1.0, 1.0)))  # line reflection: p1/p2 swapped
```

Without that swap, the reflected endpoints alone would trace out the arc's
*complementary* 3/4-of-the-circle instead of its true mirror image.

## The gap between three mutually tangent circles

Three circles that are pairwise tangent (each coin-touching-coin, or one
containing the other two) leave a curvilinear-triangle gap between them —
[`interstices`](@ref) finds it (or, when one circle encloses the other
two, *both* gaps, one on each side):

```@example geo
u1 = EGCircle2(EGPoint(0.0, 0.0), 1.0)
u2 = EGCircle2(EGPoint(2.0, 0.0), 1.0)
u3 = EGCircle2(EGPoint(1.0, sqrt(3)), 1.0)

gap = only(interstices(u1, u2, u3))
area(gap), perimeter(gap)
```

The result is an [`EGInterstice2`](@ref) — a specific 3-arc
[`EGPolygon`](@ref) built by finding the circle(s) tangent to all three
(the classical `CCC` Apollonius problem, see
[Tangency & Apollonius Problems](@ref)) and picking out the facing arc on
each of `u1`/`u2`/`u3`.

```@example geo
gap isa EGInterstice2
```

## General curvilinear polygons

[`EGCurvilinearTriangle2`](@ref), [`EGCurvilinearQuadrilateral2`](@ref) and
[`EGCurvilinearNgon2`](@ref) generalize [`EGInterstice2`](@ref) beyond "3
arcs from mutually tangent circles": each is a closed region bounded by
*any* mix of straight ([`EGSegment`](@ref)) and curved
([`EGCircularArc2`](@ref), `EGEllipticArc2`, `EGParabolicArc2`,
`EGHyperbolicArc2`) sides, built directly from those sides rather than
derived from circles:

| Type | Number of sides |
|:-----|:-----------------|
| [`EGCurvilinearTriangle2`](@ref) | 3 |
| [`EGCurvilinearQuadrilateral2`](@ref) | 4 |
| [`EGCurvilinearNgon2`](@ref) | any number ≥ 3, given as a vector |

![A curvilinear triangle mixing a circular arc and two straight sides](assets/img/placeholder.png)

```@example geo
circ = EGCircle2(EGPoint(0.0, 0.0), 3.0)
arc = EGCircularArc2(circ, EGPoint(3.0, 0.0), EGPoint(0.0, 3.0))
chord = EGSegment(EGPoint(0.0, 3.0), EGPoint(0.0, 0.0))
radius = EGSegment(EGPoint(0.0, 0.0), EGPoint(3.0, 0.0))

ct = EGCurvilinearTriangle2(radius, arc, chord)   # one curved side, two straight
area(ct), perimeter(ct)
```

This is exactly what [`EGCircularSector2`](@ref) computes for the same
three sides — building it directly like this is only necessary when the
sides don't come from a common circle/ellipse/etc. in the first place
(e.g. after inverting or affine-mapping a region whose sides were
originally circular, see [Affine Maps](@ref) and
[Inversion, polar lines and poles](@ref)):

```@example geo
eq = EGEllipse2(EGPoint(6.0, 0.0), 2.0, 1.0, 0.0)
earc = EGEllipticArc2(eq, EGPoint(8.0, 0.0), EGPoint(6.0, 1.0))
cq = EGCurvilinearQuadrilateral2(radius, arc, EGSegment(EGPoint(0.0, 3.0), EGPoint(6.0, 1.0)), earc)
area(cq) > 0   # a genuine 4-sided mixed straight/circular/elliptic region
```

[`EGCurvilinearNgon2`](@ref)`(sides)` is the same idea for any number of
sides ≥ 3, given as a plain vector instead of one positional argument per
side — useful when the side count isn't fixed ahead of time:

```@example geo
cn = EGCurvilinearNgon2([radius, arc, chord])   # the same 3 sides as ct above
area(cn) ≈ area(ct), perimeter(cn) ≈ perimeter(ct)   # same sides, same region either way
```

`rotate`, `reflection`, `homothety` and `translate` all transform every
side independently and reassemble the result — the same generic,
sides-based machinery every [`EGPolygon`](@ref) shares (see
[`EGCurvilinearNgon2`](@ref)'s own worked example above, via `invert`,
for the *n*-sided case built from an arbitrary vector of sides).
