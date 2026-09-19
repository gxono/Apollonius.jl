```@meta
CurrentModule = Apollonius
```

# Triangles & Triangle Centers

[`APTriangle`](@ref) is three points, indexed `t[1]`, `t[2]`, `t[3]` (its
own type, `<: APPolygon`; see [Apollonius.jl](@ref) for the full hierarchy). This
page is organized the same way triangle geometry
usually is: the basic measurements, the four classical centers and how the
Euler line ties three of them together, the excircles, barycentric
coordinates, and then the (long) catalogue of further named centers and
derived triangles that classical triangle geometry has accumulated.

Throughout, the running example is the scalene triangle:

```@example geo
using Apollonius

A, B, C = APPoint(0.0, 0.0), APPoint(8.0, 0.0), APPoint(3.0, 6.0)
t = APTriangle(A, B, C)

area(t), perimeter(t), is_degenerate(t)
```

## The four classical centers, and the Euler line

| Function | Center | Defined as |
|:---------|:-------|:-----------|
| [`centroid`](@ref) | `G` | average of the three vertices |
| [`circumcenter`](@ref) | `O` | equidistant from the three vertices ([`circumcircle`](@ref) passes through them) |
| [`incenter`](@ref) | `I` | equidistant from the three sides ([`incircle`](@ref) touches them) |
| [`orthocenter`](@ref) | `H` | intersection of the three altitudes |

`G`, `O` and `H` are always collinear (that line is the
[`euler_line`](@ref)), and `G` divides `OH` in a fixed `1:2` ratio (`H = O +
3(G - O)`). `I` is *not* on the Euler line in general (it only coincides
with the others for an equilateral triangle).

```@example geo
G, O, I, H = centroid(t), circumcenter(t), incenter(t), orthocenter(t)
el = euler_line(t)
npc = nine_point_circle(t)
circumradius(t)   # the radius of circumcircle(t), same as npc.r * 2
```

```@raw html
<img src="../assets/img/triangles/tri_cen.svg" alt="" style="width:100%;">
```


[`nine_point_circle`](@ref) passes through the three edge midpoints, the
three altitude feet, and the three midpoints of segment `[vertex, H]` (nine
points in total, though only the circle itself, not the nine points, is
what the function returns). Its center, [`nine_point_center`](@ref), is the
midpoint of `O` and `H`, and it always sits on the Euler line too. Its
radius is exactly half the circumradius. [`euler_points`](@ref) returns
that last group of three (the midpoints of `[H, vertex]`) directly, for
when you need those specific points rather than just the circle.

```@example geo
euler_points(t)
npc.center == nine_point_center(t), npc.r ≈ circumradius(t) / 2
```

Two more lines are naturally associated with this configuration:
[`orthic_axis`](@ref), the radical axis of the circumcircle and the
nine-point circle (always perpendicular to the Euler line), and
[`brocard_axis`](@ref), the line through `O` and the symmedian point,
whose polar line with respect to the circumcircle is, in turn, the
[`lemoine_axis`](@ref).

```@example geo
orthic_axis(t), brocard_axis(t), lemoine_axis(t)
```

```@raw html
<img src="../assets/img/triangles/obl_axis.svg" alt="" style="width:100%; max-width: 700px;">
```

```@raw html
<img src="../assets/img/triangles/orthic_axis.svg" alt="" style="width:100%; max-width: 700px;">
```



## Building the centers step by step

The blocks in this section are run when the documentation is built, and each
figure comes from the code above it; only the geometry is shown. The figures
use one color code: blue for the given triangle, green for the construction
aids, purple for what is found. In each part, the first block builds the
triangle (the one of the running example) and what is derived from it inside
[`@to_luxor_picture`](@ref), which fits it to the canvas and returns the fitted
objects in `lxo`, under the names they were given. The steps then call the
functions of this page on the fitted triangle.

### The circumcenter and the circumcircle

The circumcenter is where the perpendicular bisectors of the sides meet.

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
lxm, lxo = @to_luxor_picture width=500 margin=30 begin
    tri = APTriangle(APPoint(0.0, 0.0), APPoint(8.0, 0.0), APPoint(3.0, 6.0))
    circ = circumcircle(tri)
end
(; tri, circ) = lxo
figH = ceil(Int, lxm.height) # hide
nothing # hide
```

**Step 1.** The triangle.

```@example geo
!is_degenerate(tri)
```

```@example geo
fig_draw(500, figH) do # hide
    fig_given(tri) # hide
    fig_dots(vertices(tri), julia_blue) # hide
    fig_vtags(tri) # hide
end # hide
```

**Step 2.** The perpendicular bisectors of two sides.

```@example geo
m1, m2 = mediator(tri, 1), mediator(tri, 2)
is_perpendicular(m1, APLine(tri[2], tri[3]))
```

```@example geo
fig_draw(500, figH) do # hide
    fig_given(tri) # hide
    fig_aid([m1, m2]) # hide
    fig_dots(vertices(tri), julia_blue) # hide
    fig_vtags(tri) # hide
end # hide
```

**Step 3.** They meet at the circumcenter, and the third bisector goes through the same point.

```@example geo
o = circumcenter(tri)
(isapprox(o, only(intersection(m1, m2)); atol=1e-9), on_line(o, mediator(tri, 3)))
```

```@example geo
fig_draw(500, figH) do # hide
    fig_given(tri) # hide
    fig_aid([m1, m2, mediator(tri, 3)]) # hide
    fig_dots(vertices(tri), julia_blue) # hide
    fig_dots([o], julia_purple) # hide
    fig_vtags(tri) # hide
    fig_tags(("O", :SE, o)) # hide
end # hide
```

**Step 4.** The circle around the circumcenter through a vertex passes through the other two.

```@example geo
distance(o, tri[1]) ≈ circ.r ≈ distance(o, tri[3])
```

```@example geo
fig_draw(500, figH) do # hide
    fig_given(tri) # hide
    fig_aid([APSegment(o, v) for v in vertices(tri)]) # hide
    fig_result(circ) # hide
    fig_dots(vertices(tri), julia_blue) # hide
    fig_dots([o], julia_purple) # hide
    fig_vtags(tri) # hide
    fig_tags(("O", :SE, o)) # hide
end # hide
```

### The incenter and the incircle

The incenter is where the angle bisectors meet, and it is the center of the
circle that touches the three sides.

```@example geo
lxm, lxo = @to_luxor_picture width=500 margin=30 begin
    tri = APTriangle(APPoint(0.0, 0.0), APPoint(8.0, 0.0), APPoint(3.0, 6.0))
    inc = incircle(tri)
end
(; tri, inc) = lxo
figH = ceil(Int, lxm.height) # hide
nothing # hide
```

**Step 1.** The triangle.

```@example geo
area(tri) > 0
```

```@example geo
fig_draw(500, figH) do # hide
    fig_given(tri) # hide
    fig_dots(vertices(tri), julia_blue) # hide
    fig_vtags(tri) # hide
end # hide
```

**Step 2.** The bisectors of two angles.

```@example geo
b1, b2 = bisector(tri, 1), bisector(tri, 2)
fig_draw(500, figH) do # hide
    fig_given(tri) # hide
    fig_aid([b1, b2]) # hide
    fig_dots(vertices(tri), julia_blue) # hide
    fig_vtags(tri) # hide
end # hide
```

**Step 3.** They meet at the incenter, which is at the same distance from the three sides. The feet of the perpendiculars are the points where the incircle will touch.

```@example geo
i = incenter(tri)
feet = [projection(i, APLine(tri[k], tri[mod1(k + 1, 3)])) for k in 1:3]
(isapprox(i, only(intersection(b1, b2)); atol=1e-9), distance(i, feet[1]) ≈ distance(i, feet[2]) ≈ distance(i, feet[3]))
```

```@example geo
fig_draw(500, figH) do # hide
    fig_given(tri) # hide
    fig_aid([b1, b2]) # hide
    fig_aid([APSegment(i, q) for q in feet]) # hide
    fig_dots(vertices(tri), julia_blue) # hide
    fig_dots([i], julia_purple) # hide
    fig_dots(feet, julia_green) # hide
    fig_vtags(tri) # hide
    fig_tags(("I", :NE, i)) # hide
end # hide
```

**Step 4.** The circle around the incenter through those feet is the incircle.

```@example geo
inc.r ≈ distance(i, feet[1])
```

```@example geo
fig_draw(500, figH) do # hide
    fig_given(tri) # hide
    fig_aid([APSegment(i, q) for q in feet]) # hide
    fig_result(inc) # hide
    fig_dots(vertices(tri), julia_blue) # hide
    fig_dots([i], julia_purple) # hide
    fig_dots(feet, julia_green) # hide
    fig_vtags(tri) # hide
    fig_tags(("I", :NE, i)) # hide
end # hide
```

### The Euler line

The centroid `G`, the circumcenter `O` and the orthocenter `H` are on one line.
Each comes from a different set of lines: medians, perpendicular bisectors and
altitudes.

```@example geo
lxm, lxo = @to_luxor_picture width=500 margin=30 begin
    tri = APTriangle(APPoint(0.0, 0.0), APPoint(8.0, 0.0), APPoint(3.0, 6.0))
    cen = centroid(tri)
    cir = circumcenter(tri)
    ort = orthocenter(tri)
end
(; tri, cen, cir, ort) = lxo
figH = ceil(Int, lxm.height) # hide
nothing # hide
```

**Step 1.** The medians meet at the centroid.

```@example geo
all(on_line(cen, median(tri, k)) for k in 1:3)
```

```@example geo
fig_draw(500, figH) do # hide
    fig_given(tri) # hide
    fig_aid([median(tri, k) for k in 1:3]) # hide
    fig_dots(vertices(tri), julia_blue) # hide
    fig_dots([cen], julia_purple) # hide
    fig_vtags(tri) # hide
    fig_tags(("G", :W, cen)) # hide
end # hide
```

**Step 2.** The altitudes meet at the orthocenter.

```@example geo
all(on_line(ort, altitude(tri, k)) for k in 1:3)
```

```@example geo
fig_draw(500, figH) do # hide
    fig_given(tri) # hide
    fig_aid([altitude(tri, k) for k in 1:3]) # hide
    fig_dots(vertices(tri), julia_blue) # hide
    fig_dots([cen, ort], julia_purple) # hide
    fig_vtags(tri) # hide
    fig_tags(("G", :W, cen), ("H", :NE, ort)) # hide
end # hide
```

**Step 3.** The perpendicular bisectors meet at the circumcenter.

```@example geo
all(on_line(cir, mediator(tri, k)) for k in 1:3)
```

```@example geo
fig_draw(500, figH) do # hide
    fig_given(tri) # hide
    fig_aid([mediator(tri, k) for k in 1:3]) # hide
    fig_dots(vertices(tri), julia_blue) # hide
    fig_dots([cen, ort, cir], julia_purple) # hide
    fig_vtags(tri) # hide
    fig_tags(("G", :W, cen), ("H", :NE, ort), ("O", :SE, cir)) # hide
end # hide
```

**Step 4.** The three centers are collinear, and `G` divides `OH` in the ratio `1:2`.

```@example geo
el = euler_line(tri)
(all(on_line(q, el) for q in (cen, cir, ort)), isapprox(ort, cir + 3 * (cen - cir); atol=1e-9))
```

```@example geo
fig_draw(500, figH) do # hide
    fig_given(tri) # hide
    fig_result(el) # hide
    fig_dots(vertices(tri), julia_blue) # hide
    fig_dots([cen, ort, cir], julia_purple) # hide
    fig_vtags(tri) # hide
    fig_tags(("G", :W, cen), ("H", :NE, ort), ("O", :SE, cir)) # hide
end # hide
```

## Excenters and excircles

Where the incircle is tangent to all three sides from *inside* the
triangle, each **excircle** is tangent to one side and to the
*extensions* of the other two, from outside. There are three of them, one
opposite each vertex. [`excenters`](@ref) and [`exradii`](@ref) return
all three as a named tuple `(A=..., B=..., C=...)`, and
[`excircles`](@ref) the actual circles.

```@example geo
ex = excenters(t)
exc = excircles(t)
er = exradii(t)
exc.A.r == er.A   # excircles(t).A already has radius exradii(t).A
```

```@raw html
<img src="../assets/img/triangles/excircles.svg" alt="" style="width:100%; max-width: 700px;">
```


## Barycentric coordinates

Every point of the plane can be written as a weighted average of the three
vertices, `p = αA + βB + γC` with `α+β+γ = 1`. These weights `(α,β,γ)`
are its **barycentric coordinates** with respect to `t`.
[`barycentric_point`](@ref) goes from coordinates to a point (weights don't
need to be normalized; they're rescaled internally);
[`barycentric_coordinates`](@ref) goes the other way.

```@example geo
barycentric_point(t, 1.0, 1.0, 1.0)     # (1:1:1) is always the centroid
barycentric_coordinates(t, centroid(t)) # (1/3, 1/3, 1/3)
```

```@raw html
<img src="../assets/img/triangles/barycenter.svg" alt="" style="width:100%;">
```

Most of the named centers below have simple, well-known barycentric
coordinates (the incenter is `(a:b:c)` in the side lengths, for instance).
`barycentric_point` is the easiest way to construct a center directly from
a formula found in a reference like the *Encyclopedia of Triangle Centers*,
without rederiving it in Cartesian coordinates.

## Trilinear coordinates

**Trilinear** coordinates `(x:y:z)` are the other classical coordinate
system for a triangle: unlike barycentric weights, they're proportional to
the *actual signed perpendicular distances* from the point to the three
sides. [`trilinear_coordinates`](@ref) returns those distances directly (not
just up to a common scale); [`trilinear_point`](@ref) goes the other way,
from a trilinear ratio to a point (internally converting to barycentric via
`(a·x : b·y : c·z)`).

```@example geo
x, y, z = trilinear_coordinates(t, incenter(t))
x, y, z, inradius(t)   # x == y == z == inradius(t): (1:1:1) is always the incenter
```

```@example geo
trilinear_point(t, 1.0, 1.0, 1.0) ≈ incenter(t)
```

```@raw html
<img src="../assets/img/triangles/trilinear.svg" alt="" style="width:100%;">
```

Many named centers found in a reference like the *Encyclopedia of Triangle
Centers* are given as trilinears rather than barycentrics ([`kenmotu_point`](@ref)
below is one example), so having both conversions on hand avoids
rederiving one from the other by hand. [`clawson_point`](@ref) (Kimberling
X(19)) is exactly this: it has no simpler description than its own
trilinears, `tan(A) : tan(B) : tan(C)`, so it's built with
`trilinear_point` directly rather than from some other geometric
construction:

```@example geo
angA, angB, angC = angle_at(t[1], t[2], t[3]), angle_at(t[2], t[1], t[3]), angle_at(t[3], t[1], t[2])
clawson_point(t) ≈ trilinear_point(t, tan(angA), tan(angB), tan(angC))
```

## Vertex-indexed lines

Four of the classical triangle lines (the altitude, median, and internal
and external angle bisectors) plus the perpendicular bisector of the
opposite side and the angle trisectors, all come in threes, one per vertex.
Rather than one function per vertex, each is a single function taking the
triangle and a vertex index `i ∈ {1,2,3}`:

| Function | The line through `t[i]`... |
|:---------|:----------------------------|
| [`altitude`](@ref)`(t, i)` | ...perpendicular to the opposite side (concurs at `orthocenter`) |
| [`median`](@ref)`(t, i)` | ...through the opposite side's midpoint (concurs at `centroid`) |
| [`bisector`](@ref)`(t, i)` | ...the internal angle bisector (concurs at `incenter`) |
| [`bisector_ext`](@ref)`(t, i)` | ...the external angle bisector (perpendicular to `bisector(t, i)`) |
| [`mediator`](@ref)`(t, i)` | the perpendicular bisector of the side *opposite* `t[i]` (concurs at `circumcenter`) |
| [`trisector`](@ref)`(t, i)` | the 2 rays from `t[i]` trisecting the interior angle there |

```@example geo
altitude(t, 1), median(t, 1), bisector(t, 1)
```

```@example geo
altitude.(t, 1:3)
```

```@raw html
<img src="../assets/img/triangles/altitude.svg" alt="" style="width:100%;">
```


```@example geo
bisector.(t, 1:3)
```

```@raw html
<img src="../assets/img/triangles/median.svg" alt="" style="width:100%;">
```




```@example geo
median.(t, 1:3)
```

```@raw html
<img src="../assets/img/triangles/median.svg" alt="" style="width:100%;">
```



```@example geo
on_line(orthocenter(t), altitude(t, 1)), on_line(centroid(t), median(t, 1)), on_line(incenter(t), bisector(t, 1))
```

`bisector_ext(t, i)` and `mediator(t, i)` complete the set. The external
bisector is always perpendicular to the internal one at the same vertex,
and the mediator (the perpendicular bisector of the *opposite* side) is
what all three concur at to give the circumcenter:

```@example geo
is_perpendicular(bisector(t, 1), bisector_ext(t, 1))
```

```@example geo
on_line(circumcenter(t), mediator(t, 1)), on_line(circumcenter(t), mediator(t, 2)), on_line(circumcenter(t), mediator(t, 3))
```

```@example geo
bisector_ext.(t, 1:3)
```

```@raw html
<img src="../assets/img/triangles/bisector_ext.svg" alt="" style="width:100%;">
```

```@example geo
mediator.(t, 1:3)
```

```@raw html
<img src="../assets/img/triangles/mediator.svg" alt="" style="width:100%;">
```


The free function [`angle_trisectors`](@ref)`(vertex, p1, p2)` (see
[Angles](@ref) on the previous page) is what `trisector(t, i)` is built
from; use it directly when the two rays don't come from a triangle's own
vertices.

```@example geo
trisector.(t, 1:3)
```

```@raw html
<img src="../assets/img/triangles/trisector.svg" alt="" style="width:100%;">
```

## Further named centers

Beyond the classical four, this package implements a large catalogue of
triangle centers and associated circles from classical triangle geometry.
Two, as a sample:

```@example geo
Na = nagel_point(t)     # point where the excircle-tangency cevians meet
Ge = gergonne_point(t)  # point where the incircle-tangency cevians meet
```

The rest, grouped by what they're built from:

| Group | Functions |
|:------|:----------|
| Cevian-intersection points | [`nagel_point`](@ref), [`gergonne_point`](@ref), [`symmedian_point`](@ref), [`fermat_point`](@ref), [`second_fermat_point`](@ref) |
| Conjugates of a point | [`isogonal_conjugate`](@ref), [`isotomic_conjugate`](@ref) |
| Complement/anticomplement of a point | [`complement`](@ref), [`anticomplement`](@ref) |
| Built from the incenter/excenters | [`mittenpunkt`](@ref), [`spieker_center`](@ref), [`spieker_circle`](@ref), [`bevan_point`](@ref), [`de_longchamps_point`](@ref) |
| Trilinear/barycentric formula, no simpler description | [`clawson_point`](@ref) |
| On the circumcircle or Euler line | [`feuerbach_point`](@ref), [`feuerbach_points`](@ref), [`isodynamic_points`](@ref) |
| Brocard configuration | [`first_brocard_point`](@ref), [`second_brocard_point`](@ref), [`brocard_angle`](@ref), [`brocard_circle`](@ref), [`brocard_midpoint`](@ref) |
| Congruent-squares / conjugate-of-classical-center points | [`kenmotu_point`](@ref)/[`kenmotu_circle`](@ref), [`macbeath_point`](@ref) |
| A 4th point's common nine-point-circle point | [`poncelet_point`](@ref) |
| Pedal-type constructions | [`simson_line`](@ref), [`steiner_line`](@ref), [`orthopole`](@ref), [`pedal_triangle`](@ref)/[`pedal_circle`](@ref) |
| Named auxiliary circles | [`conway_points`](@ref)/[`conway_circle`](@ref), [`taylor_points`](@ref)/[`taylor_circle`](@ref), [`first_lemoine_points`](@ref)/[`first_lemoine_circle`](@ref)/[`second_lemoine_circle`](@ref)/[`symmedial_circle`](@ref), [`van_lamoen_points`](@ref)/[`van_lamoen_circle`](@ref), [`adams_points`](@ref)/[`adams_circle`](@ref) |
| Mutually tangent circle systems | [`mixtilinear_incircle`](@ref), [`three_tangent_circles`](@ref)/[`soddy_circles`](@ref)/[`soddy_line`](@ref)/[`soddy_center`](@ref)/[`soddy_points`](@ref), [`thebault_circles`](@ref) |
| Apollonius circles of a triangle | [`three_apollonius_circles`](@ref) (one per vertex; their common points are the [`isodynamic_points`](@ref)); [`apollonius_circle_of_triangle`](@ref)/[`apollonius_point_of_triangle`](@ref) (one circle, tangent to the three excircles instead) |
| Axis-like lines | [`fermat_axis`](@ref) (through [`fermat_point`](@ref) and [`second_fermat_point`](@ref)); see also [`orthic_axis`](@ref)/[`brocard_axis`](@ref)/[`lemoine_axis`](@ref) above and [`soddy_line`](@ref) |

All of these take the `APTriangle` as their (only, or first) argument and
return an `APPoint`, an `APCircle2`, an `APLine`, or (where there's naturally more
than one, like `soddy_circles` or `three_apollonius_circles`) a tuple or
named tuple. See the [API Reference](@ref) for exact signatures.

[`steiner_line`](@ref)`(t, p)` is closely related to [`simson_line`](@ref)`(t,
p)`: reflecting (rather than projecting) `p` across the three side-lines
gives three points that are collinear exactly when `p` is on the
circumcircle, and that Steiner line always passes through the orthocenter,
parallel to the Simson line of the same point.

```@example geo
p_on_circ = polar_point(circumradius(t), 0.7, circumcenter(t))   # any point on t's circumcircle
sl = simson_line(t, p_on_circ)
stl = steiner_line(t, p_on_circ)
on_line(orthocenter(t), stl), is_parallel(sl, stl)
```

[`orthopole`](@ref)`(l, t)` is the point where the three perpendiculars
(one per vertex, dropped from that vertex's projection onto `l`, to the
*opposite* side) always concur. [`pedal_triangle`](@ref)`(t, p)` (the feet
of the perpendiculars from `p` to the three side-lines) generalizes
[`orthic_triangle`](@ref)/[`contact_triangle`](@ref), which are just the
pedal triangles of the orthocenter/incenter:

```@example geo
orthopole(APLine(t[2], t[3]), t) isa APPoint
pedal_triangle(t, incenter(t)) ≈ contact_triangle(t)
```

[`pedal_circle`](@ref)`(t, p)` is just the circumcircle of that pedal
triangle:

```@example geo
pedal_circle(t, incenter(t)) ≈ incircle(t)   # the incircle is the pedal circle of the incenter
```

```@example geo
brocard_midpoint(t)   # midpoint of the two Brocard points (Kimberling X(39))
kenmotu_point(t)       # X(371): common vertex of 3 congruent inscribed squares
macbeath_point(t)      # X(264): isotomic conjugate of the circumcenter
```

[`symmedian_point`](@ref) is the fourth cevian-intersection point, built
from barycentric coordinates `a² : b² : c²` the same way `nagel_point`/
`gergonne_point` are built from their own:

```@example geo
symmedian_point(t)
```

[`isogonal_conjugate`](@ref)`(t, p)` reflects each cevian `vertex -> p`
across the internal bisector at that vertex; [`isotomic_conjugate`](@ref)`(t,
p)` instead reflects the cevian's foot across the opposite side's midpoint.
Both are involutions (applying either twice returns `p`), and
`isogonal_conjugate` swaps orthocenter↔circumcenter and centroid↔symmedian
point while fixing the incenter:

```@example geo
isogonal_conjugate(t, isogonal_conjugate(t, incenter(t))) ≈ incenter(t)   # incenter is a fixed point
isogonal_conjugate(t, orthocenter(t)) ≈ circumcenter(t)
isogonal_conjugate(t, centroid(t)) ≈ symmedian_point(t)
```

```@example geo
isotomic_conjugate(t, isotomic_conjugate(t, incenter(t))) ≈ incenter(t)
```

[`anticomplement`](@ref)`(t, p)` is the inverse of [`complement`](@ref)`(t,
p)`: homothety by `-2` instead of `-1/2` about the centroid:

```@example geo
anticomplement(t, complement(t, incenter(t))) ≈ incenter(t)
```

Built from the incenter/excenters: [`spieker_center`](@ref) (the incenter
of the medial triangle) and [`spieker_circle`](@ref) (its incircle);
[`bevan_point`](@ref) (circumcenter of the excentral triangle); and
[`de_longchamps_point`](@ref) (the orthocenter reflected across the
circumcenter, so it always lies on the Euler line):

```@example geo
spieker_center(t) ≈ incenter(medial_triangle(t))
spieker_circle(t) ≈ incircle(medial_triangle(t))
bevan_point(t) ≈ circumcenter(excentral_triangle(t))
on_line(de_longchamps_point(t), euler_line(t))
```

The two [`isodynamic_points`](@ref) are where the three
[`three_apollonius_circles`](@ref) (one per vertex, for points whose
distances to the other two vertices are in the same ratio as the two sides
meeting at that vertex) all meet:

```@example geo
apo = three_apollonius_circles(t)
iso1, iso2 = isodynamic_points(t)
all(c -> distance(c.center, iso1) ≈ c.r, apo), all(c -> distance(c.center, iso2) ≈ c.r, apo)
```

Despite the shared name, [`apollonius_circle_of_triangle`](@ref) is a
different construction: the circle tangent to and enclosing all three
excircles of `t`. Take that circle's point of tangency with each excircle,
draw the line from the excircle's own vertex (the one it sits opposite)
through that tangency point, and the three lines meet at
[`apollonius_point_of_triangle`](@ref) (Kimberling X(181)):

```@example geo
ap_circle = apollonius_circle_of_triangle(t)
ex = excircles(t)
distance(ap_circle.center, ex.A.center) ≈ ap_circle.r - ex.A.r  # internally tangent
```

```@example geo
apollonius_point_of_triangle(t)
```

The Brocard configuration: [`first_brocard_point`](@ref)/
[`second_brocard_point`](@ref) are the two points seeing all three sides at
the same [`brocard_angle`](@ref); [`brocard_circle`](@ref) passes through
both (and through the symmedian point):

```@example geo
Om1, Om2 = first_brocard_point(t), second_brocard_point(t)
bc = brocard_circle(t)
rad2deg(brocard_angle(t)), distance(bc.center, Om1) ≈ bc.r, distance(bc.center, Om2) ≈ bc.r
```

Named auxiliary circles: [`conway_points`](@ref)/[`conway_circle`](@ref)
(extend the two sides at each vertex outward by the length of the
opposite side; all 6 endpoints lie on a circle centered at the incenter),
[`taylor_circle`](@ref) (through the 6 [`taylor_points`](@ref)),
[`first_lemoine_points`](@ref)/[`first_lemoine_circle`](@ref) and
[`second_lemoine_circle`](@ref) (both centered differently, both built
from the symmedian point), [`symmedial_circle`](@ref) (circumcircle of
the cevian triangle of the symmedian point, a third circle built from the
same point), [`van_lamoen_circle`](@ref) (through the 6
[`van_lamoen_points`](@ref)), and [`adams_circle`](@ref) (through the 6
[`adams_points`](@ref), centered at the incenter):

```@example geo
on_circ(p, c) = distance(p, c.center) ≈ c.r   # "p is exactly on c", not just inside the disk

all(p -> on_circ(p, conway_circle(t)), conway_points(t)),
    all(p -> on_circ(p, taylor_circle(t)), taylor_points(t)),
    all(p -> on_circ(p, first_lemoine_circle(t)), first_lemoine_points(t)),
    symmedian_point(t) ≈ second_lemoine_circle(t).center,
    all(v -> on_circ(v, symmedial_circle(t)), cevian_triangle(t, symmedian_point(t))),
    all(p -> on_circ(p, van_lamoen_circle(t)), van_lamoen_points(t)),
    all(p -> on_circ(p, adams_circle(t)), adams_points(t))
```

[`mixtilinear_incircle`](@ref)`(t, i)` is tangent to the two sides through
`t[i]` and internally tangent to the circumcircle; [`soddy_circles`](@ref)
(`inner`/`outer`) and [`soddy_line`](@ref) extend
[`three_tangent_circles`](@ref) (see [Tangency & Apollonius Problems](@ref)):

```@example geo
mixt = mixtilinear_incircle(t, 1)
sc = soddy_circles(t)
on_line(sc.inner.center, soddy_line(t)), on_line(sc.outer.center, soddy_line(t))
```

[`soddy_center`](@ref)`(t; outer=false)` is just the center of one of
those two circles, as a point on its own (Kimberling X(176) for the
inner one, the default, and X(175) for `outer=true`); [`soddy_points`](@ref)
gives both at once, as `(inner=..., outer=...)`:

```@example geo
soddy_center(t) == sc.inner.center
soddy_points(t) == (inner=sc.inner.center, outer=sc.outer.center)
```

[`second_fermat_point`](@ref) is built exactly like [`fermat_point`](@ref)
but with the three equilateral triangles erected *inward* instead of
outward; [`fermat_axis`](@ref) is the line through both:

```@example geo
fermat_axis(t)   # APLine(fermat_point(t), second_fermat_point(t))
```

[`poncelet_point`](@ref)`(t, p)` uses a striking fact about *any* 4 points
in general position (here, `t`'s 3 vertices plus a 4th, `p`): the
nine-point circles of the 4 triangles obtained by leaving out one point
each time always share a single common point.

```@example geo
poncelet_point(t, APPoint(5.0, -2.0))
```

[`thebault_circles`](@ref) builds the two circles of the classical
**Sawayama–Thébault configuration**: given a point `p` on side `[t[2],
t[3]]`, each is tangent to the cevian `t[1] -> p`, to that side, and
internally tangent to the circumcircle: one nestled against `t[2]`, the
other against `t[3]`.

```@example geo
D = B + 0.4 * (C - B)   # a point on side [B, C]
th = thebault_circles(t, D)
```

No matter where `p` sits on the side, the incenter always lies
exactly on the segment joining the two circles' centers (the theorem the
construction is named for):

```@example geo
on_line(incenter(t), APLine(th.near_b.center, th.near_c.center))
```

[`three_tangent_circles`](@ref) is the simpler configuration
[`soddy_circles`](@ref) is itself built from: one circle per vertex,
radius equal to the tangent length from that vertex to the incircle, each
pair meeting exactly where the incircle touches the side between them.

```@example geo
base = three_tangent_circles(t)
distance(base[1].center, base[2].center) ≈ base[1].r + base[2].r   # pairwise externally tangent
```

[`taylor_points`](@ref) is the full 6-point construction behind
[`taylor_circle`](@ref): project each vertex of the [`orthic_triangle`](@ref)
onto each of the two sides *not* used to define it; all 6 results are
concyclic.

```@example geo
length(taylor_points(t))   # 6
```

[`van_lamoen_points`](@ref) is another 6-concyclic-points theorem: the
circumcenters of the 6 small triangles the 3 medians cut `t` into (each
formed by one vertex, one non-adjacent side midpoint, and the centroid)
always lie on a common circle, [`van_lamoen_circle`](@ref).

```@example geo
length(van_lamoen_points(t))   # 6
```

[`complement`](@ref)`(t, p)` and [`anticomplement`](@ref)`(t, p)` are the
homotheties of ratio `-1/2` and `-2` about the centroid, inverses of each
other. Applied to `t`'s own vertices they give the [`medial_triangle`](@ref)
and the anticomplementary triangle (see [Derived triangles](@ref))
respectively:

```@example geo
complement(t, A) ≈ midpoint(B, C)
```

[`kenmotu_circle`](@ref) is centered at the [`kenmotu_point`](@ref), with
radius `√2·a·b·c / (4·Area + a²+b²+c²)`; it passes through the 6 points
where the three congruent inscribed squares of the Kenmotu configuration
meet the sides.

```@example geo
kenmotu_circle(t)
```

[`feuerbach_points`](@ref) is the excircle analogue of
[`feuerbach_point`](@ref): besides its internal tangency with the
incircle, the nine-point circle is *externally* tangent to each of the
three excircles too, at these three points.

```@example geo
feuerbach_points(t)
```

[`kiepert_hyperbola`](@ref) is the unique rectangular hyperbola through
`t`'s 3 vertices, its centroid and its orthocenter (built directly via
[`conic_through_points`](@ref) on those 5 points); [`kiepert_parabola`](@ref)
has focus Kimberling center X(110) and directrix the [`euler_line`](@ref)
(undefined for an isosceles triangle, where X(110) doesn't exist):

```@example geo
kiepert_hyperbola(t) isa APHyperbola2
kiepert_parabola(t) isa APParabola2
```

## Steiner ellipses

Two more ellipses are naturally associated with a triangle, both centered
at the centroid: the **Steiner inellipse**, the (unique, maximum-area)
ellipse inscribed in the triangle and tangent to the sides at their
midpoints, and the **Steiner circumellipse**, the (unique, minimum-area)
ellipse through the three vertices. [`steiner_inellipse`](@ref) and
[`steiner_circumellipse`](@ref) build them.

```@example geo
inell = steiner_inellipse(t)
circumell = steiner_circumellipse(t)
inell.center ≈ circumell.center ≈ centroid(t)
```


```@raw html
<img src="../assets/img/triangles/steiner.svg" alt="" style="width:100%;">
```


The circumellipse is always exactly the image of the inellipse under a
homothety of ratio `-2` about the centroid, the same ratio that relates a
triangle to its own [`medial_triangle`](@ref):

```@example geo
circumell.a ≈ 2 * inell.a, circumell.b ≈ 2 * inell.b
```

`steiner_inellipse` finds its foci via **Marden's theorem**: representing
the vertices as complex numbers `z1, z2, z3`, the foci are the two roots of
the derivative of `(z-z1)(z-z2)(z-z3)`. `steiner_circumellipse` is built via
[`conic_through_points`](@ref), using the three vertices together with the
reflections of two of them across the centroid (also on the ellipse, since
any conic centered at a point is symmetric about it).

### More named inellipses

Beyond Steiner's, five more classical inscribed ellipses:

| Function | Center | Foci |
|:---------|:-------|:-----|
| [`lemoine_inellipse`](@ref) | midpoint of centroid & symmedian point | centroid, symmedian point |
| [`brocard_inellipse`](@ref) | midpoint of the two Brocard points | second/first Brocard point |
| [`macbeath_inellipse`](@ref) | midpoint of circumcenter & orthocenter | circumcenter, orthocenter (acute triangles only) |
| [`mandart_inellipse`](@ref) | [`mittenpunkt`](@ref) | (fit through 5 points instead, see below) |
| [`orthic_inellipse`](@ref) | [`symmedian_point`](@ref) | (acute triangles only) |

The first three are bifocal ellipses (see [Conics: Ellipse, Parabola & Hyperbola](@ref)):
each is pinned down by requiring it pass through one specific extra point
(a vertex of a particular cevian triangle). `mandart_inellipse` and
`orthic_inellipse` instead fit a conic through 5 points directly via
[`conic_through_points`](@ref): the 3 vertices of the
[`extouch_triangle`](@ref)/[`orthic_triangle`](@ref) it's tangent to, plus
the point-reflections of 2 of them through the known center (also on the
ellipse, since it's centrally symmetric about its own center).

```@example geo
mandart_inellipse(t).center ≈ mittenpunkt(t)
```

```@example geo
lemoine_inellipse(t).center ≈ midpoint(centroid(t), symmedian_point(t))
brocard_inellipse(t).center ≈ midpoint(first_brocard_point(t), second_brocard_point(t))
```

```@example geo
macbeath_inellipse(t).center ≈ midpoint(circumcenter(t), orthocenter(t))   # requires an acute triangle
orthic_inellipse(t).center ≈ symmedian_point(t)                             # also acute-only
```

## Derived triangles

These take an `APTriangle` and return another `APTriangle` built from it:

| Function | Vertices are... |
|:---------|:-----------------|
| [`medial_triangle`](@ref) | the three edge midpoints |
| [`anticomplementary_triangle`](@ref) | `B+C-A`, `C+A-B`, `A+B-C`: the inverse of `medial_triangle` (`t` is *its* medial triangle) |
| [`orthic_triangle`](@ref) | the three altitude feet |
| [`reflection_triangle`](@ref) | each vertex reflected across its *opposite side line* (unlike `orthic_triangle`, which projects instead) |
| [`contact_triangle`](@ref) | the three points where the incircle touches the sides |
| [`extouch_triangle`](@ref) | the three points where the excircles touch the sides |
| [`excentral_triangle`](@ref) | the three excenters |
| [`tangential_triangle`](@ref) | tangents to the circumcircle at each vertex, pairwise intersected |
| [`napoleon_triangle`](@ref) | centers of equilateral triangles erected on each side ([`napoleon_point`](@ref) is its centroid; by Napoleon's theorem, always `t`'s own centroid too) |
| [`morley_triangle`](@ref) | intersections of adjacent angle trisectors |
| [`pedal_triangle`](@ref) | projections of a chosen point onto the three sides |
| [`cevian_triangle`](@ref) / [`circumcevian_triangle`](@ref) | feet of cevians through a chosen point (extended to the circumcircle, for the latter) |

```@example geo
mt = medial_triangle(t)
```

The medial triangle is always similar to `t` at half scale, sharing its
centroid, and its own circumcircle is exactly `t`'s nine-point circle.

```@example geo
anticomplementary_triangle(mt) ≈ t   # medial_triangle and anticomplementary_triangle are inverses
```

```@example geo
oh = orthic_triangle(t)         # altitude feet (projections)
rt = reflection_triangle(t)     # each vertex reflected, instead of projected, across the opposite side
distance(t[1], rt[1]) ≈ 2 * distance(t[1], oh[1])   # reflecting doubles the projected distance
```

```@example geo
ct = contact_triangle(t)        # incircle touch points
et = extouch_triangle(t)        # excircle touch points
et_center = excentral_triangle(t)   # the 3 excenters, as a triangle
tt = tangential_triangle(t)     # tangent lines to the circumcircle at each vertex, intersected pairwise
on_line(circumcenter(t), APLine(t[1], tt[1])) == false   # circumcenter isn't generally on a tangent line
```

```@example geo
np_tri = napoleon_triangle(t)          # always equilateral (Napoleon's theorem)
distance(np_tri[1], np_tri[2]) ≈ distance(np_tri[2], np_tri[3]) ≈ distance(np_tri[3], np_tri[1])
napoleon_point(t) ≈ centroid(t)         # Napoleon's theorem: same point either way
```

```@example geo
mor = morley_triangle(t)               # always equilateral (Morley's trisector theorem)
distance(mor[1], mor[2]) ≈ distance(mor[2], mor[3]) ≈ distance(mor[3], mor[1])
```

```@example geo
cev = cevian_triangle(t, incenter(t))            # feet of the cevians through the incenter
ccev = circumcevian_triangle(t, incenter(t))     # same cevians, extended to the circumcircle
on_segment(cev[1], APSegment(t[2], t[3])), on_line(ccev[1], APLine(t[1], incenter(t)))
```

## Inscribed squares

[`square_inscribed`](@ref)`(t, i)` builds the square with one side on the
side opposite `t[i]` and its other two vertices exactly on the two sides
through `t[i]`, returned as an [`APQuadrilateral`](@ref). There are 3 such
squares (one per side, hence the vertex index):

```@example geo
sq = square_inscribed(t, 1)
distance(sq[1], sq[2]), distance(sq[2], sq[3])   # equal: it really is a square
```

Its side length is `a*h / (a+h)` (`a` the base length, `h` the
corresponding height) regardless of how oblique the triangle is, a
classical fact that falls out of simple similar-triangles reasoning once
you set up coordinates with the base on an axis.

## Triangles built on a segment

A different family of constructors, analogous to [`square_on_segment`](@ref)
(see [Polygons & Bounding Boxes](@ref)): each takes a base segment `[a, b]`
and returns the classical named triangle with that segment as one side (or,
for the two "hypotenuse" ones, as the hypotenuse), plus a `ccw::Bool=true`
keyword picking which side of `[a, b]` the third vertex falls on.

| Function | Triangle |
|:---------|:---------|
| [`equilateral_triangle_on_segment`](@ref) | equilateral, side `[a, b]` |
| [`isosceles_triangle_on_segment`](@ref) | isosceles, base `[a, b]`, given leg length |
| [`triangle_30_60_90_on_segment`](@ref) | right triangle, hypotenuse `[a, b]`, angles `30°`/`60°` at `a`/`b` |
| [`isosceles_right_triangle_on_segment`](@ref) | isosceles right triangle, hypotenuse `[a, b]` (via Thales' theorem) |
| [`golden_triangle_on_segment`](@ref) | isosceles `72°-72°-36°`, base `[a, b]` |
| [`golden_gnomon_on_segment`](@ref) | isosceles `36°-36°-108°` (the golden gnomon), base `[a, b]` |
| [`egyptian_triangle_on_segment`](@ref) | `3-4-5` right triangle, `[a, b]` the "4" side, right angle at `b` |
| [`cheops_triangle_on_segment`](@ref) | isosceles with sides in the ratio `2 : φ : φ`, base `[a, b]` (the profile of the Cheops pyramid) |
| [`golden_right_triangle_on_segment`](@ref) | right triangle with legs in the golden ratio, `[a, b]` the long leg, right angle at `b` |
| [`triangle_on_segment`](@ref) | generic ASA: base `[a, b]`, given angle at `a` and at `b` |
| [`triangle_on_segment_sas`](@ref) | generic SAS: base `[a, b]`, given angle and side length at one vertex |
| [`triangle_on_segment_ssa`](@ref) | generic SSA: base `[a, b]`, an angle at one vertex, and the length of the opposite side (0/1/2 solutions) |
| [`triangle_on_segment_sss`](@ref) | generic SSS: base `[a, b]` and both new side lengths |

The `72°-72°-36°` triangle of Euclid is [`golden_triangle_on_segment`](@ref),
and the `30°-60°-90°` "school" triangle is [`triangle_30_60_90_on_segment`](@ref).

Every fixed-shape constructor above is really just a named call into one
of these four: `golden_triangle_on_segment(a, b)` is
`triangle_on_segment(a, b, 2pi/5, 2pi/5)`, `isosceles_triangle_on_segment(a,
b, leg)` is `triangle_on_segment_sss(a, b, leg, leg)`, and so on. Reach for
the generic form directly whenever the triangle you want isn't one of the
named ones.

```@example geo
p1, p2 = APPoint(0.0, 0.0), APPoint(6.0, 0.0)
golden_triangle_on_segment(p1, p2)   # apex angle 36°, both base angles 72°
```

```@raw html
<img src="../assets/img/triangles/tronseg_gold.svg" alt="" style="width:100%;">
```

```@example geo
egyptian_triangle_on_segment(p1, p2)   # legs 4:3 (here 6:4.5), hypotenuse 5 (here 7.5)
```

```@raw html
<img src="../assets/img/triangles/tronseg_egy.svg" alt="" style="width:100%;">
```


```@example geo
eq = equilateral_triangle_on_segment(p1, p2)
distance(eq[1], eq[2]), distance(eq[2], eq[3]), distance(eq[3], eq[1])   # all 3 equal
```

```@raw html
<img src="../assets/img/triangles/tronseg_eq.svg" alt="" style="width:100%;">
```

```@example geo
gnomon = golden_gnomon_on_segment(p1, p2)   # base angles 36°, apex angle 108°
rad2deg(angle_at(gnomon[1], gnomon[3], gnomon[2])), rad2deg(angle_at(gnomon[3], gnomon[1], gnomon[2]))
```

```@raw html
<img src="../assets/img/triangles/tronseg_goldgnom.svg" alt="" style="width:100%;">
```


```@example geo
iso = isosceles_triangle_on_segment(p1, p2, 5.0)   # base [p1,p2], legs of length 5
distance(iso[1], iso[3]) ≈ 5.0, distance(iso[2], iso[3]) ≈ 5.0
```

```@raw html
<img src="../assets/img/triangles/tronseg_iso.svg" alt="" style="width:100%;">
```

```@example geo
r306090 = triangle_30_60_90_on_segment(p1, p2)   # hypotenuse [p1,p2]
rad2deg(angle_at(r306090[1], r306090[2], r306090[3])), rad2deg(angle_at(r306090[2], r306090[1], r306090[3]))
```

```@raw html
<img src="../assets/img/triangles/tronseg_306090.svg" alt="" style="width:100%;">
```

```@example geo
isr = isosceles_right_triangle_on_segment(p1, p2)   # hypotenuse [p1,p2], via Thales
rad2deg(angle_at(isr[3], isr[1], isr[2]))   # 90°: the right angle sits opposite the hypotenuse
```

```@raw html
<img src="../assets/img/triangles/tronseg_isor.svg" alt="" style="width:100%;">
```

The four generic constructors behind all of the above, named after which
three measurements pin the triangle down. ASA, given both base angles:

```@example geo
asa = triangle_on_segment(p1, p2, deg2rad(50), deg2rad(70))
rad2deg(angle_at(asa[1], asa[2], asa[3])), rad2deg(angle_at(asa[2], asa[1], asa[3]))
```

SAS, given a side length and the angle it makes with the base at one
vertex (`at=:a` or `at=:b`):

```@example geo
sas = triangle_on_segment_sas(p1, p2, deg2rad(60), 4.0; at=:b)
distance(sas[2], sas[3]), rad2deg(angle_at(sas[2], sas[1], sas[3]))
```

SSS, given both new side lengths:

```@example geo
sss = triangle_on_segment_sss(p1, p2, 5.0, 7.0)
distance(sss[1], sss[3]), distance(sss[2], sss[3])
```

SSA, given an angle at one vertex and the length of the side opposite it,
is the classically ambiguous case: depending on the numbers, 0, 1 or 2
triangles satisfy it. With 2 solutions, `second_solution=false` (the
default) picks the one with the larger angle at the other base vertex:

```@example geo
ssa1 = triangle_on_segment_ssa(p1, p2, deg2rad(40), 4.5; at=:a)
ssa2 = triangle_on_segment_ssa(p1, p2, deg2rad(40), 4.5; at=:a, second_solution=true)
distance(ssa1[2], ssa1[3]) ≈ 4.5, distance(ssa2[2], ssa2[3]) ≈ 4.5, ssa1[3] ≈ ssa2[3]
```