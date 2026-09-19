```@meta
CurrentModule = Apollonius
```

# Tangency & Apollonius Problems

The classical **problem of Apollonius** asks: given three objects, each
either a point, a line or a circle, find the circle(s) tangent to all
three (a point counts as a "circle" of radius zero to be tangent to, i.e.
passing through it). There are ten combinations up to symmetry (PPP, LPP,
LLP, CPP, CLP, CCP, LLL, CLL, CCL, CCC); this package covers the ones that
involve at least one circle or line (PPP is just
[`circumcircle`](@ref) of an `APTriangle`, and LLL is
[`incenter`](@ref)/[`excenters`](@ref)).

The functions are named by what role the *points* among the three objects
play:

* [`tangent_circles_through_points`](@ref): two of the three objects are
  points the circle must pass *through*; the third is a line or a circle
  it must be tangent to.
* [`tangent_circles_through_point`](@ref): one point to pass through, and
  two lines/circles to be tangent to.
* [`tangent_circles`](@ref), no points at all: two or three lines/circles,
  all to be tangent to.

Every one of these can return **multiple** solutions (up to 8, for three
circles), so they all return a `Vector{APCircle2}`, never a single `APCircle2`.
The given circles themselves are always excluded from the result, even
when the configuration is symmetric enough that one of them would
otherwise satisfy the tangency equations too (a circle is degenerately
"tangent" to itself in that sense).

## Through two points, tangent to a line

In general there are up to two such circles, but whenever `a` and `b` are
placed symmetrically about the perpendicular from their midpoint to `l`
(as here), one of the two degenerates to infinite radius (a straight line),
leaving exactly one genuine circle:

```@example geo
using Apollonius

a, b = APPoint(-3.0, 0.0), APPoint(3.0, 0.0)
l = APLine(APPoint(-5.0, -4.0), APPoint(5.0, -4.0))

sols = tangent_circles_through_points(a, b, l)
length(sols)   # exactly 1, in this symmetric case
```

```@raw html
<img src="../assets/img/tangency/ppl.svg" alt="" style="width:100%;">
```

The circle's center lies on the perpendicular bisector of `[a,b]` and it
touches the line from above. A less symmetric choice of `a`, `b` and `l`
generally gives two such circles, often of very different sizes, since
one tends to hug the line closely while the other bulges around to reach
it from the far side.

The same function also takes a circle instead of a line as the third,
tangent-to object:

```@example geo
a2, b2 = APPoint(-2.0, 1.0), APPoint(2.0, 1.0)
given_c = APCircle2(APPoint(0.0, -3.0), 2.0)

sols_c = tangent_circles_through_points(a2, b2, given_c)
length(sols_c)   # 2 here: one tangent externally, one internally
```

```@raw html
<img src="../assets/img/tangency/ppc.svg" alt="" style="width:100%;">
```

## Tangent to two or three circles/lines

`tangent_circles` covers every "no points, ≥2 circles/lines" combination:
two lines and a circle (`CLL`), two circles and a line (`CCL`), or three
circles (`CCC`, Apollonius' original problem, below):

```@example geo
l1 = APLine(APPoint(0.0, 0.0), APPoint(0.0, 1.0))   # the y-axis
l2 = APLine(APPoint(0.0, 0.0), APPoint(1.0, 0.0))   # the x-axis
c_cll = APCircle2(APPoint(6.0, 6.0), 2.0)

sols_cll = tangent_circles(l1, l2, c_cll)
length(sols_cll)   # 4
```

```@raw html
<img src="../assets/img/tangency/llc.svg" alt="" style="width:100%;">
```


```@example geo
c1_ccl = APCircle2(APPoint(0.0, 0.0), 2.0)
c2_ccl = APCircle2(APPoint(6.0, 0.0), 2.0)
l_ccl = APLine(APPoint(0.0, -3.0), APPoint(1.0, -3.0))

sols_ccl = tangent_circles(c1_ccl, c2_ccl, l_ccl)
length(sols_ccl)   # 6
```

```@raw html
<img src="../assets/img/tangency/ccl.svg" alt="" style="width:100%;">
```

## Tangent to three circles

With three circles and no points at all, this is Apollonius' original
problem: up to 8 solutions, since each of the three tangencies can
independently be internal or external.

```@example geo
R = 3.0
centers = [APPoint(R * cos(pi / 2 + 2pi * k / 3), R * sin(pi / 2 + 2pi * k / 3)) for k in 0:2]
given = [APCircle2(centers[k+1], 1.0) for k in 0:2]

sols3 = tangent_circles(given[1], given[2], given[3])
length(sols3)   # 8 solutions
```

```@raw html
<img src="../assets/img/tangency/ccc.svg" alt="" style="width:100%;">
```

Two of those eight happen to be concentric with the given configuration by
symmetry here: a small one nested between the three circles, and a large
one enclosing all of them:

```@example geo
small = sols3[argmin(s.r for s in sols3)]
big = sols3[argmax(s.r for s in sols3)]
```

```@raw html
<img src="../assets/img/tangency/ccc_bs.svg" alt="" style="width:100%;">
```

## Interstices: the gap between three tangent circles

Three *mutually* tangent circles (each pair, not just each with a third
common circle) leave a curvilinear-triangle-shaped gap between them,
called an **interstice** in this context (the same term used for the gaps
of an [Apollonian gasket](https://en.wikipedia.org/wiki/Apollonian_gasket)).
[`interstices`](@ref) returns it (or them, see below) as a `Vector{APInterstice2}`,
each one bounded by three [`APCircularArc2`](@ref)s, one per circle:

```@example geo
c1 = APCircle2(APPoint(0.0, 0.0), 40.0)
c2 = APCircle2(APPoint(90.0, 0.0), 50.0)   # tangent to c1: distance 90 == 40 + 50
c3_center = intersection(APCircle2(c1.center, c1.r + 35.0), APCircle2(c2.center, c2.r + 35.0))[1]
c3 = APCircle2(c3_center, 35.0)            # tangent to both c1 and c2

gaps = interstices(c1, c2, c3)
length(gaps)   # 1: an externally tangent "chain" of 3 has exactly one gap
```

```@raw html
<img src="../assets/img/tangency/ccc_gap.svg" alt="" style="width:100%;">
```

It's built by reusing `tangent_circles(c1, c2, c3)` above: every genuine
interstice has an inscribed circle tangent to all three (one of the `CCC`
solutions) that never *encloses* any of them. Unlike the "big" solution
of a chain like this one, which contains all three and isn't a curvilinear
triangle of these three circles at all (see [`soddy_circles`](@ref) for
that pairing, inner and outer, given a name).

A **second** kind of configuration is possible: if one circle contains the
other two (each internally tangent to it, and externally tangent to each
other), the two inner circles' own tangency point splits the gap into
**two** separate interstices instead of one:

```@example geo
R = 100.0
big = APCircle2(APPoint(0.0, 0.0), R)
A = APCircle2(polar_point_deg(R - 25.0, 100.0, big.center), 25.0) # inside big, tangent to it
B_center = intersection(APCircle2(big.center, R - 45.0), APCircle2(A.center, A.r + 45.0))[1]
B = APCircle2(B_center, 45.0)                                       # inside big, tangent to it and to A

length(interstices(big, A, B))   # 2
```

```@raw html
<img src="../assets/img/tangency/ccc_gap2.svg" alt="" style="width:100%;">
```

[`interstices`](@ref) figures out which of these two cases applies (and in
the second case, correctly splits the gap in two) on its own. The order
`c1`, `c2`, `c3` are given in never matters. It throws an `ArgumentError`
if the three circles aren't all pairwise tangent to begin with.

An `APInterstice2`'s [`area`](@ref) is computed via a Green's-theorem line
integral around its three arcs rather than a "straight triangle plus or
minus circular segments" formula: the latter needs an extra inside/outside
decision per arc that breaks down for very unequal arc sizes (as in the
nested case above), while the line integral doesn't:

```@example geo
area(gaps[1])
perimeter(gaps[1])   # the three arcs' arc_length, summed
```

`rotate`, `reflection` and `homothety` all work on an `APInterstice2` too:
each of the three arcs transforms on its own, and (since each does so
correctly regardless of orientation, see [`reflection(::APCircularArc2, _)`](@ref)
above) they still connect end to end afterward into the transformed gap.

## Through a point, tangent to two objects

[`tangent_circles_through_point`](@ref) covers the remaining
"one point + two circles/lines" cases (LLP, CCP, CLP). For example, tangent
to two circles and passing through a chosen point between them:

```@example geo
c1 = APCircle2(APPoint(-4.0, 0.0), 1.5)
c2 = APCircle2(APPoint(4.0, 0.0), 1.5)
p = APPoint(0.0, 1.0)

sols_p = tangent_circles_through_point(c1, c2, p)
length(sols_p)
```

```@raw html
<img src="../assets/img/tangency/ccp.svg" alt="" style="width:100%;">
```

## Fixing the radius in advance

[`tangent_circles_with_radius`](@ref)`(obj1, obj2, r)` is a different kind
of question from the rest of this page: instead of "find the tangent
circle(s), whatever their radius", it fixes the radius `r` up front and
asks for circles of exactly that radius tangent to two lines, a line and a
circle, or two circles:

```@example geo
l1 = APLine(APPoint(0.0, 0.0), APPoint(0.0, 1.0))   # the y-axis
l2 = APLine(APPoint(0.0, 0.0), APPoint(1.0, 0.0))   # the x-axis
sols_r = tangent_circles_with_radius(l1, l2, 3.0)   # radius 3, tangent to both axes
length(sols_r), all(s -> s.r == 3.0, sols_r)   # 4 solutions, one per quadrant
```

```@raw html
<img src="../assets/img/tangency/llr.svg" alt="" style="width:100%;">
```

(`l1`/`l2` need to actually meet somewhere for this to have solutions:
two *parallel* lines always return an empty vector, since then either no
radius works or, at the one radius that does, a whole line of centers
would qualify rather than finitely many circles, a degenerate case this
function doesn't handle.)

It's built internally via [`offset_line`](@ref)`(l, d)`, which shifts a
line by a signed distance along its own normal, turning "tangent to `l` at
distance `r`" into "passes through `l` shifted by `±r`", then intersecting
those shifted lines/circles directly:

```@example geo
offset_line(l1, 3.0) == APLine(APPoint(-3.0, 0.0), APPoint(-3.0, 1.0))   # shifted left of p1->p2
```

## Fixing the center in advance

[`tangent_circles_with_center`](@ref)`(center, obj)` is the mirror
question: instead of fixing the radius, it fixes the *center* and asks for
the radius (or radii) that make a circle there tangent to a line or
another circle. A line has exactly one answer, the perpendicular distance
from `center` to the line:

```@example geo
center = APPoint(0.0, 0.0)
l = APLine(APPoint(5.0, -5.0), APPoint(5.0, 5.0))
tangent_circles_with_center(center, l)
```

A circle has up to two: external tangency (`r = d + c.r`, wrapping
around the outside) and internal tangency (`r = |d - c.r|`, fitting
between `center` and the far side of `c`), where `d` is the distance
between the two centers:

```@example geo
c = APCircle2(APPoint(10.0, 0.0), 3.0)
sols = tangent_circles_with_center(center, c)
length(sols), sols[1].r, sols[2].r   # internal (7.0) then external (13.0)
```

```@raw html
<img src="../assets/img/tangency/center_fixed.svg" alt="" style="width:100%;">
```

The two solutions merge into one when `center` sits exactly on `c` (only
external tangency survives, at `r = 2*c.r`), and there are none at all
when `center` coincides with `c`'s own center: every circle centered
there is concentric with `c`, never tangent to it.

## Watching two constructions step by step

The blocks in this section are run when the documentation is built, and each
figure comes from the code above it; only the geometry is shown. The figures
use one color code: blue for the given objects, green for the construction
aids, purple for what is found. In each part, the first block builds the
objects inside [`@to_luxor_picture!`](@ref), which fits them to the canvas and
replaces each name with the fitted object.

### A circle through two points, tangent to a line

The center of the circle is at the same distance from `a` and from `b`, so it
is on the perpendicular bisector of `[a, b]`. It is also at that same distance
from the line, which is what tangency means. The line is infinite, so it is
marked `@unbounded`: it is fitted like the rest but does not set the size of
the canvas.

```@example geo
using Luxor: sethue, setline, setdash, fontsize, label, julia_blue, julia_green, julia_red, julia_purple # hide
import Luxor # hide
fig_given(x; w=2) = (sethue(julia_blue); setline(w); path(x; action=:stroke)) # hide
fig_faint(x) = (sethue("gray80"); setline(1); setdash("dash"); path(x; action=:stroke); setdash("solid")) # hide
fig_aid(x) = (sethue(julia_green); setline(1); setdash("dash"); path(x; action=:stroke); setdash("solid")) # hide
fig_result(x; w=2) = (sethue(julia_purple); setline(w); path(x; action=:stroke)) # hide
fig_fill(x; a=0.25) = (sethue(julia_purple); Luxor.setopacity(a); path(x; action=:fill); Luxor.setopacity(1.0)) # hide
fig_dots(pts, c) = (sethue(c); path(pts; radius=3, action=:fill)) # hide
fig_tags(ts...) = (sethue(julia_red); for (t, al, p) in ts; label(t, al, p); end) # hide
fig_vtags(t) = (sethue(julia_red); g = centroid(t); for (n, v) in zip(("A", "B", "C"), vertices(t)); label(n, label_anchor(v, g)...); end) # hide
function fig_draw(f, w, h) # hide
    Luxor.@drawsvg begin # hide
        Luxor.origin(); fontsize(15); f() # hide
    end w h # hide
end # hide
fsz = @to_luxor_picture! width=500 margin=30 begin
    ta = APPoint(-3.0, 0.0)
    tb = APPoint(3.0, 0.0)
    @unbounded tl = APLine(APPoint(-6.0, -4.0), APPoint(6.0, -4.0))
    tsol = only(tangent_circles_through_points(ta, tb, tl))
end
figH = ceil(Int, fsz.height) # hide
nothing # hide
```

**Step 1.** The two points and the line.

```@example geo
!on_line(ta, tl)
```

```@example geo
fig_draw(500, figH) do # hide
    fig_given(tl) # hide
    fig_dots([ta, tb], julia_blue) # hide
    fig_tags(("a", :NW, ta), ("b", :NE, tb)) # hide
end # hide
```

**Step 2.** The perpendicular bisector of `[a, b]`: the center has to be on it.

```@example geo
bax = perpendicular_bisector(ta, tb)
fig_draw(500, figH) do # hide
    fig_given(tl) # hide
    fig_aid(bax) # hide
    fig_dots([ta, tb], julia_blue) # hide
    fig_tags(("a", :NW, ta), ("b", :NE, tb)) # hide
end # hide
```

**Step 3.** The one point of the bisector that is as far from the line as from `a`.

```@example geo
ctr = tsol.center
(on_line(ctr, bax), distance(ctr, tl) ≈ distance(ctr, ta))
```

```@example geo
fig_draw(500, figH) do # hide
    fig_given(tl) # hide
    fig_aid(bax) # hide
    fig_dots([ta, tb], julia_blue) # hide
    fig_dots([ctr], julia_purple) # hide
    fig_tags(("a", :NW, ta), ("b", :NE, tb), ("center", :E, ctr)) # hide
end # hide
```

**Step 4.** The circle around that center through `a` and `b`, touching the line at the foot of the perpendicular from the center.

```@example geo
foot = projection(ctr, tl)
distance(ctr, foot) ≈ tsol.r
```

```@example geo
fig_draw(500, figH) do # hide
    fig_given(tl) # hide
    fig_aid([bax, APSegment(ctr, foot)]) # hide
    fig_result(tsol) # hide
    fig_dots([ta, tb], julia_blue) # hide
    fig_dots([ctr, foot], julia_purple) # hide
    fig_tags(("a", :NW, ta), ("b", :NE, tb), ("center", :E, ctr)) # hide
end # hide
```

### The gap between three tangent circles

Three circles that touch each other in pairs leave a curved triangle between
them. Its corners are the three points of contact.

```@example geo
fsz = @to_luxor_picture! width=500 margin=30 begin
    k1 = APCircle2(APPoint(0.0, 0.0), 40.0)
    k2 = APCircle2(APPoint(90.0, 0.0), 50.0)
    k3 = APCircle2(intersection(APCircle2(k1.center, k1.r + 35.0), APCircle2(k2.center, k2.r + 35.0))[1], 35.0)
    tgap = only(interstices(k1, k2, k3))
end
figH = ceil(Int, fsz.height) # hide
nothing # hide
```

**Step 1.** Three circles, each tangent to the other two.

```@example geo
circles_position(k1, k2), circles_position(k2, k3), circles_position(k1, k3)
```

```@example geo
fig_draw(500, figH) do # hide
    fig_given([k1, k2, k3]) # hide
end # hide
```

**Step 2.** The points of contact, and the triangle of the three centers.

```@example geo
contacts = [only(intersection(u, v)) for (u, v) in ((k1, k2), (k2, k3), (k1, k3))]
fig_draw(500, figH) do # hide
    fig_given([k1, k2, k3]) # hide
    fig_aid(APTriangle(k1.center, k2.center, k3.center)) # hide
    fig_dots([k1.center, k2.center, k3.center], julia_blue) # hide
    fig_dots(contacts, julia_green) # hide
end # hide
```

**Step 3.** The gap is bounded by one arc of each circle, between two contact points.

```@example geo
(length(sides(tgap)), area(tgap) > 0)
```

```@example geo
fig_draw(500, figH) do # hide
    fig_fill(tgap) # hide
    fig_given([k1, k2, k3]) # hide
    fig_result(tgap) # hide
    fig_dots(contacts, julia_green) # hide
end # hide
```

## Related helpers

* [`external_similitude_center`](@ref) / [`internal_similitude_center`](@ref)
  and the common tangent lines from [Circles](@ref) are the two-circle
  building blocks these constructions are built from.
* The triangle-specific tangent-circle configurations ([`mixtilinear_incircle`](@ref),
  [`soddy_circles`](@ref), [`three_tangent_circles`](@ref) and
  [`thebault_circles`](@ref)) are covered in
  [Triangles & Triangle Centers](@ref), since they are defined in terms of
  a triangle's sides and angles rather than arbitrary circles.
