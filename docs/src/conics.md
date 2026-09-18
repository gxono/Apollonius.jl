```@meta
CurrentModule = Apollonius
```

# Conics: Ellipse, Parabola & Hyperbola

Three separate types ([`APEllipse2`](@ref), [`APParabola2`](@ref) and
[`APHyperbola2`](@ref)) each aligned with a coordinate axis of its own
(`center`/`angle` for the first two, `focus`/`directrix` for the parabola),
plus a fifth constructor, [`conic_through_points`](@ref), that fits an
ellipse or hyperbola through five arbitrary points.

All three conic types share the same *shape* of API, since they share the
same underlying pattern (a curve defined by an equation in its own local
frame, plus a point/line duality): `point_on_*`, `is_on_*`, `intersection`
with an `APLine`, `polar_line`, `tangent_points` and `tangent_lines` all exist
for each of the three, with the same meaning throughout. That shared
behavior is described once, in [Points, tangents and duality](@ref), rather
than three times.

## Ellipse

```@example geo
using Apollonius

e = APEllipse2(APPoint(0.0, 0.0), 5.0, 3.0)  # center, semi-axis a, semi-axis b
```

`APEllipse2(center, a, b, angle=0.0)` places semi-axis `a` along `angle`
(radians from the x-axis) and semi-axis `b` perpendicular to it; `a` and
`b` don't need to be ordered; either can be the longer one. There is also
the classical **bifocal** constructor:

```@example geo
APEllipse2(APPoint(-4.0, 0.0), APPoint(4.0, 0.0), 5.0)   # foci + semi-major axis a
```

which throws an `ArgumentError` if `a` isn't greater than half the
distance between the foci (otherwise no real ellipse has that focal
distance and semi-major axis). A third form, `APEllipse2(f1, f2, p)`, builds
the ellipse through a known point `p` instead of a known `a`, computing
`a` from the bifocal sum `(|pf1| + |pf2|)/2` first.

```@example geo
area(e)        # π·a·b
perimeter(e)   # Ramanujan's 2nd approximation (exact when a == b)
foci(e)        # the two focus points, as a 2-tuple
vertices(e)    # the two endpoints of the major axis, as a 2-tuple
```

```@example geo
is_on_ellipse(APPoint(5.0, 0.0), e)   # true: exactly at the end of the major axis
is_on_ellipse(APPoint(1.0, 1.0), e)   # false: strictly inside
```

[`orthoptic`](@ref) is the **director circle**: the locus of points from
which the two tangent lines to `e` are perpendicular. For an ellipse it's
always a real circle, of radius `sqrt(a² + b²)`, centered at `e.center`.

```@example geo
orthoptic(e)   # APCircle2(center, sqrt(5^2+3^2)) ≈ APCircle2(center, 5.83)
```

## Parabola

```@example geo
focus = APPoint(0.0, 1.0)
directrix = APLine(APPoint(-5.0, -1.0), APPoint(5.0, -1.0))
par = APParabola2(focus, directrix)
```

A parabola only has one natural constructor (the focus/directrix
definition itself), since (unlike the ellipse/hyperbola) there's no
second, equally standard center/axis parametrization to offer as an
alternative.

```@example geo
vertex(par)            # midpoint of focus and its foot on the directrix
vertices(par)          # (vertex(par),): a 1-tuple, so vertices() works uniformly across every conic
focal_parameter(par)   # distance(focus, directrix), often called p
```

[`point_on_parabola`](@ref) parametrizes by the signed distance `s` from
the axis (so it's the local `y`-coordinate in the frame where the parabola
reads `y² = 2·p·x`, with `s = 0` at the vertex):

```@example geo
point_on_parabola(par, 2.0)
```

```@example geo
is_on_parabola(point_on_parabola(par, 2.0), par)   # true, by construction
```

The parabola's own [`orthoptic`](@ref) (director curve) turns out to be
exactly its **directrix**, a fact special to the parabola (the ellipse's
and hyperbola's orthoptics are circles, not lines):

```@example geo
orthoptic(par) == par.directrix
```

## Hyperbola

```@example geo
h = APHyperbola2(APPoint(0.0, 0.0), 3.0, 4.0)  # center, transverse a, conjugate b
```

`APHyperbola2(center, a, b, angle=0.0)` reads `(x/a)² - (y/b)² = 1` in the
rotated local frame: `a` is the semi-transverse axis (along `angle`, the
one that actually meets the curve) and `b` the semi-conjugate axis (which
doesn't). The bifocal constructor mirrors the ellipse's:

```@example geo
APHyperbola2(APPoint(-5.0, 0.0), APPoint(5.0, 0.0), 3.0)   # foci + semi-transverse axis a
```

throwing instead when `a` isn't *less* than half the focal distance (the
opposite inequality from the ellipse, since here `c > a`).

```@example geo
foci(h)         # the two foci, at distance sqrt(a²+b²) from the center
asymptotes(h)   # the two asymptote lines, through the center
vertices(h)     # the two points where each branch meets the transverse axis, at distance a from the center
```

[`orthoptic`](@ref) (the director circle) exists for a hyperbola only when
`a > b`, with radius `sqrt(a² - b²)`; otherwise there's no point in the
plane from which both tangents can be perpendicular, and it throws an
`ArgumentError`:

```@example geo
orthoptic(APHyperbola2(APPoint(0.0, 0.0), 5.0, 3.0))   # a > b: APCircle2 of radius sqrt(25-9) = 4
```

[`point_on_hyperbola`](@ref) parametrizes one branch at a time
(`branch=1`, the default, or `branch=-1` for the other) using the
hyperbolic functions: `x = branch·a·cosh(t)`, `y = b·sinh(t)`.

```@example geo
point_on_hyperbola(h, 0.5)          # on the branch nearer +x
point_on_hyperbola(h, 0.5; branch=-1)  # the mirrored point on the other branch
```

```@example geo
is_on_hyperbola(point_on_hyperbola(h, 0.5), h)   # true, on either branch
```

`p in h` (via `Base.in`) is the natural analogue of "inside" for a curve
that doesn't bound a single finite region: it's true when `p` is on `h`
itself or beyond either branch (`(x/a)² - (y/b)² >= 1` in the local
frame), i.e. on the same side as the curve, rather than in the "waist"
between the two branches.

## Points, tangents and duality

The following table applies to all three types (write `conic` for whichever
of `APEllipse2`, `APParabola2` or `APHyperbola2` you're using):

| Function | Meaning |
|:---------|:--------|
| `point_on_conic(conic, param)` | a point on the curve at the given parameter |
| `is_on_conic(p, conic)` | is `p` exactly on the curve? |
| `intersection(l, conic)` | 0, 1 or 2 points where an `APLine`/`APSegment`/`APRay` crosses the curve |
| `polar_line(conic, p)` | the polar line of `p` (see below) |
| `tangent_points(conic, p)` | the point(s) of tangency of the line(s) from `p` |
| `tangent_lines(conic, p)` | the tangent line(s) themselves |

`intersection` reduces `APSegment`/`APRay` to the underlying `APLine`
case and then keeps only the points that actually fall on the
segment/ray, so a segment that stops short of the curve correctly returns
nothing, and a ray only ever reports points ahead of its origin:

```@example geo
intersection(APSegment(APPoint(-10.0, 0.0), APPoint(0.0, 0.0)), e)   # reaches the near vertex
intersection(APRay(APPoint(0.0, 0.0), APPoint(1.0, 0.0)), e)         # the far vertex, not the near one
```

The **polar line** of a point `p` with respect to a conic is the
projective-duality construction that makes all of `tangent_points` and
`tangent_lines` work uniformly, for every conic (including `APCircle2`, see
[Circles](@ref)):

* When `p` is *outside* the curve, its polar is the chord joining the two
  points where the tangent lines from `p` touch the curve, so
  `tangent_points` is implemented as simply `intersection(polar_line(conic,
  p), conic)`.
* When `p` is *on* the curve, its polar line degenerates to the tangent
  line *at* `p` itself, which is exactly why `tangent_lines` special-cases
  that situation, rather than returning the degenerate `APLine(p, p)` a
  naive "join `p` to its own tangent point" would give.
* `polar_line` returns `nothing` at the one truly degenerate input: `p`
  being the ellipse/hyperbola's center (an ellipse's or hyperbola's polar
  of its own center would be the line at infinity), or the parabola's
  focus sitting on its own directrix (a degenerate parabola, not a real
  curve at all).

```@example geo
p = APPoint(13.0, 0.0)
tangent_points(e, p)
tangent_lines(e, p)
```

For an `APHyperbola2` specifically, note that being far from the curve doesn't
guarantee real tangents (or the lack of them) the way it does for an
ellipse. It depends on which side of which branch `p` sits on;
`tangent_points`/`tangent_lines` still return an empty vector rather than
erroring when there are none.

### Intersecting two conics

`intersection` also works between two full conics of any kind, straight
or mixed (an ellipse against a hyperbola, two different ellipses, a
circle against a parabola, ...), returning up to 4 real points:

```@example geo
intersection(e, h)
```

Two circles are the one pairing with its own dedicated, exact method
(finding two circles' intersection reduces to a single quadratic); every
other pairing goes through a general elimination method instead, since
two conics can meet in up to 4 points, one degree too many for that
shortcut. Both give a `Vector{APPoint{2,Float64}}`, so nothing about
calling `intersection` changes based on which two types you hand it.

## Arcs of a conic

[`APEllipticArc2`](@ref), [`APParabolicArc2`](@ref) and
[`APHyperbolicArc2`](@ref) are the finite-arc analogues of
[`APCircularArc2`](@ref) (see [Circles](@ref)) for these three conics: each
holds the underlying conic plus two points `p1`/`p2` on it, and
[`point_on_arc`](@ref)/[`arc_length`](@ref) work on all four arc types
uniformly:

```@example geo
earc = APEllipticArc2(e, point_on_ellipse(e, 0.2), point_on_ellipse(e, 2.0))
point_on_arc(earc, 0.0) ≈ earc.p1, point_on_arc(earc, 1.0) ≈ earc.p2
```

```@example geo
parc = APParabolicArc2(par, point_on_parabola(par, -3.0), point_on_parabola(par, 3.0))
arc_length(parc) > distance(parc.p1, parc.p2)   # the arc is always longer than its chord
```

```@example geo
harc = APHyperbolicArc2(h, point_on_hyperbola(h, -0.5), point_on_hyperbola(h, 0.5))
harc isa APHyperbolicArc2
```

Unlike a circular or elliptic arc (where "the arc from `p1` to `p2`" means
one of two complementary, closed possibilities), a single hyperbola branch
or a parabola is an *open* curve, so two points on it always determine
exactly one unambiguous arc; there's no sweep direction to pick. See
[Drawing with Luxor.jl](@ref) for how all four arc types render (a true
Cairo primitive for the circular case, a sampled polyline for the other
three, since Luxor has no native primitive for them).

All four arc types (this trio plus [`APCircularArc2`](@ref)) support
[`reverse`](@ref), swapping `p1`/`p2`. For the *closed* conics
(`APCircularArc2`/`APEllipticArc2`), this gives the complementary arc: a
genuinely different piece of the curve, "the rest of the way around" (same
gotcha as [`reverse(::APAngle2)`](@ref): useful when the arc was built from
points already in a mirrored coordinate space, e.g. after
[`@to_luxor_picture`](@ref)'s default `flip=true`). For the *open* ones
(`APParabolicArc2`/`APHyperbolicArc2`), there's no such ambiguity: `reverse`
just re-parametrizes the same arc in the opposite direction (`point_on_arc(arc,
t)` becomes `point_on_arc(reverse(arc), 1 - t)`):

```@example geo
reverse(reverse(parc)) == parc, point_on_arc(reverse(parc), 0.0) ≈ parc.p2
```

### Intersecting an arc

`intersection` works on an arc the same way it works on the full conic:
against `APLine`/`APSegment`/`APRay`, it intersects the underlying curve
and keeps only the points that also fall within the arc's own sweep
(the same idea as [`in`](@ref)`(p, arc)`, used internally):

```@example geo
l = APLine(APPoint(-10.0, 1.0), APPoint(10.0, 1.0))
intersection(l, earc)   # only one of the two ellipse crossings is on this short arc
```

An arc also intersects a full conic of any kind, not just the one it's
cut from, and another arc of any kind, the same way: intersect the two
underlying full conics, then keep only the points within every arc's own
sweep.

```@example geo
circ = APCircle2(APPoint(0.0, 0.0), 5.0)
carc = APCircularArc2(circ, APPoint(5.0, 0.0), APPoint(0.0, 5.0))
intersection(APCircle2(APPoint(5.0, 5.0), 5.0), carc)   # circle against a circular arc
```

```@example geo
intersection(APCircle2(APPoint(5.0, 5.0), 5.0), earc)   # same idea, an elliptic arc this time
```

### Random points

[`rand`](@ref) draws a random point on an `APEllipse2` or any of these
three arc types (see [Points, Lines & Rays](@ref) for the general story
across every shape in the package). Unlike a circle or circular arc, this
is uniform in the curve's own parameter, *not* in arc length: exact
arc-length sampling would need elliptic integrals for these three, so
points cluster slightly more densely near the flatter parts of the curve
(near an ellipse's minor axis, for instance):

```@example geo
is_on_ellipse(rand(e), e)   # true, but not uniformly spread along the perimeter
in(rand(earc), earc), in(rand(parc), parc), in(rand(harc), harc)
```

## Transforming conics

`rotate`, `reflection` and `homothety` work on all three types. For
`APEllipse2`/`APHyperbola2`, `center` transforms pointwise; `rotate` adds its
angle onto `angle` too; `homothety` scales `a`/`b` by `abs(k)` (never
negative, and never swaps which axis is which) while leaving `angle`
alone, even for a negative `k`: a homothety, negative ratio included,
never reverses orientation:

```@example geo
rotate(e, pi / 6)
homothety(e, -2.0)   # a, b both scale by 2 (abs(-2.0)); angle unchanged
```

`reflection` needs two separate methods here, the same way the base
`reflection(::APPoint, about)` itself does:

* `reflection(conic, about::APPoint)` is a point reflection (a 180°
  rotation): orientation-preserving, so `angle` is unchanged.
* `reflection(conic, about::APLine)` is a true mirror: orientation-reversing,
  so the new `angle` is `2φ - conic.angle`, where `φ` is the line's own
  angle from the x-axis (not simply `conic.angle` unchanged, nor its
  negation; the formula accounts for the mirror line's own orientation).

```@example geo
reflection(e, APPoint(1.0, 1.0))                              # angle unchanged
reflection(e, APLine(APPoint(0.0, 0.0), APPoint(1.0, 1.0)))       # angle: 2φ - e.angle
```

An `APParabola2` is entirely determined by its `focus` and `directrix`, and
both already transform correctly on their own (an `APPoint` and an `APLine`),
so its `rotate`/`reflection`/`homothety` just transform each of the two
and rebuild:

```@example geo
rotate(par, pi / 4)
```

## Fitting a conic through five points

[`conic_through_points`](@ref) takes five points in general position and
returns the unique `APEllipse2` or `APHyperbola2` passing through all of them
(five points determine a conic, the same way three determine a circle or
two a line):

```@example geo
pts = [point_on_ellipse(APEllipse2(APPoint(1.0, 2.0), 6.0, 4.0, 0.3), t) for t in (0.1, 1.0, 2.0, 3.0, 4.5)]
conic_through_points(pts...)
```

It throws an `ArgumentError` when the five points don't determine a unique
conic (a degenerate configuration, e.g. four of them collinear), or when
they do determine a conic but it's a parabola (discriminant ≈ 0): a
parabola isn't representable by this function, since it isn't a
`(center, a, b, angle)`-style object the way the other two are.

Internally, the points are first centered on their own centroid and
rescaled to unit average distance before the linear system is solved, and
the fitted center/axes are transformed back afterwards. Fitting directly
in the original coordinates would badly ill-condition the underlying
linear algebra for points far from the origin or spread far apart, since
the quadratic terms of the conic's equation would then dwarf the linear
and constant ones.
