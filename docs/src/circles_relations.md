```@meta
CurrentModule = Apollonius
```

# Circles: How They Relate

The two circles from [Circles: Basics](@ref):

```@example geo
using Apollonius

c = APCircle2(APPoint(0.0, 0.0), 5.0)
c1 = APCircle2(APPoint(0.0, 0.0), 3.0)
c2 = APCircle2(APPoint(8.0, 0.0), 2.0)
nothing # hide
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
<img src="../assets/img/circles/similitude_center.svg" alt="Two circles with their two external and two internal common tangent lines, meeting at the external and internal similitude centers" style="width:100%; max-width: 700px;">
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
incircle(t))` is X(55) (see [Triangles: The Classical Centers](@ref)).

[`tangent_parallel`](@ref) gives the two tangent lines to a circle parallel to a given line: the tangents at the two ends of the diameter perpendicular to it. In each returned line, the first point is the point of tangency:

```@example geo
t1, t2 = tangent_parallel(c, APLine(APPoint(0.0, 3.0), APPoint(1.0, 4.0)))
```

```@raw html
<img src="../assets/img/circles/tangent_parallel.svg" alt="A circle, a line, and the two tangent lines to the circle parallel to it" style="width:100%; max-width: 700px;">
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

!!! details "See script"
    ```julia
    using Apollonius, Luxor
    import Luxor: julia_red, julia_blue, julia_green, julia_purple
    import Apollonius: rotate, translate, distance, midpoint

    lxm = @prepare_to_picture! width=500 height=300 margin=30 begin  
        c = APCircle2(APPoint(0.0, 0.0), 5.0)
        l = APLine(APPoint(-5.0, 0.0), APPoint(0.0, 3.0))
        known = APPoint(-5.0, 0.0)
        other = other_intersection(l, c, known)
        c2 = APCircle2(APPoint(6.0, 0.0), 5.0)
        pts = intersection(c, c2)
        ref = APPoint(3.0, 8.0)
        chosen = nearest_point(pts, ref)
    end


    begin
    Drawing(lxm.width, lxm.height, :svg)
    origin(); fontsize(15)
    sethue(julia_blue)
    path([c, c2], action=:stroke)
    path(l, action=:stroke, extend=40)
    sethue(julia_purple)
    sethue("gray80")
    sethue(julia_red)
    label("known", :NW, known); label("other", :N, other); label("p", :N, ref)
    sethue("white"); path([known, ref], action=:fillpreserve); sethue(julia_blue); strokepath()
    sethue("white"); path([other, chosen], action=:fillpreserve); sethue(julia_purple); strokepath()
    sethue("white"); path([p for p in pts if p != chosen], action=:fillpreserve); sethue("gray80"); strokepath()

    finish()
    preview()
    end
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

!!! details "See script"
    ```julia
    using Apollonius, Luxor
    import Luxor: julia_red, julia_blue, julia_green, julia_purple
    import Apollonius: rotate, translate, distance, midpoint

    lxm = @prepare_to_picture! width=560 height=300 margin=30 begin  
        cs = [c for (i, (r1, r2, d)) in enumerate([(1.5, 1.0, 4.0), (1.5, 1.0, 2.5), (1.5, 1.0, 1.8), (1.5, 0.75, 0.75), (1.5, 0.5, 0.4), (1.5, 1.0, 0.0)]) for c in (APCircle2(APPoint(8.0 * mod(i - 1, 3), -6.0 * fld(i - 1, 3)), r1), APCircle2(APPoint(8.0 * mod(i - 1, 3) + d, -6.0 * fld(i - 1, 3)), r2))]
        labpts = [APPoint(8.0 * mod(i - 1, 3) + 1.5, -6.0 * fld(i - 1, 3) - 2.4) for i in 1:6]
    end


    begin
    Drawing(lxm.width, lxm.height, :svg)
    origin(); fontsize(13)
    sethue(julia_blue)
    path(cs, action=:stroke)
    sethue(julia_red)
    for (n, p) in zip((":disjoint_ext", ":tangent_ext", ":secant", ":tangent_int", ":disjoint_int", ":concentric"), labpts)
        label(n, :S, p)
    end

    finish()
    preview()
    end
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

!!! details "See script"
    ```julia
    using Apollonius, Luxor
    import Luxor: julia_red, julia_blue, julia_green, julia_purple
    import Apollonius: rotate, translate, distance, midpoint

    lxm = @prepare_to_picture! width=500 height=300 margin=30 begin  
        c = APCircle2(APPoint(0.0, 0.0), 3.0)
        out = offset_circle(c, 1.0)
        inn = offset_circle(c, -1.0)
        ch = chord(c, 0.5, 2.4)
        di = diameter(c, 5.0)
    end


    begin
    Drawing(lxm.width, lxm.height, :svg)
    origin(); fontsize(15)
    gsave()
    setline(1); setdash("dash")
    sethue("gray80")
    path([out, inn], action=:stroke)
    grestore()
    sethue(julia_blue)
    path(c, action=:stroke)
    sethue(julia_purple)
    path([ch, di], action=:stroke)
    sethue(julia_red)
    label("chord", :NW, ch.p1); label("diameter", :SE, di.p1); label("offset_circle(c, 1)", :S, APPoint(0.0, -4.0))
    sethue("white"); path([ch.p1, ch.p2, di.p1, di.p2], action=:fillpreserve); sethue(julia_purple); strokepath()

    finish()
    preview()
    end
    ```
