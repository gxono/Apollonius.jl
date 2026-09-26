```@meta
CurrentModule = Apollonius
```

# Intersections

[`intersection`](@ref)`(a, b)` returns the points where two objects meet, as
a `Vector` of [`APPoint`](@ref)s. The vector is empty when they do not meet,
so the result is always safe to `filter`, `map` or `length`, and it is never
`nothing`. The arguments can be given in either order.

**Except** when one side is an [`APAngle2`](@ref), [`APHalfPlane2`](@ref) or
[`APStrip2`](@ref) and the other a line, segment, ray, or a conic (circle,
ellipse, parabola, hyperbola) or an arc of one: those three are regions, not
curves, so there `intersection` gives the *part of the other object that
lies inside the region*, in that object's own type (a point, a segment, a
ray, an arc, the whole object, `nothing`, or a `Vector` of pieces), not the
points where a boundary is crossed. For a line/segment/ray/circle/ellipse
this is a bare value unless one side is a reflex `APAngle2` or a strip wide
enough to be crossed on both sides; for a parabola/hyperbola (open, unlike
the other conics) it's *always* a `Vector`, since even a single half-plane
can split one into two disjoint pieces. See
[Unbounded Regions: Half-Planes, Strips & Angles](@ref),
[Points, Lines & Rays: Angles](@ref) and
[Conics: Tangents, Duality & Arcs](@ref).

**Also except** when *both* sides are one of `APAngle2`/`APHalfPlane2`/
`APStrip2`: there `intersection` gives the region common to both, whichever
type it collapses to (`nothing`, an [`APLine`](@ref), one of the same three
types unchanged, a bounded [`APTriangle`](@ref)/[`APQuadrilateral`](@ref), or
an [`APUnboundedPolygon2`](@ref)), as a bare value unless one side is a
reflex `APAngle2`, when it's a `Vector` of up to 2 pieces (up to 4 if both
sides are reflex, possibly with some overlap between pieces in that last
case). See [Unbounded Regions: Half-Planes, Strips & Angles](@ref).

**Also except** when one side is an `APAngle2`/`APHalfPlane2`/`APStrip2` and
the other a straight-sided [`APTriangle`](@ref)/[`APQuadrilateral`](@ref)/
[`APStraightNgon`](@ref): the part of the polygon inside the region, in the
tightest fitting bounded type, a bare value unless one side is a reflex
`APAngle2` (curved-sided polygons aren't supported yet). See [Unbounded
Regions: Half-Planes, Strips & Angles](@ref).

**Also except** when both sides are bounded and closed: an [`APCircle2`](@ref),
an [`APEllipse2`](@ref), or any member of the `APPolygon` family (straight or
curved). There a `mode` keyword picks, per side, whether it means just its own
boundary curve or the filled region it encloses, the same `:boundary`/
`:region` vocabulary [`distance`](@ref) already uses. `mode=(:boundary,
:boundary)` (the default, and what happens when `mode` is left out) is the
boundary-crossing points above, unchanged. `mode=(:boundary, :region)` or
`(:region, :boundary)` gives the part of the *boundary-only* side's own curve
that lies inside the *region* side, as a `Vector` (0, 1, or more disjoint
pieces, since the region side need not be convex). `mode=(:region, :region)`
gives the actual overlap of the two filled interiors, also always a `Vector`,
each piece the tightest fitting shape: `APTriangle`/`APQuadrilateral`/
`APStraightNgon` when every side of a piece is straight,
`APCurvilinearTriangle2`/`APCurvilinearQuadrilateral2`/`APCurvilinearNgon2`
when any side is curved. One shape entirely inside the other comes back as
that inner shape unchanged; disjoint shapes give an empty `Vector`. A bare
`mode=:region` (or `:boundary`) is shorthand for the same choice on both
sides. Two shapes that share part of a boundary edge or arc drop that shared
piece, the same convention already noted above for two curves that coincide.

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
| polyline, polygon, chain, bounding box | as many as the sides cross | the points on the boundary, see below |
| angle, half-plane or strip with a line, segment, ray, or any conic or arc | **not points** | the part of the other object inside the region, see above |
| angle, half-plane or strip with another one of the three | **not points** | the region common to both, see above |
| angle, half-plane or strip with a straight-sided triangle, quadrilateral or n-gon | **not points** | the part of the polygon inside the region, see above |
| circle, ellipse, or any polygon-family shape with another one of those, given `mode` | **not points** | the clipped curve or the overlap region, see above |
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

!!! details "See script"
    ```julia
    using Apollonius, Luxor
    import Luxor: julia_red, julia_blue, julia_green, julia_purple
    import Apollonius: rotate, translate, distance, midpoint

    lxm = @prepare_to_picture! width=500 height=300 margin=30 begin  
        c = APCircle2(APPoint(0.0, 0.0), 3.0)
        l = APSegment(APPoint(-6.0, 1.0), APPoint(6.0, 1.0))
        r = APRay(APPoint(0.0, -1.0), APPoint(1.0, -1.0))
        s = APSegment(APPoint(-6.0, -2.0), APPoint(0.0, -2.0))
        rl = APLine(APPoint(0.0, -1.0), APPoint(1.0, -1.0))
        sl = APLine(APPoint(-6.0, -2.0), APPoint(0.0, -2.0))
        kept = [intersection(l, c); intersection(r, c); intersection(s, c)]
        dropped = [intersection(rl, c)[1]; intersection(sl, c)[2]]
    end


    begin
    Drawing(lxm.width, lxm.height, :svg)
    origin()
    gsave()
    setline(1); setdash("dash")
    sethue("gray80")
    path([rl, sl], action=:stroke, extend=200)
    grestore()
    sethue(julia_blue)
    path([c, l, s], action=:stroke)
    path(r, action=:stroke, extend=200)
    sethue(julia_purple)
    sethue("gray80")
    sethue("white"); path(kept, action=:fillpreserve); sethue(julia_purple); strokepath()
    sethue("white"); path(dropped, action=:fillpreserve); sethue("gray80"); strokepath()

    finish()
    preview()
    end
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

## Bounded regions: clip and overlap

Two circles, two ellipses, or two polygon-family shapes (straight or curved,
in any combination) accept `mode` on top of the plain boundary-crossing
behavior above:

```@example geo
t1 = APTriangle(APPoint(0.0, 0.0), APPoint(4.0, 0.0), APPoint(2.0, 4.0))
t2 = APTriangle(APPoint(1.0, 1.0), APPoint(5.0, 1.0), APPoint(3.0, 5.0))
intersection(t1, t2; mode=(:boundary, :region))
```

`mode=(:boundary, :region)` kept the part of `t1`'s own boundary that lies
inside `t2`. Asking for `mode=(:region, :region)` instead gives the actual
overlap, as a filled shape of its own:

```@example geo
intersection(t1, t2; mode=:region)
```

```@raw html
<img src="../assets/img/intersections/region_overlap_polygons.svg" alt="Two triangles whose overlap, a quadrilateral, is filled in purple" style="width:100%; max-width: 700px;">
```

!!! details "See script"
    ```julia
    include("../default_config.jl")
    lxm, lxo = @prepare_to_picture width=500 height=280 margin=30 begin
        t1 = APTriangle(APPoint(0.0, 0.0), APPoint(4.0, 0.0), APPoint(2.0, 4.0))
        t2 = APTriangle(APPoint(1.0, 1.0), APPoint(5.0, 1.0), APPoint(3.0, 5.0))
        overlap = only(intersection(t1, t2; mode=:region))
    end
    (; t1, t2, overlap) = lxo
    @svg_doc(lxm, @__FILE__, begin
    sethue(julia_purple); setopacity(0.25)
    path(overlap; action=:fill)
    setopacity(1.0)
    sethue(julia_blue)
    path([t1, t2], action=:stroke)
    sethue(julia_purple)
    path(overlap; action=:stroke)
    sethue("white"); path(vertices(overlap), action=:fillpreserve); sethue(julia_purple); strokepath()
    end)
    ```

The same `mode=:region` works for two circles, giving the lens between them:

```@example geo
c1 = APCircle2(APPoint(0.0, 0.0), 3.0)
c2 = APCircle2(APPoint(4.0, 0.0), 3.0)
lens = only(intersection(c1, c2; mode=:region))
area(lens)
```

```@raw html
<img src="../assets/img/intersections/region_overlap_circles.svg" alt="Two circles whose lens-shaped overlap is filled in purple" style="width:100%; max-width: 700px;">
```

!!! details "See script"
    ```julia
    include("../default_config.jl")
    lxm, lxo = @prepare_to_picture width=500 height=280 margin=30 begin
        c1 = APCircle2(APPoint(0.0, 0.0), 3.0)
        c2 = APCircle2(APPoint(4.0, 0.0), 3.0)
        lens = only(intersection(c1, c2; mode=:region))
    end
    (; c1, c2, lens) = lxo
    @svg_doc(lxm, @__FILE__, begin
    sethue(julia_purple); setopacity(0.25)
    path(lens; action=:fill)
    setopacity(1.0)
    sethue(julia_blue)
    path([c1, c2], action=:stroke)
    sethue(julia_purple)
    path(lens; action=:stroke)
    end)
    ```

A shape entirely inside another comes back unchanged, and disjoint shapes give
an empty `Vector`, for every combination in scope, mixed types included (a
polygon and a circle, an ellipse and a curved polygon-family shape, and so
on):

```@example geo
small = APCircle2(APPoint(0.0, 0.0), 1.0)
big = APCircle2(APPoint(0.0, 0.0), 5.0)
intersection(small, big; mode=:region), intersection(small, APCircle2(APPoint(50.0, 0.0), 1.0); mode=:region)
```

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
  two circles, and it exists even when they do not meet. [`radical_center`](@ref)
  is the same idea for three circles: the one point where all three radical
  axes meet, and [`radical_circle`](@ref) the circle centered there that cuts
  all three at right angles.
* [`tangent_points`](@ref) and [`tangent_lines`](@ref) give the points and lines of
  tangency from a point to a circle, and [`external_tangent_lines`](@ref) and
  [`internal_tangent_lines`](@ref) the common tangents of two circles. All
  of them are in [Circles: How They Relate](@ref).
* [`diagonal_intersection`](@ref) is the point where a quadrilateral's two
  diagonals cross, in [Polygons: Named Constructors & Quadrilaterals](@ref).
