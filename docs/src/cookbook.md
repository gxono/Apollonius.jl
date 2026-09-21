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

## Working with points and segments

### The midpoint, or a point a fraction of the way along

```@example geo
A, B = APPoint(1.0, 2.0), APPoint(7.0, 5.0)
s = APSegment(A, B)
midpoint(s), point_on_line(s, 0.25)
```

```@raw html
<img src="../assets/img/cookbook/midpoint_fraction.svg" alt="A segment with its midpoint and the point a quarter of the way from A" style="width:100%; max-width: 700px;">
```

[`point_on_line`](@ref)`(s, t)` takes a fraction of the way from the first end to the
second. It works on a line, a segment or a ray, and `t` can leave `[0, 1]` to go
past the ends.

### A point at a given distance and direction

```@example geo
polar_point(4.0, pi / 3), polar_point_deg(4.0, 60.0), polar_point_deg(4.0, 60.0, APPoint(1.0, 1.0))
```

```@raw html
<img src="../assets/img/points_lines/polar.svg" alt="A point at distance 4 and angle 40 degrees from a center" style="width:100%; max-width: 700px;">
```

### Divide a segment in the golden ratio, or find a harmonic conjugate

```@example geo
A, B = APPoint(0.0, 0.0), APPoint(10.0, 0.0)
golden_ratio_point(A, B), harmonic_conjugate(A, B, APPoint(2.0, 0.0))
```

```@raw html
<img src="../assets/img/points_lines/harmonic.svg" alt="Two points, a third between them, its harmonic conjugate and the golden ratio point" style="width:100%; max-width: 700px;">
```

### The distance from a point to a segment, a line or a polygon

```@example geo
p = APPoint(5.0, 4.0)
distance(p, APSegment(APPoint(0.0, 0.0), APPoint(3.0, 0.0))), distance(p, APLine(APPoint(0.0, 0.0), APPoint(1.0, 0.0)))
```

```@raw html
<img src="../assets/img/points_lines/distance_curves.svg" alt="The distance from a point to a line, a segment and a ray" style="width:100%; max-width: 700px;">
```

See [Measurements & Queries](@ref) for what `distance` means for each type.

## Working with lines

### The perpendicular from a point, and its foot

```@example geo
l = APLine(APPoint(0.0, 0.0), APPoint(4.0, 1.0))
p = APPoint(3.0, 4.0)
perp = perpendicular_through(l, p)
projection(p, l), is_perpendicular(perp, l)
```

```@raw html
<img src="../assets/img/cookbook/perpendicular_foot.svg" alt="A line, a point off it, the perpendicular from the point and its foot" style="width:100%; max-width: 700px;">
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

```@raw html
<img src="../assets/img/cookbook/perp_bisector.svg" alt="A segment, its perpendicular bisector and a point on it equally far from both ends" style="width:100%; max-width: 700px;">
```

### Reflect a point in a line

```@example geo
l = APLine(APPoint(0.0, 0.0), APPoint(1.0, 1.0))
reflection(APPoint(3.0, 0.0), l)
```

```@raw html
<img src="../assets/img/cookbook/reflect_point.svg" alt="A point, a line and the mirror image of the point across it" style="width:100%; max-width: 700px;">
```

### Where two lines meet, or whether they do

```@example geo
l1 = APLine(APPoint(0.0, 0.0), APPoint(4.0, 2.0))
l2 = APLine(APPoint(0.0, 3.0), APPoint(4.0, 1.0))
intersection(l1, l2), intersection(l1, offset_line(l1, 1.0))
```

```@raw html
<img src="../assets/img/cookbook/lines_meet.svg" alt="Two lines that cross at a point, and a parallel to one of them that does not meet it" style="width:100%; max-width: 700px;">
```

The second is empty because the lines are parallel. See
[Intersections](@ref).

### Bisect an angle, or split it in three

```@example geo
O, P1, P2 = APPoint(0.0, 0.0), APPoint(4.0, 0.0), APPoint(0.0, 4.0)
ang = APAngle2(O, P1, P2)
first(angle_bisectors(ang)), length(angle_trisectors(ang))
```

```@raw html
<img src="../assets/img/points_lines/angle_split.svg" alt="A right angle with its two trisectors and its bisector" style="width:100%; max-width: 700px;">
```

## Working with circles

### The circle through three points

```@example geo
c = APCircle2(APPoint(0.0, 0.0), APPoint(6.0, 0.0), APPoint(1.5, 4.0))
c.center, c.r
```

```@raw html
<img src="../assets/img/circles/circle_3p.svg" alt="Three points and the circle through them" style="width:100%; max-width: 700px;">
```

### A circle from its diameter, or from a center and a point on it

```@example geo
A, B = APPoint(0.0, 0.0), APPoint(6.0, 0.0)
by_diameter = circle_with_diameter(A, B)      # or circle_with_diameter(APSegment(A, B))
by_point = APCircle2(A, APPoint(3.0, 4.0))     # center A, through the second point
by_diameter.r, by_point.r
```

```@raw html
<img src="../assets/img/circles/circle_diameter.svg" alt="A segment, the circle that has it as a diameter, and a point of the circle that sees the segment under a right angle" style="width:100%; max-width: 700px;">
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

```@raw html
<img src="../assets/img/circles/similitude_center.svg" alt="Two circles with their external and internal common tangents" style="width:100%; max-width: 700px;">
```

### The radical axis of two circles

```@example geo
c1, c2 = APCircle2(APPoint(0.0, 0.0), 3.0), APCircle2(APPoint(4.0, 0.0), 2.0)
radical_axis(c1, c2)
```

```@raw html
<img src="../assets/img/circles/circle_radical.svg" alt="Two circles and their radical axis" style="width:100%; max-width: 700px;">
```

The line through the two points where the circles cross, when they do.

### A circle orthogonal to another, with a given center

```@example geo
c = APCircle2(APPoint(0.0, 0.0), 3.0)
o = orthogonal_circle(c, APPoint(7.0, 0.0))
o.center, angle_measure_intersection(c, o) ≈ pi / 2
```

```@raw html
<img src="../assets/img/cookbook/orthogonal.svg" alt="A circle and the circle orthogonal to it centered at an outside point, crossing at right angles" style="width:100%; max-width: 700px;">
```

### The power of a point

```@example geo
power_of_point(APPoint(7.0, 0.0), APCircle2(APPoint(0.0, 0.0), 3.0))
```

```@raw html
<img src="../assets/img/circles/circle_tanp.svg" alt="A circle, a point outside it and the tangent segments from the point" style="width:100%; max-width: 700px;">
```

Negative inside the circle, zero on it, and the square of the tangent length
outside.

### Invert a circle or a line

```@example geo
c = APCircle2(APPoint(3.0, 0.0), 1.0)
invert(c, APPoint(0.0, 0.0); k=2.0)
```

```@raw html
<img src="../assets/img/macros/invert.svg" alt="A line and a circle inverted with respect to a circle centered at the origin" style="width:100%; max-width: 700px;">
```

See [Circles](@ref) for inverting lines, segments and polygons too.

## Working with tangent circles

### The circle through two points tangent to a line

```@example geo
A, B = APPoint(0.0, 0.0), APPoint(4.0, 1.0)
l = APLine(APPoint(-3.0, 3.0), APPoint(8.0, 3.0))
sols = tangent_circles_through_points(A, B, l)
length(sols), all(c -> line_circle_position(l, c) == :tangent, sols)
```

```@raw html
<img src="../assets/img/tangency/ppl.svg" alt="Two points, a line, and the circles through the points tangent to the line" style="width:100%; max-width: 700px;">
```

### The circle through a point tangent to two lines

```@example geo
l1, l2 = APLine(APPoint(0.0, 0.0), APPoint(1.0, 0.0)), APLine(APPoint(0.0, 0.0), APPoint(0.0, 1.0))
sols = tangent_circles_through_point(l1, l2, APPoint(3.0, 1.0))
length(sols), all(c -> line_circle_position(l1, c) == :tangent, sols)
```

```@raw html
<img src="../assets/img/cookbook/tangent_two_lines_point.svg" alt="Two lines, a point, and the two circles through the point tangent to both lines" style="width:100%; max-width: 700px;">
```

### The circles tangent to three circles

```@example geo
c1, c2, c3 = APCircle2(APPoint(0.0, 0.0), 2.0), APCircle2(APPoint(6.0, 0.0), 1.5), APCircle2(APPoint(2.0, 5.0), 1.0)
length(tangent_circles(c1, c2, c3))
```

```@raw html
<img src="../assets/img/tangency/ccc.svg" alt="Three circles and the circles tangent to all of them" style="width:100%; max-width: 700px;">
```

Up to eight solutions. The order is not fixed: choose with
[`nearest_point`](@ref) on the centers. See
[Tangency & Apollonius Problems](@ref).

### The circle tangent to two lines with a given radius

```@example geo
l1, l2 = APLine(APPoint(0.0, 0.0), APPoint(1.0, 0.0)), APLine(APPoint(0.0, 0.0), APPoint(0.0, 1.0))
tangent_circles_with_radius(l1, l2, 2.0)
```

```@raw html
<img src="../assets/img/cookbook/tangent_radius.svg" alt="Two perpendicular lines and the four circles of radius 2 tangent to both" style="width:100%; max-width: 700px;">
```

### The circle with a given center tangent to a line

```@example geo
l = APLine(APPoint(0.0, 0.0), APPoint(1.0, 0.0))
tangent_circles_with_center(APPoint(2.0, 3.0), l)
```

```@raw html
<img src="../assets/img/tangency/center_fixed.svg" alt="A circle with a fixed center tangent to a line" style="width:100%; max-width: 700px;">
```

### The second point where a line meets a circle

When you already know one of the points, `other_intersection` gives the
other, or `nothing` if the line is tangent there:

```@example geo
c = APCircle2(APPoint(0.0, 0.0), 5.0)
l = APLine(APPoint(-5.0, 0.0), APPoint(0.0, 3.0))
other_intersection(l, c, APPoint(-5.0, 0.0))
```

```@raw html
<img src="../assets/img/circles/intersection_choice.svg" alt="Choosing the second point where a line meets a circle" style="width:100%; max-width: 700px;">
```

### Circles that touch each other in a ring

The three circles centered at the vertices of a triangle that touch pairwise
at the points where the incircle touches the sides:

```@example geo
t = APTriangle(APPoint(0.0, 0.0), APPoint(8.0, 0.0), APPoint(3.0, 6.0))
ring = three_tangent_circles(t)
circles_position(ring[1], ring[2]), circles_position(ring[2], ring[3])
```

```@raw html
<img src="../assets/img/triangles/three_tangent.svg" alt="Three pairwise tangent circles centered at the vertices" style="width:100%; max-width: 700px;">
```

## Working with triangles

### Build a triangle from a side and two angles

```@example geo
A, B = APPoint(0.0, 0.0), APPoint(6.0, 0.0)
t = triangle_on_segment(A, B, deg2rad(50), deg2rad(60))
rad2deg(angle_measure_at(t[3], t[1], t[2]))
```

```@raw html
<img src="../assets/img/cookbook/asa_triangle.svg" alt="A triangle built on a base from the angles 50 and 60 degrees at its ends" style="width:100%; max-width: 700px;">
```

The same idea, with other data: [`triangle_on_segment_sas`](@ref) (an angle
and a side), [`triangle_on_segment_sss`](@ref) (three sides) and the named
ones such as [`equilateral_triangle_on_segment`](@ref). See
[Triangles & Triangle Centers](@ref).

### An equilateral triangle on a segment, or a square

```@example geo
A, B = APPoint(0.0, 0.0), APPoint(4.0, 0.0)
eq = equilateral_triangle_on_segment(A, B)
distance(eq[3], A) ≈ 4.0, distance(eq[3], B) ≈ 4.0
```

```@raw html
<img src="../assets/img/triangles/tronseg_eq.svg" alt="An equilateral triangle on a segment" style="width:100%; max-width: 700px;">
```

Pass `ccw=false` for the other side of the segment.

### The classical centers, and the Euler line

```@example geo
t = APTriangle(APPoint(0.0, 0.0), APPoint(8.0, 0.0), APPoint(3.0, 6.0))
on_line(centroid(t), euler_line(t)), on_line(orthocenter(t), euler_line(t)), on_line(circumcenter(t), euler_line(t))
```

```@raw html
<img src="../assets/img/triangles/tri_cen.svg" alt="A triangle with its centroid, circumcenter, orthocenter and the Euler line" style="width:100%; max-width: 700px;">
```

### The nine-point circle

```@example geo
t = APTriangle(APPoint(0.0, 0.0), APPoint(8.0, 0.0), APPoint(3.0, 6.0))
npc = nine_point_circle(t)
npc ≈ circumcircle(medial_triangle(t)), npc.r ≈ circumradius(t) / 2
```

```@raw html
<img src="../assets/img/cookbook/nine_point.svg" alt="A triangle and its nine-point circle through the midpoints, the feet of the altitudes and the Euler points" style="width:100%; max-width: 700px;">
```

### The law of sines

```@example geo
t = APTriangle(APPoint(0.0, 0.0), APPoint(8.0, 0.0), APPoint(3.0, 6.0))
a = distance(t[2], t[3])
a / sin(angle_measure_at(t[1], t[2], t[3])) ≈ 2 * circumradius(t)
```

```@raw html
<img src="../assets/img/cookbook/law_sines.svg" alt="A triangle with its circumcircle, the angle at A, the side a and the circumradius R" style="width:100%; max-width: 700px;">
```

### The inscribed square

```@example geo
t = APTriangle(APPoint(0.0, 0.0), APPoint(8.0, 0.0), APPoint(3.0, 6.0))
sq = square_inscribed(t, 3)
area(sq)
```

```@raw html
<img src="../assets/img/triangles/inscribed_squares.svg" alt="The three squares inscribed in a triangle" style="width:100%; max-width: 700px;">
```

### A point in a triangle from barycentric coordinates

```@example geo
t = APTriangle(APPoint(0.0, 0.0), APPoint(8.0, 0.0), APPoint(3.0, 6.0))
barycentric_point(t, 1.0, 1.0, 1.0) ≈ centroid(t)
```

```@raw html
<img src="../assets/img/triangles/barycenter.svg" alt="A point of a triangle given by its barycentric coordinates" style="width:100%; max-width: 700px;">
```

### Napoleon's theorem

The centers of the equilateral triangles built outward on the sides form an
equilateral triangle:

```@example geo
t = APTriangle(APPoint(0.0, 0.0), APPoint(8.0, 0.0), APPoint(3.0, 6.0))
n = napoleon_triangle(t)
distance(n[1], n[2]) ≈ distance(n[2], n[3]) ≈ distance(n[3], n[1])
```

```@raw html
<img src="../assets/img/triangles/derived_equilateral.svg" alt="The Napoleon and Morley triangles, both equilateral" style="width:100%; max-width: 700px;">
```

### The Simson line of a point on the circumcircle

```@example geo
t = APTriangle(APPoint(0.0, 0.0), APPoint(8.0, 0.0), APPoint(3.0, 6.0))
p = point_on_circle(circumcircle(t), 0.7)
sl = simson_line(t, p)
all(on_line(f, sl) for f in vertices(pedal_triangle(t, p)))   # the feet of the perpendiculars
```

```@raw html
<img src="../assets/img/triangles/simson_steiner.svg" alt="The Simson and Steiner lines of a point on the circumcircle" style="width:100%; max-width: 700px;">
```

## Working with polygons

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

```@raw html
<img src="../assets/img/cookbook/on_segment_shapes.svg" alt="A regular triangle, a square and a rectangle built on segments" style="width:100%; max-width: 700px;">
```

### The convex hull of some points

```@example geo
using Random
box = APBoundingBox(APPoint(0.0, 0.0), APPoint(10.0, 6.0))
pts = [rand_inside(Xoshiro(k), box) for k in 1:30]
hull = convex_hull(pts)
length(vertices(hull)), is_convex(hull)
```

```@raw html
<img src="../assets/img/cookbook/convex_hull.svg" alt="A cloud of random points and the polygon of their convex hull" style="width:100%; max-width: 700px;">
```

### The area, and whether a point is inside

```@example geo
pg = APStraightNgon([APPoint(0.0, 0.0), APPoint(4.0, 0.0), APPoint(4.0, 3.0), APPoint(1.0, 3.0)])
area(pg), APPoint(2.0, 1.0) in pg, APPoint(5.0, 1.0) in pg
```

```@raw html
<img src="../assets/img/polygons/containment.svg" alt="A polygon with the points inside it in purple and those outside in gray" style="width:100%; max-width: 700px;">
```

### The box around some objects

```@example geo
c = APCircle2(APPoint(0.0, 0.0), 2.0)
box = bbox_union(APBoundingBox(c), APBoundingBox(pg))
bbox_width(box), bbox_height(box)
```

```@raw html
<img src="../assets/img/macros/boundingbox.svg" alt="A triangle and a circle with the dashed bounding box around both" style="width:100%; max-width: 700px;">
```

### Random points inside a shape

```@example geo
using Random
c = APCircle2(APPoint(0.0, 0.0), 3.0)
pts = [rand_inside(Xoshiro(k), c) for k in 1:5]
all(p -> distance(p, c.center) <= c.r, pts)
```

```@raw html
<img src="../assets/img/points_lines/random_disk.svg" alt="Random points on a circle and inside it" style="width:100%; max-width: 700px;">
```

`rand(rng, shape)` gives points on the boundary instead. See
[Points, Lines & Rays](@ref).

## Two classical results

### The lune of Hippocrates

The two crescents cut from the semicircles on the legs of a right isosceles
triangle have together the area of the triangle:

```@example geo
A, B, C = APPoint(0.0, 0.0), APPoint(2.0, 0.0), APPoint(1.0, 1.0)
half(p, q) = area(circle_with_diameter(p, q)) / 2   # a semicircle on [p, q]
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

```@raw html
<img src="../assets/img/points_lines/ap_circ.svg" alt="The Apollonius circle of two points" style="width:100%; max-width: 700px;">
```

## Working with conics

### An ellipse from its foci

```@example geo
e = APEllipse2(APPoint(-3.0, 0.0), APPoint(3.0, 0.0), 5.0)
e.a, e.b, foci(e)
```

```@raw html
<img src="../assets/img/conics/ellipse_foci.svg" alt="An ellipse with its foci and the two focal distances of a point" style="width:100%; max-width: 700px;">
```

The last argument is the semi-major axis `a`, so the sum of the distances from a point of the ellipse to the two foci is `2a`.

### The tangent to a conic at a point, and from a point

The polar of a point on a conic is its tangent there, and the tangents from
an outside point are two:

```@example geo
e = APEllipse2(APPoint(0.0, 0.0), 5.0, 3.0)
p = point_on_ellipse(e, 1.0)
at_p = polar_line(e, p)
on_line(p, at_p), length(tangent_lines(e, APPoint(8.0, 0.0)))
```

```@raw html
<img src="../assets/img/conics/tangents.svg" alt="An ellipse with a tangent at a point and the two tangents from an outside point" style="width:100%; max-width: 700px;">
```

### A parabola from a focus and a directrix

```@example geo
par = APParabola2(APPoint(0.0, 1.0), APLine(APPoint(0.0, -1.0), APPoint(1.0, -1.0)))
p = point_on_parabola(par, 0.7)
distance(p, par.focus) ≈ distance(p, par.directrix)
```

```@raw html
<img src="../assets/img/conics/parabola.svg" alt="A parabola with its focus, directrix and the equal distances of a point" style="width:100%; max-width: 700px;">
```

### The conic through five points

```@example geo
pts = [APPoint(5.0, 0.0), APPoint(0.0, 3.0), APPoint(-5.0, 0.0), APPoint(0.0, -3.0), APPoint(3.0, 2.4)]
conic_through_points(pts...)
```

```@raw html
<img src="../assets/img/conics/fit.svg" alt="A conic through five points" style="width:100%; max-width: 700px;">
```

See [Conics: Ellipse, Parabola & Hyperbola](@ref).

## Building shapes from what you have

### A line, a ray or a segment from a point and a direction

```@example geo
p = APPoint(1.0, 1.0)
APLine(p, APVector(2.0, 1.0)), APRay(p, pi / 2), APSegment(p, 5.0, pi / 3)
```

```@raw html
<img src="../assets/img/points_lines/from_direction.svg" alt="A line from a point and a vector, a ray from a point and an angle and a segment from a point, a length and an angle" style="width:100%; max-width: 700px;">
```

### Cut a segment in equal parts, or in a ratio

```@example geo
s = APSegment(APPoint(0.0, 0.0), APPoint(8.0, 0.0))
divide_segment(s, 4), divide_segment(s, 1, 2), point_at_distance(s, 6.5)
```

```@raw html
<img src="../assets/img/points_lines/divide_points.svg" alt="A segment with its three quarter points, the point that divides it 1 to 2 and the point at distance 6.5" style="width:100%; max-width: 700px;">
```

### Points spread evenly on a circle, an arc or a segment

```@example geo
equally_spaced_points(APCircle2(APPoint(0.0, 0.0), 2.0), 6)
```

### An angle of a given measure, or between two lines

```@example geo
a60 = angle_with_measure(APPoint(0.0, 0.0), APPoint(4.0, 0.0), pi / 3)
rad2deg(measure(a60)), rad2deg(measure(APAngle2(APLine(APPoint(0.0, 0.0), APPoint(1.0, 0.0)), APLine(APPoint(0.0, 0.0), APPoint(1.0, 1.0)))))
```

```@raw html
<img src="../assets/img/points_lines/angle_from_measure.svg" alt="An angle of 60 degrees built from a ray and a measure, and the angle between two crossing lines" style="width:100%; max-width: 700px;">
```

### The tangent and the normal at a point of a curve

```@example geo
e = APEllipse2(APPoint(0.0, 0.0), 5.0, 3.0)
pt = point_on_ellipse(e, 1.0)
on_line(pt, tangent_line(e, pt)), is_perpendicular(tangent_line(e, pt), normal_line(e, pt))
```

```@raw html
<img src="../assets/img/conics/tangents.svg" alt="An ellipse with a tangent at a point and the two tangents from an outside point" style="width:100%; max-width: 700px;">
```

### A regular polygon on a side, and a star

```@example geo
a, b = APPoint(0.0, 0.0), APPoint(3.0, 0.0)
area(regular_polygon_on_segment(a, b, 5)), length(vertices(star_polygon(APPoint(0.0, 0.0), APPoint(3.0, 0.0), 5, 2)))
```

```@raw html
<img src="../assets/img/polygons/on_segment_family.svg" alt="A regular pentagon, hexagon and triangle built on segments, and a pentagram" style="width:100%; max-width: 700px;">
```

### A rhombus, a rectangle, a trapezoid or a kite

```@example geo
a, b = APPoint(0.0, 0.0), APPoint(4.0, 0.0)
area(rhombus_on_segment(a, b, pi / 3)), area(rectangle_from_diagonal(a, APPoint(4.0, 3.0), 0.5)), area(isosceles_trapezoid_on_segment(a, b, 2.0, 2.5)), area(kite_on_diagonal(a, APPoint(0.0, 4.0), 0.6, 1.5))
```

```@raw html
<img src="../assets/img/polygons/quad_family.svg" alt="A rhombus, a square, a rectangle, an isosceles trapezoid, a right trapezoid, a kite and a turned rectangle" style="width:100%; max-width: 700px;">
```

### A circle inside or around a quadrilateral

```@example geo
trap = isosceles_trapezoid_on_segment(APPoint(0.0, 0.0), APPoint(6.0, 0.0), 2.0, 3.0)
kite = kite_on_diagonal(APPoint(0.0, 0.0), APPoint(0.0, 7.0), 0.35, 2.0)
circumcircle(trap).r, incircle(kite).r
```

```@raw html
<img src="../assets/img/polygons/quad_circles.svg" alt="An isosceles trapezoid with its circumcircle and a kite with its incircle" style="width:100%; max-width: 700px;">
```

### Round the corners of a polygon or a polyline

```@example geo
sq = APStraightNgon([APPoint(0.0, 0.0), APPoint(4.0, 0.0), APPoint(4.0, 4.0), APPoint(0.0, 4.0)])
rounded = round_corners(sq, 1.0)
length(sides(rounded)), area(rounded)
```

```@raw html
<img src="../assets/img/circles/round_corners.svg" alt="A pentagon and a polyline with their corners rounded, the originals dashed" style="width:100%; max-width: 700px;">
```

### Move a polygon outward or inward, or grow a box

```@example geo
area(offset_polygon(sq, 1.0)), area(offset_polygon(sq, -1.0)), inflate(APBoundingBox(APPoint(0.0, 0.0), 4.0, 2.0), 1.0)
```

```@raw html
<img src="../assets/img/polygons/offset_box.svg" alt="A pentagon with its outward and inward offsets, and a box with its inflated box" style="width:100%; max-width: 700px;">
```

### An arc through three points, or with a given radius

```@example geo
arc_through_points(APPoint(0.0, 0.0), APPoint(2.0, 1.5), APPoint(4.0, 0.0)), arc_with_radius(APPoint(7.0, 0.0), APPoint(10.0, 0.0), 2.0)
```

```@raw html
<img src="../assets/img/circles/arcs_from_data.svg" alt="An arc through three points, and the short and the long arc of radius 2 between two points" style="width:100%; max-width: 700px;">
```

### A circle tangent to a line at a given point

```@example geo
l = APLine(APPoint(-3.0, 0.0), APPoint(9.0, 0.0))
tangent_circle_at_point(l, APPoint(2.0, 0.0), APPoint(0.0, 2.0)), length(tangent_circles_at_point(l, APPoint(2.0, 0.0), 1.2))
```

```@raw html
<img src="../assets/img/tangency/tangent_at_point.svg" alt="A line, a point on it and a point off it, the circle tangent at the first through the second, and the two circles of radius 1.2 tangent at the first" style="width:100%; max-width: 700px;">
```

### A triangle around a circle

```@example geo
c = APCircle2(APPoint(0.0, 0.0), 1.0)
t = circumscribed_triangle(c, point_on_circle(c, 0.5), point_on_circle(c, 2.5), point_on_circle(c, 4.5))
isapprox(incircle(t), c; atol=1e-9)
```

```@raw html
<img src="../assets/img/triangles/circumscribed.svg" alt="A circle with three points on it and the triangle whose sides touch the circle at them" style="width:100%; max-width: 700px;">
```

### A conic from a focus and a directrix

```@example geo
F, d = APPoint(0.0, 0.0), APLine(APPoint(4.0, -1.0), APPoint(4.0, 1.0))
typeof(conic_with_focus(F, d, 0.5)), typeof(conic_with_focus(F, d, 1.0)), typeof(conic_with_focus(F, d, 2.0))
```

```@raw html
<img src="../assets/img/conics/focus_directrix.svg" alt="An ellipse, a parabola and a hyperbola with the same focus and directrix" style="width:100%; max-width: 700px;">
```

### An ellipse from a center, a vertex and a point

```@example geo
el = ellipse_with_axis(APPoint(0.0, 0.0), APPoint(5.0, 0.0), APPoint(3.0, 2.4))
el.a, el.b
```

```@raw html
<img src="../assets/img/conics/ellipse_axis.svg" alt="An ellipse built from its center, one vertex and a point on it" style="width:100%; max-width: 700px;">
```

### A hyperbola from its asymptotes

```@example geo
hy = hyperbola_with_asymptotes(APLine(APPoint(0.0, 0.0), APPoint(1.0, 1.0)), APLine(APPoint(0.0, 0.0), APPoint(1.0, -1.0)), APPoint(2.0, 0.0))
hy.a, hy.b
```

```@raw html
<img src="../assets/img/conics/asymptotes_ctor.svg" alt="A hyperbola built from its two asymptotes and a point on it" style="width:100%; max-width: 700px;">
```

### A parabola through three points

```@example geo
pa = parabola_through_points(APPoint(-2.0, 4.0), APPoint(0.0, 0.0), APPoint(1.0, 1.0), APVector(0.0, 1.0))
pa.focus
```

```@raw html
<img src="../assets/img/conics/parabola_ctor.svg" alt="A parabola through three points with a vertical axis" style="width:100%; max-width: 700px;">
```

### A similarity from two points and their images

```@example geo
m = similarity_map(APPoint(0.0, 0.0) => APPoint(1.0, 1.0), APPoint(1.0, 0.0) => APPoint(1.0, 2.0))
m(APPoint(0.0, 1.0)), scaling_map(2.0, 0.5)(APPoint(1.0, 1.0)), shear_map(1.0)(APPoint(0.0, 2.0))
```

```@raw html
<img src="../assets/img/affine/similarity_shear.svg" alt="A square and its images under a similarity, a scaling and a shear" style="width:100%; max-width: 700px;">
```


## Moving things

### Rotate, scale or reflect a whole shape

```@example geo
t = APTriangle(APPoint(0.0, 0.0), APPoint(3.0, 0.0), APPoint(0.0, 4.0))
O = APPoint(0.0, 0.0)
isapprox(rotate(t, pi / 2), APTriangle(O, APPoint(0.0, 3.0), APPoint(-4.0, 0.0)); atol=1e-9), area(homothety(t, 2.0)) ≈ 4 * area(t), reflection(t, APLine(O, APPoint(0.0, 1.0))) ≈ APTriangle(O, APPoint(-3.0, 0.0), APPoint(0.0, 4.0))
```

```@raw html
<img src="../assets/img/macros/rotate.svg" alt="A triangle and a circle rotated a quarter turn about a point" style="width:100%; max-width: 700px;">
```

Every type accepts these. `rotate` and `homothety` turn and scale about the origin
unless you give a center as the last argument, as in `rotate(t, pi / 2, c)`. See
[Affine Maps](@ref).

### Apply several steps as one

```@example geo
m = rotation_map(pi / 2, APPoint(0.0, 0.0)) ∘ translation_map(APVector(3.0, 0.0))
isapprox(m(APPoint(0.0, 0.0)), APPoint(0.0, 3.0); atol=1e-9)
```

```@raw html
<img src="../assets/img/affine/composed.svg" alt="A triangle, its translation and the composition of the translation and a rotation" style="width:100%; max-width: 700px;">
```

### A map from three points and their images

```@example geo
m = affine_map(APPoint(0.0, 0.0) => APPoint(1.0, 1.0), APPoint(1.0, 0.0) => APPoint(3.0, 1.0), APPoint(0.0, 1.0) => APPoint(1.0, 4.0))
m(APPoint(1.0, 1.0))
```

```@raw html
<img src="../assets/img/affine/create.svg" alt="A triangle and its image under the affine map defined by three point pairs" style="width:100%; max-width: 700px;">
```

### Transform several objects with one macro

```@example geo
c = APCircle2(APPoint(1.0, 2.0), 3.0)
s = APSegment(APPoint(0.0, 0.0), APPoint(4.0, 0.0))
C2, S2 = @rotate (pi / 2) begin
    c
    s
end
C2.r, C2.center ≈ APPoint(-2.0, 1.0)
```

```@raw html
<img src="../assets/img/cookbook/macro_rotate.svg" alt="A circle and a segment with their images rotated a quarter turn about the origin" style="width:100%; max-width: 700px;">
```

See [Transforming in Bulk: Macros](@ref).

## Checking recipes

### Are these points on a circle? On a line?

```@example geo
a, b, c = APPoint(0.0, 0.0), APPoint(6.0, 0.0), APPoint(5.0, 4.0)
d = point_on_circle(circumcircle(APTriangle(a, b, c)), 2.0)
is_concyclic(a, b, c, d), is_collinear(a, b, c)
```

```@raw html
<img src="../assets/img/predicates/concyclic.svg" alt="Three points, their circumcircle dashed, a fourth point on it in purple and a fifth point off it in gray" style="width:100%; max-width: 700px;">
```

### Which side of a line, and is a point in a region?

```@example geo
l = APLine(APPoint(0.0, 0.0), APPoint(4.0, 2.0))
side_of_line(APPoint(1.0, 3.0), l), APPoint(1.0, 1.0) in APHalfPlane2(l, APPoint(1.0, 3.0))
```

```@raw html
<img src="../assets/img/predicates/side.svg" alt="A line oriented by an arrow, with a point on its left marked +1, a point on its right marked -1 and a point on it marked 0" style="width:100%; max-width: 700px;">
```

See [Predicates](@ref).

## Drawing recipes

### Fit a construction to a canvas

```julia
using Apollonius, Luxor

t = APTriangle(APPoint(0.0, 0.0), APPoint(6.0, 0.0), APPoint(1.5, 4.0))
cc = circumcircle(t)

lxm, lxo = @to_luxor_picture width=500 margin=30 begin
    t
    cc
end
```

```@raw html
<img src="../assets/img/getting_started/first_figure.svg" alt="A triangle with its circumcircle and incircle, the two centers and the labels" style="width:100%; max-width: 700px;">
```

`lxm` holds the canvas size, and `lxo` the objects in canvas coordinates, under the
names they had in the block. Every name in the block must be an object with a size. See
[Workflow: From Construction to Figure](@ref).

### Put a label outside a vertex

```julia
A2, B2, C2 = vertices(lxo.t)
G = centroid(lxo.t)
for (v, name) in zip((A2, B2, C2), ("A", "B", "C"))
    label(name, label_anchor(v, G)...)
end
```

```@raw html
<img src="../assets/img/workflow/decorate.svg" alt="Equal tangent segments marked with ticks and vertex labels placed outside the triangle" style="width:100%; max-width: 700px;">
```

### Mark equal sides and a right angle

On the fitted vertices `A2`, `B2` and `C2` of the previous recipe:

```julia
path(marks(APSegment(A2, B2); count=2); action=:stroke)             # two ticks
path(APAngle2(A2, B2, C2); as=:rarc, radius=12, action=:stroke)     # the right-angle square
```

```@raw html
<img src="../assets/img/decorations/full_figure.svg" alt="A triangle with equal-side marks, angle marks, an arrowhead, a brace and labels" style="width:100%; max-width: 700px;">
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
path(lxo.l, action=:stroke, extend=500)
```

```@raw html
<img src="../assets/img/cookbook/unbounded_line.svg" alt="A triangle and the line through two of its vertices, drawn without end" style="width:100%; max-width: 700px;">
```
