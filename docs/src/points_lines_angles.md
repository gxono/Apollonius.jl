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


