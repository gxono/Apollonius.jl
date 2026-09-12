```@meta
CurrentModule = EuclideanGeometry
```

# Polygons & Bounding Boxes

[`EGStraightNgon`](@ref) is an ordered list of vertices (no repeated
closing point), assumed to describe a *simple* polygon (edges don't cross
themselves). It's one member of the [`EGPolygon`](@ref) family — the same
one `EGTriangle` and `EGQuadrilateral` belong to — so `area`, `perimeter`,
`centroid`, `is_convex` and `point_in_polygon` are all defined *once*,
generically, on `EGPolygon` itself, rather than reimplemented per type.
This page also covers a separate, lighter-weight [`EGBoundingBox`](@ref)
type for quick axis-aligned containment/overlap tests.

## Basic measurements

```@example geo
using EuclideanGeometry

pg = EGStraightNgon([EGPoint(0.0, 0.0), EGPoint(4.0, 0.0), EGPoint(4.0, 3.0), EGPoint(1.0, 3.0)])
vertices(pg)
```

```@example geo
area(pg)       # 10.5, shoelace formula
perimeter(pg)  # sum of edge lengths
centroid(pg)   # area-weighted centroid — not the plain vertex average
```

[`centroid`](@ref) weights by area rather than just averaging the vertices
(a polygon with vertices clustered on one side but a large flat area on the
other still gets the geometrically correct center of mass). For a
(near-)zero-area degenerate polygon, where that weighting breaks down, it
falls back to the plain vertex average instead.

`rotate`, `reflection` and `homothety` all work on an `EGStraightNgon` too,
transforming every vertex:

```@example geo
rotate(pg, pi / 4, centroid(pg))
homothety(pg, 2.0)
```

## Convexity and containment

```@example geo
is_convex(pg)                                # true
point_in_polygon(EGPoint(2.0, 1.0), pg)        # true: strictly inside
point_in_polygon(EGPoint(5.0, 1.0), pg)        # false: strictly outside
```

[`point_in_polygon`](@ref) uses the standard ray-casting (even-odd) rule,
and works the same way for every [`EGPolygon`](@ref) — `EGTriangle`,
`EGQuadrilateral`, or any curved region from [Circles](@ref). Its one
sharp edge: a point that lies *exactly* on the boundary can come back as
either `true` or `false`, depending on which edge and in which direction —
this is a well-known property of ray casting itself, not a bug, so don't
rely on an exact boundary point going either way.

## Convex hull

```@example geo
pts = [EGPoint(0.0, 0.0), EGPoint(4.0, 0.0), EGPoint(4.0, 3.0), EGPoint(1.0, 3.0), EGPoint(2.0, 1.0)]
hull = convex_hull(pts)
vertices(hull)
```

[`convex_hull`](@ref) is Andrew's monotone chain algorithm (`O(n log n)`,
sorts the points then builds the lower and upper chains in one pass each),
returning an [`EGStraightNgon`](@ref). Points strictly inside the hull —
like `(2, 1)` above — are simply dropped; duplicate input points are also
removed before the sweep.

## Bounding boxes

[`EGBoundingBox`](@ref) is a separate, minimal type — just two points,
`.min` and `.max` — for when a full polygon is more machinery than you
need (a quick overlap test, a viewport, a spatial-indexing key). It has
constructors from a vector of points or directly from an `EGSegment`,
`EGTriangle`, `EGPolygon` or `EGCircle2`:

```@example geo
bb = EGBoundingBox(pg)          # same as EGBoundingBox(vertices(pg))
bb.min, bb.max
```

```@example geo
bbox_width(bb), bbox_height(bb)   # 4.0, 3.0
bbox_center(bb)                   # (2.0, 1.5)
bbox_diagonal(bb)                 # 5.0
bbox_aspect_ratio(bb)             # width / height
```

Translating (`+`/`-` an `EGPoint`) and scaling (`*` a real number) an
`EGBoundingBox` both return a new, still-valid `EGBoundingBox` — scaling by
a negative factor still produces `min <= max` correctly, by re-sorting the
two scaled corners rather than assuming the sign of the factor.

Unlike everything in the [`EGPolygon`](@ref) family, `EGBoundingBox`
deliberately sits outside the [`EGObject`](@ref) hierarchy's region
branch and has no `rotate`/`reflection` methods: an arbitrary rotation or
reflection wouldn't generally produce another *axis-aligned* box, only a
rotated rectangle, which isn't what this type represents. Translation and
uniform scaling about the origin are the only transforms that always
preserve that invariant, so those are what's supported (`+`/`-`/`*`
above, rather than `rotate`/`reflection`/`homothety`).

```@example geo
EGPoint(1.0, 1.0) in bb   # containment, boundary included
bb2 = EGBoundingBox(EGPoint(2.0, 1.0), EGPoint(6.0, 5.0))
bboxes_intersect(bb, bb2)     # true: they overlap
bbox_intersection(bb, bb2)    # the overlapping region itself
```

[`bboxes_intersect`](@ref) treats touching (sharing just an edge or corner)
as intersecting. [`bbox_intersection`](@ref) returns `nothing` instead of a
degenerate box when they don't overlap at all.

## Named polygon constructors

A handful of constructors build common quadrilaterals and regular polygons
directly, so they interoperate with everything above (`area`, `is_convex`,
`EGBoundingBox`, ...) for free.

| Function | Builds | Returns |
|:---------|:-------|:--------|
| [`parallelogram`](@ref) | the parallelogram through 3 consecutive vertices `a, b, c` (the 4th, `d`, is completed automatically) | `EGQuadrilateral` |
| [`square_on_segment`](@ref) | the square with `[a,b]` as one side | `EGQuadrilateral` |
| [`rectangle_on_segment`](@ref) | the rectangle with `[a,b]` as one side and a given height | `EGQuadrilateral` |
| [`regular_polygon`](@ref) | the regular `n`-gon with a given center and one vertex | `EGStraightNgon` |

```@example geo
a, b, c = EGPoint(0.0, 0.0), EGPoint(4.0, 0.0), EGPoint(5.0, 2.0)

parallelogram(a, b, c)          # 4th vertex completed as a + (c - b)
square_on_segment(a, b)         # built counterclockwise from a to b by default
rectangle_on_segment(a, b, 2.0) # same, with an explicit height instead of |a-b|
regular_polygon(EGPoint(0.0, 0.0), EGPoint(1.0, 0.0), 6)  # a regular hexagon
```

`square_on_segment` and `rectangle_on_segment` both take a `ccw` keyword
(default `true`) to build on the other side of `[a,b]` instead — useful
when the side you're extending from is itself part of a larger polygon and
you need to stay outside (or inside) it consistently.

## Quadrilaterals

[`EGQuadrilateral`](@ref) is a dedicated 4-vertex type (fields `a, b, c,
d`, taken in order around the shape), distinct from a general
`EGStraightNgon` — it exists because a quadrilateral has its own
well-known named features (a pair of diagonals, a well-defined "is it
cyclic" question) that don't generalize cleanly to arbitrary polygons.

```@example geo
q = EGQuadrilateral(EGPoint(0.0, 0.0), EGPoint(4.0, 0.0), EGPoint(5.0, 3.0), EGPoint(1.0, 3.0))
vertices(q)
```

`area`, `perimeter`, `is_convex` and `EGBoundingBox` all work on an
`EGQuadrilateral` exactly as they do on any other [`EGPolygon`](@ref)
(internally, it's treated as the 4-vertex polygon `[a,b,c,d]` for these):

```@example geo
area(q), perimeter(q), is_convex(q)
```

```@example geo
sides(q)        # the 4 sides, as EGSegments a-b, b-c, c-d, d-a
diagonals(q)     # the 2 diagonals, as EGSegments a-c and b-d
diagonal_intersection(q)  # where the diagonals cross (nothing if they're parallel)
```

```@example geo
is_cyclic(q)                     # false: no circle passes through all 4 vertices
point_in_polygon(EGPoint(2.0, 1.0), q)  # true: strictly inside
```

There's no separate `point_in_quadrilateral` function — since
`EGQuadrilateral` is a genuine [`EGPolygon`](@ref) rather than an unrelated
struct, the one generic [`point_in_polygon`](@ref)/`Base.in` already
covers it, along with every other member of the family.

One thing to watch: [`centroid`](@ref) of an `EGQuadrilateral` is the
plain average of the 4 vertices `(a+b+c+d)/4`, **not** area-weighted like
the generic `centroid(::EGPolygon)` — for a quadrilateral this plain
average is itself a classical, well-defined point (sometimes called the
"vertex centroid"), so it's kept simple rather than silently reproducing
the polygon's weighted version under the same name.

`rotate`, `reflection` and `homothety` transform `a`, `b`, `c` and `d`
pointwise, same as for any other polygon:

```@example geo
rotate(q, pi / 6)
```
