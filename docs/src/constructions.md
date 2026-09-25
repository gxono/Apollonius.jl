```@meta
CurrentModule = Apollonius
```

# Compass & Ruler Constructions

Euclid built everything with two tools: a straightedge and a compass. The
straightedge is a line, and the compass is a circle whose radius you fix
and then swing. On paper it leaves a short arc, and that trace is what
shows the reader how a point was found.

This page is about drawing that. The construction functions return the
result of a step *and* the compass traces that produced it, so a figure can
show the work.

## The compass trace

A trace is an [`APCircularArc2`](@ref). Several functions build one, each
for a different way of saying which arc you want:

| You know | Function | Result |
|:---------|:---------|:-------|
| Center, a point, and the measure to sweep from the point | [`arc_with_measure`](@ref) | an arc starting at the point |
| Center, a point, and the length to sweep from the point | [`arc_with_length`](@ref) | an arc starting at the point |
| Center, a point, and the total sweep, symmetric about the point | [`compass_trace`](@ref) | an arc centered on the point |
| Center, radius and two polar angles | [`APCircularArc2`](@ref)`(center, r, θ1, θ2)` | the arc between them |
| Center, radius and two points | [`APCircularArc2`](@ref)`(center, r, p1, p2)` | the arc between them |
| A center and the start of a half turn | [`semicircle`](@ref) | a half circle |
| An arc to lengthen at both ends | [`extend_arc`](@ref) | the longer arc |

[`compass_trace`](@ref)`(center, p; angle)` is the one a construction
uses: the compass is centered at `center` and opened to reach `p`. The arc
it draws passes through `p`, with `p` at its middle and the sweep spread
evenly to both sides. Give the total sweep as `angle` in radians, or as
`length` for the total arc length, but not both.

```@example geo
using Apollonius

center, p = APPoint(0.0, 0.0), APPoint(5.0, 0.0)
trace = compass_trace(center, p; angle=pi / 3)
measure(trace) ≈ pi / 3, isapprox(midpoint(trace), p; atol=1e-9)
```

```@raw html
<img src="../assets/img/constructions/compass_trace.svg" alt="A compass trace around a point P, centered at O" style="width:100%; max-width: 700px;">
```

[`arc_with_measure`](@ref) and [`arc_with_length`](@ref) both start at the
given point and sweep from it; the difference is only in what you give as
the third argument, an angle or a length:

```@example geo
by_angle = arc_with_measure(center, p, pi / 3)
by_length = arc_with_length(center, p, 5.0 * pi / 3)
isapprox(by_angle, by_length; atol=1e-9)
```

Three of the other builders side by side: `arc_with_measure` starts at the point and sweeps from it, `semicircle` is a half turn, and `extend_arc` lengthens an arc (the blue part is the original).

```@raw html
<img src="../assets/img/constructions/arc_builders.svg" alt="Three compass arcs: arc_with_measure, semicircle and extend_arc" style="width:100%; max-width: 700px;">
```

!!! details "See script"
    ```julia
    using Apollonius, Luxor
    import Luxor: julia_red, julia_blue, julia_green, julia_purple
    import Apollonius: rotate, translate, distance, midpoint

    lxm = @prepare_to_picture! width=500 height=200 margin=45 begin  
        O1, P1 = APPoint(0.0, 0.0), APPoint(3.0, 0.0)
        aux = reflection(P1, O1)
        O2, P2 = APPoint(8.0, 0.0), APPoint(11.0, 0.0)
        O3, P3 = APPoint(16.0, 0.0), APPoint(19.0, 0.0)
        a1 = arc_with_measure(O1, P1, pi / 3)
        a2 = semicircle(O2, P2)
        a3 = arc_with_measure(O3, P3, pi / 3)
        a3x = extend_arc(a3, 0.5)
    end


    begin
    Drawing(lxm.width, lxm.height, :svg)
    origin(); fontsize(15)

    sethue(julia_purple)
    path([a1, a2, a3x], action=:stroke)

    sethue(julia_blue)
    path(a3, action=:stroke)

    sethue(julia_red)
    label("arc_with_measure", :S, O1, offset=8)
    label("semicircle", :S , O2, offset=8)
    label("extend_arc", :S , O3, offset=8)

    sethue("white")
    path([O1, P1, O2, P2, O3, P3], action=:fillpreserve)
    sethue(julia_blue); strokepath()

    finish()
    preview()
    end
    ```


## A first construction: Euclid I.1

The first proposition of the *Elements* builds an equilateral triangle on a
given segment. Draw the circle centered at each end passing through the
other. They cross at two points, and either one is the third vertex.

```@example geo
A, B = APPoint(0.0, 0.0), APPoint(6.0, 0.0)
r = distance(A, B)
crossings = intersection(APCircle2(A, r), APCircle2(B, r))
C = first(crossings)
traces = [compass_trace(A, C; angle=pi / 6), compass_trace(B, C; angle=pi / 6)]
distance(A, C) ≈ r, distance(B, C) ≈ r
```

```@raw html
<img src="../assets/img/constructions/euclid_i1.svg" alt="Two circles, the compass traces around C and the equilateral triangle" style="width:100%; max-width: 700px;">
```
!!! details "See script"
    ```julia
    using Apollonius, Luxor
    import Luxor: julia_red, julia_blue, julia_green, julia_purple
    import Apollonius: rotate, translate, distance, midpoint

    lxm = @prepare_to_picture! width=500 height=280 margin=30 begin  
        A, B = APPoint(0.0, 0.0), APPoint(6.0, 0.0)
        C = argmax(p -> p[2], intersection(APCircle2(A, 6.0), APCircle2(B, 6.0)))
        cA, cB = APCircle2(A, 6.0), APCircle2(B, 6.0)
    end
    traces = [compass_trace(A, C; angle=pi / 4), compass_trace(B, C; angle=pi / 4)]

    begin
    Drawing(lxm.width, lxm.height, :svg)
    origin(); fontsize(15)

    @layer begin
    setline(0.5); setdash(:dash); sethue("gray80")
    path([cA, cB], action=:stroke)
    end

    @layer begin
    setline(1); sethue(julia_green)
    path(traces, action=:stroke)
    end

    sethue(julia_purple)
    path(APTriangle(A, B, C), action=:stroke)

    sethue(julia_red)
    label("A", :SW, A, offset=8)
    label("B", :SE, B, offset=8)
    label("C", :N , C, offset=8)

    sethue("white")
    path([A, B], action=:fillpreserve)
    sethue(julia_blue); strokepath()
    sethue("white")
    path([C], action=:fillpreserve)
    sethue(julia_purple); strokepath()

    finish()
    preview()
    end
    ```



`traces` are the two arcs a compass would leave around `C`, ready for
`path`.

## Shown constructions

Each of these does the construction with a real compass and returns a
`NamedTuple` `(result, arcs, points)`:

* `result` is the thing you asked for: a line for the first four functions,
  a point for the transformations.
* `arcs` are the compass traces, [`APCircularArc2`](@ref)s of total angle
  `sweep` (default `π/6`), drawn like any other curve.
* `points` are the auxiliary points in the order the construction finds
  them.

| Function | Constructs | `result` | Steps drawn |
|:---------|:-----------|:---------|:------------|
| [`mediator_construction`](@ref)`(a, b)` | the perpendicular bisector of `[a, b]` | a line | 4 traces |
| [`perpendicular_construction`](@ref)`(l, p)` | the perpendicular to `l` through `p` | a line | 4 traces (6 if `p` is on `l`) |
| [`parallel_construction`](@ref)`(l, p)` | the parallel to `l` through `p`, as a rhombus | a line | 4 traces |
| [`bisector_construction`](@ref)`(vertex, p1, p2)` | the bisector of the angle | a line | 4 traces |
| [`projection_construction`](@ref)`(p, l)` | the foot of the perpendicular from `p` | a point | 4 traces |
| [`reflection_construction`](@ref)`(p, l)` | the mirror image of `p` across `l` | a point | 6 traces |
| [`symmetry_construction`](@ref)`(p, center)` | the image of `p` by point symmetry | a point | 2 traces |
| [`translation_construction`](@ref)`(p, a, b)` | the image of `p` by the translation `a → b`, as a parallelogram | a point | 2 traces |

The keywords are the radii of the compass and the size of the traces:

| Keyword | Where | Default | Meaning |
|:--------|:------|:--------|:--------|
| `radius` | bisector, mediator, perpendicular, reflection | see below | radius of the first compass opening |
| `radius2` | bisector, perpendicular, projection | `0.75 ×` the distance between the two points found first | radius of the second opening |
| `sweep` | all | `π/6` | total angle of each trace |

The default first opening is `0.75 × distance(a, b)` for the mediator,
`1.5 ×` the distance from `p` to `l` for the perpendicular, projection and
reflection, and half the shorter ray for the bisector. A radius that cannot
work, one too small for the circles to cross, raises an `ArgumentError`.

### The lines

```@example geo
a, b = APPoint(0.0, 0.0), APPoint(6.0, 2.0)
m = mediator_construction(a, b)
isapprox(m.result, perpendicular_bisector(a, b); atol=1e-9), length(m.arcs)
```

```@raw html
<img src="../assets/img/constructions/mediator.svg" alt="The perpendicular bisector of a segment with its four compass traces" style="width:100%; max-width: 700px;">
```

!!! details "See script"
    ```julia
    using Apollonius, Luxor
    import Luxor: julia_red, julia_blue, julia_green, julia_purple
    import Apollonius: rotate, translate, distance, midpoint

    lxm = @prepare_to_picture! width=500 height=280 margin=30 begin  
        a, b = APPoint(0.0, 0.0), APPoint(6.0, 2.0)
        extent = mediator_construction(a, b; sweep=pi / 4).arcs
    end

    m = mediator_construction(a, b; sweep=pi / 4)

    begin
    Drawing(lxm.width, lxm.height, :svg)
    origin(); fontsize(15)

    @layer begin
        setline(1)
        sethue(julia_green)
        path(m.arcs, action=:stroke)
    end

    sethue(julia_blue)
    path(APSegment(a, b), action=:stroke)

    sethue(julia_purple)
    path(m.result; add=(0.3, 0.3), action=:stroke)

    sethue(julia_red)
    label("A", :W, a, offset=8)
    label("B", :E, b, offset=8)

    sethue("white")
    path([a, b], action=:fillpreserve)
    sethue(julia_blue); strokepath()
    sethue("white")
    path(m.points, action=:fillpreserve)
    sethue(julia_green); strokepath()

    finish()
    preview()
    end
    ```


```@example geo
l = APLine(APPoint(0.0, 0.0), APPoint(5.0, 1.0))
q = APPoint(2.0, 4.0)
perp = perpendicular_construction(l, q)
par = parallel_construction(l, q)
is_perpendicular(perp.result, l), is_parallel(par.result, l), is_on_line(q, par.result)
```

```@raw html
<img src="../assets/img/constructions/perpendicular.svg" alt="The perpendicular to a line through a point off the line" style="width:100%; max-width: 700px;">
```

!!! details "See script"
    ```julia
    using Apollonius, Luxor
    import Luxor: julia_red, julia_blue, julia_green, julia_purple
    import Apollonius: rotate, translate, distance, midpoint

    lxm = @prepare_to_picture! width=500 height=280 margin=30 begin  
        A, B, p = APPoint(0.0, 0.0), APPoint(8.0, 1.0), APPoint(3.0, 4.0)
        extent = perpendicular_construction(APLine(A, B), p; sweep=pi / 4).arcs
    end

    l = APLine(A, B)
    m = perpendicular_construction(l, p; sweep=pi / 4)

    begin
    Drawing(lxm.width, lxm.height, :svg)
    origin(); fontsize(15)

    @layer begin
    setline(1); sethue(julia_green)
    path(m.arcs, action=:stroke)
    end

    sethue(julia_blue)
    path(l; extend=(80, 80), action=:stroke)
    sethue(julia_purple)
    path(m.result; add=(0.3, 0.3), action=:stroke)

    sethue(julia_red)
    label.(["p", "l"], [:NE, :S], [p, l.p2])

    sethue("white")
    path(p, action=:fillpreserve)
    sethue(julia_blue); strokepath()
    sethue("white")
    path(m.points, action=:fillpreserve)
    sethue(julia_green); strokepath()

    finish()
    preview()
    end
    ```


The parallel is a rhombus: `A`, `D`, `E` and the point, with the parallel through the point and `E`.

```@raw html
<img src="../assets/img/constructions/parallel.svg" alt="The parallel to a line through a point, built as a rhombus" style="width:100%; max-width: 700px;">
```


!!! details "See script"
    ```julia
    using Apollonius, Luxor
    import Luxor: julia_red, julia_blue, julia_green, julia_purple
    import Apollonius: rotate, translate, distance, midpoint

    lxm = @prepare_to_picture! width=500 height=280 margin=40 begin  
        A, B, p = APPoint(0.0, 0.0), APPoint(8.0, 1.0), APPoint(2.0, 4.0)
        extent = parallel_construction(APLine(A, B), p; sweep=pi / 4).arcs
    end

    l = APLine(A, B)
    m = parallel_construction(l, p; sweep=pi / 4)
    D, E = m.points

    begin
    Drawing(lxm.width, lxm.height, :svg)
    origin(); fontsize(15)

    @layer begin
        setline(1); sethue(julia_green)
        path(m.arcs, action=:stroke)
        setdash(:dash)
        path(APPolyline2([A, p, E, D, A]), action=:stroke)
    end

    sethue(julia_blue)
    path(l; extend=(80, 80), action=:stroke)
    sethue(julia_purple)
    path(m.result; add=(0.3, 0.3), action=:stroke)

    sethue(julia_red)
    label("A", :SW, A, offset=8)
    label("D", :SW, D, offset=8)
    label("E", :NE, E, offset=8)
    label("p", :NE, p, offset=8)

    sethue("white")
    path([A, p], action=:fillpreserve)
    sethue(julia_blue); strokepath()
    sethue("white")
    path([D, E], action=:fillpreserve)
    sethue(julia_green); strokepath()

    finish()
    preview()
    end
    ```


When `q` is already on `l`, `perpendicular_construction` marks two points on
`l` at the same distance from `q` and takes the mediator of those, so the
result is the same kind of line.

```@raw html
<img src="../assets/img/constructions/perpendicular_on_line.svg" alt="The perpendicular to a line through a point on the line" style="width:100%; max-width: 700px;">
```

!!! details "See script"
    ```julia
    using Apollonius, Luxor
    import Luxor: julia_red, julia_blue, julia_green, julia_purple
    import Apollonius: rotate, translate, distance, midpoint

    lxm = @prepare_to_picture! width=500 height=280 margin=30 begin  
        A, B, p = APPoint(0.0, 0.0), APPoint(8.0, 2.0), APPoint(4.0, 1.0)
        extent = perpendicular_construction(APLine(A, B), p; sweep=pi / 4).arcs
    end

    l = APLine(A, B)
    m = perpendicular_construction(l, p; sweep=pi / 4)

    begin
    Drawing(lxm.width, lxm.height, :svg)
    origin(); fontsize(15)

    @layer begin
    setline(1); sethue(julia_green)
    path(m.arcs, action=:stroke)
    end

    sethue(julia_blue)
    path(l; extend=(80, 80), action=:stroke)
    sethue(julia_purple)
    path(m.result; add=(0.3, 0.3), action=:stroke)
    sethue(julia_red)
    label("p", :SW, p, offset=8)

    sethue("white")
    path(p, action=:fillpreserve)
    sethue(julia_blue); strokepath()
    sethue("white")
    path(m.points, action=:fillpreserve)
    sethue(julia_green); strokepath()

    finish()
    preview()
    end
    ```


```@example geo
v, p1, p2 = APPoint(0.0, 0.0), APPoint(4.0, 0.0), APPoint(1.0, 3.0)
bis = bisector_construction(v, p1, p2)
y = bis.points[3]
angle_measure_at(v, p1, y) ≈ angle_measure_at(v, y, p2)
```

```@raw html
<img src="../assets/img/constructions/bisector.svg" alt="The bisector of an angle with its compass traces" style="width:100%; max-width: 700px;">
```

!!! details "See script"
    ```julia
    using Apollonius, Luxor
    import Luxor: julia_red, julia_blue, julia_green, julia_purple
    import Apollonius: rotate, translate, distance, midpoint

    lxm = @prepare_to_picture! width=500 height=280 margin=30 begin
        v, p1, p2 = APPoint(0.0, 0.0), APPoint(8.0, 0.0), APPoint(3.0, 6.0)
        extent = bisector_construction(v, p1, p2; sweep=pi / 4).arcs
    end

    m = bisector_construction(v, p1, p2; sweep=pi / 4)

    begin
    Drawing(lxm.width, lxm.height, :svg)
    origin(); fontsize(15)

    @layer begin
        setline(1); sethue(julia_green)
        path(m.arcs, action=:stroke)
    end

    sethue(julia_blue)
    path(APPolyline2(p1, v, p2), action=:stroke)
    sethue(julia_purple)
    path(m.result; extend=(0, 250), action=:stroke)

    sethue(julia_red)
    label("vertex", :SW, v)

    sethue("white")
    path(v, action=:fillpreserve)
    sethue(julia_blue); strokepath()
    sethue("white")
    path(m.points, action=:fillpreserve)
    sethue(julia_green); strokepath()

    finish()
    preview()
    end
    ```


### The points

For the transformations, `result` is the image point, and it agrees with the
direct functions:

```@example geo
proj = projection_construction(q, l)
refl = reflection_construction(q, l)
sym = symmetry_construction(q, APPoint(1.0, 1.0))
tra = translation_construction(q, APPoint(0.0, 0.0), APPoint(3.0, 1.0))
proj.result ≈ projection(q, l), refl.result ≈ reflection(q, l),
sym.result ≈ reflection(q, APPoint(1.0, 1.0)), tra.result ≈ q + APVector(3.0, 1.0)
```

The projection drops the foot of the perpendicular:

```@raw html
<img src="../assets/img/constructions/projection.svg" alt="The projection of a point on a line" style="width:100%; max-width: 700px;">
```

The reflection finds the mirror image with two circles through the point:

```@raw html
<img src="../assets/img/constructions/reflection.svg" alt="The reflection of a point across a line" style="width:100%; max-width: 700px;">
```

The point symmetry needs two traces:

```@raw html
<img src="../assets/img/constructions/symmetry.svg" alt="The image of a point by symmetry about a center" style="width:100%; max-width: 700px;">
```

And the translation completes a parallelogram:

```@raw html
<img src="../assets/img/constructions/translation.svg" alt="The image of a point by a translation" style="width:100%; max-width: 700px;">
```

If the point is its own image (a point on `l` for a reflection, a zero
translation) the result is the point itself and `arcs` is empty.

## Drawing the steps

The traces are ordinary arcs and the result is an ordinary line or point,
so a figure that shows its work is a few `path` calls. Draw the traces
thin and in a different color from the result, so a reader can tell the
construction from the outcome. This example needs Luxor:

```julia
using Apollonius, Luxor

m = mediator_construction(a, b; sweep=pi / 5)

@svg begin
    sethue(julia_green); setline(0.5)
    path(m.arcs; action=:stroke)                    # the compass traces
    sethue(julia_purple); setline(1)
    path(m.result; add=(0.2, 0.2), action=:stroke)  # the bisector, a bit past both crossings
    sethue(julia_blue)
    path([a, b, m.points...]; action=:fill)         # the points involved
end 400 300
```

Sizes here follow the rule in [Conventions & FAQ](@ref): `radius` is in the
units of the points you pass, so build the construction from points that
are already in canvas coordinates.
