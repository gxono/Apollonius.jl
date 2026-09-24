```@meta
CurrentModule = Apollonius
```

# Points, Lines & Rays: Creating Them

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
functions are willing to do with them (e.g. [`is_on_segment`](@ref) only
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
APRay(p0, -pi / 2), APSegment(p0, APVector(3.0, 0.0)), APSegment(p0, 5.0, pi / 3)
```

```@raw html
<img src="../assets/img/points_lines/from_direction.svg" alt="A line from a point and a vector, a ray from a point and an angle and a segment from a point, a length and an angle" style="width:100%; max-width: 700px;">
```

!!! details "See script"
    ```julia
    using Apollonius
    using Luxor
    import Apollonius: midpoint
    import Luxor: julia_blue, julia_purple

    lxm = @prepare_to_picture! width=500 height=240 margin=20 begin
        p = APPoint(-1.0, -1.0)
        v = APVector(2.0, 1.0)
        vec = APEquipollentVector(v, p)
        l = APLine(p, v)


        q = APPoint(5.0, -1.0)
        seg = APSegment(q, 3.0, 2pi / 3)
        ang_seg = APAngle2(q, q + APVector(1.0, 0), seg.p2)


        r0 = APPoint(-3.0, 3.0)
        ray = APRay(r0, -pi / 4)
        ang_ray = reverse(APAngle2(r0, r0 + APVector(1.0, 0), ray.through))
    end


    begin
    Drawing(lxm.width, lxm.height, :svg)
    origin(); fontsize(15)
    fontsize(15)

    @layer begin
        sethue(julia_blue); setopacity(0.25)
        path(ang_seg, action=:fill, as=:sector, radius=50)
        path(ang_ray, action=:fill, as=:sector, radius=50)
        setopacity(1)
        path(ang_seg, action=:stroke, radius=50)
        path(ang_ray, action=:stroke, radius=50)
    end

    sethue(julia_purple)
    path(l, action=:stroke)
    path(ray, action=:stroke)
    path(seg, action=:stroke)

    sethue(julia_blue)
    path(vec; as=:arrow, action=:stroke)

    sethue(julia_red)
    text("line", p + APVector(-5.0, -5.0), halign=:right, direction=l, valign=:bottom)
    text("segment", midpoint(seg) + APVector(3,0), direction=-direction(seg), halign=:right, valign=:bottom)
    text("ray", r0 + APVector(-8.0,5.0), direction=ray, valign=:top)

    sethue("white")
    path([p, q, r0], action=:fillpreserve)
    sethue(julia_blue); strokepath()
    finish()
    end
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
contributes to [`@prepare_to_picture`](@ref)'s fit-to-canvas *sizing*, and
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

Putting one inside a [`@prepare_to_picture!`](@ref) block and drawing it
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

[`point_on`](@ref)`(obj, t)` is the point `p1 + t * (p2 - p1)` of a
line, segment or ray: `t = 0` is the first defining point, `t = 1` the
second, and the parameter is not restricted to `[0, 1]`. [`point_on`](@ref)`(c, angle)`
is the point of a circle at an angle (radians, counterclockwise from the
positive x-axis) as seen from its center.

```@example geo
point_on(s, 0.5) ≈ midpoint(s), point_on(l, 2.0), point_on(r, -1.0)
```

```@example geo
c = APCircle2(APPoint(1.0, 2.0), 5.0)
point_on(c, 0.0), point_on(c, pi / 2)
```

```@raw html
<img src="../assets/img/points_lines/by_parameter.svg" alt="Points of a line at several parameters and points of a circle at several angles" style="width:100%; max-width: 700px;">
```

## By distance, by ratio and evenly spaced

[`point_on`](@ref) takes a *fraction* of the way from the first point to
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
