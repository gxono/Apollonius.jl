```@meta
CurrentModule = Apollonius
```

# Polygons: Bounding Boxes

The polygon from [Polygons: Measurements & Operations](@ref):

```@example geo
using Apollonius

pg = APStraightNgon([APPoint(0.0, 0.0), APPoint(4.0, 0.0), APPoint(4.0, 3.0), APPoint(1.0, 3.0)])
nothing # hide
```

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
[Points, Lines & Rays: Special Points & Curves](@ref) for the general story across every shape in
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
