```@meta
CurrentModule = Apollonius
```

# Cookbook: Polygons

## Working with polygons

### A regular polygon

Give the center and one vertex:

```@example geo
using Apollonius

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

!!! details "See script"
    ```julia
    using Apollonius, Luxor
    import Luxor: julia_red, julia_blue, julia_green, julia_purple
    import Apollonius: rotate, translate, distance, midpoint

    lxm = @prepare_to_picture! width=560 height=220 margin=30 begin
        eq = equilateral_triangle_on_segment(APPoint(0.0, 0.0), APPoint(4.0, 0.0))
        sq = square_on_segment(APPoint(6.0, 0.0), APPoint(10.0, 0.0))
        rc = rectangle_on_segment(APPoint(12.0, 0.0), APPoint(16.0, 0.0), 2.0)
        bases = [APSegment(APPoint(0.0, 0.0), APPoint(4.0, 0.0)), APSegment(APPoint(6.0, 0.0), APPoint(10.0, 0.0)), APSegment(APPoint(12.0, 0.0), APPoint(16.0, 0.0))]
        labs = [APPoint(2.0, -1.0), APPoint(8.0, -1.0), APPoint(14.0, -1.0)]
    end


    begin
    Drawing(lxm.width, lxm.height, :svg)
    origin(); fontsize(15)

    sethue(julia_purple)
    path([eq, sq, rc], action=:stroke)
    sethue(julia_blue)
    path(bases, action=:stroke)
    sethue(julia_red)
    for (n, p) in zip(("equilateral triangle", "square", "rectangle"), labs)
        label(n, :S, p)
    end
    sethue("white"); path(vcat([[b.p1, b.p2] for b in bases]...), action=:fillpreserve); sethue(julia_blue); strokepath()

    finish()
    preview()
    end
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
[Points, Lines & Rays: Special Points & Curves](@ref).

