```@meta
CurrentModule = EuclideanGeometry
```

# Triangles & Triangle Centers

[`EGTriangle`](@ref) is three points, indexed `t[1]`, `t[2]`, `t[3]` (its
own type, `<: EGPolygon` — see [EuclideanGeometry.jl](@ref) for the full hierarchy). This
page is organized the same way triangle geometry
usually is: the basic measurements, the four classical centers and how the
Euler line ties three of them together, the excircles, barycentric
coordinates, and then the (long) catalogue of further named centers and
derived triangles that classical triangle geometry has accumulated.

Throughout, the running example is the scalene triangle:

```@example geo
using EuclideanGeometry

A, B, C = EGPoint(0.0, 0.0), EGPoint(8.0, 0.0), EGPoint(3.0, 6.0)
t = EGTriangle(A, B, C)

area(t), perimeter(t), is_degenerate(t)
```

## The four classical centers, and the Euler line

| Function | Center | Defined as |
|:---------|:-------|:-----------|
| [`centroid`](@ref) | `G` | average of the three vertices |
| [`circumcenter`](@ref) | `O` | equidistant from the three vertices ([`circumcircle`](@ref) passes through them) |
| [`incenter`](@ref) | `I` | equidistant from the three sides ([`incircle`](@ref) touches them) |
| [`orthocenter`](@ref) | `H` | intersection of the three altitudes |

`G`, `O` and `H` are always collinear — that line is the
[`euler_line`](@ref) — and `G` divides `OH` in a fixed `1:2` ratio (`H = O +
3(G - O)`). `I` is *not* on the Euler line in general (it only coincides
with the others for an equilateral triangle).

```@example geo
G, O, I, H = centroid(t), circumcenter(t), incenter(t), orthocenter(t)
el = euler_line(t)
npc = nine_point_circle(t)
```

[`nine_point_circle`](@ref) passes through the three edge midpoints, the
three altitude feet, and the three midpoints of segment `[vertex, H]` (nine
points in total, though only the circle itself — not the nine points — is
what the function returns). Its center, [`nine_point_center`](@ref), is the
midpoint of `O` and `H`, and it always sits on the Euler line too — its
radius is exactly half the circumradius. [`euler_points`](@ref) returns
that last group of three (the midpoints of `[H, vertex]`) directly, for
when you need those specific points rather than just the circle.

```@example geo
euler_points(t)
```

Two more lines are naturally associated with this configuration:
[`orthic_axis`](@ref), the radical axis of the circumcircle and the
nine-point circle (always perpendicular to the Euler line), and
[`brocard_axis`](@ref), the line through `O` and the symmedian point —
whose polar line with respect to the circumcircle is, in turn, the
[`lemoine_axis`](@ref).

```@example geo
orthic_axis(t), brocard_axis(t), lemoine_axis(t)
```

## Excenters and excircles

Where the incircle is tangent to all three sides from *inside* the
triangle, each **excircle** is tangent to one side and to the
*extensions* of the other two, from outside. There are three of them, one
opposite each vertex — [`excenters`](@ref) and [`exradii`](@ref) return
all three as a named tuple `(A=..., B=..., C=...)`, and
[`excircles`](@ref) the actual circles.

```@example geo
ex = excenters(t)
exc = excircles(t)
```

## Barycentric coordinates

Every point of the plane can be written as a weighted average of the three
vertices, `p = αA + βB + γC` with `α+β+γ = 1` — these weights `(α,β,γ)`
are its **barycentric coordinates** with respect to `t`.
[`barycentric_point`](@ref) goes from coordinates to a point (weights don't
need to be normalized — they're rescaled internally);
[`barycentric_coordinates`](@ref) goes the other way.

```@example geo
barycentric_point(t, 1.0, 1.0, 1.0)     # (1:1:1) is always the centroid
barycentric_coordinates(t, centroid(t)) # (1/3, 1/3, 1/3)
```

Most of the named centers below have simple, well-known barycentric
coordinates (the incenter is `(a:b:c)` in the side lengths, for instance) —
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

Many named centers found in a reference like the *Encyclopedia of Triangle
Centers* are given as trilinears rather than barycentrics — [`kenmotu_point`](@ref)
below is one example — so having both conversions on hand avoids
rederiving one from the other by hand.

## Vertex-indexed lines

Four of the classical triangle lines — the altitude, median, and internal
and external angle bisectors — plus the perpendicular bisector of the
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
altitude(t, 1), median(t, 1)
```

```@example geo
on_line(orthocenter(t), altitude(t, 1)), on_line(centroid(t), median(t, 1))
```

The free function [`angle_trisectors`](@ref)`(vertex, p1, p2)` (see
[Angles](@ref) on the previous page) is what `trisector(t, i)` is built
from; use it directly when the two rays don't come from a triangle's own
vertices.

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
| On the circumcircle or Euler line | [`feuerbach_point`](@ref), [`feuerbach_points`](@ref), [`isodynamic_points`](@ref) |
| Brocard configuration | [`first_brocard_point`](@ref), [`second_brocard_point`](@ref), [`brocard_angle`](@ref), [`brocard_circle`](@ref), [`brocard_midpoint`](@ref) |
| Congruent-squares / conjugate-of-classical-center points | [`kenmotu_point`](@ref)/[`kenmotu_circle`](@ref), [`macbeath_point`](@ref) |
| A 4th point's common nine-point-circle point | [`poncelet_point`](@ref) |
| Pedal-type constructions | [`simson_line`](@ref), [`steiner_line`](@ref), [`orthopole`](@ref), [`pedal_triangle`](@ref) |
| Named auxiliary circles | [`conway_points`](@ref)/[`conway_circle`](@ref), [`taylor_points`](@ref)/[`taylor_circle`](@ref), [`first_lemoine_points`](@ref)/[`first_lemoine_circle`](@ref)/[`second_lemoine_circle`](@ref), [`van_lamoen_points`](@ref)/[`van_lamoen_circle`](@ref) |
| Mutually tangent circle systems | [`mixtilinear_incircle`](@ref), [`three_tangent_circles`](@ref)/[`soddy_circles`](@ref)/[`soddy_line`](@ref), [`thebault_circles`](@ref) |
| Apollonius circles of a triangle | [`three_apollonius_circles`](@ref) (one per vertex; their common points are the [`isodynamic_points`](@ref)) |
| Axis-like lines | [`fermat_axis`](@ref) (through [`fermat_point`](@ref) and [`second_fermat_point`](@ref)); see also [`orthic_axis`](@ref)/[`brocard_axis`](@ref)/[`lemoine_axis`](@ref) above and [`soddy_line`](@ref) |

All of these take the `EGTriangle` as their (only, or first) argument and
return an `EGPoint`, an `EGCircle2`, an `EGLine`, or — where there's naturally more
than one, like `soddy_circles` or `three_apollonius_circles` — a tuple or
named tuple. See the [API Reference](@ref) for exact signatures.

[`steiner_line`](@ref)`(t, p)` is closely related to [`simson_line`](@ref)`(t,
p)`: reflecting (rather than projecting) `p` across the three side-lines
gives three points that are collinear exactly when `p` is on the
circumcircle — and that Steiner line always passes through the orthocenter,
parallel to the Simson line of the same point.

```@example geo
brocard_midpoint(t)   # midpoint of the two Brocard points (Kimberling X(39))
kenmotu_point(t)       # X(371): common vertex of 3 congruent inscribed squares
macbeath_point(t)      # X(264): isotomic conjugate of the circumcenter
```

[`second_fermat_point`](@ref) is built exactly like [`fermat_point`](@ref)
but with the three equilateral triangles erected *inward* instead of
outward; [`fermat_axis`](@ref) is the line through both:

```@example geo
fermat_axis(t)   # EGLine(fermat_point(t), second_fermat_point(t))
```

[`poncelet_point`](@ref)`(t, p)` uses a striking fact about *any* 4 points
in general position (here, `t`'s 3 vertices plus a 4th, `p`): the
nine-point circles of the 4 triangles obtained by leaving out one point
each time always share a single common point.

```@example geo
poncelet_point(t, EGPoint(5.0, -2.0))
```

[`thebault_circles`](@ref) builds the two circles of the classical
**Sawayama–Thébault configuration**: given a point `p` on side `[t[2],
t[3]]`, each is tangent to the cevian `t[1] -> p`, to that side, and
internally tangent to the circumcircle — one nestled against `t[2]`, the
other against `t[3]`.

```@example geo
D = B + 0.4 * (C - B)   # a point on side [B, C]
th = thebault_circles(t, D)
```

Remarkably, no matter where `p` sits on the side, the incenter always lies
exactly on the segment joining the two circles' centers (the theorem the
construction is named for):

```@example geo
on_line(incenter(t), EGLine(th.near_b.center, th.near_c.center))
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
onto each of the two sides *not* used to define it — all 6 results are
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
homotheties of ratio `-1/2` and `-2` about the centroid — inverses of each
other. Applied to `t`'s own vertices they give the [`medial_triangle`](@ref)
and the anticomplementary triangle (see [Derived triangles](@ref))
respectively:

```@example geo
complement(t, A) ≈ midpoint(B, C)
```

[`kenmotu_circle`](@ref) is centered at the [`kenmotu_point`](@ref), with
radius `√2·a·b·c / (4·Area + a²+b²+c²)` — it passes through the 6 points
where the three congruent inscribed squares of the Kenmotu configuration
meet the sides.

```@example geo
kenmotu_circle(t)
```

[`feuerbach_points`](@ref) is the excircle analogue of
[`feuerbach_point`](@ref): the nine-point circle is not just internally
tangent to the incircle, it's also *externally* tangent to each of the
three excircles, at these three points.

```@example geo
feuerbach_points(t)
```

[`kiepert_hyperbola`](@ref) is the unique rectangular hyperbola through
`t`'s 3 vertices, its centroid and its orthocenter (built directly via
[`conic_through_points`](@ref) on those 5 points); [`kiepert_parabola`](@ref)
has focus Kimberling center X(110) and directrix the [`euler_line`](@ref)
(undefined for an isosceles triangle, where X(110) doesn't exist):

```@example geo
kiepert_hyperbola(t) isa EGHyperbola2
kiepert_parabola(t) isa EGParabola2
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

The circumellipse is always exactly the image of the inellipse under a
homothety of ratio `-2` about the centroid — the same ratio that relates a
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
| [`mandart_inellipse`](@ref) | [`mittenpunkt`](@ref) | — (fit through 5 points instead, see below) |
| [`orthic_inellipse`](@ref) | [`symmedian_point`](@ref) | — (acute triangles only) |

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

## Derived triangles

These take an `EGTriangle` and return another `EGTriangle` built from it:

| Function | Vertices are... |
|:---------|:-----------------|
| [`medial_triangle`](@ref) | the three edge midpoints |
| [`anticomplementary_triangle`](@ref) | `B+C-A`, `C+A-B`, `A+B-C` — the inverse of `medial_triangle` (`t` is *its* medial triangle) |
| [`orthic_triangle`](@ref) | the three altitude feet |
| [`reflection_triangle`](@ref) | each vertex reflected across its *opposite side line* (unlike `orthic_triangle`, which projects instead) |
| [`contact_triangle`](@ref) | the three points where the incircle touches the sides |
| [`extouch_triangle`](@ref) | the three points where the excircles touch the sides |
| [`excentral_triangle`](@ref) | the three excenters |
| [`tangential_triangle`](@ref) | tangents to the circumcircle at each vertex, pairwise intersected |
| [`napoleon_triangle`](@ref) | centers of equilateral triangles erected on each side ([`napoleon_point`](@ref) is its centroid — by Napoleon's theorem, always `t`'s own centroid too) |
| [`morley_triangle`](@ref) | intersections of adjacent angle trisectors |
| [`pedal_triangle`](@ref) | projections of a chosen point onto the three sides |
| [`cevian_triangle`](@ref) / [`circumcevian_triangle`](@ref) | feet of cevians through a chosen point (extended to the circumcircle, for the latter) |

```@example geo
mt = medial_triangle(t)
```

The medial triangle is always similar to `t` at half scale, sharing its
centroid — and its own circumcircle is exactly `t`'s nine-point circle.

## Inscribed squares

[`square_inscribed`](@ref)`(t, i)` builds the square with one side on the
side opposite `t[i]` and its other two vertices exactly on the two sides
through `t[i]` — returned as an [`EGQuadrilateral`](@ref). There are 3 such
squares (one per side, hence the vertex index):

```@example geo
sq = square_inscribed(t, 1)
distance(sq[1], sq[2]), distance(sq[2], sq[3])   # equal: it really is a square
```

Its side length is `a*h / (a+h)` (`a` the base length, `h` the
corresponding height) regardless of how oblique the triangle is — a
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

```@example geo
p1, p2 = EGPoint(0.0, 0.0), EGPoint(6.0, 0.0)
golden_triangle_on_segment(p1, p2)   # apex angle 36°, both base angles 72°
```

```@example geo
egyptian_triangle_on_segment(p1, p2)   # legs 4:3 (here 6:4.5), hypotenuse 5 (here 7.5)
```
