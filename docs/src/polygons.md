```@meta
CurrentModule = Apollonius
```

# Polygons & Bounding Boxes

[`APStraightNgon`](@ref) is an ordered list of vertices (no repeated
closing point), assumed to describe a *simple* polygon (edges don't cross
themselves). It's one member of the [`APPolygon`](@ref) family — the same
one `APTriangle` and `APQuadrilateral` belong to — so `area`, `perimeter`,
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

```@example geo
area(pg)       # 10.5, shoelace formula
perimeter(pg)  # sum of edge lengths
centroid(pg)   # area-weighted centroid — not the plain vertex average
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

## Convexity and containment

```@example geo
is_convex(pg)                                # true
point_in_polygon(APPoint(2.0, 1.0), pg)        # true: strictly inside
point_in_polygon(APPoint(5.0, 1.0), pg)        # false: strictly outside
```

[`point_in_polygon`](@ref) uses the standard ray-casting (even-odd) rule,
and works the same way for every [`APPolygon`](@ref) — `APTriangle`,
`APQuadrilateral`, or any curved region from [Circles](@ref). Its one
sharp edge: a point that lies *exactly* on the boundary can come back as
either `true` or `false`, depending on which edge and in which direction —
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
returning an [`APStraightNgon`](@ref). Points strictly inside the hull —
like `(2, 1)` above — are simply dropped; duplicate input points are also
removed before the sweep.

## Bounding boxes

[`APBoundingBox`](@ref) is a separate, minimal type — just two points,
`.min` and `.max` — for when a full polygon is more machinery than you
need (a quick overlap test, a viewport, a spatial-indexing key). It has
constructors from a vector of points, or directly from most shapes in the
package (`APSegment`, `APTriangle`, `APPolygon`, `APCircle2`, ...):

```@example geo
bb = APBoundingBox(pg)          # same as APBoundingBox(vertices(pg))
bb.min, bb.max
```

```@example geo
bbox_width(bb), bbox_height(bb)   # 4.0, 3.0
bbox_center(bb)                   # (2.0, 1.5)
bbox_diagonal(bb)                 # 5.0
bbox_aspect_ratio(bb)             # width / height
```

```@raw html
<img src="../assets/img/polygons/pol_bb.svg" alt="" style="width:100%;">
```

Translating (`+`/`-` an `APPoint`) and scaling (`*` a real number) an
`APBoundingBox` both return a new, still-valid `APBoundingBox` — scaling by
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
as `distance(p, pg::APPolygon)` above — `0.0` from inside with the default
`:region`, or always the distance to the box's edge with `:boundary`:

```@example geo
distance(APPoint(1.0, 1.0), bb)                  # 0.0: inside bb
distance(APPoint(1.0, 1.0), bb; mode=:boundary)   # > 0.0: distance to the nearest edge
```

[`bboxes_intersect`](@ref) treats touching (sharing just an edge or corner)
as intersecting. [`bbox_intersection`](@ref) returns `nothing` instead of a
degenerate box when they don't overlap at all.

[`bbox_union`](@ref) is the other direction — the smallest box containing
both, always defined (unlike the intersection, `a`/`b` don't need to
overlap):

```@example geo
bbox_union(bb, bb2)
```

```@raw html
<img src="../assets/img/polygons/bb_uni.svg" alt="" style="width:100%;">
```

Not everything has a *finite* box to report. [`APPoint`](@ref) gets a real
but degenerate (zero-size) box at its own location — a point is a
position, so it can still grow a union — while a plain number, an
[`APVector`](@ref) (a direction, not a location), and any unbounded
curve/region (`APLine`, `APRay`, `APAngle2`, `APHalfPlane2`, `APStrip2`)
have none at all. `APBoundingBox` returns the special **empty box**,
[`APBoundingBox()`](@ref), for these — the identity element for
`bbox_union`: unioning it with anything just returns the other box
unchanged, and [`isempty`](@ref) tells the two apart:

```@example geo
isempty(APBoundingBox(5.0)), isempty(APBoundingBox(APLine(APPoint(0.0, 0.0), APPoint(1.0, 1.0))))
```

```@example geo
bbox_union(APBoundingBox(5.0), bb) == bb
```

This is what lets [`@boundingbox`](@ref)/[`@to_luxor_picture`](@ref) (see
[Transforming in Bulk: Macros](@ref)) call `APBoundingBox` on *every*
value named in a block — construction helpers included — without needing
to special-case the ones that were never meant to be drawn or sized.

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
(default `true`) to build on the other side of `[a,b]` instead — useful
when the side you're extending from is itself part of a larger polygon and
you need to stay outside (or inside) it consistently.

## Quadrilaterals

[`APQuadrilateral`](@ref) is a dedicated 4-vertex type (fields `a, b, c,
d`, taken in order around the shape), distinct from a general
`APStraightNgon` — it exists because a quadrilateral has its own
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

```@example geo
is_cyclic(q)                     # false: no circle passes through all 4 vertices
point_in_polygon(APPoint(2.0, 1.0), q)  # true: strictly inside
```

There's no separate `point_in_quadrilateral` function — since
`APQuadrilateral` is a genuine [`APPolygon`](@ref) rather than an unrelated
struct, the one generic [`point_in_polygon`](@ref)/`Base.in` already
covers it, along with every other member of the family.

One thing to watch: [`centroid`](@ref) of an `APQuadrilateral` is the
plain average of the 4 vertices `(a+b+c+d)/4`, **not** area-weighted like
the generic `centroid(::APPolygon)` — for a quadrilateral this plain
average is itself a classical, well-defined point (sometimes called the
"vertex centroid"), so it's kept simple rather than silently reproducing
the polygon's weighted version under the same name.

`rotate`, `reflection` and `homothety` transform `a`, `b`, `c` and `d`
pointwise, same as for any other polygon:

```@example geo
rotate(q, pi / 6)
```
