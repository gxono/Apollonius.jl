```@meta
CurrentModule = Apollonius
```

# Polygons: Measurements & Operations

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
[Points, Lines & Rays: Creating Them](@ref)):

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
`APQuadrilateral`, or any curved region from [Circles: Sectors, Segments & Curvilinear Chains](@ref). Its one
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
