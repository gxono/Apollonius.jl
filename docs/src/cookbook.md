```@meta
CurrentModule = Apollonius
```

# Cookbook

Short recipes for things people ask of a geometry package: a goal, the call
that does it, and its result. Each block defines what it needs, so you can
copy one without reading the ones before it. The recipes point to the page
that explains the function in depth.

```@example geo
using Apollonius
```

## Points and segments

### The midpoint, or a point a fraction of the way along

```@example geo
A, B = APPoint(1.0, 2.0), APPoint(7.0, 5.0)
midpoint(A, B), A + 0.25 * (B - A)
```

The second form works for any fraction, including outside `[0, 1]`. On a
line, [`point_on_line`](@ref)`(l, t)` does the same with a parameter `t`.

### A point at a given distance and direction

```@example geo
O = APPoint(0.0, 0.0)
polar_point(4.0, pi / 3, O), polar_point_deg(4.0, 60.0, O)
```

### Divide a segment in the golden ratio, or find a harmonic conjugate

```@example geo
A, B = APPoint(0.0, 0.0), APPoint(10.0, 0.0)
golden_ratio_point(A, B), harmonic_conjugate(A, B, APPoint(2.0, 0.0))
```

### The distance from a point to a segment, a line or a polygon

```@example geo
p = APPoint(5.0, 4.0)
distance(p, APSegment(APPoint(0.0, 0.0), APPoint(3.0, 0.0))), distance(p, APLine(APPoint(0.0, 0.0), APPoint(1.0, 0.0)))
```

See [Measurements & Queries](@ref) for what `distance` means for each type.

## Lines

### The perpendicular from a point, and its foot

```@example geo
l = APLine(APPoint(0.0, 0.0), APPoint(4.0, 1.0))
p = APPoint(3.0, 4.0)
perp = perpendicular_through(l, p)
projection(p, l), is_perpendicular(perp, l)
```

### The parallel through a point, and a line shifted sideways

```@example geo
l = APLine(APPoint(0.0, 0.0), APPoint(4.0, 1.0))
par = parallel_through(l, APPoint(0.0, 3.0))
is_parallel(par, l), offset_line(l, 2.0)
```

```@raw html
<img src="../assets/img/cookbook/parallels.svg" alt="A line, the parallel through a point above it and a line shifted by a fixed distance" style="width:100%; max-width: 700px;">
```

### The perpendicular bisector of a segment

```@example geo
A, B = APPoint(0.0, 0.0), APPoint(6.0, 2.0)
m = perpendicular_bisector(A, B)
distance(A, m) ≈ distance(B, m), on_line(midpoint(A, B), m)
```

### Reflect a point in a line

```@example geo
l = APLine(APPoint(0.0, 0.0), APPoint(1.0, 1.0))
reflection(APPoint(3.0, 0.0), l)
```

### Where two lines meet, or whether they do

```@example geo
l1 = APLine(APPoint(0.0, 0.0), APPoint(4.0, 2.0))
l2 = APLine(APPoint(0.0, 3.0), APPoint(4.0, 1.0))
intersection(l1, l2), intersection(l1, offset_line(l1, 1.0))
```

The second is empty because the lines are parallel. See
[Intersections](@ref).

### Bisect an angle, or split it in three

```@example geo
O, P1, P2 = APPoint(0.0, 0.0), APPoint(4.0, 0.0), APPoint(0.0, 4.0)
ang = APAngle2(O, P1, P2)
first(angle_bisectors(ang)), length(angle_trisectors(ang))
```

The figure is in [Points, Lines & Rays](@ref).

## Circles

### The circle through three points

```@example geo
c = circumcircle(APTriangle(APPoint(0.0, 0.0), APPoint(6.0, 0.0), APPoint(1.5, 4.0)))
c.center, c.r
```

### A circle from its diameter, or from a center and a point on it

```@example geo
A, B = APPoint(0.0, 0.0), APPoint(6.0, 0.0)
by_diameter = APCircle2(midpoint(A, B), distance(A, B) / 2)
by_point = APCircle2(A, distance(A, APPoint(3.0, 4.0)))
by_diameter.r, by_point.r
```

### The tangent lines from a point to a circle

```@example geo
c = APCircle2(APPoint(0.0, 0.0), 3.0)
p = APPoint(7.0, 0.0)
tangent_points(c, p), tangent_length(c, p)
```

```@raw html
<img src="../assets/img/cookbook/tangent_from_point.svg" alt="A circle, an outside point, the two tangent segments and their points of contact" style="width:100%; max-width: 700px;">
```

### The common tangents of two circles

```@example geo
c1, c2 = APCircle2(APPoint(0.0, 0.0), 3.0), APCircle2(APPoint(10.0, 0.0), 1.5)
length(external_tangent_lines(c1, c2)), length(internal_tangent_lines(c1, c2))
```

The figure is in [Circles](@ref), under "Similitude centers and common
tangents".

### The radical axis of two circles

```@example geo
c1, c2 = APCircle2(APPoint(0.0, 0.0), 3.0), APCircle2(APPoint(4.0, 0.0), 2.0)
radical_axis(c1, c2)
```

The line through the two points where the circles cross, when they do.

### A circle orthogonal to another, through a point

```@example geo
c = APCircle2(APPoint(0.0, 0.0), 3.0)
o = orthogonal_circle(c, APPoint(7.0, 0.0))
intersection_angle(c, o) ≈ pi / 2
```

```@raw html
<img src="../assets/img/cookbook/orthogonal.svg" alt="A circle and a circle orthogonal to it through an outside point, crossing at right angles" style="width:100%; max-width: 700px;">
```

### The power of a point

```@example geo
power_of_point(APPoint(7.0, 0.0), APCircle2(APPoint(0.0, 0.0), 3.0))
```

Negative inside the circle, zero on it, and the square of the tangent length
outside.

### Invert a circle or a line

```@example geo
c = APCircle2(APPoint(3.0, 0.0), 1.0)
invert(c, APPoint(0.0, 0.0); k=2.0)
```

See [Circles](@ref) for the figures.

## Tangent circles

### The circle through two points tangent to a line

```@example geo
A, B = APPoint(0.0, 0.0), APPoint(4.0, 0.0)
l = APLine(APPoint(-3.0, 3.0), APPoint(8.0, 3.0))
sols = tangent_circles_through_points(A, B, l)
length(sols), all(c -> line_circle_position(l, c) == :tangent, sols)
```

### The circles tangent to three circles

```@example geo
c1, c2, c3 = APCircle2(APPoint(0.0, 0.0), 2.0), APCircle2(APPoint(6.0, 0.0), 1.5), APCircle2(APPoint(2.0, 5.0), 1.0)
length(tangent_circles(c1, c2, c3))
```

Up to eight solutions. The order is not fixed: choose with
[`nearest_point`](@ref) on the centers. See
[Tangency & Apollonius Problems](@ref).

### The circle tangent to two lines with a given radius

```@example geo
l1, l2 = APLine(APPoint(0.0, 0.0), APPoint(1.0, 0.0)), APLine(APPoint(0.0, 0.0), APPoint(0.0, 1.0))
tangent_circles_with_radius(l1, l2, 2.0)
```

### The circle tangent to a line at a point

```@example geo
l = APLine(APPoint(0.0, 0.0), APPoint(1.0, 0.0))
p = APPoint(2.0, 0.0)
tangent_circles_with_center(APPoint(2.0, 3.0), l)
```

## Triangles

### Build a triangle from a side and two angles

```@example geo
A, B = APPoint(0.0, 0.0), APPoint(6.0, 0.0)
t = triangle_on_segment(A, B, deg2rad(50), deg2rad(60))
rad2deg(angle_at(t[3], t[1], t[2]))
```

The same idea, with other data: [`triangle_on_segment_sas`](@ref) (an angle
and a side), [`triangle_on_segment_sss`](@ref) (three sides) and the named
ones such as [`equilateral_triangle_on_segment`](@ref). See
[Triangles & Triangle Centers](@ref).

### The classical centers, and the Euler line

```@example geo
t = APTriangle(APPoint(0.0, 0.0), APPoint(8.0, 0.0), APPoint(3.0, 6.0))
on_line(centroid(t), euler_line(t)), on_line(orthocenter(t), euler_line(t)), on_line(circumcenter(t), euler_line(t))
```

### The nine-point circle

```@example geo
t = APTriangle(APPoint(0.0, 0.0), APPoint(8.0, 0.0), APPoint(3.0, 6.0))
npc = nine_point_circle(t)
npc.r ≈ circumradius(t) / 2, all(p -> distance(p, npc.center) ≈ npc.r, vertices(medial_triangle(t)))
```

### The law of sines

```@example geo
t = APTriangle(APPoint(0.0, 0.0), APPoint(8.0, 0.0), APPoint(3.0, 6.0))
a = distance(t[2], t[3])
a / sin(angle_at(t[1], t[2], t[3])) ≈ 2 * circumradius(t)
```

### The inscribed square

```@example geo
t = APTriangle(APPoint(0.0, 0.0), APPoint(8.0, 0.0), APPoint(3.0, 6.0))
sq = square_inscribed(t, 3)
area(sq)
```

### A point in a triangle from barycentric coordinates

```@example geo
t = APTriangle(APPoint(0.0, 0.0), APPoint(8.0, 0.0), APPoint(3.0, 6.0))
barycentric_point(t, 1.0, 1.0, 1.0) ≈ centroid(t)
```

### The Simson line of a point on the circumcircle

```@example geo
t = APTriangle(APPoint(0.0, 0.0), APPoint(8.0, 0.0), APPoint(3.0, 6.0))
p = point_on_circle(circumcircle(t), 0.7)
sl = simson_line(t, p)
all(on_line(projection(p, APLine(s.p1, s.p2)), sl) for s in sides(t))
```

## Polygons

### A regular polygon

Give the center and one vertex:

```@example geo
hexagon = regular_polygon(APPoint(0.0, 0.0), APPoint(3.0, 0.0), 6)
pentagon = regular_polygon(APPoint(0.0, 0.0), APPoint(3.0, 0.0), 5)
length(vertices(hexagon)), area(hexagon), perimeter(pentagon)
```

```@raw html
<img src="../assets/img/cookbook/regular_polygons.svg" alt="A regular pentagon and hexagon inscribed in the same circle" style="width:100%; max-width: 700px;">
```

### A square or rectangle on a segment

```@example geo
A, B = APPoint(0.0, 0.0), APPoint(4.0, 0.0)
area(square_on_segment(A, B)), area(rectangle_on_segment(A, B, 2.0))
```

### The convex hull of some points

```@example geo
using Random
pts = rand(Xoshiro(3), APBoundingBox(APPoint(0.0, 0.0), APPoint(10.0, 6.0)), 30)
hull = convex_hull(pts)
length(hull), all(p -> point_in_polygon(p, APStraightNgon(hull)) || p in hull, pts)
```

```@raw html
<img src="../assets/img/cookbook/convex_hull.svg" alt="A cloud of random points and the polygon of their convex hull" style="width:100%; max-width: 700px;">
```

### The area, and whether a point is inside

```@example geo
pg = APStraightNgon([APPoint(0.0, 0.0), APPoint(4.0, 0.0), APPoint(4.0, 3.0), APPoint(1.0, 3.0)])
area(pg), point_in_polygon(APPoint(2.0, 1.0), pg), point_in_polygon(APPoint(5.0, 1.0), pg)
```

### The box around some objects

```@example geo
c = APCircle2(APPoint(0.0, 0.0), 2.0)
box = bbox_union(APBoundingBox(c), APBoundingBox(pg))
bbox_width(box), bbox_height(box)
```

## Two classical results

### The lune of Hippocrates

The two crescents cut from the semicircles on the legs of a right isosceles
triangle have together the area of the triangle:

```@example geo
A, B, C = APPoint(0.0, 0.0), APPoint(2.0, 0.0), APPoint(1.0, 1.0)
half(p, q) = area(APCircle2(midpoint(p, q), distance(p, q) / 2)) / 2   # a semicircle on [p, q]
lunes = half(A, C) + half(C, B) - (half(A, B) - area(APTriangle(A, B, C)))
lunes ≈ area(APTriangle(A, B, C))
```

```@raw html
<img src="../assets/img/cookbook/hippocrates.svg" alt="A right isosceles triangle inscribed in a semicircle, with semicircles on its legs" style="width:100%; max-width: 700px;">
```

### The Apollonius circle of two points

The points whose distances to `A` and `B` are in a fixed ratio lie on a
circle:

```@example geo
A, B = APPoint(0.0, 0.0), APPoint(6.0, 0.0)
c = apollonius_circle(A, B, 2.0)
p = point_on_circle(c, 1.2)
distance(p, A) / distance(p, B) ≈ 2.0
```

## Conics

### An ellipse from its foci

```@example geo
e = APEllipse2(APPoint(-3.0, 0.0), APPoint(3.0, 0.0), 5.0)
e.a, e.b, foci(e)
```

The last argument is the sum of the distances to the foci, which is `2a`.

### The tangent to a conic at a point, and from a point

```@example geo
e = APEllipse2(APPoint(0.0, 0.0), 5.0, 3.0)
p = point_on_ellipse(e, 1.0)
tangent_at(e, 1.0), length(tangent_lines(e, APPoint(8.0, 0.0)))
```

### A parabola from a focus and a directrix

```@example geo
par = APParabola2(APPoint(0.0, 1.0), APLine(APPoint(0.0, -1.0), APPoint(1.0, -1.0)))
p = point_on_parabola(par, 0.7)
distance(p, par.focus) ≈ distance(p, par.directrix)
```

### The conic through five points

```@example geo
pts = [APPoint(5.0, 0.0), APPoint(0.0, 3.0), APPoint(-5.0, 0.0), APPoint(0.0, -3.0), APPoint(3.0, 2.4)]
conic_through_points(pts...)
```

See [Conics: Ellipse, Parabola & Hyperbola](@ref).

## Moving things

### Rotate, scale or reflect a whole shape

```@example geo
t = APTriangle(APPoint(0.0, 0.0), APPoint(3.0, 0.0), APPoint(0.0, 4.0))
rotate(t, pi / 2, APPoint(0.0, 0.0)), homothety(t, 2.0, APPoint(0.0, 0.0)), reflection(t, APLine(APPoint(0.0, 0.0), APPoint(0.0, 1.0)))
```

Every type accepts these. See [Affine Maps](@ref).

### Apply several steps as one

```@example geo
m = rotation_map(pi / 2, APPoint(0.0, 0.0)) ∘ translation_map(APVector(3.0, 0.0))
m(APPoint(0.0, 0.0))
```

### A map from three points and their images

```@example geo
m = affine_map(APPoint(0.0, 0.0) => APPoint(1.0, 1.0), APPoint(1.0, 0.0) => APPoint(3.0, 1.0), APPoint(0.0, 1.0) => APPoint(1.0, 4.0))
m(APPoint(1.0, 1.0))
```

### Transform several objects with one macro

```@example geo
c = APCircle2(APPoint(1.0, 2.0), 3.0)
s = APSegment(APPoint(0.0, 0.0), APPoint(4.0, 0.0))
C2, S2 = @rotate (pi / 2) begin
    c
    s
end
C2
```

See [Transforming in Bulk: Macros](@ref).

## Checking

### Are these points on a circle? On a line?

```@example geo
a, b, c = APPoint(0.0, 0.0), APPoint(6.0, 0.0), APPoint(5.0, 4.0)
d = point_on_circle(circumcircle(APTriangle(a, b, c)), 2.0)
is_concyclic(a, b, c, d), is_collinear(a, b, c)
```

### Which side of a line, and is a point in a region?

```@example geo
l = APLine(APPoint(0.0, 0.0), APPoint(4.0, 2.0))
side_of_line(APPoint(1.0, 3.0), l), APPoint(1.0, 1.0) in APHalfPlane2(l, APPoint(1.0, 3.0))
```

See [Predicates](@ref).

## Drawing

### Fit a construction to a canvas

```julia
using Apollonius, Luxor

lxm, lxo = @to_luxor_picture width=500 margin=30 begin
    t
    circumcircle(t)
end
```

`lxm` holds the canvas size, and `lxo` the objects in canvas coordinates. See
[Workflow: From Construction to Figure](@ref).

### Put a label outside a vertex

```julia
G = centroid(lxo.t)
for (v, name) in zip(vertices(lxo.t), ("A", "B", "C"))
    label(name, label_anchor(v, G)...)
end
```

### Mark equal sides and right angles

```julia
path(marks(APSegment(A2, B2); count=2); action=:stroke)      # two ticks
path(marks(APAngle2(B2, A2, C2); style=:square); action=:stroke)
```

Marks, braces, arrowheads and their styles are in
[Marks, Labels & Decorations](@ref).

### Draw a curve that goes on forever

Infinite lines and conics have no size, so name them with
[`@unbounded`](@ref) inside the fitting block and draw them with `extend`:

```julia
lxm, lxo = @to_luxor_picture width=500 begin
    t
    @unbounded l = APLine(t[1], t[2])
end
path(lxo.l, action=:stroke, extend=200)
```
