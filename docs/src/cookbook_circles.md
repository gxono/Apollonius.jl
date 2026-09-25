```@meta
CurrentModule = Apollonius
```

# Cookbook: Circles

## Working with circles

### The circle through three points

```@example geo
using Apollonius

c = APCircle2(APPoint(0.0, 0.0), APPoint(6.0, 0.0), APPoint(1.5, 4.0))
c.center, c.r
```

```@raw html
<img src="../assets/img/circles/circle_3p.svg" alt="Three points and the circle through them" style="width:100%; max-width: 700px;">
```

### A circle from its diameter, or from a center and a point on it

```@example geo
A, B = APPoint(0.0, 0.0), APPoint(6.0, 0.0)
by_diameter = circle_with_diameter(A, B)      # or circle_with_diameter(APSegment(A, B))
by_point = APCircle2(A, APPoint(3.0, 4.0))     # center A, through the second point
by_diameter.r, by_point.r
```

```@raw html
<img src="../assets/img/circles/circle_diameter.svg" alt="A segment, the circle that has it as a diameter, and a point of the circle that sees the segment under a right angle" style="width:100%; max-width: 700px;">
```

!!! details "See script"
    ```julia
    using Apollonius, Luxor
    import Luxor: julia_red, julia_blue, julia_green, julia_purple
    import Apollonius: rotate, translate, distance, midpoint

    lxm = @prepare_to_picture! width=500 height=280 margin=30 begin  
        d = APSegment(APPoint(0.0, 0.0), APPoint(6.0, 2.0))
        c = circle_with_diameter(d)
        p = point_on(c, 1.0)
        legs = [APSegment(p, d.p1), APSegment(p, d.p2)]
        ang = APAngle2(p, d.p1, d.p2)
    end


    begin
    Drawing(lxm.width, lxm.height, :svg)
    origin(); fontsize(15)
    gsave()
    setline(1); setdash("dash")
    sethue(julia_green)
    path(legs, action=:stroke)
    grestore()
    sethue(julia_blue)
    path(d, action=:stroke)
    sethue(julia_purple)
    path(c, action=:stroke)
    path(only(marks(APAngle2(p, d.p1, d.p2); style=:parallelogram, size=14)); action=:stroke)
    sethue(julia_red)
    label("center", :S, c.center); label("p", :N, p)
    sethue("white"); path([d.p1, d.p2], action=:fillpreserve); sethue(julia_blue); strokepath()
    sethue("white"); path([c.center, p], action=:fillpreserve); sethue(julia_purple); strokepath()

    finish()
    preview()
    end
    ```

### Where a line or two circles meet

```@example geo
c1, c2 = APCircle2(APPoint(0.0, 0.0), 3.0), APCircle2(APPoint(4.0, 0.0), 3.0)
l = APLine(APPoint(-4.0, 1.0), APPoint(4.0, 1.0))
intersection(c1, c2), intersection(l, c1)
```

```@raw html
<img src="../assets/img/cookbook/circle_intersections.svg" alt="Two circles crossing at two points, and a line crossing one of them at two other points" style="width:100%; max-width: 700px;">
```

An empty result means no intersection; see [Intersections](@ref) for
tangency and every other pair of shapes `intersection` accepts.

### The tangent lines from a point to a circle

```@example geo
c = APCircle2(APPoint(0.0, 0.0), 3.0)
p = APPoint(7.0, 0.0)
tangent_points(c, p), tangent_length(c, p)
```

```@raw html
<img src="../assets/img/cookbook/tangent_from_point.svg" alt="A circle, an outside point, the two tangent segments and their points of contact" style="width:100%; max-width: 700px;">
```

### The common tangents of two circles

```@example geo
c1, c2 = APCircle2(APPoint(0.0, 0.0), 3.0), APCircle2(APPoint(10.0, 0.0), 1.5)
length(external_tangent_lines(c1, c2)), length(internal_tangent_lines(c1, c2))
```

```@raw html
<img src="../assets/img/circles/similitude_center.svg" alt="Two circles with their external and internal common tangents" style="width:100%; max-width: 700px;">
```

### The radical axis of two circles

```@example geo
c1, c2 = APCircle2(APPoint(0.0, 0.0), 3.0), APCircle2(APPoint(4.0, 0.0), 2.0)
radical_axis(c1, c2)
```

```@raw html
<img src="../assets/img/circles/circle_radical.svg" alt="Two circles and their radical axis" style="width:100%; max-width: 700px;">
```

!!! details "See script"
    ```julia
    using Apollonius, Luxor
    import Luxor: julia_red, julia_blue, julia_green, julia_purple
    import Apollonius: rotate, translate, distance, midpoint

    lxm = @prepare_to_picture! width=500 height=240 margin=20 begin
        c1 = APCircle2(APPoint(0.0, 0.0), 3.0)
        c2 = APCircle2(APPoint(8.0, 0.0), 2.0)
        c3 = APCircle2(APPoint(3.0, 6.0), 4.0)
        ra1 = radical_axis(c1, c2)
        ra2 = radical_axis(c2, c3)
        ra3 = radical_axis(c3, c1)
        rc = radical_center(c1, c2, c3)
        rcirc = radical_circle(c1, c2, c3)
    end


    begin
    Drawing(lxm.width, lxm.height, :svg)
    origin()
    sethue("gray80")
    setdash(:dash)
    path(APSegment(c1.center, c3.center), action=:stroke)
    path(APSegment(c2.center, c3.center), action=:stroke)
    path([ra2, ra3], action=:stroke)
    sethue(julia_purple)
    path(APSegment(c1.center, c2.center), action=:stroke)
    setdash(:solid)
    sethue(julia_blue)
    path([c1,c2,c3], action=:stroke)
    sethue(julia_purple)
    path(rcirc, action=:stroke)
    path(ra1, action=:stroke)
    sethue("white"); path(rc, action=:fillpreserve); sethue(julia_purple); strokepath()
    sethue("white"); path([c1.center, c2.center, c3.center], action=:fillpreserve); sethue(julia_blue); strokepath()

    finish()
    preview()
    end
    ```

The line through the two points where the circles cross, when they do.

### A circle orthogonal to another, with a given center

```@example geo
c = APCircle2(APPoint(0.0, 0.0), 3.0)
o = orthogonal_circle(c, APPoint(7.0, 0.0))
o.center, angle_measure_intersection(c, o) ≈ pi / 2
```

```@raw html
<img src="../assets/img/cookbook/orthogonal.svg" alt="A circle and the circle orthogonal to it centered at an outside point, crossing at right angles" style="width:100%; max-width: 700px;">
```

### The power of a point

```@example geo
power_of_point(APPoint(7.0, 0.0), APCircle2(APPoint(0.0, 0.0), 3.0))
```

```@raw html
<img src="../assets/img/circles/circle_tanp.svg" alt="A circle, a point outside it and the tangent segments from the point" style="width:100%; max-width: 700px;">
```

Negative inside the circle, zero on it, and the square of the tangent length
outside.

### Invert a circle or a line

```@example geo
c = APCircle2(APPoint(3.0, 0.0), 1.0)
invert(c, APPoint(0.0, 0.0); k=2.0)
```

```@raw html
<img src="../assets/img/macros/invert.svg" alt="A line and a circle inverted with respect to a circle centered at the origin" style="width:100%; max-width: 700px;">
```

See [Circles: Inversion](@ref) for inverting lines, segments and polygons too.


## Two classical results

### The lune of Hippocrates

The two crescents cut from the semicircles on the legs of a right isosceles
triangle have together the area of the triangle:

```@example geo
A, B, C = APPoint(0.0, 0.0), APPoint(2.0, 0.0), APPoint(1.0, 1.0)
half(p, q) = area(circle_with_diameter(p, q)) / 2   # a semicircle on [p, q]
lunes = half(A, C) + half(C, B) - (half(A, B) - area(APTriangle(A, B, C)))
lunes ≈ area(APTriangle(A, B, C))
```

```@raw html
<img src="../assets/img/cookbook/hippocrates.svg" alt="A right isosceles triangle inscribed in a semicircle, with semicircles on its legs" style="width:100%; max-width: 700px;">
```

### The Apollonius circle of two points

The points whose distances to `A` and `B` are in a fixed ratio lie on a
circle:

```@example geo
A, B = APPoint(0.0, 0.0), APPoint(6.0, 0.0)
c = apollonius_circle(A, B, 2.0)
p = point_on(c, 1.2)
distance(p, A) / distance(p, B) ≈ 2.0
```

```@raw html
<img src="../assets/img/points_lines/ap_circ.svg" alt="The Apollonius circle of two points" style="width:100%; max-width: 700px;">
```
