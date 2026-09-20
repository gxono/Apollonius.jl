```@meta
CurrentModule = Apollonius
```

# Points, Lines & Rays

These are the building blocks everything else in the package is made of.

* A **point** is [`APPoint`](@ref), and a **vector** (a free direction, with
  no fixed location) is the separate type [`APVector`](@ref). Both wrap the
  same `(x, y)` coordinate pair, but keeping them distinct means `APVector`
  can carry its own meaning (a *direction*, e.g. what
  [`direction`](@ref) returns) without being confused for a location.
  Arithmetic between them stays permissive on purpose: `APPoint - APPoint`
  still gives back an `APPoint` (not a vector), so familiar formulas like
  `2*about - p` keep working exactly as before. See the table below.
* A **segment** is a finite piece of straight line between two points:
  [`APSegment`](@ref).
* A **line** ([`APLine`](@ref)) is the *infinite* straight line through two
  points, and a **ray** ([`APRay`](@ref)) is the *half-line* starting at an
  origin and passing through a second point. Both are small immutable
  structs holding the two defining points.

All four are part of the package's own AP-prefixed type hierarchy (see
[Apollonius.jl](@ref) for the full tree): `APPoint`/`APVector` sit directly under
`APObject`, while `APSegment`/`APLine`/`APRay` are all `APCurve`s.

| Type | Represents | Fields |
|:-----|:-----------|:-------|
| [`APPoint`](@ref) | a point in the plane | `p[1]`, `p[2]` (x, y) |
| [`APVector`](@ref) | a free direction/displacement | `v[1]`, `v[2]` (x, y) |
| [`APSegment`](@ref) | the segment `[p1, p2]` | `s[1]`, `s[2]` (also `.p1`, `.p2`) |
| [`APLine`](@ref) | the infinite line through `p1`, `p2` | `l[1]`, `l[2]` (also `.p1`, `.p2`) |
| [`APRay`](@ref) | the half-line from `origin` through `through` | `r[1]`, `r[2]` (also `.origin`, `.through`) |

None of `APSegment`/`APLine`/`APRay` carry a direction *magnitude* (an
`APLine` through `p1` and `p2` is the same object as the line through `p2`
and `p1`), but `APSegment` and `APRay` do remember which of their two
points comes first, since that is what makes them finite/one-sided in the
first place.

`APPoint`/`APVector`/`APSegment`/`APLine`/`APRay` all support
**destructuring** (`x, y = p`, `p1, p2 = s`) for convenience, including
flattening a whole collection of them into their defining points at once,
via `Iterators.flatten`:

```@example geo
using Apollonius

c1, c2 = APCircle2(APPoint(0.0, 0.0), 2.0), APCircle2(APPoint(10.0, 0.0), 1.0)
l1, l2 = external_tangent_lines(c1, c2)
collect(Iterators.flatten([l1, l2]))   # the 4 points of tangency, in one Vector{APPoint}
```

```@raw html
<img src="../assets/img/points_lines/destructuring_tangents.svg" alt="Two circles with their two common external tangent lines, the four tangent points marked" style="width:100%; max-width: 700px;">
```

But every `APObject`/`APTransform` (this one included) is always a
*scalar* for **broadcasting** purposes, so `translate.(p, [v1, v2])` or
`intersection.(l, [c1, c2])` repeats the single shape against each
element of the other argument, rather than Julia's usual `f.(x)`
mistaking an iterable `x` for a collection to broadcast over its own
components.

## Creating them

```@example geo
using Apollonius

A = APPoint(3.0, 4.0)
O = APPoint(0.0, 0.0)

s = APSegment(O, A)     # the segment from O to A
l = APLine(O, A)        # the infinite line through O and A
r = APRay(O, A)         # the half-line starting at O, through A

distance(O, A)
```

`distance(O, A)` is `5.0`: with `A = APPoint(3.0, 4.0)`, this is just the classic
3-4-5 triangle. `APSegment`, `APLine` and `APRay` all wrap the *same* two
points here. What differs is only how far they extend and what other
functions are willing to do with them (e.g. [`on_segment`](@ref) only
makes sense for an `APSegment`, [`slope_angle`](@ref) treats `APLine` and
`APRay` as pointing one way and an `APSegment` as pointing from its first
point to its second).

## From a direction

A line or a ray can also be built from a point and a direction, given as a
vector or as an angle (radians, counterclockwise from the positive x-axis). A
segment can be built from a point and a vector, or from a length and an angle:

```@example geo
p0 = APPoint(1.0, 1.0)
APLine(p0, APVector(2.0, 1.0)), APLine(p0, pi / 6)
```

```@example geo
APRay(p0, pi / 2), APSegment(p0, APVector(3.0, 0.0)), APSegment(p0, 5.0, pi / 3)
```

```@raw html
<img src="../assets/img/points_lines/from_direction.svg" alt="A line from a point and a vector, a ray from a point and an angle and a segment from a point, a length and an angle" style="width:100%; max-width: 700px;">
```

The forms with a vector use the two points `p` and `p + v`, so `l.p2 - l.p1` is
`v` itself. The forms with an angle use a unit vector. A zero vector raises an
`ArgumentError`.

## Points vs. vectors

A point minus a point is *still a point*, not a vector. `A - O` above
stays an `APPoint`. This is a deliberate choice: it keeps existing
point-arithmetic formulas (like a reflection written as `2*about - p`)
working exactly as they read, without forcing every subtraction through a
vector type first. Where a genuine *direction* is called for (the
result of [`direction`](@ref) below, for instance), the package hands
back an actual [`APVector`](@ref) instead:

```@example geo
d = direction(l)    # an APVector, not an APPoint
typeof(d)
```

```@raw html
<img src="../assets/img/points_lines/line_types.svg" alt="The same two points define a segment, a line and a ray" style="width:100%; max-width: 700px;">
```

Both types support the same arithmetic and the standard linear-algebra
functions `norm`, `dot` and `normalize`, re-exported from `LinearAlgebra`
purely so `using Apollonius` alone is enough to get the full
vector toolkit, without a separate `using LinearAlgebra`:

```@example geo
norm(d)        # 5.0
normalize(d)   # ⟨0.6, 0.8⟩: unit vector, same direction
dot(d, APVector(1.0, 0.0))   # 3.0
```

### Giving a vector a position: `APEquipollentVector`

An `APVector` is deliberately positionless. That's exactly what makes it
the right type for `direction(l)`, a normal, or anything else that's
purely "which way and how far," never "where." That positionlessness
means a bare `APVector` has no [`APBoundingBox`](@ref) at all
(`isempty(APBoundingBox(::APVector))` is always `true`), so it never
contributes to [`@to_luxor_picture`](@ref)'s fit-to-canvas *sizing*, and
it can't be shifted into place the way a positioned shape can (there's
nowhere to shift it *to*), but it still gets scaled and flipped to the
picture's own scale, so `path(v, from=anchor)` (with `v` and `anchor`
both built inside the same block) comes out at the right length and
orientation, anchored wherever `anchor` itself lands.

What a bare vector still can't do is stand as *one positioned thing*: it
has no bounding box of its own to size a picture by, can't be
`translate`d anywhere, and can't be transformed as a single unit together
with a point that's tracked separately alongside it.
[`APEquipollentVector`](@ref) (the classical "vector equipolente": a
representative of a free vector, tied to a point of application) is the
fix for that. It wraps a `vector` and the `point` it's applied at as one
object, with a real, non-empty bounding box, and transforms fully like
any other `APCurve`:

```@example geo
ev = APEquipollentVector(d, O)   # d applied at O
APBoundingBox(ev)                 # a real box now, unlike APBoundingBox(d)
```

`tip(ev)` is `ev.point + ev.vector`, computed on demand. `norm`/
`normalize`/`dot` all work the same way as on a bare `APVector` (acting on
`ev.vector`; `normalize` keeps `ev.point` fixed), and the usual
`rotate`/`translate`/`homothety`/`reflection` quartet works too.
`translate` in particular moves `ev.point`, something a bare `APVector`
(having no position to begin with) can never do:

```@example geo
translate(ev, APVector(1.0, 1.0))   # ev.point moves; ev.vector itself doesn't
```

`homothety` scales `ev.point` about a center *and* `ev.vector`'s own
length together, matching how the whole configuration grows or shrinks
as one piece:

```@example geo
homothety(ev, 2.0, O)   # both O and the vector scale together
```

[`APVector`](@ref)`(ev)` unwraps back to the bare, positionless vector
(mirroring `APVector(::APPoint)`), and, more usefully, every
[`translate`](@ref) method that already accepts a bare `APVector` accepts
an `APEquipollentVector` in its place too, driven by `ev.vector` and
ignoring wherever `ev` itself happens to be anchored; `p + ev` (point
arithmetic, not a call to `translate`) is the same shorthand for a plain
`APPoint`:

```@example geo
APVector(ev)         # unwraps back to the bare vector, same as d
translate(A, ev)     # same as translate(A, d): ev's own point is ignored
```

Putting one inside a [`@to_luxor_picture!`](@ref) block and drawing it
with [`path`](@ref)`(ev; as=:arrow)` (see
[Drawing with Luxor.jl](@ref)) is what correctly scales/places it:

```@raw html
<img src="../assets/img/points_lines/direction_vector.svg" alt="A line, its direction vector d drawn as a green arrow, and the unit vector v = normalize(d) drawn as a purple arrow, both correctly anchored and scaled" style="width:100%; max-width: 700px;">
```

## Polar coordinates

[`polar_point`](@ref) builds a point from a distance and an angle (radians,
counterclockwise from the positive x-axis) instead of `x`/`y`, and
[`polar_point_deg`](@ref) is the same with the angle in degrees. Both
take the `center` as an optional third argument, and measure from the origin
without it:

```@example geo
Bpolar = polar_point_deg(4.0, 40.0)      # 4 units out from the origin, at 40°
distance(O, Bpolar)                       # 4.0, regardless of the angle
polar_point_deg(4.0, 40.0, APPoint(2.0, 1.0))   # the same, around another center
```

```@raw html
<img src="../assets/img/points_lines/polar.svg" alt="A point at distance 4 and angle 40 degrees from a center" style="width:100%; max-width: 700px;">
```

This is exactly the point/angle/modulus relationship [`slope_angle`](@ref)
and [`distance`](@ref) give you the other way around:
`polar_point(distance(O, p), slope_angle(APLine(O, p)), O)` recovers `p`
(for `p != O`). [`polar_angle`](@ref)`(p, center)` is the angle alone, in `(-π, π]`,
and the center is the origin when omitted:

```@example geo
rad2deg(polar_angle(APPoint(0.0, 3.0))), rad2deg(polar_angle(APPoint(3.0, 4.0), APPoint(3.0, 1.0)))
```

## Points by parameter and by angle

[`point_on_line`](@ref)`(obj, t)` is the point `p1 + t * (p2 - p1)` of a
line, segment or ray: `t = 0` is the first defining point, `t = 1` the
second, and the parameter is not restricted to `[0, 1]`. [`point_on_circle`](@ref)`(c, angle)`
is the point of a circle at an angle (radians, counterclockwise from the
positive x-axis) as seen from its center.

```@example geo
point_on_line(s, 0.5) ≈ midpoint(s), point_on_line(l, 2.0), point_on_line(r, -1.0)
```

```@example geo
c = APCircle2(APPoint(1.0, 2.0), 5.0)
point_on_circle(c, 0.0), point_on_circle(c, pi / 2)
```

```@raw html
<img src="../assets/img/points_lines/by_parameter.svg" alt="Points of a line at several parameters and points of a circle at several angles" style="width:100%; max-width: 700px;">
```

## By distance, by ratio and evenly spaced

[`point_on_line`](@ref) takes a *fraction* of the way from the first point to
the second. When you know a *length* instead, use [`point_at_distance`](@ref),
which works on a line, a ray or a segment and goes the other way for a
negative length. [`divide_segment`](@ref) cuts a segment in `n` equal parts, or
finds the point that divides it in a ratio `m : n`, from outside when `n` is
negative:

```@example geo
sg = APSegment(APPoint(0.0, 0.0), APPoint(8.0, 0.0))
point_at_distance(sg, 6.5), divide_segment(sg, 4)
```

```@example geo
divide_segment(sg, 1, 2), divide_segment(sg, 3, -1)   # 1 : 2 inside, 3 : -1 outside
```

```@raw html
<img src="../assets/img/points_lines/divide_points.svg" alt="A segment with its three quarter points, the point at distance 6.5, the point that divides it 1 to 2 and the external point 3 to -1" style="width:100%; max-width: 700px;">
```

[`equally_spaced_points`](@ref)`(obj, n)` spreads `n` points along a curve:

| Object | Points | Spacing |
|:-------|:-------|:--------|
| [`APSegment`](@ref) | both ends and the ones between, `n >= 2` | equal lengths |
| [`APCircularArc2`](@ref) | both ends and the ones between, `n >= 2` | equal arc lengths |
| [`APCircle2`](@ref) | `n` points, from the angle `start` | equal arc lengths |
| [`APEllipse2`](@ref) | `n` points, from the parameter `start` | equal parameter, not equal arc length |

```@example geo
equally_spaced_points(APCircle2(APPoint(0.0, 0.0), 1.0), 4)
```

```@example geo
arc_eq = APCircularArc2(APCircle2(APPoint(0.0, 0.0), 1.0), APPoint(1.0, 0.0), APPoint(0.0, 1.0))
equally_spaced_points(arc_eq, 3)
```

## Direction, slope and predicates

```@example geo
direction(l)                    # ⟨3.0, 4.0⟩: l.p2 - l.p1, as an APVector
rad2deg(slope_angle(l))         # ≈ 53.13°
v = APVector(1.0, 1.0)
rad2deg(slope_angle(v))
is_collinear(O, A, APPoint(6.0, 8.0))
on_line(APPoint(6.0, 8.0), l)
on_segment(APPoint(6.0, 8.0), s) # false: beyond A
```

| Function | Returns | Meaning |
|:---------|:--------|:--------|
| [`direction`](@ref) | `APVector` | non-normalized direction of an `APLine`/`APRay`/`APSegment` |
| [`slope_angle`](@ref) | angle | `atan(dy, dx)` of that direction, in radians; also for an `APVector` |
| [`is_collinear`](@ref) | `Bool` | do three points lie on a common line? |
| [`is_parallel`](@ref) / [`is_perpendicular`](@ref) | `Bool` | relation between two lines |
| [`on_line`](@ref) / [`on_segment`](@ref) / [`on_ray`](@ref) | `Bool` | is a point on this line / this finite segment / this half-line? |
| [`side_of_line`](@ref) | `-1`, `0` or `1` | which side of a line a point falls on |

```@example geo
l_horiz = APLine(APPoint(0.0, 0.0), APPoint(4.0, 0.0))
side_of_line(APPoint(2.0, 1.0), l_horiz)   #  1 : "above"
side_of_line(APPoint(2.0, -1.0), l_horiz)  # -1 : "below"
```

```@example geo
l_vert = APLine(APPoint(0.0, 0.0), APPoint(0.0, 4.0))
is_parallel(l, APLine(APPoint(1.0, 0.0), APPoint(4.0, 4.0))), is_perpendicular(l_horiz, l_vert)
```

```@example geo
r = APRay(APPoint(0.0, 0.0), APPoint(4.0, 0.0))
on_ray(APPoint(10.0, 0.0), r)    # true: ahead of the origin, same direction
on_ray(APPoint(-1.0, 0.0), r)    # false: on the line, but behind the origin
```

`on_line`/`on_segment`/`on_ray` are also exactly what `Base.in` uses under
the hood, so the more natural `p in l` reads just as well:

```@example geo
APPoint(6.0, 8.0) in l, APPoint(10.0, 0.0) in r
```

```@raw html
<img src="../assets/img/points_lines/direction_slope.svg" alt="A line with its direction vector, its slope angle and a point on it" style="width:100%; max-width: 700px;">
```

## Lengthening a line or segment

[`extend_line`](@ref)`(l, before, after)` lengthens the line through
`l.p1` and `l.p2` by fractions of `distance(l.p1, l.p2)` past each point
and returns the resulting [`APSegment`](@ref). The fractions are relative to
the two defining points, so the same value adds more length to a longer
line. A negative fraction shortens that end, and an [`APSegment`](@ref) is
accepted too.

```@example geo
base = APLine(APPoint(0.0, 0.0), APPoint(10.0, 0.0))
ext = extend_line(base, 0.5)         # half of 10.0 more, at each end
ext.p1, ext.p2, distance(ext.p1, ext.p2)
```

```@raw html
<img src="../assets/img/decorations/extend_line.svg" alt="A segment lengthened at both ends" style="width:100%; max-width: 700px;">
```

The same lengthening is available when drawing, as the `add` keyword of
`path`; see [Drawing with Luxor.jl](@ref). More on this function is in
[Marks, Labels & Decorations](@ref).

## Distance to a line, segment or ray

[`distance`](@ref) also works between a point and any of `APLine`,
`APSegment` or `APRay`: the perpendicular distance to the *infinite* line
in the first case, but clamped to the finite extent for the other two (so
a point "past the end" measures to the nearest endpoint, not along the
infinite extension):

```@example geo
far_point = APPoint(10.0, 10.0)
distance(far_point, l), distance(far_point, s), distance(far_point, r)
# perpendicular to the infinite line; clamped to the finite segment [O,A]; clamped to the ray
```

`on_line`/`on_segment`/`on_ray` each also take just the line/segment/ray
(no point) to build a reusable one-argument predicate, for `filter`:

```@example geo
pts = [APPoint(2.0, 0.0), APPoint(2.0, 1.0), APPoint(-1.0, 0.0)]
filter(on_ray(r), pts)   # only the point that's on r
```

```@raw html
<img src="../assets/img/points_lines/distance_curves.svg" alt="The distance from a point to a line, a segment and a ray" style="width:100%; max-width: 700px;">
```

## Projection, reflection and the perpendicular foot

[`projection`](@ref) drops a point onto a line at a right angle;
[`reflection`](@ref) mirrors a point through another point (its use for
mirroring *across a line* is: project first, then reflect through the
foot).

```@example geo
P, Q = APPoint(1.0, 1.0), APPoint(6.0, 3.0)
l = APLine(P, Q)
C = APPoint(2.0, 6.0)

foot = projection(C, l)      # the perpendicular foot of C on l
Cref = reflection(C, foot)   # C mirrored through that foot, i.e. across l
```

```@raw html
<img src="../assets/img/points_lines/projection_reflection.svg" alt="A line l, a point C, its perpendicular foot on l, and C reflected through that foot to the other side of l, joined by a dashed segment" style="width:100%; max-width: 700px;">
```

`projection` also takes an `angle` keyword (radians, default `pi/2`,
measured counterclockwise from `l`'s own direction) for the **oblique**
projection of `p` onto `l`: the point where a line through `p` at that
angle meets `l`, instead of the perpendicular:

```@example geo
projection(C, l; angle=pi / 2) == foot   # pi/2 is the ordinary case
projection(C, l; angle=pi / 3)            # a genuinely oblique projection
```

`angle` must be strictly between `0` and `π`. At either end the
projecting line would be parallel to `l` itself, so there'd be no single
intersection point:

```@example geo
try
    projection(C, l; angle=0.0)
catch e
    e
end
```

Like the predicates above, `projection(l; angle=...)` (no point) builds a
reusable one-argument function, for `map`/`|>`:

```@example geo
map(projection(l), [C, P, Q])   # project a whole collection onto l at once
```

## Rotation, homothety and translation

[`rotate`](@ref) turns a point about a center by an angle (radians,
counter-clockwise); [`homothety`](@ref) scales it by a factor `k` about a
center (`k = -1` is a point reflection, `0 < k < 1` shrinks towards the
center); [`translate`](@ref) shifts it by an [`APVector`](@ref) (the
fourth member of this quartet, and the only one with no `center`: a
translation has none). `rotate`/`homothety` default to the origin when no
center is given.

```@example geo
rotate(C, pi / 2, P)     # C rotated 90° about P
homothety(C, 2.0, P)     # C scaled by 2 about P
translate(C, APVector(1.0, -1.0))   # C shifted by (1,-1)
barycenter([P, Q, C], [1.0, 1.0, 2.0])   # weighted average of the three
```

```@raw html
<img src="../assets/img/points_lines/rotation_homothety_translation.svg" alt="" style="width:100%; max-width: 700px;">
```


## Parallels, perpendiculars and bisectors

```@example geo
midpoint(P, Q)                      # [3.5, 2.0]: the plain average of the two
parallel_through(l, C)             # line through C, parallel to l
perpendicular_through(l, C)        # line through C, perpendicular to l
pb = perpendicular_bisector(P, Q)  # perpendicular to [P,Q] through its midpoint
```

```@raw html
<img src="../assets/img/points_lines/par_per_bis.svg" alt="" style="width:100%; max-width: 700px;">
```


[`angle_bisectors`](@ref) is the analogous construction for two intersecting
lines: it returns *both* bisectors (they are always perpendicular to each
other), as a 2-element vector.

```@example geo
xaxis = APLine(APPoint(0.0, 0.0), APPoint(4.0, 0.0))
yaxis = APLine(APPoint(0.0, 0.0), APPoint(0.0, 4.0))
angle_bisectors(xaxis, yaxis)   # the two diagonals y = x and y = -x
```

```@raw html
<img src="../assets/img/points_lines/ang_bis.svg" alt="" style="width:100%; max-width: 700px;">
```

## Angles

Under the hood, angles between two vectors come from two free functions:
[`angle_between`](@ref)`(u, v)` (signed, counterclockwise from `u` to `v`,
in `(-π, π]`) and [`angle_at`](@ref)`(vertex, p1, p2)` (unsigned, in
`[0, π]`). Use these directly when you just need a number and not
something to pass around.

```@example geo
angle_between(APVector(4.0, 0.0), APVector(0.0, 4.0))   # π/2
```

[`APAngle2`](@ref) wraps up the "angle at a vertex between two rays" idea
into a small struct (`vertex`, `a`, `b`) so it can be passed around and
measured without repeating the three points everywhere.
`measure`/`abs` on an `APAngle2` are exactly `angle_between`/`angle_at` on
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
[`@to_luxor_picture`](@ref)'s default `flip=true`, see
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
as an `APAngle2` (say, from `angle_between`'s caller building one to
measure/display it) and don't want to unwrap it by hand first:

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


## Harmonic conjugate and the golden ratio point

Given `A`, `B` on a line and a third point `P` on that same line,
[`harmonic_conjugate`](@ref) returns the point `P'` for which `(A, B; P, P')`
is a harmonic range, i.e. `P` and `P'` divide `[A,B]` internally and
externally in the same ratio. [`golden_ratio_point`](@ref) is the special
point that divides `[A,B]` in the golden ratio, `A + (B-A)/φ`.

```@example geo
A, B = APPoint(0.0, 0.0), APPoint(8.0, 0.0)
P = APPoint(2.0, 0.0)

Pgold = golden_ratio_point(A, B)     # ≈ [4.944, 0.0]
Pconj = harmonic_conjugate(A, B, P)  # [-4.0, 0.0]: P's harmonic conjugate
```

```@raw html
<img src="../assets/img/points_lines/harmonic.svg" alt="Two points, a third between them, its harmonic conjugate and the golden ratio point" style="width:100%; max-width: 700px;">
```

`P'` falls *outside* `[A,B]`, on the opposite side from `B`: that is exactly
what makes the division "external" for one of the two points and "internal"
for the other, which is the defining property of a harmonic range.

## The Apollonius circle of two points, and concyclic points

[`apollonius_circle`](@ref)`(a, b, k)` is the locus of points `p` with
`distance(p, a) / distance(p, b) == k`: a genuine circle for any `k != 1`
(at `k == 1` the locus degenerates to the perpendicular bisector of
`[a, b]`, a line, so that case throws an `ArgumentError` instead):

```@example geo
ap = apollonius_circle(A, B, 2.0)     # every point on it is twice as far from B as from A
Ptest = polar_point_deg(ap.r, 50.0, ap.center)   # an arbitrary point on ap
distance(Ptest, A) / distance(Ptest, B)          # ≈ 2.0, regardless of the angle chosen
```

```@raw html
<img src="../assets/img/points_lines/ap_circ.svg" alt="" style="width:100%; max-width: 700px;">
```


```@example geo
try
    apollonius_circle(A, B, 1.0)   # k == 1: the locus is a line, not a circle
catch e
    e
end
```

[`is_concyclic`](@ref)`(a, b, c, d)` tests whether four points lie on a
common circle, used internally by [`is_cyclic`](@ref) for a quadrilateral:

```@example geo
circ = APCircle2(APPoint(0.0, 0.0), 5.0)
Q1, Q2, Q3, Q4 = (polar_point_deg(5.0, ang) for ang in (0.0, 80.0, 170.0, 260.0))
is_concyclic(Q1, Q2, Q3, Q4)                       # true: all 4 on the same circle
is_concyclic(Q1, Q2, Q3, APPoint(1.0, 1.0))        # false: this last point isn't on circ
```

## Random points on a boundary

`rand(s)` (and `rand(s, n)`, `rand(rng, s)`, the usual `Base.rand` forms)
draws a random point on `s`'s own boundary or perimeter, never its
interior. It's defined once, generically, via Julia's `Random.Sampler`
protocol, so it works the same way for `APSegment` here and for most
other shapes in this package:

| Type | Uniform in |
|:-----|:-----------|
| `APSegment` | arc length (exact) |
| `APCircle2`, `APCircularArc2` | arc length (exact) |
| `APEllipse2`, `APEllipticArc2`, `APParabolicArc2`, `APHyperbolicArc2` | the curve's own parameter (slightly denser near the flatter parts) |
| `APTriangle`/`APQuadrilateral`/`APStraightNgon`, curved regions, `APBoundingBox` | the whole perimeter (each side chosen with probability proportional to its own length, then a point on it by the rule above) |

Not defined for `APLine`/`APRay` (infinite: no uniform distribution
exists) or `APParabola2`/`APHyperbola2` as full curves (also infinite).

For a point in the *interior*, use [`rand_inside`](@ref)`([rng,] s)`: uniform
over the area of an [`APCircle2`](@ref) (the disk), an [`APEllipse2`](@ref),
an [`APBoundingBox`](@ref) or an [`APTriangle`](@ref).

```@example geo
using Random
q = rand_inside(Xoshiro(1), APCircle2(APPoint(0.0, 0.0), 2.0))
distance(q, APPoint(0.0, 0.0)) <= 2.0
```

```@example geo
s = APSegment(APPoint(0.0, 0.0), APPoint(10.0, 0.0))
p = rand(s)
on_segment(p, s)          # true: always exactly on the segment, by construction
pts = rand(s, 5)          # the dims... form: a Vector of 5 independent draws
length(pts) == 5 && all(q -> on_segment(q, s), pts)
```

```@raw html
<img src="../assets/img/points_lines/random_disk.svg" alt="Random points on a circle and inside it" style="width:100%; max-width: 700px;">
```

Every other page repeats this for its own types where it matters: see
[Circles](@ref), [Conics: Ellipse, Parabola & Hyperbola](@ref) and
[Polygons & Bounding Boxes](@ref).

## Arbitrary parametric curves

Every curve so far has a closed analytic form (a line, a circle, an
ellipse...). [`APParametricCurve2`](@ref) is the escape hatch for anything
outside those fixed families: it wraps a function `f(t)::APPoint` over a
range `t ∈ (tmin, tmax)`. An ordinary `y = f(x)` curve is just
`APParametricCurve2(x -> APPoint(x, f(x)), (xmin, xmax))`:

```@example geo
sine_curve = APParametricCurve2(x -> APPoint(x, sin(x)), (0.0, 2pi))
point_on_curve(sine_curve, pi / 2)   # (π/2, 1.0): the peak
```

`translate`/`rotate`/`homothety`/`reflection` all wrap `f` in a new
closure rather than sampling it, so a transformed `APParametricCurve2`
stays exact regardless of what `f` computes:

```@example geo
shifted = translate(sine_curve, APVector(0.0, 2.0))
point_on_curve(shifted, pi / 2)   # (π/2, 3.0): same curve, raised by 2
```

`f` has no closed form the package can inspect, so
[`APBoundingBox`](@ref) falls back to sampling it at `n` (default `200`)
evenly spaced points over `trange` and taking the union of their boxes.
Unlike every other `APBoundingBox` method in this package, this one is an
approximation, not exact: a sharply curving `f` between sample points can
poke outside the box it returns.

```@example geo
box = APBoundingBox(sine_curve)
box.min[2], box.max[2]   # ≈ (-1.0, 1.0), the true range of sin, already tight at the default n
```

```@raw html
<img src="../assets/img/points_lines/parametric.svg" alt="A sine curve, the same curve raised by 2 and the bounding box of the first" style="width:100%; max-width: 700px;">
```
