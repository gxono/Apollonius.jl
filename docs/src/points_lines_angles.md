```@meta
CurrentModule = Apollonius
```

# Points, Lines & Rays: Angles

## Angles

An angle is a region of the plane, an [`APAngle2`](@ref), and its measure is a
number. The measures come from two free functions:
[`angle_measure_between`](@ref)`(u, v)` (signed, counterclockwise from `u` to `v`,
in `(-π, π]`) and [`angle_measure_at`](@ref)`(vertex, p1, p2)` (unsigned, in
`[0, π]`). Use these directly when you just need a number and not
something to pass around.

```@example geo
using Apollonius

angle_measure_between(APVector(4.0, 0.0), APVector(0.0, 4.0))   # π/2
```

[`APAngle2`](@ref) wraps up the "angle at a vertex between two rays" idea
into a small struct (`vertex`, `a`, `b`) so it can be passed around and
measured without repeating the three points everywhere.
`measure`/`abs` on an `APAngle2` are exactly `angle_measure_between`/`angle_measure_at` on
its two defining vectors. Unlike a bare number, it's also a genuine
*region* of the plane (it's part of the [`APSet`](@ref) family): `p in ang`
tests whether `p` falls in the infinite wedge swept counterclockwise from
`a` to `b`. It's oriented: `APAngle2(O, P1, P2)` and `APAngle2(O, P2, P1)`
have the same [`abs`](@ref) but opposite sign.

```@example geo
O = APPoint(0.0, 0.0)
P1, P2 = APPoint(4.0, 0.0), APPoint(0.0, 4.0)
ang = APAngle2(O, P1, P2)

rad2deg(measure(ang))    # 90.0: signed, counterclockwise from a to b
abs(ang)                 # 1.5707...: the unsigned angle, in [0, π]
is_direct(ang)           # true: measure(ang) > 0
(O + APVector(1.0, 1.0)) in ang   # true: inside the wedge
```

```@raw html
<img src="../assets/img/points_lines/angle_wedge.svg" alt="An angle as a wedge, with a point inside and a point outside" style="width:100%; max-width: 700px;">
```

[`normalized_measure`](@ref) is [`measure`](@ref) shifted into `[0, 2π)`
instead of `(-π, π]`, for when you'd rather not deal with negative angles.
Swapping `a` and `b` flips the sign of `measure` (and `is_direct`) but
leaves `abs` unchanged:

```@example geo
ang2 = APAngle2(O, P2, P1)
measure(ang2), is_direct(ang2)   # (-π/2, false): same magnitude, opposite orientation
normalized_measure(ang2)          # -π/2 + 2π = 3π/2 rad (270°), shifted into [0, 2π)
```

[`reverse`](@ref)`(ang)` does exactly that swap for you (`ang2 == reverse(ang)`
above), handy when you've built an `APAngle2` from points that already
live in a mirrored coordinate space (e.g. after
[`@prepare_to_picture`](@ref)'s default `flip=true`, see
[Drawing with Luxor.jl](@ref)) and need the wedge that matches what you'd
see drawn, rather than its mirror image:

```@example geo
reverse(ang) == ang2, reverse(reverse(ang)) == ang
```

[`angle_trisectors`](@ref) is the free-function analogue of
[`angle_bisectors`](@ref): given a vertex and two points, it returns the
*two* rays that cut `∠(p1, vertex, p2)` into three equal parts.

```@example geo
rays = angle_trisectors(O, P1, P2)   # 2 rays, each 30° apart (a 90° angle, /3)
```

Both also have an `APAngle2` form, splitting `ang` itself into equal-sized
`APAngle2` pieces (instead of just the intersecting rays/lines), handy
when you want to keep working with wedges rather than unwrap them into
points again:

```@example geo
angle_bisectors(ang)     # (APAngle2(O,P1,bisector), APAngle2(O,bisector,P2))
angle_trisectors(ang)    # the 3 equal thirds of ang, each its own APAngle2
```

```@raw html
<img src="../assets/img/points_lines/angle_split.svg" alt="A right angle with its two trisectors and its bisector" style="width:100%; max-width: 700px;">
```

[`distance`](@ref)`(p, ang)` follows the same `mode = :region`/`:boundary`
convention as the other [`APSet`](@ref) types (see
[Unbounded Regions: Half-Planes, Strips & Angles](@ref)): `0.0` from inside the
wedge with the default `:region`, or always the distance to the nearer of
the two bounding rays (`vertex -> a`, `vertex -> b`) with `:boundary`:

```@example geo
distance(APPoint(1.0, 1.0), ang)                  # 0.0: inside the wedge
distance(APPoint(-1.0, -1.0), ang; mode=:boundary) # distance to the nearer ray
```

`rotate`, `reflection` and `homothety` transform `vertex`, `a` and `b`
pointwise, so `abs(ang)` is always preserved, and so is the *sign* of
`measure`, for every one of them, including `reflection`. That's a
deliberate consequence of `APAngle2` being a real region rather than a bare
signed value: reflecting about an `APLine` (a true mirror) swaps `a` and
`b` internally so the wedge comes back as a genuine mirror image of the
original (not its complement), and that swap is exactly what keeps
`measure`'s sign unchanged too, the same convention
[`APCircularArc2`](@ref)/[`APEllipticArc2`](@ref) use for the same reason.

```@example geo
measure(rotate(ang, pi / 3)) ≈ measure(ang)                        # sign preserved
measure(reflection(ang, APPoint(1.0, 1.0))) ≈ measure(ang)         # point reflection
measure(reflection(ang, APLine(O, APPoint(1.0, 1.0)))) ≈ measure(ang)  # line reflection too
```

Conversely, `rotate(obj, ang::APAngle2, ...)` goes the other way: it
rotates some *other* object by `measure(ang)`, driven directly by an
`APAngle2`'s own measure instead of a bare number, a stand-in for
`rotate(obj, measure(ang), ...)`, useful once you already have the angle
as an `APAngle2` and don't want to unwrap it by hand first:

```@example geo
rotate(P1, ang, O) == rotate(P1, measure(ang), O)   # true: same rotation, just driven by ang directly
```

### Angles from a measure or from two lines

[`angle_with_measure`](@ref)`(vertex, p, θ)` builds the angle whose first ray
goes through `p` and whose second is `θ` radians counterclockwise from it, a
negative `θ` opening it clockwise. `APAngle2(l1, l2)` is the angle at the point
where two lines cross, from the direction of `l1` to the direction of `l2`,
counterclockwise. It is more than a straight angle when `l2` is clockwise from
`l1`, so swap the lines to get the other one:

```@example geo
a60 = angle_with_measure(APPoint(0.0, 0.0), APPoint(4.0, 0.0), pi / 3)
rad2deg(measure(a60))
```

```@example geo
la, lb = APLine(APPoint(0.0, 0.0), APPoint(1.0, 0.0)), APLine(APPoint(0.0, 0.0), APPoint(1.0, 1.0))
rad2deg(measure(APAngle2(la, lb))), rad2deg(measure(APAngle2(lb, la)))
```

```@raw html
<img src="../assets/img/points_lines/angle_from_measure.svg" alt="An angle of 60 degrees built from a ray and a measure, and the angle between two crossing lines" style="width:100%; max-width: 700px;">
```

### Clipping a line, segment or ray

`ang` is a region, so [`intersection`](@ref)`(ang, obj)` for a line, a
segment or a ray is the part of `obj` that lies inside the wedge, not the
points where its two rays are crossed (see
[Unbounded Regions: Half-Planes, Strips & Angles](@ref) for the same idea
on `APHalfPlane2`/`APStrip2`). The result is always a `Vector`, though, not
the bare value those two give: a convex `ang` (`normalized_measure(ang) <=
π`, the ordinary case) never gives more than one piece, but a **reflex**
one can give two.

```@example geo
crossing = APLine(APPoint(-1.0, 2.0), APPoint(5.0, 2.0))
intersection(ang, crossing)
```

A reflex angle (more than half the plane) is not convex: a line can cross
into it, back out through the excluded wedge on the other side, and back
in again, leaving two disjoint pieces instead of one:

```@example geo
reflex = APAngle2(O, P1, APPoint(0.0, -4.0))   # everything except the fourth quadrant
rad2deg(normalized_measure(reflex))            # 270°: more than a straight angle
intersection(reflex, APLine(APPoint(-6.0, -6.0), APPoint(16.0, 5.0)))
```

```@raw html
<img src="../assets/img/points_lines/angle_clip_reflex.svg" alt="A reflex wedge's two boundary rays, a line crossing through the excluded quadrant, and the two disjoint rays of the line that lie inside the wedge, drawn over it in purple" style="width:100%; max-width: 700px;">
```

A point works the same way as `in`, without the two-piece question: the
point itself if it's inside `ang`, `nothing` otherwise. Both argument
orders work for all of these.

The same clipping works against an [`APCircle2`](@ref) or [`APEllipse2`](@ref)
(or one of their arcs), still always as a `Vector` of pieces in that curve's
own type, since a reflex `ang` can split a circle into two arcs too:

```@example geo
c = APCircle2(O, 2.0)
quarter = only(intersection(ang, c))
rad2deg(measure(quarter))
```

```@raw html
<img src="../assets/img/points_lines/angle_clip_circle.svg" alt="A wedge and a circle at its vertex, with the quarter of the circle inside the wedge drawn over it in purple" style="width:100%; max-width: 700px;">
```

### Intersecting with another region

[`intersection`](@ref)`(ang, other)` also works when `other` is itself an
[`APHalfPlane2`](@ref)/[`APStrip2`](@ref)/`APAngle2`: the region common to
both, always as a `Vector` (0, 1, or, only when one side is reflex, up to 2
pieces). A half-plane crossing both of `ang`'s rays closes it off into a
bounded triangle:

```@example geo
hp = APHalfPlane2(APLine(APPoint(6.0, 0.0), APPoint(0.0, 6.0)), O)
only(intersection(ang, hp))
```

```@raw html
<img src="../assets/img/points_lines/angle_intersect_halfplane.svg" alt="A wedge and a half-plane whose boundary crosses both of its rays, with the triangle common to both drawn over them in purple" style="width:100%; max-width: 700px;">
```

Crossing only one ray gives an unbounded [`APUnboundedPolygon2`](@ref)
instead (see [Unbounded Regions: Half-Planes, Strips & Angles](@ref) for
that type, and for the same idea against `APHalfPlane2`/`APStrip2`
themselves). The same clipping also works against a straight-sided
[`APTriangle`](@ref)/[`APQuadrilateral`](@ref)/[`APStraightNgon`](@ref),
giving the part of the polygon inside `ang`; see
[Unbounded Regions: Half-Planes, Strips & Angles](@ref)'s "Clipping a
bounded polygon".


