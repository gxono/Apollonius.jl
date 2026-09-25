```@meta
CurrentModule = Apollonius
```

# Cookbook: Building & Moving Shapes

## Building shapes from what you have

### A line, a ray or a segment from a point and a direction

```@example geo
using Apollonius

p = APPoint(1.0, 1.0)
APLine(p, APVector(2.0, 1.0)), APRay(p, pi / 2), APSegment(p, 5.0, pi / 3)
```

```@raw html
<img src="../assets/img/points_lines/from_direction.svg" alt="A line from a point and a vector, a ray from a point and an angle and a segment from a point, a length and an angle" style="width:100%; max-width: 700px;">
```

!!! details "See script"
    ```julia
    using Apollonius, Luxor
    import Luxor: julia_red, julia_blue, julia_green, julia_purple
    import Apollonius: rotate, translate, distance, midpoint

    lxm = @prepare_to_picture! width=500 height=240 margin=20 begin
        p = APPoint(-1.0, -1.0)
        v = APVector(2.0, 1.0)
        vec = APEquipollentVector(v, p)
        l = APLine(p, v)

        q = APPoint(5.0, -1.0)
        seg = APSegment(q, 3.0, 2pi / 3)
        ang_seg = APAngle2(q, q + APVector(1.0, 0), seg.p2)

        r0 = APPoint(-3.0, 3.0)
        ray = APRay(r0, -pi / 4)
        ang_ray = reverse(APAngle2(r0, r0 + APVector(1.0, 0), ray.through))
    end


    begin
    Drawing(lxm.width, lxm.height, :svg)
    origin(); fontsize(15)

    arc_seg = only(marks(ang_seg; size=50))
    arc_ray = only(marks(ang_ray; size=50))
    @layer begin
        sethue(julia_blue); setopacity(0.25)
        path(APCircularSector2(arc_seg), action=:fill)
        path(APCircularSector2(arc_ray), action=:fill)
        setopacity(1)
        path(arc_seg, action=:stroke)
        path(arc_ray, action=:stroke)
    end

    sethue(julia_purple)
    path(l, action=:stroke)
    path(ray, action=:stroke)
    path(seg, action=:stroke)

    sethue(julia_blue)
    path(vec; as=:arrow, action=:stroke)

    sethue(julia_red)
    text("line", p + APVector(-5.0, -5.0), halign=:right, direction=l, valign=:bottom)
    text("segment", midpoint(seg) + APVector(3,0), direction=-direction(seg), halign=:right, valign=:bottom)
    text("ray", r0 + APVector(-8.0,5.0), direction=ray, valign=:top)

    sethue("white")
    path([p, q, r0], action=:fillpreserve)
    sethue(julia_blue); strokepath()

    finish()
    preview()
    end
    ```

### Cut a segment in equal parts, or in a ratio

```@example geo
s = APSegment(APPoint(0.0, 0.0), APPoint(8.0, 0.0))
divide_segment(s, 4), divide_segment(s, 1, 2), point_at_distance(s, 6.5)
```

```@raw html
<img src="../assets/img/points_lines/divide_points.svg" alt="A segment with its three quarter points, the point that divides it 1 to 2 and the point at distance 6.5" style="width:100%; max-width: 700px;">
```

### Points spread evenly on a circle, an arc or a segment

```@example geo
equally_spaced_points(APCircle2(APPoint(0.0, 0.0), 2.0), 6)
```

```@raw html
<img src="../assets/img/points_lines/equally_spaced.svg" alt="Points spread evenly along a segment (both ends included) and around a circle" style="width:100%; max-width: 700px;">
```

### An angle of a given measure, or between two lines

```@example geo
a60 = angle_with_measure(APPoint(0.0, 0.0), APPoint(4.0, 0.0), pi / 3)
rad2deg(measure(a60)), rad2deg(measure(APAngle2(APLine(APPoint(0.0, 0.0), APPoint(1.0, 0.0)), APLine(APPoint(0.0, 0.0), APPoint(1.0, 1.0)))))
```

```@raw html
<img src="../assets/img/points_lines/angle_from_measure.svg" alt="An angle of 60 degrees built from a ray and a measure, and the angle between two crossing lines" style="width:100%; max-width: 700px;">
```

!!! details "See script"
    ```julia
    using Apollonius, Luxor
    import Luxor: julia_red, julia_blue, julia_green, julia_purple
    import Apollonius: rotate, translate, distance, midpoint

    lxm = @prepare_to_picture! width=560 height=260 margin=30 begin
        O1, P1 = APPoint(0.0, 0.0), APPoint(4.0, 0.0)
        ang1 = angle_with_measure(O1, P1, pi / 3)
        r1 = [APSegment(O1, P1), APSegment(O1, ang1.b)]
        l1 = APLine(APPoint(7.0, 0.0), APPoint(11.0, 1.0))
        l2 = APLine(APPoint(7.0, 3.0), APPoint(11.0, 0.0))
        ends = [APPoint(7.0, 0.0), APPoint(11.0, 1.0), APPoint(7.0, 3.0), APPoint(11.0, 0.0)]
        ang2 = APAngle2(APLine(ends[3], ends[4]), APLine(ends[1], ends[2]))
    end


    begin
    Drawing(lxm.width, lxm.height, :svg)
    origin(); fontsize(15)

    sethue(julia_blue)
    path(r1, action=:stroke)
    path([l1, l2], action=:stroke, extend=300)
    sethue(julia_purple)
    path(marks(ang1; size=40); action=:stroke)
    path(marks(ang2; size=40); action=:stroke)
    sethue(julia_red)
    label("60°", label_anchor(ang1; dist=64)...); label("θ", label_anchor(ang2; dist=64)...)

    finish()
    preview()
    end
    ```

### The tangent and the normal at a point of a curve

```@example geo
e = APEllipse2(APPoint(0.0, 0.0), 5.0, 3.0)
pt = point_on(e, 1.0)
is_on_line(pt, tangent_line(e, pt)), is_perpendicular(tangent_line(e, pt), normal_line(e, pt))
```

```@raw html
<img src="../assets/img/points_lines/tangent_normal.svg" alt="An ellipse with the tangent and the normal line at one of its points" style="width:100%; max-width: 700px;">
```

### A regular polygon on a side, and a star

```@example geo
a, b = APPoint(0.0, 0.0), APPoint(3.0, 0.0)
area(regular_polygon_on_segment(a, b, 5)), length(vertices(star_polygon(APPoint(0.0, 0.0), APPoint(3.0, 0.0), 5, 2)))
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

### A rhombus, a rectangle, a trapezoid or a kite

```@example geo
a, b = APPoint(0.0, 0.0), APPoint(4.0, 0.0)
area(rhombus_on_segment(a, b, pi / 3)), area(rectangle_from_diagonal(a, APPoint(4.0, 3.0), 0.5)), area(isosceles_trapezoid_on_segment(a, b, 2.0, 2.5)), area(kite_on_diagonal(a, APPoint(0.0, 4.0), 0.6, 1.5))
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

### A circle inside or around a quadrilateral

```@example geo
trap = isosceles_trapezoid_on_segment(APPoint(0.0, 0.0), APPoint(6.0, 0.0), 2.0, 3.0)
kite = kite_on_diagonal(APPoint(0.0, 0.0), APPoint(0.0, 7.0), 0.35, 2.0)
circumcircle(trap).r, incircle(kite).r
```

```@raw html
<img src="../assets/img/polygons/quad_circles.svg" alt="An isosceles trapezoid with its circumcircle and a kite with its incircle" style="width:100%; max-width: 700px;">
```

### Round the corners of a polygon or a polyline

```@example geo
sq = APStraightNgon([APPoint(0.0, 0.0), APPoint(4.0, 0.0), APPoint(4.0, 4.0), APPoint(0.0, 4.0)])
rounded = round_corners(sq, 1.0)
length(sides(rounded)), area(rounded)
```

```@raw html
<img src="../assets/img/circles/round_corners.svg" alt="A pentagon and a polyline with their corners rounded, the originals dashed" style="width:100%; max-width: 700px;">
```

### Move a polygon outward or inward, or grow a box

```@example geo
area(offset_polygon(sq, 1.0)), area(offset_polygon(sq, -1.0)), inflate(APBoundingBox(APPoint(0.0, 0.0), 4.0, 2.0), 1.0)
```

```@raw html
<img src="../assets/img/polygons/offset_box.svg" alt="A pentagon with its outward and inward offsets, and a box with its inflated box" style="width:100%; max-width: 700px;">
```

### An arc through three points, or with a given radius

```@example geo
arc_through_points(APPoint(0.0, 0.0), APPoint(2.0, 1.5), APPoint(4.0, 0.0)), arc_with_radius(APPoint(7.0, 0.0), APPoint(10.0, 0.0), 2.0)
```

```@raw html
<img src="../assets/img/circles/arcs_from_data.svg" alt="An arc through three points, and the short and the long arc of radius 2 between two points" style="width:100%; max-width: 700px;">
```

### A circle tangent to a line at a given point

```@example geo
l = APLine(APPoint(-3.0, 0.0), APPoint(9.0, 0.0))
tangent_circle_at_point(l, APPoint(2.0, 0.0), APPoint(0.0, 2.0)), length(tangent_circles_at_point(l, APPoint(2.0, 0.0), 1.2))
```

```@raw html
<img src="../assets/img/tangency/tangent_at_point.svg" alt="A line, a point on it and a point off it, the circle tangent at the first through the second, and the two circles of radius 1.2 tangent at the first" style="width:100%; max-width: 700px;">
```

### A triangle around a circle

```@example geo
c = APCircle2(APPoint(0.0, 0.0), 1.0)
t = circumscribed_triangle(c, point_on(c, 0.5), point_on(c, 2.5), point_on(c, 4.5))
isapprox(incircle(t), c; atol=1e-9)
```

```@raw html
<img src="../assets/img/triangles/circumscribed.svg" alt="A circle with three points on it and the triangle whose sides touch the circle at them" style="width:100%; max-width: 700px;">
```

### A conic from a focus and a directrix

```@example geo
F, d = APPoint(0.0, 0.0), APLine(APPoint(4.0, -1.0), APPoint(4.0, 1.0))
typeof(conic_with_focus(F, d, 0.5)), typeof(conic_with_focus(F, d, 1.0)), typeof(conic_with_focus(F, d, 2.0))
```

```@raw html
<img src="../assets/img/conics/focus_directrix.svg" alt="An ellipse, a parabola and a hyperbola with the same focus and directrix" style="width:100%; max-width: 700px;">
```

!!! details "See script"
    ```julia
    using Apollonius, Luxor
    import Luxor: julia_red, julia_blue, julia_green, julia_purple
    import Apollonius: rotate, translate, distance, midpoint

    lxm = @prepare_to_picture! width=560 height=240 margin=20 begin
        F = APPoint(0.0, 0.0)
        dl = APSegment(APPoint(4.0, -5.0), APPoint(4.0, 5.0))
        d = APLine(dl.p1, dl.p2)
        ell = conic_with_focus(F, d, 0.5)
        par = conic_with_focus(F, d, 1.0)
        hyp = conic_with_focus(F, d, 2.0)
        parc = APParabolicArc2(par, point_on(par, -6.0), point_on(par, 6.0))
        harc = APHyperbolicArc2(hyp, point_on(hyp, -1.1; branch=-1), point_on(hyp, 1.1; branch=-1))
    end


    begin
    Drawing(lxm.width, lxm.height, :svg)
    origin(); fontsize(15)

    sethue(julia_blue)
    path(dl, action=:stroke)
    sethue(julia_purple)
    path([ell, parc, harc], action=:stroke)
    sethue(julia_red)
    label("F", :W, F, offset=8)
    label("e = 1", :N, parc.p1)
    label("e = 2", :S, harc.p1)
    text("directrix", dl.p2 + APVector(5.0,0.0), angle=pi/2)
    label("e = 0.5", :W, point_on(ell, pi), offset=8)

    sethue("white")
    path(F, action=:fillpreserve)
    sethue(julia_blue); strokepath()

    finish()
    preview()
    end
    ```

### An ellipse from a center, a vertex and a point

```@example geo
el = ellipse_with_axis(APPoint(0.0, 0.0), APPoint(5.0, 0.0), APPoint(3.0, 2.4))
el.a, el.b
```

```@raw html
<img src="../assets/img/conics/ellipse_axis.svg" alt="An ellipse built from its center, one vertex and a point on it" style="width:100%; max-width: 700px;">
```

### A hyperbola from its asymptotes

```@example geo
hy = hyperbola_with_asymptotes(APLine(APPoint(0.0, 0.0), APPoint(1.0, 1.0)), APLine(APPoint(0.0, 0.0), APPoint(1.0, -1.0)), APPoint(2.0, 0.0))
hy.a, hy.b
```

```@raw html
<img src="../assets/img/conics/asymptotes_ctor.svg" alt="A hyperbola built from its two asymptotes and a point on it" style="width:100%; max-width: 700px;">
```

### A parabola through three points

```@example geo
pa = parabola_through_points(APPoint(-2.0, 4.0), APPoint(0.0, 0.0), APPoint(1.0, 1.0), APVector(0.0, 1.0))
pa.focus
```

```@raw html
<img src="../assets/img/conics/parabola_ctor.svg" alt="A parabola through three points with a vertical axis" style="width:100%; max-width: 700px;">
```

### A similarity from two points and their images

```@example geo
m = similarity_map(APPoint(0.0, 0.0) => APPoint(1.0, 1.0), APPoint(1.0, 0.0) => APPoint(1.0, 2.0))
m(APPoint(0.0, 1.0)), scaling_map(2.0, 0.5)(APPoint(1.0, 1.0)), shear_map(1.0)(APPoint(0.0, 2.0))
```

```@raw html
<img src="../assets/img/affine/similarity_shear.svg" alt="A square and its images under a similarity, a scaling and a shear" style="width:100%; max-width: 700px;">
```

!!! details "See script"
    ```julia
    using Apollonius, Luxor
    import Luxor: julia_red, julia_blue, julia_green, julia_purple
    import Apollonius: rotate, translate, distance, midpoint

    lxm = @prepare_to_picture! width=560 height=240 margin=30 begin
        s1 = square_with_center(APPoint(0.0, 0.0), 2.0)
        s2 = square_with_center(APPoint(5.0, 0.0), 2.0)
        s3 = square_with_center(APPoint(10.0, 0.0), 2.0)
        @unbounded m1 = similarity_map(1.4, 0.4, APPoint(0.0, 0.0))
        @unbounded m2 = scaling_map(1.8, 0.6, APPoint(5.0, 0.0))
        @unbounded m3 = shear_map(0.6, 0.0, APPoint(10.0, 0.0))
        i1, i2, i3 = m1(s1), m2(s2), m3(s3)
        labs = [APPoint(0.0, -3.2), APPoint(5.0, -3.2), APPoint(10.0, -3.2)]
    end


    begin
    Drawing(lxm.width, lxm.height, :svg)
    origin(); fontsize(14)

    sethue(julia_blue)
    path([s1, s2, s3], action=:stroke)
    sethue(julia_purple)
    path([i1, i2, i3], action=:stroke)
    sethue(julia_red)
    for (n, p) in zip(("similarity_map", "scaling_map", "shear_map"), labs)
        label(n, :S, p)
    end

    finish()
    preview()
    end
    ```


## Moving things

### Rotate, scale or reflect a whole shape

```@example geo
t = APTriangle(APPoint(0.0, 0.0), APPoint(3.0, 0.0), APPoint(0.0, 4.0))
O = APPoint(0.0, 0.0)
isapprox(rotate(t, pi / 2), APTriangle(O, APPoint(0.0, 3.0), APPoint(-4.0, 0.0)); atol=1e-9), area(homothety(t, 2.0)) ≈ 4 * area(t), reflection(t, APLine(O, APPoint(0.0, 1.0))) ≈ APTriangle(O, APPoint(-3.0, 0.0), APPoint(0.0, 4.0))
```

```@raw html
<img src="../assets/img/macros/rotate.svg" alt="A triangle and a circle rotated a quarter turn about a point" style="width:100%; max-width: 700px;">
```

Every type accepts these. `rotate` and `homothety` turn and scale about the origin
unless you give a center as the last argument, as in `rotate(t, pi / 2, c)`. See
[Affine Maps](@ref).

### Repeat a shape in a circular pattern

Broadcast [`rotate`](@ref) over a vector of angles to place several copies
of the same shape evenly around a center, the same idea behind
[Building the package logo](@ref):

```@example geo
center = APPoint(0.0, 0.0)
petal = APCircle2(APPoint(3.0, 0.0), 1.2)
copies = rotate.(petal, (1:5) .* (2pi / 6), center)   # 5 more, 6 in total
length(copies)
```

```@raw html
<img src="../assets/img/cookbook/rosette.svg" alt="A circle repeated six times in a ring around a center" style="width:100%; max-width: 700px;">
```

### Apply several steps as one

```@example geo
m = rotation_map(pi / 2, APPoint(0.0, 0.0)) ∘ translation_map(APVector(3.0, 0.0))
isapprox(m(APPoint(0.0, 0.0)), APPoint(0.0, 3.0); atol=1e-9)
```

```@raw html
<img src="../assets/img/affine/composed.svg" alt="A triangle, its translation and the composition of the translation and a rotation" style="width:100%; max-width: 700px;">
```

### A map from three points and their images

```@example geo
m = affine_map(APPoint(0.0, 0.0) => APPoint(1.0, 1.0), APPoint(1.0, 0.0) => APPoint(3.0, 1.0), APPoint(0.0, 1.0) => APPoint(1.0, 4.0))
m(APPoint(1.0, 1.0))
```

```@raw html
<img src="../assets/img/affine/create.svg" alt="A triangle and its image under the affine map defined by three point pairs" style="width:100%; max-width: 700px;">
```

!!! details "See script"
    ```julia
    using Apollonius, Luxor
    import Luxor: julia_red, julia_blue, julia_green, julia_purple
    import Apollonius: rotate, translate, distance, midpoint

    lxm = @prepare_to_picture! width=500 height=300 margin=30 begin
        a = APPoint(0.0, 0.0)
        b = APPoint(1.0, 0.0)
        c = APPoint(0.0, 1.0)
        a2 = APPoint(2.0, 3.0)
        b2 = APPoint(5.0, 3.0)
        c2 = APPoint(2.0, 7.0)
        @unbounded m = affine_map(a => a2, b => b2, c => c2)
        t = APTriangle(a, b, c)
        timg = m(t)
    end


    begin
    Drawing(lxm.width, lxm.height, :svg)
    origin(); fontsize(15)

    gsave()
    setline(1); setdash("dash")
    sethue(julia_green)
    path([APSegment(a, a2), APSegment(b, b2), APSegment(c, c2)], action=:stroke)
    grestore()
    sethue(julia_blue)
    path(t, action=:stroke)
    sethue(julia_purple)
    path(timg, action=:stroke)
    sethue(julia_red)
    label("a", :S, a, offset=8);
    label("b", :S, b, offset=8);
    label("c", :W, c, offset=8)
    label("a'", :S, a2, offset=8);
    label("b'", :S, b2, offset=8);
    label("c'", :W, c2, offset=8)
    sethue("white"); path([a, b, c], action=:fillpreserve); sethue(julia_blue); strokepath()
    sethue("white"); path([a2, b2, c2], action=:fillpreserve); sethue(julia_purple); strokepath()

    finish()
    preview()
    end
    ```

### Transform several objects with one macro

```@example geo
c = APCircle2(APPoint(1.0, 2.0), 3.0)
s = APSegment(APPoint(0.0, 0.0), APPoint(4.0, 0.0))
C2, S2 = @rotate (pi / 2) begin
    c
    s
end
C2.r, C2.center ≈ APPoint(-2.0, 1.0)
```

```@raw html
<img src="../assets/img/cookbook/macro_rotate.svg" alt="A circle and a segment with their images rotated a quarter turn about the origin" style="width:100%; max-width: 700px;">
```

See [Macros: Transforming Shapes](@ref).

