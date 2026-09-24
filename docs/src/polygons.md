```@meta
CurrentModule = Apollonius
```

# Polygons & Bounding Boxes

[`APStraightNgon`](@ref) is an ordered list of vertices (no repeated
closing point), assumed to describe a *simple* polygon (edges don't cross
themselves). It's one member of the [`APPolygon`](@ref) family (the same
one `APTriangle` and `APQuadrilateral` belong to), so `area`, `perimeter`,
`centroid`, `is_convex` and `point_in_polygon` are all defined *once*,
generically, on `APPolygon` itself, rather than reimplemented per type.
This page also covers a separate, lighter-weight [`APBoundingBox`](@ref)
type for quick axis-aligned containment/overlap tests.

## Basic measurements

```@example geo
using Apollonius

pg = APStraightNgon([APPoint(0.0, 0.0), APPoint(4.0, 0.0), APPoint(4.0, 3.0), APPoint(1.0, 3.0)])
vertices(pg)
```

One vertex per argument works too, instead of wrapping them in a
`Vector` (the same pair of forms [`APPolyline2`](@ref) has, see
[Points, Lines & Rays](@ref)):

```@example geo
pg == APStraightNgon(APPoint(0.0, 0.0), APPoint(4.0, 0.0), APPoint(4.0, 3.0), APPoint(1.0, 3.0))
```

```@example geo
area(pg)       # 10.5, shoelace formula
perimeter(pg)  # sum of edge lengths
centroid(pg)   # area-weighted centroid, not the plain vertex average
```

```@raw html
<img src="../assets/img/polygons/pol1.svg" alt="" style="width:100%;">
```


[`centroid`](@ref) weights by area rather than just averaging the vertices
(a polygon with vertices clustered on one side but a large flat area on the
other still gets the geometrically correct center of mass). For a
(near-)zero-area degenerate polygon, where that weighting breaks down, it
falls back to the plain vertex average instead.

`rotate`, `reflection` and `homothety` all work on an `APStraightNgon` too,
transforming every vertex:

```@example geo
rotate(pg, pi / 4, centroid(pg))
homothety(pg, 2.0)
```

```@raw html
<img src="../assets/img/polygons/pol_rothom.svg" alt="" style="width:100%;">
```

## Distance to a polygon

[`distance`](@ref)`(p, pg)` works the same way for every [`APPolygon`](@ref)
(straight or curved). With `mode = :region` (the default), it's `0.0` for a
point inside or on `pg`, otherwise the distance to the nearest side; with
`mode = :boundary`, it's always the distance to the boundary, even from
inside:

```@example geo
distance(APPoint(2.0, 1.0), pg)                    # 0.0: strictly inside
distance(APPoint(2.0, 1.0), pg; mode=:boundary)     # > 0.0: distance to the nearest side instead
distance(APPoint(6.0, 1.0), pg)                     # outside: both modes agree
```

```@raw html
<img src="../assets/img/polygons/distance_polygon.svg" alt="A polygon, a point inside and a point outside, each with the segment to its nearest side" style="width:100%; max-width: 700px;">
```

## Convexity and containment

```@example geo
is_convex(pg)                                # true
point_in_polygon(APPoint(2.0, 1.0), pg)        # true: strictly inside
point_in_polygon(APPoint(5.0, 1.0), pg)        # false: strictly outside
```

```@raw html
<img src="../assets/img/polygons/containment.svg" alt="A polygon with the points inside it in purple and those outside in gray" style="width:100%; max-width: 700px;">
```

[`point_in_polygon`](@ref) uses the standard ray-casting (even-odd) rule,
and works the same way for every [`APPolygon`](@ref): `APTriangle`,
`APQuadrilateral`, or any curved region from [Circles](@ref). Its one
sharp edge: a point that lies *exactly* on the boundary can come back as
either `true` or `false`, depending on which edge and in which direction;
this is a well-known property of ray casting itself, not a bug, so don't
rely on an exact boundary point going either way.

## Convex hull

```@example geo
pts = [APPoint(0.0, 0.0), APPoint(4.0, 0.0), APPoint(4.0, 3.0), APPoint(1.0, 3.0), APPoint(2.0, 1.0)]
hull = convex_hull(pts)
vertices(hull)
```

```@raw html
<img src="../assets/img/polygons/pol_hull.svg" alt="" style="width:100%;">
```

[`convex_hull`](@ref) is Andrew's monotone chain algorithm (`O(n log n)`,
sorts the points then builds the lower and upper chains in one pass each),
returning an [`APStraightNgon`](@ref). Points strictly inside the hull
(like `(2, 1)` above) are simply dropped; duplicate input points are also
removed before the sweep.

## Bounding boxes

[`APBoundingBox`](@ref) is a separate, minimal type (just two points,
`.min` and `.max`) for when a full polygon is more machinery than you
need (a quick overlap test, a viewport, a spatial-indexing key). It has
constructors from a vector of points, or directly from most shapes in the
package (`APSegment`, `APTriangle`, `APPolygon`, `APCircle2`, ...):

```@example geo
bb = APBoundingBox(pg)          # same as APBoundingBox(vertices(pg))
bb.min, bb.max
```

```@example geo
bbox_width(bb), bbox_height(bb)   # 4.0, 3.0
bbox_center(bb)                   # [2.0, 1.5]
bbox_diagonal(bb)                 # 5.0
bbox_aspect_ratio(bb)             # width / height
```

```@raw html
<img src="../assets/img/polygons/pol_bb.svg" alt="" style="width:100%;">
```

Translating (`+`/`-` an `APPoint`) and scaling (`*` a real number) an
`APBoundingBox` both return a new, still-valid `APBoundingBox`: scaling by
a negative factor still produces `min <= max` correctly, by re-sorting the
two scaled corners rather than assuming the sign of the factor.

Unlike everything in the [`APPolygon`](@ref) family, `APBoundingBox`
deliberately sits outside the [`APObject`](@ref) hierarchy's region
branch and has no `rotate`/`reflection` methods: an arbitrary rotation or
reflection wouldn't generally produce another *axis-aligned* box, only a
rotated rectangle, which isn't what this type represents. Translation and
uniform scaling about the origin are the only transforms that always
preserve that invariant, so those are what's supported (`+`/`-`/`*`
above, rather than `rotate`/`reflection`/`homothety`).

```@example geo
APPoint(1.0, 1.0) in bb   # containment, boundary included
bb2 = APBoundingBox(APPoint(2.0, 1.0), APPoint(6.0, 5.0))
bboxes_intersect(bb, bb2)     # true: they overlap
bbox_intersection(bb, bb2)    # the overlapping region itself
```

```@raw html
<img src="../assets/img/polygons/bb_int.svg" alt="" style="width:100%;">
```

[`distance`](@ref)`(p, bb)` has the same `mode = :region`/`:boundary` pair
as `distance(p, pg::APPolygon)` above: `0.0` from inside with the default
`:region`, or always the distance to the box's edge with `:boundary`:

```@example geo
distance(APPoint(1.0, 1.0), bb)                  # 0.0: inside bb
distance(APPoint(1.0, 1.0), bb; mode=:boundary)   # > 0.0: distance to the nearest edge
```

[`bboxes_intersect`](@ref) treats touching (sharing just an edge or corner)
as intersecting. [`bbox_intersection`](@ref) returns `nothing` instead of a
degenerate box when they don't overlap at all.

[`bbox_union`](@ref) is the other direction: the smallest box containing
both, always defined (unlike the intersection, `a`/`b` don't need to
overlap):

```@example geo
bbox_union(bb, bb2)
```

```@raw html
<img src="../assets/img/polygons/bb_uni.svg" alt="" style="width:100%;">
```

Not everything has a *finite* box to report. [`APPoint`](@ref) gets a real
but degenerate (zero-size) box at its own location (a point is a
position, so it can still grow a union), while a plain number, an
[`APVector`](@ref) (a direction, not a location), and any unbounded
curve/region (`APLine`, `APRay`, `APAngle2`, `APHalfPlane2`, `APStrip2`)
have none at all. `APBoundingBox` returns the special **empty box**,
[`APBoundingBox()`](@ref), for these, the identity element for
`bbox_union`: unioning it with anything just returns the other box
unchanged, and [`isempty`](@ref) tells the two apart:

```@example geo
isempty(APBoundingBox(5.0)), isempty(APBoundingBox(APLine(APPoint(0.0, 0.0), APPoint(1.0, 1.0))))
```

```@example geo
bbox_union(APBoundingBox(5.0), bb) == bb
```

This is what lets [`@boundingbox`](@ref)/[`@prepare_to_picture`](@ref) (see
[Transforming in Bulk: Macros](@ref)) call `APBoundingBox` on *every*
value named in a block (construction helpers included) without needing
to special-case the ones that were never meant to be drawn or sized.

### Boxes from a center and a size

`APBoundingBox(center, width, height)` builds the box with the given center and
size, and [`inflate`](@ref)`(bb, margin)` grows a box by `margin` on every side
(or by `mx` and `my` on the two directions), or shrinks it when negative. An
empty box stays empty:

```@example geo
bx = APBoundingBox(APPoint(1.0, 1.0), 4.0, 2.0)
bx, inflate(bx, 1.0), inflate(bx, 1.0, 0.5)
```

## Offsetting a polygon

[`offset_polygon`](@ref)`(pg, d)` is the polygon parallel to `pg` at distance `d`:
outward for a positive `d`, inward for a negative one. Each side moves along its
normal, and every new vertex is where two neighbouring moved sides meet. A
concave polygon, or an inward offset larger than the polygon, can cross itself.
To round the corners instead, see [`round_corners`](@ref) in
[Rounding a corner](@ref).

```@example geo
sq_o = APStraightNgon([APPoint(0.0, 0.0), APPoint(4.0, 0.0), APPoint(4.0, 4.0), APPoint(0.0, 4.0)])
area(offset_polygon(sq_o, 1.0)), area(offset_polygon(sq_o, -1.0))
```

```@raw html
<img src="../assets/img/polygons/offset_box.svg" alt="A pentagon with its outward and inward offsets, and a box with its inflated box" style="width:100%; max-width: 700px;">
```


## Random points on a perimeter

[`rand`](@ref) draws a uniformly random point on a polygon's or a
bounding box's own perimeter, never its interior (see
[Points, Lines & Rays](@ref) for the general story across every shape in
the package): each side is picked with probability proportional to its
own length, then a point on that side uniformly, so the result is uniform
along the whole boundary, not just uniform-per-side:

```@example geo
p = rand(pg)
point_in_polygon(p, pg)   # true: on the boundary, which counts as "in" by default

pb = rand(bb)
pb in bb                  # same idea for a bounding box's own edge
```

```@raw html
<img src="../assets/img/polygons/random_perimeter.svg" alt="Random points on the perimeter of a polygon and of its bounding box" style="width:100%; max-width: 700px;">
```

## Named polygon constructors

A handful of constructors build common quadrilaterals and regular polygons
directly, so they interoperate with everything above (`area`, `is_convex`,
`APBoundingBox`, ...) for free.

| Function | Builds | Returns |
|:---------|:-------|:--------|
| [`parallelogram`](@ref) | the parallelogram through 3 consecutive vertices `a, b, c` (the 4th, `d`, is completed automatically) | `APQuadrilateral` |
| [`square_on_segment`](@ref) | the square with `[a,b]` as one side | `APQuadrilateral` |
| [`rectangle_on_segment`](@ref) | the rectangle with `[a,b]` as one side and a given height | `APQuadrilateral` |
| [`regular_polygon`](@ref) | the regular `n`-gon with a given center and one vertex | `APStraightNgon` |

```@example geo
a, b, c = APPoint(0.0, 0.0), APPoint(4.0, 0.0), APPoint(5.0, 2.0)

parallelogram(a, b, c)          # 4th vertex completed as a + (c - b)
square_on_segment(a, b)         # built counterclockwise from a to b by default
rectangle_on_segment(a, b, 2.0) # same, with an explicit height instead of |a-b|
regular_polygon(APPoint(0.0, 0.0), APPoint(1.0, 0.0), 6)  # a regular hexagon
```

```@raw html
<img src="../assets/img/polygons/pol_nam.svg" alt="" style="width:100%;">
```

`square_on_segment` and `rectangle_on_segment` both take a `ccw` keyword
(default `true`) to build on the other side of `[a,b]` instead, useful
when the side you're extending from is itself part of a larger polygon and
you need to stay outside (or inside) it consistently.

## Polygons on a segment, from a diagonal or from a center

The named constructors above have relatives that start from other data. All of
them take the base or the diagonal in the order given, and `ccw` (default `true`)
picks the side or the direction of the vertices where it exists.

| Function | Builds | Returns |
|:---------|:-------|:--------|
| [`regular_polygon_on_segment`](@ref)`(a, b, n)` | the regular `n`-gon with side `[a, b]` | `APStraightNgon` |
| [`star_polygon`](@ref)`(center, vertex, n, k)` | the star `{n/k}` on the regular `n`-gon, `{5/2}` being the pentagram | `APStraightNgon` |
| [`rhombus_on_segment`](@ref)`(a, b, angle)` | the rhombus with side `[a, b]` and the given angle at `a` | `APQuadrilateral` |
| [`square_from_diagonal`](@ref)`(a, c)` | the square with diagonal `[a, c]` | `APQuadrilateral` |
| [`rectangle_from_diagonal`](@ref)`(a, c, angle)` | the rectangle with diagonal `[a, c]`, at `angle` with the side from `a` | `APQuadrilateral` |
| [`rectangle_with_center`](@ref)`(center, w, h)`, [`square_with_center`](@ref)`(center, side)` | a rectangle or square of a given size, turned by the keyword `angle` | `APQuadrilateral` |
| [`isosceles_trapezoid_on_segment`](@ref)`(a, b, top, height)` | the trapezoid on base `[a, b]` with equal legs | `APQuadrilateral` |
| [`right_trapezoid_on_segment`](@ref)`(a, b, top, height)` | the trapezoid with right angles at `a` and at the other end of the leg | `APQuadrilateral` |
| [`kite_on_diagonal`](@ref)`(a, c, t, half_width)` | the kite with axis `[a, c]`, its other corners at the fraction `t` | `APQuadrilateral` |

```@example geo
pa, pb = APPoint(0.0, 0.0), APPoint(3.0, 0.0)
area(regular_polygon_on_segment(pa, pb, 6)), area(rhombus_on_segment(pa, pb, pi / 3))
```

```@example geo
sd = square_from_diagonal(APPoint(0.0, 0.0), APPoint(2.0, 2.0))
area(sd), area(rectangle_with_center(APPoint(1.0, 1.0), 4.0, 2.0; angle=pi / 6)), area(kite_on_diagonal(pa, APPoint(0.0, 6.0), 0.4, 2.0))
```

```@raw html
<img src="../assets/img/polygons/on_segment_family.svg" alt="A regular pentagon, hexagon and triangle built on segments, and a pentagram" style="width:100%; max-width: 700px;">
```

```@raw html
<img src="../assets/img/polygons/quad_family.svg" alt="A rhombus, a square, a rectangle, an isosceles trapezoid, a right trapezoid, a kite and a turned rectangle" style="width:100%; max-width: 700px;">
```


## Quadrilaterals

[`APQuadrilateral`](@ref) is a dedicated 4-vertex type (fields `a, b, c,
d`, taken in order around the shape), distinct from a general
`APStraightNgon`. It exists because a quadrilateral has its own
well-known named features (a pair of diagonals, a well-defined "is it
cyclic" question) that don't generalize cleanly to arbitrary polygons.

```@example geo
q = APQuadrilateral(APPoint(0.0, 0.0), APPoint(4.0, 0.0), APPoint(5.0, 3.0), APPoint(1.0, 3.0))
vertices(q)
```

`area`, `perimeter`, `is_convex` and `APBoundingBox` all work on an
`APQuadrilateral` exactly as they do on any other [`APPolygon`](@ref)
(internally, it's treated as the 4-vertex polygon `[a,b,c,d]` for these):

```@example geo
area(q), perimeter(q), is_convex(q)
```

```@example geo
sides(q)        # the 4 sides, as APSegments a-b, b-c, c-d, d-a
diagonals(q)     # the 2 diagonals, as APSegments a-c and b-d
diagonal_intersection(q)  # where the diagonals cross (nothing if they're parallel)
```

```@raw html
<img src="../assets/img/polygons/quadrilateral.svg" alt="A quadrilateral with its two diagonals and the point where they cross" style="width:100%; max-width: 700px;">
```

```@example geo
is_cyclic(q)                     # false: no circle passes through all 4 vertices
point_in_polygon(APPoint(2.0, 1.0), q)  # true: strictly inside
```

There's no separate `point_in_quadrilateral` function, since
`APQuadrilateral` is a genuine [`APPolygon`](@ref) rather than an unrelated
struct, the one generic [`point_in_polygon`](@ref)/`Base.in` already
covers it, along with every other member of the family.

One thing to watch: [`centroid`](@ref) of an `APQuadrilateral` is the
plain average of the 4 vertices `(a+b+c+d)/4`, **not** area-weighted like
the generic `centroid(::APPolygon)`: for a quadrilateral this plain
average is itself a classical, well-defined point (sometimes called the
"vertex centroid"), so it's kept simple rather than silently reproducing
the polygon's weighted version under the same name.

`rotate`, `reflection` and `homothety` transform `a`, `b`, `c` and `d`
pointwise, same as for any other polygon:

```@example geo
rotate(q, pi / 6)
```

### Circles inside and around a quadrilateral

[`circumcircle`](@ref) and [`incircle`](@ref) also work for a quadrilateral, and
for any polygon with straight sides, when the circle exists. The circle through
all the vertices needs them to be concyclic (a cyclic quadrilateral, a regular
polygon), and the one that touches all the sides needs a *tangential* polygon
(a quadrilateral with `a + c = b + d` for its sides, a regular polygon). Both
throw an `ArgumentError` otherwise. An isosceles trapezoid is cyclic and a kite
is tangential:

```@example geo
circumcircle(isosceles_trapezoid_on_segment(APPoint(0.0, 0.0), APPoint(6.0, 0.0), 2.0, 3.0)),
incircle(kite_on_diagonal(APPoint(0.0, 0.0), APPoint(0.0, 7.0), 0.35, 2.0))
```

```@raw html
<img src="../assets/img/polygons/quad_circles.svg" alt="An isosceles trapezoid with its circumcircle and a kite with its incircle" style="width:100%; max-width: 700px;">
```

