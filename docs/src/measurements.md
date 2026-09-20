```@meta
CurrentModule = Apollonius
```

# Measurements & Queries

The functions on this page take an object and return a number, an angle or a
point derived from it. They are spread over the pages of each kind of object;
this page puts them side by side and says what each one accepts.

| You want | Function | Accepts |
|:---------|:---------|:--------|
| Distance | [`distance`](@ref) | points, lines, rays, segments, circles, conics, arcs, polylines, polygons, bounding boxes, angles, half-planes, strips |
| Area | [`area`](@ref), [`signed_area`](@ref) | any polygon (including curvilinear ones), circle, ellipse, bounding box; the signed one for polygons |
| Perimeter | [`perimeter`](@ref), [`semiperimeter`](@ref) | any polygon, circle, ellipse, bounding box |
| Length of a curve | [`arc_length`](@ref) | segments, circular, elliptic, parabolic and hyperbolic arcs, polylines |
| Sides and angles of a polygon | [`side_lengths`](@ref), [`interior_angles`](@ref) | polygons, curvilinear ones included |
| Shape of a conic | [`eccentricity`](@ref), [`linear_eccentricity`](@ref), [`semi_major`](@ref), [`semi_minor`](@ref), [`focal_parameter`](@ref) | ellipses, hyperbolas, parabolas |
| Curvature | [`curvature`](@ref), [`signed_curvature`](@ref) | circles, circular arcs, conics at a point, parametric curves at a parameter |
| Chord and sagitta | [`chord_length`](@ref), [`sagitta`](@ref) | arcs; the sagitta of circular arcs |
| Angle swept | [`measure`](@ref) | angles, circular and elliptic arcs |
| Angle between things | [`angle_at`](@ref), [`angle_between`](@ref), [`intersection_angle`](@ref), [`slope_angle`](@ref) | points, vectors, circles, lines |
| Middle | [`midpoint`](@ref) | two points, a segment, any arc |
| Center of mass | [`centroid`](@ref) | polygons, sectors, segments, annular sectors |
| Foci | [`foci`](@ref) | ellipses, hyperbolas |
| Closest of several points | [`nearest_point`](@ref) | a vector of points and a point |
| Sizes of a triangle | [`circumradius`](@ref), [`inradius`](@ref) | triangles |
| Circle and point | [`power_of_point`](@ref), [`tangent_length`](@ref) | a point and a circle |

```@example geo
using Apollonius
```

## Distance

[`distance`](@ref) is the shortest distance between two objects, and it is
`0` when they touch. It works in either order (`distance(p, c)` and
`distance(c, p)` are the same) and for every pair the table above allows.
What "the object" means depends on the type:

* For a curve (a circle, an ellipse, an arc, a polyline) it is the curve
  itself, so a point inside a circle is at distance `r - d` from it, not `0`.
* For a line it is the whole infinite line. For a ray or a segment it is
  only the piece drawn, so a point past the end is measured to the endpoint.
* For a region (a polygon, an angle, a half-plane, a strip) it is `0` inside,
  unless you pass `mode=:boundary`. See
  [Polygons & Bounding Boxes](@ref) and
  [Unbounded Regions: Half-Planes, Strips & Angles](@ref).

```@example geo
c = APCircle2(APPoint(0.0, 0.0), 5.0)
distance(APPoint(2.0, 0.0), c), distance(APPoint(8.0, 0.0), c)   # inside and outside: both 3.0
```

Two objects of the same kind are measured between their nearest points:

```@example geo
c1, c2 = APCircle2(APPoint(0.0, 0.0), 1.0), APCircle2(APPoint(5.0, 0.0), 1.0)
sa, sb = APSegment(APPoint(9.0, 0.0), APPoint(10.0, 0.0)), APSegment(APPoint(12.0, 1.0), APPoint(12.0, 5.0))
la, lb = APLine(APPoint(15.0, 0.0), APPoint(19.0, 0.0)), APLine(APPoint(15.0, 2.5), APPoint(19.0, 2.5))
distance(c1, c2), distance(sa, sb), distance(la, lb)
```

```@raw html
<img src="../assets/img/measurements/distance_pairs.svg" alt="The shortest distance between two circles, two segments and two parallel lines" style="width:100%; max-width: 700px;">
```

## Area, perimeter and length

[`area`](@ref) and [`perimeter`](@ref) cover every closed shape: polygons of
every kind, a circle and an ellipse.

```@example geo
t = APTriangle(APPoint(0.0, 0.0), APPoint(4.0, 0.0), APPoint(0.0, 3.0))
e = APEllipse2(APPoint(0.0, 0.0), 5.0, 3.0)
area(t), perimeter(t), area(e), perimeter(e)
```

The area of an ellipse is exact (`π·a·b`). Its perimeter has no closed form,
and the value returned is Ramanujan's approximation, which is accurate to
many more digits than a drawing needs.

For a piece of a curve, use [`arc_length`](@ref). It also works for an open
chain such as an [`APPolyline2`](@ref), where it is the sum of the sides.

```@example geo
arc = APCircularArc2(APCircle2(APPoint(0.0, 0.0), 3.0), APPoint(3.0, 0.0), APPoint(0.0, 3.0))
measure(arc), arc_length(arc) ≈ 3.0 * measure(arc)
```

```@raw html
<img src="../assets/img/measurements/arc_measure.svg" alt="A circular arc with the angle it sweeps, its measure, and its length" style="width:100%; max-width: 700px;">
```

```@example geo
arc_length(APPolyline2(APPoint(0.0, 0.0), APPoint(3.0, 4.0), APPoint(3.0, 6.0)))
```

## Angle functions

Five functions return an angle. They differ in what they take and in
whether the sign means anything:

| Function | Takes | Result |
|:---------|:------|:-------|
| [`angle_at`](@ref)`(vertex, p1, p2)` | three points | unsigned, in `[0, π]` |
| [`angle_between`](@ref)`(u, v)` | two vectors | signed, in `(-π, π]` |
| [`measure`](@ref)`(ang)` | an [`APAngle2`](@ref) or an arc | signed for an angle, the angle swept for an arc |
| [`intersection_angle`](@ref)`(c1, c2)` | two circles | the angle between the tangents where they cross |
| [`slope_angle`](@ref)`(obj)` | a vector, line, ray or segment | the angle of its direction from the `x` axis |
| [`polar_angle`](@ref)`(p, center)` | a point | the angle of `p` around `center` (the origin by default) |

```@example geo
v = APPoint(0.0, 0.0)
angle_at(v, APPoint(1.0, 0.0), APPoint(0.0, -1.0)), angle_between(APVector(1.0, 0.0), APVector(0.0, -1.0))
```

The first is the plain opening between the two rays, the second says the
turn from the first vector to the second is clockwise. See
[Points, Lines & Rays](@ref) for the angle type and its marks.

## Shape of conics, arcs and polygons

The eccentricity says how far a conic is from a circle: `0` for a circle, below
`1` for an ellipse, `1` for a parabola and above `1` for a hyperbola.
[`linear_eccentricity`](@ref) is the distance from the center to each focus.
An ellipse stores the semi-axes `a` and `b` along its own axes, and either can
be the longer, so [`semi_major`](@ref) and [`semi_minor`](@ref) give them by
size.

```@example geo
el = APEllipse2(APPoint(0.0, 0.0), 3.0, 5.0)
semi_major(el), semi_minor(el), linear_eccentricity(el), eccentricity(el)
```

```@raw html
<img src="../assets/img/measurements/ellipse_axes.svg" alt="An ellipse with its semi-axes, its foci and the linear eccentricity" style="width:100%; max-width: 700px;">
```

[`curvature`](@ref) is `1 / r` for a circle or a circular arc and depends on
the point for the other conics, which must lie on the curve. On an ellipse it
is largest at the ends of the major axis:

```@example geo
curvature(el, APPoint(0.0, 5.0)), curvature(el, APPoint(3.0, 0.0))
```

For an [`APParametricCurve2`](@ref) the curvature is taken at a parameter `t` and
computed numerically, to about seven digits. [`signed_curvature`](@ref) keeps
the sign: positive where the curve turns counterclockwise as `t` grows and
negative where it turns clockwise, so it also tells the two sides of an
inflection point apart:

```@example geo
cubic = APParametricCurve2(t -> APPoint(t, t^3), (-1.0, 1.0))
signed_curvature(cubic, -0.5), signed_curvature(cubic, 0.5), curvature(cubic, 0.0)
```

```@raw html
<img src="../assets/img/measurements/curvature_cubic.svg" alt="A cubic curve with its osculating circles on both sides of the inflection point, one turning each way" style="width:100%; max-width: 700px;">
```

An arc has a [`chord_length`](@ref) (the distance between its endpoints) and,
if it is circular, a [`sagitta`](@ref), the height of the arc over its chord:

```@example geo
circ3 = APCircle2(APPoint(0.0, 0.0), 3.0)
bow = APCircularArc2(circ3, point_on_circle(circ3, π / 9), point_on_circle(circ3, 8π / 9))
chord_length(bow), sagitta(bow), arc_length(bow)
```

```@raw html
<img src="../assets/img/measurements/arc_chord_sagitta.svg" alt="A circular arc with its chord and its sagitta" style="width:100%; max-width: 700px;">
```

For a polygon, [`side_lengths`](@ref) lists the sides in order and
[`interior_angles`](@ref) the angle at each vertex, above `π` at a reflex
vertex. [`signed_area`](@ref) is positive when the vertices run
counterclockwise, which is a quick test of their order.
The last two also work for curvilinear polygons. There the angle at a vertex
is the one between the tangents of the two sides that meet, and `signed_area`
follows the direction of the first side:

```@example geo
L = APStraightNgon([APPoint(0.0, 0.0), APPoint(2.0, 0.0), APPoint(2.0, 1.0), APPoint(1.0, 1.0), APPoint(1.0, 2.0), APPoint(0.0, 2.0)])
rad2deg.(interior_angles(L)), side_lengths(L), signed_area(L), semiperimeter(L)
```

```@raw html
<img src="../assets/img/measurements/polygon_angles.svg" alt="An L-shaped polygon with the interior angle marked at each vertex, 270 degrees at the reflex one" style="width:100%; max-width: 700px;">
```

```@example geo
cvt = APCurvilinearTriangle2(APSegment(APPoint(0.0, 0.0), APPoint(4.0, 0.0)),
    APCircularArc2(APCircle2(APPoint(4.0, 2.0), 2.0), APPoint(4.0, 0.0), APPoint(4.0, 4.0)),
    APSegment(APPoint(4.0, 4.0), APPoint(0.0, 0.0)))
signed_area(cvt), rad2deg.(interior_angles(cvt))   # 180° where the arc leaves the segment smoothly
```

An [`APBoundingBox`](@ref) has an [`area`](@ref) and a [`perimeter`](@ref) too,
next to its `bbox_width` and `bbox_height`.

## Points derived from an object

[`midpoint`](@ref) works for two points, for a segment and for any arc (the
point halfway along the curve). [`centroid`](@ref) is the center of mass of
the enclosed area, not the average of the vertices, and the two differ as
soon as the vertices are not evenly spread:

```@example geo
pg = APStraightNgon([APPoint(0.0, 0.0), APPoint(6.0, 0.0), APPoint(6.0, 1.0), APPoint(1.0, 1.0), APPoint(1.0, 4.0), APPoint(0.0, 4.0)])
centroid(pg)   # area-weighted, not the average of the six vertices
```

```@raw html
<img src="../assets/img/measurements/centroid.svg" alt="An L-shaped polygon with its area-weighted centroid and the plain average of its vertices" style="width:100%; max-width: 700px;">
```

[`centroid`](@ref) also answers for a point, a segment (its midpoint), a bounding
box, a circle or an ellipse (their center) and a polyline (the mass is on the
curve). [`center`](@ref) and [`radius`](@ref) read the same data from every
circle-like object (circles, ellipses and hyperbolas, their arcs, sectors,
segments and annular sectors) without knowing which field holds it:

```@example geo
c0 = APCircle2(APPoint(1.0, 2.0), 3.0)
center(c0), radius(c0), center(APCircularArc2(c0, APPoint(4.0, 2.0), APPoint(1.0, 5.0))), centroid(APSegment(APPoint(0.0, 0.0), APPoint(2.0, 4.0)))
```

[`foci`](@ref) returns the two foci of an ellipse or a hyperbola as a tuple.
[`nearest_point`](@ref) picks, from a vector of points such as the one
[`intersection`](@ref) returns, the closest to a reference point, which is
how to choose one of several solutions by where you want it.

```@example geo
foci(e), nearest_point([APPoint(1.0, 1.0), APPoint(4.0, 4.0)], APPoint(0.0, 0.0))
```

For a triangle, [`circumradius`](@ref) and [`inradius`](@ref) give the radii
of its circumscribed and inscribed circles. For a point and a circle,
[`power_of_point`](@ref) is `d² - r²`, and [`tangent_length`](@ref) is its
square root, the length of the tangent from the point (see [Circles](@ref)).

```@example geo
circumradius(t), inradius(t), power_of_point(APPoint(13.0, 0.0), c), tangent_length(c, APPoint(13.0, 0.0))
```
