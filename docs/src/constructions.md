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
| Center, a point, and the angle to sweep from the point | [`arc_with_angle`](@ref) | an arc starting at the point |
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

Three of the other builders side by side: `arc_with_angle` starts at the point and sweeps from it, `semicircle` is a half turn, and `extend_arc` lengthens an arc (the blue part is the original).

```@raw html
<img src="../assets/img/constructions/arc_builders.svg" alt="Three compass arcs: arc_with_angle, semicircle and extend_arc" style="width:100%; max-width: 700px;">
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

```@example geo
l = APLine(APPoint(0.0, 0.0), APPoint(5.0, 1.0))
q = APPoint(2.0, 4.0)
perp = perpendicular_construction(l, q)
par = parallel_construction(l, q)
is_perpendicular(perp.result, l), is_parallel(par.result, l), on_line(q, par.result)
```

```@raw html
<img src="../assets/img/constructions/perpendicular.svg" alt="The perpendicular to a line through a point off the line" style="width:100%; max-width: 700px;">
```

The parallel is a rhombus: `A`, `D`, `E` and the point, with the parallel through the point and `E`.

```@raw html
<img src="../assets/img/constructions/parallel.svg" alt="The parallel to a line through a point, built as a rhombus" style="width:100%; max-width: 700px;">
```

When `q` is already on `l`, `perpendicular_construction` marks two points on
`l` at the same distance from `q` and takes the mediator of those, so the
result is the same kind of line.

```@raw html
<img src="../assets/img/constructions/perpendicular_on_line.svg" alt="The perpendicular to a line through a point on the line" style="width:100%; max-width: 700px;">
```

```@example geo
v, p1, p2 = APPoint(0.0, 0.0), APPoint(4.0, 0.0), APPoint(1.0, 3.0)
bis = bisector_construction(v, p1, p2)
y = bis.points[3]
angle_at(v, p1, y) ≈ angle_at(v, y, p2)
```

```@raw html
<img src="../assets/img/constructions/bisector.svg" alt="The bisector of an angle with its compass traces" style="width:100%; max-width: 700px;">
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

## Watching a construction step by step

The blocks in this section are run when the documentation is built, and each
figure comes from the code above it. Only the geometry is shown: the lines that
draw are hidden. The figures use one color code: blue for the given objects,
gray for the circles of the construction, green for the points found along the
way, purple for the result.

Each construction is done by hand, with the same steps the shown constructions
above use. The first block of each one builds everything inside
[`@to_luxor_picture`](@ref), which fits it to the canvas and returns the fitted
objects in `lxo`, under the names they were given, so every step is drawn in
the same frame. The line `(; a, b, ...) = lxo` brings them into scope. A plain
number such as a radius is not scaled, so the checks compare distances between
the fitted objects.

### The perpendicular bisector

The perpendicular bisector of `[a, b]`, built by hand instead of with
[`mediator_construction`](@ref).

```@example geo
using Luxor: sethue, setline, setdash, fontsize, label, julia_blue, julia_green, julia_red, julia_purple # hide
import Luxor # hide
fig_given(x) = (sethue(julia_blue); path(x; action=:stroke)) # hide
fig_faint(x) = (Luxor.gsave(); setline(1); setdash("dash"); sethue("gray80"); path(x; action=:stroke); Luxor.grestore()) # hide
fig_aid(x) = (Luxor.gsave(); setline(1); setdash("dash"); sethue(julia_green); path(x; action=:stroke); Luxor.grestore()) # hide
fig_result(x) = (sethue(julia_purple); path(x; action=:stroke)) # hide
fig_fill(x; a=0.25) = (sethue(julia_purple); Luxor.setopacity(a); path(x; action=:fill); Luxor.setopacity(1.0)) # hide
fig_dots(pts, c) = (path(pts); sethue("white"); Luxor.fillpreserve(); sethue(c); Luxor.strokepath()) # hide
fig_tags(ts...) = (sethue(julia_red); for (t, al, p) in ts; label(t, al, p); end) # hide
fig_vtags(t) = (sethue(julia_red); g = centroid(t); for (n, v) in zip(("A", "B", "C"), vertices(t)); label(n, label_anchor(v, g)...); end) # hide
function fig_draw(f, w, h) # hide
    Luxor.@drawsvg begin # hide
        Luxor.origin(); fontsize(15); f() # hide
    end w h # hide
end # hide
lxm, lxo = @to_luxor_picture width=500 margin=30 begin
    a = APPoint(0.0, 0.0)
    b = APPoint(6.0, 2.0)
    c1 = APCircle2(a, 0.75 * distance(a, b))     # any radius above half of distance(a, b) works
    c2 = APCircle2(b, 0.75 * distance(a, b))
    p, q = intersection(c1, c2)                  # the two crossings of the circles
end
(; a, b, c1, c2, p, q) = lxo
figH = ceil(Int, lxm.height) # hide
nothing # hide
```

**Step 1.** The given segment.

```@example geo
segment = APSegment(a, b)
fig_draw(500, figH) do # hide
    fig_given(segment) # hide
    fig_dots([a, b], julia_blue) # hide
    fig_tags(("A", :W, a), ("B", :E, b)) # hide
end # hide
```

**Step 2.** A circle around each end, with the same radius.

```@example geo
c1.r == c2.r
```

```@example geo
fig_draw(500, figH) do # hide
    fig_faint([c1, c2]) # hide
    fig_given(segment) # hide
    fig_dots([a, b], julia_blue) # hide
    fig_tags(("A", :W, a), ("B", :E, b)) # hide
end # hide
```

**Step 3.** The circles cross at two points, and each one is at the same distance from `a` and from `b`.

```@example geo
(distance(p, a) ≈ distance(p, b), distance(q, a) ≈ distance(q, b))
```

```@example geo
fig_draw(500, figH) do # hide
    fig_faint([c1, c2]) # hide
    fig_given(segment) # hide
    fig_dots([a, b], julia_blue) # hide
    fig_dots([p, q], julia_green) # hide
    fig_tags(("A", :W, a), ("B", :E, b), ("P", :N, p), ("Q", :S, q)) # hide
end # hide
```

**Step 4.** The line through the two crossings is the result.

```@example geo
bisector = APLine(p, q)
(is_perpendicular(bisector, APLine(a, b)), on_line(midpoint(a, b), bisector))
```

```@example geo
fig_draw(500, figH) do # hide
    fig_faint([c1, c2]) # hide
    fig_given(segment) # hide
    fig_result(bisector) # hide
    fig_dots([a, b], julia_blue) # hide
    fig_dots([p, q], julia_green) # hide
    fig_tags(("A", :W, a), ("B", :E, b), ("P", :N, p), ("Q", :S, q)) # hide
end # hide
```

### The perpendicular from a point

The perpendicular to a line `l` through a point `p` off the line, as in
[`perpendicular_construction`](@ref). A circle around `p` cuts `l` at two
points; two equal circles around those cross on the other side of `l`. The
line is infinite, so it is marked `@unbounded`: it is fitted like the rest but
does not set the size of the canvas.

```@example geo
lxm, lxo = @to_luxor_picture width=500 margin=30 begin
    A = APPoint(0.0, 0.0)
    B = APPoint(8.0, 1.0)
    @unbounded l = APLine(A, B)
    p = APPoint(3.0, 4.0)
    cp = APCircle2(p, 1.5 * distance(p, l))        # a circle around p that reaches l
    x1, x2 = intersection(l, cp)                   # where it cuts l
    cx1 = APCircle2(x1, 0.75 * distance(x1, x2))
    cx2 = APCircle2(x2, 0.75 * distance(x1, x2))
    ys = intersection(cx1, cx2)
    y = side_of_line(ys[1], l) != side_of_line(p, l) ? ys[1] : ys[2]   # the crossing on the far side of l
end
(; A, B, l, p, cp, x1, x2, cx1, cx2, ys, y) = lxo
figH = ceil(Int, lxm.height) # hide
nothing # hide
```

**Step 1.** The line and the point.

```@example geo
!on_line(p, l)
```

```@example geo
fig_draw(500, figH) do # hide
    fig_given(l) # hide
    fig_dots([p], julia_blue) # hide
    fig_tags(("p", :NE, p)) # hide
end # hide
```

**Step 2.** A circle around `p` that cuts the line at `x1` and `x2`.

```@example geo
distance(x1, p) ≈ distance(x2, p) ≈ cp.r
```

```@example geo
fig_draw(500, figH) do # hide
    fig_faint(cp) # hide
    fig_given(l) # hide
    fig_dots([p], julia_blue) # hide
    fig_dots([x1, x2], julia_green) # hide
    fig_tags(("p", :NE, p), ("x1", :SW, x1), ("x2", :SE, x2)) # hide
end # hide
```

**Step 3.** Two equal circles around `x1` and `x2` cross at `y`, on the other side of the line.

```@example geo
side_of_line(y, l) != side_of_line(p, l)
```

```@example geo
fig_draw(500, figH) do # hide
    fig_faint([cx1, cx2]) # hide
    fig_given(l) # hide
    fig_dots([p], julia_blue) # hide
    fig_dots([x1, x2, y], julia_green) # hide
    fig_tags(("p", :NE, p), ("x1", :SW, x1), ("x2", :SE, x2), ("y", :E, y)) # hide
end # hide
```

**Step 4.** The line through `p` and `y` is perpendicular to `l`.

```@example geo
perp = APLine(p, y)
is_perpendicular(perp, l)
```

```@example geo
fig_draw(500, figH) do # hide
    fig_faint([cx1, cx2]) # hide
    fig_given(l) # hide
    fig_result(perp) # hide
    fig_dots([p], julia_blue) # hide
    fig_dots([x1, x2, y], julia_green) # hide
    fig_tags(("p", :NE, p), ("x1", :SW, x1), ("x2", :SE, x2), ("y", :E, y)) # hide
end # hide
```

### The parallel

The parallel to `l` through `p`, as a rhombus, as in
[`parallel_construction`](@ref). A circle around a point `A` of `l` through `p`
gives `D` on `l`; two circles of the same radius around `D` and `p` meet at `E`.

```@example geo
lxm, lxo = @to_luxor_picture width=500 margin=30 begin
    A = APPoint(0.0, 0.0)
    B = APPoint(8.0, 1.0)
    @unbounded l = APLine(A, B)
    p = APPoint(2.0, 4.0)
    cA = APCircle2(A, distance(A, p))              # the circle around A through p
    D = A + distance(A, p) * normalize(direction(l))    # ... cuts l at D
    cD = APCircle2(D, distance(A, p))
    cP = APCircle2(p, distance(A, p))
    es = intersection(cD, cP)
    E = distance(es[1], A) > distance(es[2], A) ? es[1] : es[2]
end
(; A, B, l, p, cA, D, cD, cP, es, E) = lxo
figH = ceil(Int, lxm.height) # hide
nothing # hide
```

**Step 1.** The line, the point `A` on it, and `p`.

```@example geo
distance(A, p) ≈ cA.r
```

```@example geo
fig_draw(500, figH) do # hide
    fig_given(l) # hide
    fig_dots([A, p], julia_blue) # hide
    fig_tags(("A", :SW, A), ("p", :NW, p)) # hide
end # hide
```

**Step 2.** The circle around `A` through `p` cuts `l` at `D`.

```@example geo
(on_line(D, l), distance(A, D) ≈ cA.r)
```

```@example geo
fig_draw(500, figH) do # hide
    fig_faint(cA) # hide
    fig_given(l) # hide
    fig_dots([A, p], julia_blue) # hide
    fig_dots([D], julia_green) # hide
    fig_tags(("A", :SW, A), ("p", :NW, p), ("D", :S, D)) # hide
end # hide
```

**Step 3.** Two circles of the same radius, around `D` and around `p`, meet at `E`.

```@example geo
(distance(E, D) ≈ cD.r, distance(E, p) ≈ cP.r)
```

```@example geo
fig_draw(500, figH) do # hide
    fig_faint([cA, cD, cP]) # hide
    fig_given(l) # hide
    fig_dots([A, p], julia_blue) # hide
    fig_dots([D, E], julia_green) # hide
    fig_tags(("A", :SW, A), ("p", :NW, p), ("D", :S, D), ("E", :NE, E)) # hide
end # hide
```

**Step 4.** `A`, `D`, `E` and `p` are the corners of a rhombus, so the line through `p` and `E` is parallel to `l`.

```@example geo
par = APLine(p, E)
is_parallel(par, l)
```

```@example geo
fig_draw(500, figH) do # hide
    fig_faint([cA, cD, cP]) # hide
    fig_aid(APPolyline2([A, p, E, D, A])) # hide
    fig_given(l) # hide
    fig_result(par) # hide
    fig_dots([A, p], julia_blue) # hide
    fig_dots([D, E], julia_green) # hide
    fig_tags(("A", :SW, A), ("p", :NW, p), ("D", :S, D), ("E", :NE, E)) # hide
end # hide
```

### The angle bisector

The bisector of the angle at `v` between `p1` and `p2`, as in
[`bisector_construction`](@ref). A circle around `v` cuts the two rays; two
equal circles around those points cross inside the angle.

```@example geo
lxm, lxo = @to_luxor_picture width=500 margin=30 begin
    v = APPoint(0.0, 0.0)
    s1 = APSegment(v, APPoint(4.0, 0.0))
    s2 = APSegment(v, APPoint(1.0, 3.0))
    cv = APCircle2(v, 1.5)                           # a circle around v
    x1 = only(intersection(cv, s1))                  # where it cuts the two rays
    x2 = only(intersection(cv, s2))
    cx1 = APCircle2(x1, 0.75 * distance(x1, x2))
    cx2 = APCircle2(x2, 0.75 * distance(x1, x2))
    y = argmax(q -> distance(q, v), intersection(cx1, cx2))   # the crossing inside the angle
end
(; v, s1, s2, cv, x1, x2, cx1, cx2, y) = lxo
figH = ceil(Int, lxm.height) # hide
nothing # hide
```

**Step 1.** The two rays.

```@example geo
angle_at(v, s1.p2, s2.p2)
```

```@example geo
fig_draw(500, figH) do # hide
    fig_given([s1, s2]) # hide
    fig_dots([v], julia_blue) # hide
    fig_tags(("v", :SW, v)) # hide
end # hide
```

**Step 2.** A circle around `v` cuts the rays at `x1` and `x2`, at the same distance from `v`.

```@example geo
distance(v, x1) ≈ distance(v, x2) ≈ cv.r
```

```@example geo
fig_draw(500, figH) do # hide
    fig_faint(cv) # hide
    fig_given([s1, s2]) # hide
    fig_dots([v], julia_blue) # hide
    fig_dots([x1, x2], julia_green) # hide
    fig_tags(("v", :SW, v), ("x1", :S, x1), ("x2", :NW, x2)) # hide
end # hide
```

**Step 3.** Two equal circles around `x1` and `x2` cross at `y`, inside the angle.

```@example geo
distance(y, x1) ≈ distance(y, x2)
```

```@example geo
fig_draw(500, figH) do # hide
    fig_faint([cx1, cx2]) # hide
    fig_given([s1, s2]) # hide
    fig_dots([v], julia_blue) # hide
    fig_dots([x1, x2, y], julia_green) # hide
    fig_tags(("v", :SW, v), ("x1", :S, x1), ("x2", :NW, x2), ("y", :NE, y)) # hide
end # hide
```

**Step 4.** The ray from `v` through `y` is the bisector: both angles it makes are equal.

```@example geo
angle_at(v, s1.p2, y) ≈ angle_at(v, y, s2.p2)
```

```@example geo
fig_draw(500, figH) do # hide
    fig_faint([cx1, cx2]) # hide
    fig_given([s1, s2]) # hide
    fig_result(APRay(v, y)) # hide
    fig_dots([v], julia_blue) # hide
    fig_dots([x1, x2, y], julia_green) # hide
    fig_tags(("v", :SW, v), ("x1", :S, x1), ("x2", :NW, x2), ("y", :NE, y)) # hide
end # hide
```

These are the same lines that `mediator_construction`, `perpendicular_construction`, `parallel_construction` and `bisector_construction` return as `result`, with the compass traces they also return.

## Drawing the steps

The traces are ordinary arcs and the result is an ordinary line or point,
so a figure that shows its work is a few `path` calls. Draw the traces
thin and in a different color from the result, so a reader can tell the
construction from the outcome. This example needs Luxor:

```julia
using Apollonius, Luxor

m = mediator_construction(a, b; sweep=pi / 5)

@svg begin
    sethue("orange"); setline(0.5)
    path(m.arcs; action=:stroke)                    # the compass traces
    sethue("black"); setline(1)
    path(m.result; add=(0.2, 0.2), action=:stroke)  # the bisector, a bit past both crossings
    path([a, b, m.points...]; action=:fill)         # the points involved
end 400 300
```

Sizes here follow the rule in [Conventions & FAQ](@ref): `radius` is in the
units of the points you pass, so build the construction from points that
are already in canvas coordinates.
