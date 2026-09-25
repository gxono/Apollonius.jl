```@meta
CurrentModule = Apollonius
```

# Cookbook: Triangles

## Working with triangles

### Build a triangle from a side and two angles

```@example geo
using Apollonius

A, B = APPoint(0.0, 0.0), APPoint(6.0, 0.0)
t = triangle_on_segment(A, B, deg2rad(50), deg2rad(60))
rad2deg(angle_measure_at(t[3], t[1], t[2]))
```

```@raw html
<img src="../assets/img/cookbook/asa_triangle.svg" alt="A triangle built on a base from the angles 50 and 60 degrees at its ends" style="width:100%; max-width: 700px;">
```

!!! details "See script"
    ```julia
    using Apollonius, Luxor
    import Luxor: julia_red, julia_blue, julia_green, julia_purple
    import Apollonius: rotate, translate, distance, midpoint

    lxm = @prepare_to_picture! width=500 height=280 margin=30 begin  
        A, B = APPoint(0.0, 0.0), APPoint(6.0, 0.0)
        t = triangle_on_segment(A, B, deg2rad(50), deg2rad(60))
        angA = APAngle2(t[1], t[2], t[3])
        angB = APAngle2(t[2], t[3], t[1])
    end


    begin
    Drawing(lxm.width, lxm.height, :svg)
    origin(); fontsize(15)

    sethue(julia_blue)
    path(t, action=:stroke)
    sethue(julia_purple)
    path(marks(angA; size=40); action=:stroke)
    path(marks(angB; size=40); action=:stroke)
    sethue(julia_red)
    label("50°", label_anchor(angA; dist=62)...); label("60°", label_anchor(angB; dist=62)...)
    label("A", :SW, A); label("B", :SE, B)
    sethue("white"); path([A, B], action=:fillpreserve); sethue(julia_blue); strokepath()
    sethue("white"); path([t[3]], action=:fillpreserve); sethue(julia_purple); strokepath()

    finish()
    preview()
    end
    ```

The same idea, with other data: [`triangle_on_segment_sas`](@ref) (an angle
and a side), [`triangle_on_segment_sss`](@ref) (three sides) and the named
ones such as [`equilateral_triangle_on_segment`](@ref). See
[Triangles: The Classical Centers](@ref).

### An equilateral triangle on a segment

```@example geo
A, B = APPoint(0.0, 0.0), APPoint(4.0, 0.0)
eq = equilateral_triangle_on_segment(A, B)
distance(eq[3], A) ≈ 4.0, distance(eq[3], B) ≈ 4.0
```

```@raw html
<img src="../assets/img/triangles/tronseg_eq.svg" alt="An equilateral triangle on a segment" style="width:100%; max-width: 700px;">
```

Pass `ccw=false` for the other side of the segment.

### The classical centers, and the Euler line

```@example geo
t = APTriangle(APPoint(0.0, 0.0), APPoint(8.0, 0.0), APPoint(3.0, 6.0))
is_on_line(centroid(t), euler_line(t)), is_on_line(orthocenter(t), euler_line(t)), is_on_line(circumcenter(t), euler_line(t))
```

```@raw html
<img src="../assets/img/triangles/tri_cen.svg" alt="A triangle with its centroid, circumcenter, orthocenter and the Euler line" style="width:100%; max-width: 700px;">
```

!!! details "See script"
    ```julia
    using Apollonius, Luxor
    import Luxor: julia_red, julia_blue, julia_green, julia_purple
    import Apollonius: rotate, translate, distance, midpoint

    lxm = @prepare_to_picture! width=500 height=240 margin=20 begin  
        A, B, C = APPoint(0.0,0), APPoint(10,0), APPoint(7,5)
        triangle =  APTriangle(A, B, C)
        G = centroid(triangle)
        O = circumcenter(triangle)
        I = incenter(triangle)
        H = orthocenter(triangle)
        l = euler_line(triangle)
        lados = APLine.(sides(triangle))
        @unbounded cc = circumcircle(triangle)
        ic = incircle(triangle)
        iv = projection.(I, lados)
        npc = nine_point_circle(triangle)
        npc_c = nine_point_center(triangle)
        ep = collect(euler_points(triangle))
        ips = reduce(vcat, intersection.(npc, lados))
    end


    begin
    Drawing(lxm.width, lxm.height, :svg)
    origin()

    sethue("gray80")
    @layer begin
    	setline(1); setdash(:dash)
    	path([cc, ic, APSegment.([O,I], [A,iv[2]])...], action=:stroke)
    end

    sethue(julia_purple)
    path([l, npc], action=:stroke)
    sethue(julia_blue)
    path(triangle, action=:stroke)

    sethue("white")
    path([G,O,I,H,[iv; ips; ep]...], action=:fillpreserve)
    sethue(julia_purple); strokepath()
    sethue("white")
    path([A,B,C], action=:fillpreserve)
    sethue(julia_blue); strokepath()
    sethue("white")
    path(npc_c, action=:fillpreserve)
    sethue("gray80"); strokepath()

    finish()
    preview()
    end
    ```

### The nine-point circle

```@example geo
t = APTriangle(APPoint(0.0, 0.0), APPoint(8.0, 0.0), APPoint(3.0, 6.0))
npc = nine_point_circle(t)
npc ≈ circumcircle(medial_triangle(t)), npc.r ≈ circumradius(t) / 2
```

```@raw html
<img src="../assets/img/cookbook/nine_point.svg" alt="A triangle and its nine-point circle through the midpoints, the feet of the altitudes and the Euler points" style="width:100%; max-width: 700px;">
```

### The law of sines

```@example geo
t = APTriangle(APPoint(0.0, 0.0), APPoint(8.0, 0.0), APPoint(3.0, 6.0))
a = distance(t[2], t[3])
a / sin(angle_measure_at(t[1], t[2], t[3])) ≈ 2 * circumradius(t)
```

```@raw html
<img src="../assets/img/cookbook/law_sines.svg" alt="A triangle with its circumcircle, the angle at A, the side a and the circumradius R" style="width:100%; max-width: 700px;">
```

!!! details "See script"
    ```julia
    using Apollonius, Luxor
    import Luxor: julia_red, julia_blue, julia_green, julia_purple
    import Apollonius: rotate, translate, distance, midpoint

    lxm = @prepare_to_picture! width=500 height=320 margin=30 begin  
        A, B, C = APPoint(0.0, 0.0), APPoint(8.0, 0.0), APPoint(3.0, 6.0)
        t = APTriangle(A, B, C)
        cc = circumcircle(t)
        O = circumcenter(t)
        angA = APAngle2(A, B, C)
        radius = APSegment(O, A)
    end


    begin
    Drawing(lxm.width, lxm.height, :svg)
    origin(); fontsize(15)

    gsave()
    setline(1); setdash("dash")
    sethue(julia_green)
    path(radius, action=:stroke)
    grestore()
    sethue(julia_blue)
    path(t, action=:stroke)
    sethue(julia_purple)
    path(cc, action=:stroke)
    path(marks(angA; size=36); action=:stroke)
    sethue(julia_red)
    label("A", :SW, A); label("a", label_anchor(APSegment(B, C); side=:right)...); label("R", :N, midpoint(O, A))
    sethue("white"); path([A, B, C], action=:fillpreserve); sethue(julia_blue); strokepath()
    sethue("white"); path([O], action=:fillpreserve); sethue(julia_purple); strokepath()

    finish()
    preview()
    end
    ```

### The inscribed square

```@example geo
t = APTriangle(APPoint(0.0, 0.0), APPoint(8.0, 0.0), APPoint(3.0, 6.0))
sq = square_inscribed(t, 3)
area(sq)
```

```@raw html
<img src="../assets/img/triangles/inscribed_squares.svg" alt="The three squares inscribed in a triangle" style="width:100%; max-width: 700px;">
```

### A point in a triangle from barycentric coordinates

```@example geo
t = APTriangle(APPoint(0.0, 0.0), APPoint(8.0, 0.0), APPoint(3.0, 6.0))
barycentric_point(t, 1.0, 1.0, 1.0) ≈ centroid(t)
```

```@raw html
<img src="../assets/img/triangles/barycenter.svg" alt="A point of a triangle given by its barycentric coordinates" style="width:100%; max-width: 700px;">
```

### Napoleon's theorem

The centers of the equilateral triangles built outward on the sides form an
equilateral triangle:

```@example geo
t = APTriangle(APPoint(0.0, 0.0), APPoint(8.0, 0.0), APPoint(3.0, 6.0))
n = napoleon_triangle(t)
distance(n[1], n[2]) ≈ distance(n[2], n[3]) ≈ distance(n[3], n[1])
```

```@raw html
<img src="../assets/img/triangles/derived_equilateral.svg" alt="The Napoleon and Morley triangles, both equilateral" style="width:100%; max-width: 700px;">
```

!!! details "See script"
    ```julia
    using Apollonius, Luxor
    import Luxor: julia_red, julia_blue, julia_green, julia_purple
    import Apollonius: rotate, translate, distance, midpoint

    lxm = @prepare_to_picture! width=500 height=340 margin=30 begin  
        A, B, C = APPoint(0.0, 0.0), APPoint(8.0, 0.0), APPoint(3.0, 6.0)
        t = APTriangle(A, B, C)
        np_tri = napoleon_triangle(t)
        mor = morley_triangle(t)
    end


    begin
    Drawing(lxm.width, lxm.height, :svg)
    origin()

    sethue(julia_blue)
    path(t, action=:stroke)
    sethue(julia_purple)
    path([np_tri, mor], action=:stroke)
    sethue("white"); path([A, B, C], action=:fillpreserve); sethue(julia_blue); strokepath()

    finish()
    preview()
    end
    ```

### The Simson line of a point on the circumcircle

```@example geo
t = APTriangle(APPoint(0.0, 0.0), APPoint(8.0, 0.0), APPoint(3.0, 6.0))
p = point_on(circumcircle(t), 0.7)
sl = simson_line(t, p)
all(is_on_line(f, sl) for f in vertices(pedal_triangle(t, p)))   # the feet of the perpendiculars
```

```@raw html
<img src="../assets/img/triangles/simson_steiner.svg" alt="The Simson and Steiner lines of a point on the circumcircle" style="width:100%; max-width: 700px;">
```

!!! details "See script"
    ```julia
    using Apollonius, Luxor
    import Luxor: julia_red, julia_blue, julia_green, julia_purple
    import Apollonius: rotate, translate, distance, midpoint

    lxm = @prepare_to_picture! width=500 height=320 margin=30 begin  
        A, B, C = APPoint(0.0, 0.0), APPoint(8.0, 0.0), APPoint(3.0, 6.0)
        t = APTriangle(A, B, C)
        cc = circumcircle(t)
        P = polar_point(circumradius(t), 0.7, circumcenter(t))
        feet = [projection(P, APLine(s.p1, s.p2)) for s in sides(t)]
        sl = simson_line(t, P)
        stl = steiner_line(t, P)
        H = orthocenter(t)
    end


    begin
    Drawing(lxm.width, lxm.height, :svg)
    origin(); fontsize(15)

    gsave()
    sethue("gray80")
    path(cc, action=:stroke)
    grestore()
    sethue(julia_blue)
    path(t, action=:stroke)
    sethue(julia_purple)
    path(sl, action=:stroke, extend=30)
    gsave()
    setline(1); setdash("dash")
    path(stl, action=:stroke, extend=30)
    grestore()
    sethue(julia_red)
    label("P", :NE, P); label("H", :E, H)
    sethue("white"); path([A, B, C], action=:fillpreserve); sethue(julia_blue); strokepath()
    sethue("white"); path(feet, action=:fillpreserve); sethue(julia_purple); strokepath()
    sethue("white"); path([P, H], action=:fillpreserve); sethue(julia_blue); strokepath()

    finish()
    preview()
    end
    ```

