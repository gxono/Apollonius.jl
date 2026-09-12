```@meta
CurrentModule = EuclideanGeometry
```

# Points, Lines & Rays

These are the building blocks everything else in the package is made of.

* A **point** is [`EGPoint`](@ref), and a **vector** (a free direction, with
  no fixed location) is the separate type [`EGVector`](@ref). Both wrap the
  same `(x, y)` coordinate pair, but keeping them distinct means `EGVector`
  can carry its own meaning (a *direction*, e.g. what
  [`direction`](@ref) returns) without being confused for a location.
  Arithmetic between them stays permissive on purpose: `EGPoint - EGPoint`
  still gives back an `EGPoint` (not a vector), so familiar formulas like
  `2*about - p` keep working exactly as before — see the table below.
* A **segment** is a finite piece of straight line between two points:
  [`EGSegment`](@ref).
* A **line** ([`EGLine`](@ref)) is the *infinite* straight line through two
  points, and a **ray** ([`EGRay`](@ref)) is the *half-line* starting at an
  origin and passing through a second point. Both are small immutable
  structs holding the two defining points.

All four are part of the package's own EG-prefixed type hierarchy (see
[EuclideanGeometry.jl](@ref) for the full tree): `EGPoint`/`EGVector` sit directly under
`EGObject`, while `EGSegment`/`EGLine`/`EGRay` are all `EGCurve`s.

| Type | Represents | Fields |
|:-----|:-----------|:-------|
| [`EGPoint`](@ref) | a point in the plane | `p[1]`, `p[2]` (x, y) |
| [`EGVector`](@ref) | a free direction/displacement | `v[1]`, `v[2]` (x, y) |
| [`EGSegment`](@ref) | the segment `[p1, p2]` | `s[1]`, `s[2]` |
| [`EGLine`](@ref) | the infinite line through `p1`, `p2` | `.p1`, `.p2` |
| [`EGRay`](@ref) | the half-line from `origin` through `through` | `.origin`, `.through` |

None of `EGSegment`/`EGLine`/`EGRay` carry a direction *magnitude* — an
`EGLine` through `p1` and `p2` is the same object as the line through `p2`
and `p1` — but `EGSegment` and `EGRay` do remember which of their two
points comes first, since that is what makes them finite/one-sided in the
first place.

## Creating them

```@example geo
using EuclideanGeometry

A = EGPoint(3.0, 4.0)
O = EGPoint(0.0, 0.0)

s = EGSegment(O, A)     # the segment from O to A
l = EGLine(O, A)        # the infinite line through O and A
r = EGRay(O, A)         # the half-line starting at O, through A

distance(O, A)
```

`distance(O, A)` is `5.0`: with `A = (3, 4)`, this is just the classic
3-4-5 triangle. `EGSegment`, `EGLine` and `EGRay` all wrap the *same* two
points here — what differs is only how far they extend and what other
functions are willing to do with them (e.g. [`on_segment`](@ref) only
makes sense for an `EGSegment`, [`slope_angle`](@ref) treats `EGLine` and
`EGRay` as pointing one way and an `EGSegment` as pointing from its first
point to its second).

## Points vs. vectors

A point minus a point is *still a point*, not a vector — `A - O` above
stays an `EGPoint`. This is a deliberate choice: it keeps existing
point-arithmetic formulas (like a reflection written as `2*about - p`)
working exactly as they read, without forcing every subtraction through a
vector type first. Where a genuine *direction* is called for — the
result of [`direction`](@ref) below, for instance — the package hands
back an actual [`EGVector`](@ref) instead:

```@example geo
d = direction(l)    # an EGVector, not an EGPoint
typeof(d)
```

Both types support the same arithmetic and the standard linear-algebra
functions `norm`, `dot` and `normalize` — re-exported from `LinearAlgebra`
purely so `using EuclideanGeometry` alone is enough to get the full
vector toolkit, without a separate `using LinearAlgebra`:

```@example geo
norm(d)        # 5.0
normalize(d)   # (0.6, 0.8): unit vector, same direction
dot(d, EGVector(1.0, 0.0))   # 3.0
```

## Polar coordinates

[`polar_point`](@ref) builds a point from a distance and an angle (radians,
counterclockwise from the positive x-axis) instead of `x`/`y` — and
[`polar_point_deg`](@ref) is the same with the angle in degrees. Both
require an explicit `center` (there's no zero-argument default here, to
avoid ambiguity with `Real`-only single-argument calls elsewhere in the
package):

```@example geo
Bpolar = polar_point_deg(4.0, 40.0, O)   # 4 units out from O, at 40°
distance(O, Bpolar)                       # 4.0, regardless of the angle
```

This is exactly the point/angle/modulus relationship [`slope_angle`](@ref)
and [`distance`](@ref) give you the other way around:
`polar_point(distance(O, p), slope_angle(EGLine(O, p)), O)` recovers `p`
(for `p != O`).

## Direction, slope and predicates

```@example geo
direction(l)                    # (3.0, 4.0) — l.p2 - l.p1, as an EGVector
rad2deg(slope_angle(l))         # ≈ 53.13°
is_collinear(O, A, EGPoint(6.0, 8.0))
on_line(EGPoint(6.0, 8.0), l)
on_segment(EGPoint(6.0, 8.0), s) # false: beyond A
```

| Function | Returns | Meaning |
|:---------|:--------|:--------|
| [`direction`](@ref) | `EGVector` | non-normalized direction of an `EGLine`/`EGRay`/`EGSegment` |
| [`slope_angle`](@ref) | angle | `atan(dy, dx)` of that direction, in radians |
| [`is_collinear`](@ref) | `Bool` | do three points lie on a common line? |
| [`is_parallel`](@ref) / [`is_perpendicular`](@ref) | `Bool` | relation between two lines |
| [`on_line`](@ref) / [`on_segment`](@ref) | `Bool` | is a point on this line / this finite segment? |
| [`side_of_line`](@ref) | `-1`, `0` or `1` | which side of a line a point falls on |

```@example geo
l_horiz = EGLine(EGPoint(0.0, 0.0), EGPoint(4.0, 0.0))
side_of_line(EGPoint(2.0, 1.0), l_horiz)   #  1 : "above"
side_of_line(EGPoint(2.0, -1.0), l_horiz)  # -1 : "below"
```

## Projection, reflection and the perpendicular foot

[`projection`](@ref) drops a point onto a line at a right angle;
[`reflection`](@ref) mirrors a point through another point (its use for
mirroring *across a line* is: project first, then reflect through the
foot).

```@example geo
P, Q = EGPoint(1.0, 1.0), EGPoint(6.0, 3.0)
l = EGLine(P, Q)
C = EGPoint(2.0, 6.0)

foot = projection(C, l)      # the perpendicular foot of C on l
Cref = reflection(C, foot)   # C mirrored through that foot — i.e. across l
```

## Rotation and homothety

[`rotate`](@ref) turns a point about a center by an angle (radians,
counter-clockwise); [`homothety`](@ref) scales it by a factor `k` about a
center (`k = -1` is a point reflection, `0 < k < 1` shrinks towards the
center). Both default to the origin when no center is given.

```@example geo
rotate(C, pi / 2, P)     # C rotated 90° about P
homothety(C, 2.0, P)     # C scaled by 2 about P
barycenter([P, Q, C], [1.0, 1.0, 2.0])   # weighted average of the three
```

## Parallels, perpendiculars and bisectors

```@example geo
parallel_through(l, C)             # line through C, parallel to l
perpendicular_through(l, C)        # line through C, perpendicular to l
pb = perpendicular_bisector(P, Q)  # perpendicular to [P,Q] through its midpoint
```

[`angle_bisectors`](@ref) is the analogous construction for two intersecting
lines: it returns *both* bisectors (they are always perpendicular to each
other), as a 2-element vector.

```@example geo
xaxis = EGLine(EGPoint(0.0, 0.0), EGPoint(4.0, 0.0))
yaxis = EGLine(EGPoint(0.0, 0.0), EGPoint(0.0, 4.0))
angle_bisectors(xaxis, yaxis)   # the two diagonals y = x and y = -x
```

## Angles

Under the hood, angles between two vectors come from two free functions:
[`angle_between`](@ref)`(u, v)` (signed, counterclockwise from `u` to `v`,
in `(-π, π]`) and [`angle_at`](@ref)`(vertex, p1, p2)` (unsigned, in
`[0, π]`) — use these directly when you just need a number and not
something to pass around.

```@example geo
angle_between(EGVector(4.0, 0.0), EGVector(0.0, 4.0))   # π/2
```

[`EGAngle2`](@ref) wraps up the "angle at a vertex between two rays" idea
into a small struct (`vertex`, `a`, `b`) so it can be passed around and
measured without repeating the three points everywhere —
`measure`/`abs` on an `EGAngle2` are exactly `angle_between`/`angle_at` on
its two defining vectors. Unlike a bare number, it's also a genuine
*region* of the plane (it's part of the [`EGSet`](@ref) family): `p in ang`
tests whether `p` falls in the infinite wedge swept counterclockwise from
`a` to `b`. It's oriented: `EGAngle2(O, P1, P2)` and `EGAngle2(O, P2, P1)`
have the same [`abs`](@ref) but opposite sign.

```@example geo
O = EGPoint(0.0, 0.0)
P1, P2 = EGPoint(4.0, 0.0), EGPoint(0.0, 4.0)
ang = EGAngle2(O, P1, P2)

rad2deg(measure(ang))    # 90.0 — signed, counterclockwise from a to b
abs(ang)                 # 1.5707... — the unsigned angle, in [0, π]
is_direct(ang)           # true: measure(ang) > 0
(O + EGPoint(1.0, 1.0)) in ang   # true: inside the wedge
```

[`normalized_measure`](@ref) is [`measure`](@ref) shifted into `[0, 2π)`
instead of `(-π, π]`, for when you'd rather not deal with negative angles.
Swapping `a` and `b` flips the sign of `measure` (and `is_direct`) but
leaves `abs` unchanged:

```@example geo
ang2 = EGAngle2(O, P2, P1)
measure(ang2), is_direct(ang2)   # (-π/2, false) — same magnitude, opposite orientation
```

[`angle_trisectors`](@ref) is the free-function analogue of
[`angle_bisectors`](@ref): given a vertex and two points, it returns the
*two* rays that cut `∠(p1, vertex, p2)` into three equal parts.

```@example geo
rays = angle_trisectors(O, P1, P2)   # 2 rays, each 30° apart (a 90° angle, /3)
```

`rotate`, `reflection` and `homothety` transform `vertex`, `a` and `b`
pointwise, so `abs(ang)` is always preserved, and so is the *sign* of
`measure` — for every one of them, including `reflection`. That's a
deliberate consequence of `EGAngle2` being a real region rather than a bare
signed value: reflecting about an `EGLine` (a true mirror) swaps `a` and
`b` internally so the wedge comes back as a genuine mirror image of the
original (not its complement), and that swap is exactly what keeps
`measure`'s sign unchanged too — the same convention
[`EGCircularArc2`](@ref)/[`EGEllipticArc2`](@ref) use for the same reason.

```@example geo
measure(rotate(ang, pi / 3)) ≈ measure(ang)                        # sign preserved
measure(reflection(ang, EGPoint(1.0, 1.0))) ≈ measure(ang)         # point reflection
measure(reflection(ang, EGLine(O, EGPoint(1.0, 1.0)))) ≈ measure(ang)  # line reflection too
```

## Harmonic conjugate and the golden ratio point

Given `A`, `B` on a line and a third point `P` on that same line,
[`harmonic_conjugate`](@ref) returns the point `P'` for which `(A, B; P, P')`
is a harmonic range — i.e. `P` and `P'` divide `[A,B]` internally and
externally in the same ratio. [`golden_ratio_point`](@ref) is the special
point that divides `[A,B]` in the golden ratio, `A + (B-A)/φ`.

```@example geo
A, B = EGPoint(0.0, 0.0), EGPoint(8.0, 0.0)
P = EGPoint(2.0, 0.0)

Pgold = golden_ratio_point(A, B)     # ≈ (4.944, 0)
Pconj = harmonic_conjugate(A, B, P)  # (-4.0, 0) — P's harmonic conjugate
```

`P'` falls *outside* `[A,B]`, on the opposite side from `B`: that is exactly
what makes the division "external" for one of the two points and "internal"
for the other, which is the defining property of a harmonic range.

See the [API Reference](@ref) for the complete, exhaustive list of
functions, including a few not walked through here (like
[`apollonius_circle`](@ref), which needs a circle to make sense of, or
[`is_concyclic`](@ref)).
