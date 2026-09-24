```@meta
CurrentModule = Apollonius
```

# Conics: Tangents, Duality & Arcs

The ellipse, parabola and hyperbola from [Conics: Ellipse, Parabola & Hyperbola](@ref):

```@example geo
using Apollonius

e = APEllipse2(APPoint(0.0, 0.0), 5.0, 3.0)
focus = APPoint(0.0, 1.0)
directrix = APLine(APPoint(-5.0, -1.0), APPoint(5.0, -1.0))
par = APParabola2(focus, directrix)
h = APHyperbola2(APPoint(0.0, 0.0), 3.0, 4.0)
nothing # hide
```

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
[Circles: Inversion](@ref)):

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

```@raw html
<img src="../assets/img/conics/tangents.svg" alt="The two tangent lines from an outside point to an ellipse, the points of tangency and the polar line" style="width:100%; max-width: 700px;">
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

```@raw html
<img src="../assets/img/conics/intersect.svg" alt="An ellipse and a hyperbola meeting in four points" style="width:100%; max-width: 700px;">
```

Two circles are the one pairing with its own dedicated, exact method
(finding two circles' intersection reduces to a single quadratic); every
other pairing goes through a general elimination method instead, since
two conics can meet in up to 4 points, one degree too many for that
shortcut. Both give a `Vector{APPoint{2,Float64}}`, so nothing about
calling `intersection` changes based on which two types you hand it.

### The tangent and the normal at a point

[`tangent_line`](@ref)`(curve, p)` is the tangent to a circle, an ellipse, a
hyperbola, a parabola or an arc of any of them at its point `p`, and
[`normal_line`](@ref) the perpendicular to it through `p`. The point must be on
the curve (or on the arc), or an `ArgumentError` is raised. They are the same
tangent as [`polar_line`](@ref) gives for a point of the conic, in one function
for every curve:

```@example geo
ec = APEllipse2(APPoint(0.0, 0.0), 5.0, 3.0)
pc = point_on(ec, 1.0)
tangent_line(ec, pc) ≈ polar_line(ec, pc), is_on_line(pc, normal_line(ec, pc))
```

## Arcs of a conic

[`APEllipticArc2`](@ref), [`APParabolicArc2`](@ref) and
[`APHyperbolicArc2`](@ref) are the finite-arc analogues of
[`APCircularArc2`](@ref) (see [Circles: Arcs](@ref)) for these three conics: each
holds the underlying conic plus two points `p1`/`p2` on it, and
[`point_on`](@ref)/[`arc_length`](@ref) work on all four arc types
uniformly:

```@example geo
earc = APEllipticArc2(e, point_on(e, 0.2), point_on(e, 2.0))
point_on(earc, 0.0) ≈ earc.p1, point_on(earc, 1.0) ≈ earc.p2
```

```@example geo
parc = APParabolicArc2(par, point_on(par, -3.0), point_on(par, 3.0))
arc_length(parc) > distance(parc.p1, parc.p2)   # the arc is always longer than its chord
```

```@example geo
harc = APHyperbolicArc2(h, point_on(h, -0.5), point_on(h, 0.5))
harc isa APHyperbolicArc2
```

Each also builds directly from the underlying conic's own raw parameters,
without an `APEllipse2`/`APHyperbola2`/`APParabola2` in hand first (the
same idea as [`APCircularArc2`](@ref)`(center, r, p1, p2)` in
[Circles: Arcs](@ref)):

```@example geo
APEllipticArc2(e.center, e.a, e.b, earc.p1, earc.p2; angle=e.angle) == earc
```

```@raw html
<img src="../assets/img/conics/arcs.svg" alt="An elliptic, a parabolic and a hyperbolic arc, each on its full conic" style="width:100%; max-width: 700px;">
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
[`@prepare_to_picture`](@ref)'s default `flip=true`). For the *open* ones
(`APParabolicArc2`/`APHyperbolicArc2`), there's no such ambiguity: `reverse`
just re-parametrizes the same arc in the opposite direction (`point_on(arc,
t)` becomes `point_on(reverse(arc), 1 - t)`):

```@example geo
reverse(reverse(parc)) == parc, point_on(reverse(parc), 0.0) ≈ parc.p2
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

```@raw html
<img src="../assets/img/conics/arc_intersect.svg" alt="A segment crossing an ellipse twice but its elliptic arc only once" style="width:100%; max-width: 700px;">
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
three arc types (see [Points, Lines & Rays: Special Points & Curves](@ref) for the general story
across every shape in the package). Unlike a circle or circular arc, this
is uniform in the curve's own parameter, *not* in arc length: exact
arc-length sampling would need elliptic integrals for these three, so
points cluster slightly more densely near the flatter parts of the curve
(near an ellipse's minor axis, for instance):

```@example geo
is_on_ellipse(rand(e), e)   # true, but not uniformly spread along the perimeter
in(rand(earc), earc), in(rand(parc), parc), in(rand(harc), harc)
```

```@raw html
<img src="../assets/img/conics/random_points.svg" alt="Random points on an ellipse, denser near the flatter parts" style="width:100%; max-width: 700px;">
```
