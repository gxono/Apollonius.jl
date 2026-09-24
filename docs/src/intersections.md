```@meta
CurrentModule = Apollonius
```

# Intersections

[`intersection`](@ref)`(a, b)` returns the points where two objects meet, as
a `Vector` of [`APPoint`](@ref)s. The vector is empty when they do not meet,
so the result is always safe to `filter`, `map` or `length`, and it is never
`nothing`. The arguments can be given in either order.

```@example geo
using Apollonius
```

## Which pairs

| Pair | Points | Notes |
|:-----|:-------|:------|
| line, line | 0 or 1 | none when parallel, and also none when they are the same line |
| line, circle | 0, 1 or 2 | two points in the direction of the line; one when tangent |
| circle, circle | 0, 1 or 2 | first the point on the left going from the first center to the second |
| line, ellipse, hyperbola or parabola | 0, 1 or 2 | order not specified |
| conic, conic | up to 4 | any two of circle, ellipse, hyperbola, parabola |
| segment or ray with anything above | as above | only the points inside the segment or ray are kept |
| arc of a conic with anything above | as above | only the points on the arc are kept |
| polyline, polygon, chain, bounding box, angle, half-plane, strip | as many as the sides cross | the points on the curves or boundaries, see below |
| parametric curve with a line, conic or any of the above | found by sampling | see below |
| point with anything above | 0 or 1 | the point itself, if it lies on the curve or boundary |

Two curves that coincide return an empty vector rather than infinitely many
points. A tangent contact counts as one point.

```@example geo
c = APCircle2(APPoint(0.0, 0.0), 3.0)
l = APLine(APPoint(-5.0, 1.0), APPoint(5.0, 1.0))
intersection(l, c)
```

```@example geo
c2 = APCircle2(APPoint(4.0, 0.0), 3.0)
intersection(c, c2)   # first the point above the line of centers, then the one below
```

## Segments, rays and arcs

A segment is a piece of a line, and a ray is half of one. `intersection`
first finds the points on the whole line, then drops the ones that fall
outside the piece. The same holds for an arc and its circle or conic.

```@example geo
r = APRay(APPoint(0.0, -1.0), APPoint(1.0, -1.0))
s = APSegment(APPoint(-6.0, -2.0), APPoint(0.0, -2.0))
intersection(r, c), intersection(s, c)   # one point each: the other point of the line is off the ray, off the segment
```

```@raw html
<img src="../assets/img/intersections/extent.svg" alt="A circle crossed by a segment, a ray and another segment. The points kept are purple; the points of the extended lines that fall outside the ray and the segment are gray" style="width:100%; max-width: 700px;">
```

```@example geo
arc = APCircularArc2(c, APPoint(3.0, 0.0), APPoint(0.0, 3.0))
intersection(arc, l), intersection(arc, c2)
```

```@raw html
<img src="../assets/img/conics/arc_intersect.svg" alt="An arc of a circle and the points where a line and another circle meet it" style="width:100%; max-width: 700px;">
```

## Two conics

Any two conics can meet in up to four points. A circle and an ellipse, for
example:

```@example geo
e = APEllipse2(APPoint(0.0, 0.0), 5.0, 2.0)
length(intersection(e, c))
```

```@raw html
<img src="../assets/img/intersections/conic_pairs.svg" alt="An ellipse and a circle that cross at four points" style="width:100%; max-width: 700px;">
```

## Polygons, polylines and other composite objects

Every object made of pieces works with `intersection`, against any other one.
A polyline, a polygon or a chain counts as the union of its sides. A
bounding box is its four sides, an angle its two rays, a half-plane its
boundary line and a strip its two lines. The result is the points where those
curves meet, so it can hold many points, and a vertex shared by two sides is
given once.

```@example geo
pg = APStraightNgon([APPoint(0.0, 0.0), APPoint(5.0, 0.0), APPoint(6.0, 3.0), APPoint(2.0, 4.0), APPoint(-1.0, 2.0)])
cut = APLine(APPoint(-2.0, 1.0), APPoint(7.0, 2.5))
intersection(pg, cut)
```

```@raw html
<img src="../assets/img/intersections/polygon_line.svg" alt="A pentagon cut by a line, with the two points where the line crosses its boundary" style="width:100%; max-width: 700px;">
```

Two polygons give the points where their boundaries cross:

```@example geo
other = APStraightNgon([APPoint(3.0, -1.0), APPoint(8.0, -1.0), APPoint(8.0, 2.0), APPoint(3.0, 2.0)])
intersection(pg, other)
```

```@raw html
<img src="../assets/img/intersections/polygon_polygon.svg" alt="Two polygons whose boundaries cross at two points" style="width:100%; max-width: 700px;">
```

The same holds for the polygons with curved sides, such as a
[`APCircularSector2`](@ref), and for chains that mix segments and arcs.

The inside of a region is not part of its curve, so a point inside a polygon
is not in the intersection of the polygon with a line that passes through it:
the line meets the polygon's boundary where it enters and where it leaves.
To ask whether a point is inside, use `in` (see [Predicates](@ref)).

## Points

The intersection of a point with a curve or with the boundary of a region is
the point itself if it lies there, and empty otherwise. The distance allowed is
the one of [`is_on_line`](@ref).

```@example geo
intersection(APPoint(2.5, 0.0), pg), intersection(APPoint(2.5, 1.0), pg)
```

## Parametric curves

A [`APParametricCurve2`](@ref) has no formula to solve, so its intersections
are found numerically: the curve is sampled at `n = 400` parameters, and each
place where it passes from one side of the other object to the other is
refined by bisection.

```@example geo
sine = APParametricCurve2(x -> APPoint(x, sin(x)), (0.0, 6.0))
intersection(sine, APLine(APPoint(0.0, 0.5), APPoint(1.0, 0.5)))
```

```@raw html
<img src="../assets/img/intersections/parametric.svg" alt="A sine curve, a line and a circle, with the points where the curve meets each" style="width:100%; max-width: 700px;">
```

It works against a line, ray, segment, conic, conic arc, and every composite
object above. Two limits come from sampling. A curve that only touches the other
object without crossing it is missed, and so are two crossings that fall between
two samples: pass a larger `n`. Two parametric curves are not supported.

## Choosing one of the points

Since the order of the result is only fixed for a line and a circle, and for
two circles, pick a point by where it is, not by its index.
[`nearest_point`](@ref) takes the one closest to a reference, and
[`other_intersection`](@ref) returns the second point when you already know
one. Both are in [Circles: How They Relate](@ref), under "Choosing among the intersections".

```@example geo
nearest_point(intersection(l, c), APPoint(3.0, 3.0)), other_intersection(l, c, APPoint(-sqrt(8.0), 1.0))
```

## Related functions

* [`angle_measure_intersection`](@ref) gives the measure of the angle at which two circles cross.
* [`radical_axis`](@ref) is the line through the two intersection points of
  two circles, and it exists even when they do not meet.
* [`tangent_points`](@ref) and [`tangent_lines`](@ref) give the points and lines of
  tangency from a point to a circle, and [`external_tangent_lines`](@ref) and
  [`internal_tangent_lines`](@ref) the common tangents of two circles. All
  of them are in [Circles: How They Relate](@ref).
