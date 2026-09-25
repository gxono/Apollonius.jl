```@meta
CurrentModule = Apollonius
```

# Polygons: Named Constructors & Quadrilaterals

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
using Apollonius

a, b, c = APPoint(0.0, 0.0), APPoint(4.0, 0.0), APPoint(5.0, 2.0)

parallelogram(a, b, c)          # 4th vertex completed as a + (c - b)
square_on_segment(a, b)         # built counterclockwise from a to b by default
rectangle_on_segment(a, b, 2.0) # same, with an explicit height instead of |a-b|
regular_polygon(APPoint(0.0, 0.0), APPoint(1.0, 0.0), 6)  # a regular hexagon
```

```@raw html
<img src="../assets/img/polygons/pol_nam.svg" alt="A parallelogram, a square, a rectangle, and a regular hexagon, each built by a named constructor" style="width:100%;">
```

!!! details "See script"
    ```julia
    using Apollonius, Luxor
    import Luxor: julia_red, julia_blue, julia_green, julia_purple
    import Apollonius: rotate, translate, distance, midpoint

    lxm = @prepare_to_picture! width=500 height=240 margin=20 begin
        a, b, c = APPoint(0.0, 0.0), APPoint(4.0, 0.0), APPoint(5.0, 2.0)
        d = APPoint(1.0, 0.0)
        pa = parallelogram(a, b, c)
        ps = square_on_segment(a, b)
        pr = rectangle_on_segment(a, b, 2.0)
        pp = regular_polygon(a, d, 6)
    end


    begin
    Drawing(lxm.width, lxm.height, :svg)
    origin()

    sethue(julia_purple)
    path([pa, ps, pr, pp], action=:stroke)
    sethue("white"); path([a, b, c, d], action=:fillpreserve); sethue(julia_blue); strokepath()

    finish()
    preview()
    end
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

!!! details "See script"
    ```julia
    using Apollonius, Luxor
    import Luxor: julia_red, julia_blue, julia_green, julia_purple
    import Apollonius: rotate, translate, distance, midpoint

    lxm = @prepare_to_picture! width=560 height=220 margin=30 begin
        pent = regular_polygon_on_segment(APPoint(0.0, 0.0), APPoint(3.0, 0.0), 5)
        hexa = regular_polygon_on_segment(APPoint(7.0, 0.0), APPoint(10.0, 0.0), 6)
        tri = regular_polygon_on_segment(APPoint(13.0, 0.0), APPoint(16.0, 0.0), 3; ccw=false)
        star = star_polygon(APPoint(20.0, 2.0), APPoint(20.0, 4.0), 5, 2)
        bases = [APSegment(APPoint(0.0, 0.0), APPoint(3.0, 0.0)), APSegment(APPoint(7.0, 0.0), APPoint(10.0, 0.0)), APSegment(APPoint(13.0, 0.0), APPoint(16.0, 0.0))]
    end


    begin
    Drawing(lxm.width, lxm.height, :svg)
    origin()

    sethue(julia_blue)
    path(bases, action=:stroke)
    sethue(julia_purple)
    path([pent, hexa, tri, star], action=:stroke)

    finish()
    preview()
    end
    ```

```@raw html
<img src="../assets/img/polygons/quad_family.svg" alt="A rhombus, a square, a rectangle, an isosceles trapezoid, a right trapezoid, a kite and a turned rectangle" style="width:100%; max-width: 700px;">
```

!!! details "See script"
    ```julia
    using Apollonius, Luxor
    import Luxor: julia_red, julia_blue, julia_green, julia_purple
    import Apollonius: rotate, translate, distance, midpoint

    lxm = @prepare_to_picture! width=560 height=320 margin=30 begin
        rh = rhombus_on_segment(APPoint(0.0, 0.0), APPoint(3.0, 0.0), pi / 3)
        sq = square_from_diagonal(APPoint(5.0, 0.0), APPoint(8.0, 3.0))
        re = rectangle_from_diagonal(APPoint(10.0, 0.0), APPoint(15.0, 3.0), 0.5)
        it = isosceles_trapezoid_on_segment(APPoint(0.0, -5.0), APPoint(4.0, -5.0), 2.0, 2.5)
        rt = right_trapezoid_on_segment(APPoint(6.0, -5.0), APPoint(10.0, -5.0), 2.0, 2.5)
        kt = kite_on_diagonal(APPoint(13.0, -5.0), APPoint(13.0, -1.0), 0.6, 1.5)
        rc = rectangle_with_center(APPoint(16.5, -3.0), 3.0, 1.5; angle=0.6)
    end


    begin
    Drawing(lxm.width, lxm.height, :svg)
    origin()

    sethue(julia_purple)
    path([rh, sq, re, it, rt, kt, rc], action=:stroke)

    finish()
    preview()
    end
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

