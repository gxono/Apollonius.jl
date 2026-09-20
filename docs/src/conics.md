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

```@raw html
<img src="../assets/img/conics/ellipse_foci.svg" alt="An ellipse with its foci, vertices and director circle, and a point whose distances to the foci add up to 2a" style="width:100%; max-width: 700px;">
```

## Parabola

```@example geo
focus = APPoint(0.0, 1.0)
directrix = APLine(APPoint(-5.0, -1.0), APPoint(5.0, -1.0))
par = APParabola2(focus, directrix)
```

```@example geo
vertex(par)            # midpoint of focus and its foot on the directrix
vertices(par)          # (vertex(par),): a 1-tuple, so vertices() works uniformly across every conic
focal_parameter(par)   # distance(focus, directrix), often called p
```

`APParabola2(vertex, focus)` is the point-based alternative, the same
idea as [`APCircle2`](@ref)`(center, through)` or the bifocal
`APEllipse2`/`APHyperbola2` constructors: vertex and focus alone pin down
the axis, the focal parameter, and so the directrix too.

```@example geo
APParabola2(vertex(par), focus) ≈ par
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

```@raw html
<img src="../assets/img/conics/parabola.svg" alt="A parabola with its focus, directrix and vertex, and a point equally far from the focus and the directrix" style="width:100%; max-width: 700px;">
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

```@raw html
<img src="../assets/img/conics/hyperbola.svg" alt="A hyperbola with its two branches, asymptotes, foci and vertices" style="width:100%; max-width: 700px;">
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

## Conic constructions step by step

The blocks in this section are run when the documentation is built, and each
figure comes from the code above it; only the geometry is shown. The figures
use one color code: blue for the given objects, green for the construction
aids, purple for what is found. In each part, the first block builds the
objects inside [`@to_luxor_picture`](@ref), which fits them to the canvas and
returns the fitted objects in `lxo`, under the names they were given. The
answer is built there too, so that the canvas has room for every step, and each
step then rebuilds its part of it from the given objects. A curve that goes on
forever is marked `@unbounded`, and an arc of it is drawn in its place.

### An ellipse from the sum of distances

An ellipse is the set of points whose distances to the two foci add up to a
constant, `2a`. To find such a point, pick a radius `r`, and draw the circle of
radius `r` around one focus and the circle of radius `2a - r` around the other.
They cross at points of the ellipse.

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
    ef1 = APPoint(-3.0, 0.0)
    ef2 = APPoint(3.0, 0.0)
    eell = APEllipse2(ef1, ef2, 5.0)
end
(; ef1, ef2, eell) = lxo
figH = ceil(Int, lxm.height) # hide
nothing # hide
```

**Step 1.** The two foci, and the sum of distances `2a`.

```@example geo
ea = eell.a
distance(ef1, ef2) < 2ea
```

```@example geo
fig_draw(500, figH) do # hide
    fig_dots([ef1, ef2], julia_blue) # hide
    fig_tags(("F1", :S, ef1), ("F2", :S, ef2)) # hide
end # hide
```

**Step 2.** A radius `r` between `a - c` and `a + c`, and the two circles of radius `r` and `2a - r`.

```@example geo
er = 0.6 * ea
ek1, ek2 = APCircle2(ef1, er), APCircle2(ef2, 2ea - er)
ep = intersection(ek1, ek2)
all(p -> distance(p, ef1) + distance(p, ef2) ≈ 2ea, ep)
```

```@example geo
fig_draw(500, figH) do # hide
    fig_faint([ek1, ek2]) # hide
    fig_dots([ef1, ef2], julia_blue) # hide
    fig_dots(ep, julia_purple) # hide
    fig_tags(("F1", :S, ef1), ("F2", :S, ef2)) # hide
end # hide
```

**Step 3.** The same with other radii. Each pair of circles gives two more points.

```@example geo
epall = reduce(vcat, [intersection(APCircle2(ef1, s * ea), APCircle2(ef2, (2 - s) * ea)) for s in (0.45, 0.6, 0.8, 1.0, 1.2, 1.4, 1.55)])
length(epall)
```

```@example geo
fig_draw(500, figH) do # hide
    fig_dots([ef1, ef2], julia_blue) # hide
    fig_dots(epall, julia_purple) # hide
    fig_tags(("F1", :S, ef1), ("F2", :S, ef2)) # hide
end # hide
```

**Step 4.** The ellipse passes through all of them.

```@example geo
all(p -> is_on_ellipse(p, eell), epall)
```

```@example geo
fig_draw(500, figH) do # hide
    fig_result(eell) # hide
    fig_dots([ef1, ef2], julia_blue) # hide
    fig_dots(epall, julia_purple) # hide
    fig_tags(("F1", :S, ef1), ("F2", :S, ef2)) # hide
end # hide
```

### A parabola from a focus and a directrix

A parabola is the set of points as far from the focus as from the directrix.
Take a point `D` on the directrix. A point `P` of the parabola that is as far
from the focus as from `D` is on the perpendicular bisector of `[F, D]`, and
its distance to the directrix is measured along the perpendicular at `D`. So it
is where the two lines meet.

```@example geo
lxm, lxo = @to_luxor_picture width=500 margin=30 begin
    pf = APPoint(0.0, 1.0)
    pd = APSegment(APPoint(-6.0, -1.0), APPoint(6.0, -1.0))
    @unbounded ppar = APParabola2(pf, APLine(pd.p1, pd.p2))
    parc = APParabolicArc2(ppar, point_on_parabola(ppar, -5.0), point_on_parabola(ppar, 5.0))
end
(; pf, pd, ppar, parc) = lxo
figH = ceil(Int, lxm.height) # hide
nothing # hide
```

**Step 1.** The focus, and the directrix as a line.

```@example geo
pl = APLine(pd.p1, pd.p2)
!on_line(pf, pl)
```

```@example geo
fig_draw(500, figH) do # hide
    fig_given(pd) # hide
    fig_dots([pf], julia_blue) # hide
    fig_tags(("F", :N, pf)) # hide
end # hide
```

**Step 2.** A point `D` of the directrix, and the perpendicular bisector of `[F, D]`.

```@example geo
pdp = point_on_line(pl, 0.7)
pm = perpendicular_bisector(pf, pdp)
distance(pf, pm) ≈ distance(pdp, pm)
```

```@example geo
fig_draw(500, figH) do # hide
    fig_given(pd) # hide
    fig_aid([pm, APSegment(pf, pdp)]) # hide
    fig_dots([pf], julia_blue) # hide
    fig_dots([pdp], julia_green) # hide
    fig_tags(("F", :N, pf), ("D", :S, pdp)) # hide
end # hide
```

**Step 3.** The perpendicular to the directrix at `D` meets it at a point of the parabola.

```@example geo
pn = perpendicular_through(pl, pdp)
pp = only(intersection(pm, pn))
distance(pp, pf) ≈ distance(pp, pl)
```

```@example geo
fig_draw(500, figH) do # hide
    fig_given(pd) # hide
    fig_aid([pm, pn, APSegment(pf, pdp)]) # hide
    fig_dots([pf], julia_blue) # hide
    fig_dots([pdp], julia_green) # hide
    fig_dots([pp], julia_purple) # hide
    fig_tags(("F", :N, pf), ("D", :S, pdp), ("P", :E, pp)) # hide
end # hide
```

**Step 4.** The same for other points of the directrix, and the parabola through all of them.

```@example geo
pps = [only(intersection(perpendicular_bisector(pf, d), perpendicular_through(pl, d))) for d in [point_on_line(pl, t) for t in (0.05, 0.2, 0.35, 0.5, 0.65, 0.8, 0.95)]]
all(p -> is_on_parabola(p, ppar), pps)
```

```@example geo
fig_draw(500, figH) do # hide
    fig_given(pd) # hide
    fig_result(parc) # hide
    fig_dots([pf], julia_blue) # hide
    fig_dots(pps, julia_purple) # hide
    fig_tags(("F", :N, pf)) # hide
end # hide
```

### The tangent to an ellipse at a point

Light from one focus reflects off the ellipse towards the other, so the tangent
at `P` makes equal angles with the two focal radii. Reflecting `F1` in the
tangent puts it on the line `F2P`, at distance `|PF1|` from `P`. That point `Q` is
then at distance `|PF1| + |PF2| = 2a` from `F2`, and the tangent is the
perpendicular bisector of `[F1, Q]`.

```@example geo
lxm, lxo = @to_luxor_picture width=500 margin=30 begin
    tf1 = APPoint(-3.0, 0.0)
    tf2 = APPoint(3.0, 0.0)
    tell = APEllipse2(tf1, tf2, 5.0)
    tp = point_on_ellipse(tell, 1.0)
    tq = only(intersection(APRay(tf2, tp), APCircle2(tf2, 2 * tell.a)))
    @unbounded ttan = polar_line(tell, tp)
end
(; tf1, tf2, tell, tp, tq, ttan) = lxo
figH = ceil(Int, lxm.height) # hide
nothing # hide
```

**Step 1.** The ellipse with its foci, and a point `P` on it.

```@example geo
is_on_ellipse(tp, tell)
```

```@example geo
fig_draw(500, figH) do # hide
    fig_given(tell) # hide
    fig_dots([tf1, tf2, tp], julia_blue) # hide
    fig_tags(("F1", :S, tf1), ("F2", :S, tf2), ("P", :N, tp)) # hide
end # hide
```

**Step 2.** The two focal radii. Their lengths add up to `2a`.

```@example geo
tr1, tr2 = APSegment(tp, tf1), APSegment(tp, tf2)
distance(tp, tf1) + distance(tp, tf2) ≈ 2tell.a
```

```@example geo
fig_draw(500, figH) do # hide
    fig_given(tell) # hide
    fig_aid([tr1, tr2]) # hide
    fig_dots([tf1, tf2, tp], julia_blue) # hide
    fig_tags(("F1", :S, tf1), ("F2", :S, tf2), ("P", :N, tp)) # hide
end # hide
```

**Step 3.** The circle of radius `2a` around `F2` cuts the line `F2P` beyond `P` at `Q`, and `|PQ| = |PF1|`.

```@example geo
tq = only(intersection(APRay(tf2, tp), APCircle2(tf2, 2tell.a)))
distance(tp, tq) ≈ distance(tp, tf1)
```

```@example geo
fig_draw(500, figH) do # hide
    fig_given(tell) # hide
    fig_aid([APSegment(tf2, tq), tr1]) # hide
    fig_dots([tf1, tf2, tp], julia_blue) # hide
    fig_dots([tq], julia_green) # hide
    fig_tags(("F1", :S, tf1), ("F2", :S, tf2), ("P", :N, tp), ("Q", :N, tq)) # hide
end # hide
```

**Step 4.** The tangent is the perpendicular bisector of `[F1, Q]`.

```@example geo
ttl = perpendicular_bisector(tf1, tq)
(on_line(tp, ttl), ttl ≈ polar_line(tell, tp))
```

```@example geo
fig_draw(500, figH) do # hide
    fig_given(tell) # hide
    fig_aid([APSegment(tf1, tq)]) # hide
    fig_result(ttl) # hide
    fig_dots([tf1, tf2, tp], julia_blue) # hide
    fig_dots([tq], julia_green) # hide
    fig_tags(("F1", :S, tf1), ("F2", :S, tf2), ("P", :N, tp), ("Q", :N, tq)) # hide
end # hide
```

### A hyperbola from the difference of distances

A hyperbola is the set of points whose distances to the two foci differ by a
constant, `2a`. To find such a point, pick a distance `d` from one focus, and
draw the circle of radius `d` around it and the circle of radius `d + 2a` around
the other. They cross at points of the branch that is nearer the first focus.
Swapping the two circles gives the other branch.

```@example geo
lxm, lxo = @to_luxor_picture width=500 margin=30 begin
    hf1 = APPoint(-3.0, 0.0)
    hf2 = APPoint(3.0, 0.0)
    @unbounded hyp = APHyperbola2(hf1, hf2, 1.5)
    harc1 = APHyperbolicArc2(hyp, point_on_hyperbola(hyp, -1.3), point_on_hyperbola(hyp, 1.3))
    harc2 = APHyperbolicArc2(hyp, point_on_hyperbola(hyp, -1.3; branch=-1), point_on_hyperbola(hyp, 1.3; branch=-1))
end
(; hf1, hf2, hyp, harc1, harc2) = lxo
figH = ceil(Int, lxm.height) # hide
nothing # hide
```

**Step 1.** The two foci, and the difference of distances `2a`. It has to be smaller than the distance between the foci.

```@example geo
ha = hyp.a
2ha < distance(hf1, hf2)
```

```@example geo
fig_draw(500, figH) do # hide
    fig_dots([hf1, hf2], julia_blue) # hide
    fig_tags(("F1", :S, hf1), ("F2", :S, hf2)) # hide
end # hide
```

**Step 2.** A distance `d` from `F2`, and the circles of radius `d` around `F2` and `d + 2a` around `F1`.

```@example geo
hd = 1.4 * ha
hk1, hk2 = APCircle2(hf1, hd + 2ha), APCircle2(hf2, hd)
hp = intersection(hk1, hk2)
all(p -> distance(p, hf1) - distance(p, hf2) ≈ 2ha, hp)
```

```@example geo
fig_draw(500, figH) do # hide
    fig_faint([hk1, hk2]) # hide
    fig_dots([hf1, hf2], julia_blue) # hide
    fig_dots(hp, julia_purple) # hide
    fig_tags(("F1", :S, hf1), ("F2", :S, hf2)) # hide
end # hide
```

**Step 3.** The same for other distances, and with the circles swapped for the other branch.

```@example geo
hpts = reduce(vcat, [intersection(APCircle2(hf1, (s + 2) * ha), APCircle2(hf2, s * ha)) for s in (1.05, 1.4, 1.8, 2.4)])
hpts = [hpts; reduce(vcat, [intersection(APCircle2(hf1, s * ha), APCircle2(hf2, (s + 2) * ha)) for s in (1.05, 1.4, 1.8, 2.4)])]
length(hpts)
```

```@example geo
fig_draw(500, figH) do # hide
    fig_dots([hf1, hf2], julia_blue) # hide
    fig_dots(hpts, julia_purple) # hide
    fig_tags(("F1", :S, hf1), ("F2", :S, hf2)) # hide
end # hide
```

**Step 4.** The two branches pass through all of them.

```@example geo
all(p -> is_on_hyperbola(p, hyp), hpts)
```

```@example geo
fig_draw(500, figH) do # hide
    fig_result([harc1, harc2]) # hide
    fig_dots([hf1, hf2], julia_blue) # hide
    fig_dots(hpts, julia_purple) # hide
    fig_tags(("F1", :S, hf1), ("F2", :S, hf2)) # hide
end # hide
```

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

Each also builds directly from the underlying conic's own raw parameters,
without an `APEllipse2`/`APHyperbola2`/`APParabola2` in hand first (the
same idea as [`APCircularArc2`](@ref)`(center, r, p1, p2)` in
[Circles](@ref)):

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

```@raw html
<img src="../assets/img/conics/random_points.svg" alt="Random points on an ellipse, denser near the flatter parts" style="width:100%; max-width: 700px;">
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

```@raw html
<img src="../assets/img/conics/transform.svg" alt="An ellipse, its rotation and its homothety of ratio -0.5" style="width:100%; max-width: 700px;">
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

```@raw html
<img src="../assets/img/conics/fit.svg" alt="Five points and the ellipse through them" style="width:100%; max-width: 700px;">
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
