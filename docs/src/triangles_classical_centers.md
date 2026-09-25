```@meta
CurrentModule = Apollonius
```

# Triangles: The Classical Centers

[`APTriangle`](@ref) is three points, indexed `t[1]`, `t[2]`, `t[3]` (its
own type, `<: APPolygon`; see [Apollonius.jl](@ref) for the full hierarchy). This
page is organized the same way triangle geometry
usually is: the basic measurements, the four classical centers and how the
Euler line ties three of them together, the excircles, barycentric
coordinates, and then the (long) catalogue of further named centers and
derived triangles that classical triangle geometry has accumulated.

Throughout, the running example is the scalene triangle:

```@example geo
using Apollonius

A, B, C = APPoint(0.0, 0.0), APPoint(8.0, 0.0), APPoint(3.0, 6.0)
t = APTriangle(A, B, C)

area(t), perimeter(t), is_degenerate(t)
```

## The four classical centers, and the Euler line

| Function | Center | Defined as |
|:---------|:-------|:-----------|
| [`centroid`](@ref) | `G` | average of the three vertices |
| [`circumcenter`](@ref) | `O` | equidistant from the three vertices ([`circumcircle`](@ref) passes through them) |
| [`incenter`](@ref) | `I` | equidistant from the three sides ([`incircle`](@ref) touches them) |
| [`orthocenter`](@ref) | `H` | intersection of the three altitudes |

`G`, `O` and `H` are always collinear (that line is the
[`euler_line`](@ref)), and `G` divides `OH` in a fixed `1:2` ratio (`H = O +
3(G - O)`). `I` is *not* on the Euler line in general (it only coincides
with the others for an equilateral triangle).

```@example geo
G, O, I, H = centroid(t), circumcenter(t), incenter(t), orthocenter(t)
el = euler_line(t)
npc = nine_point_circle(t)
circumradius(t)   # the radius of circumcircle(t), same as npc.r * 2
```

```@raw html
<img src="../assets/img/triangles/tri_cen.svg" alt="A triangle with its circumcircle, incircle and nine-point circle, the four classical centers G, O, I, H, and the Euler line through three of them" style="width:100%;">
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


[`nine_point_circle`](@ref) passes through the three edge midpoints, the
three altitude feet, and the three midpoints of segment `[vertex, H]` (nine
points in total, though only the circle itself, not the nine points, is
what the function returns). Its center, [`nine_point_center`](@ref), is the
midpoint of `O` and `H`, and it always sits on the Euler line too. Its
radius is exactly half the circumradius. [`euler_points`](@ref) returns
that last group of three (the midpoints of `[H, vertex]`) directly, for
when you need those specific points rather than just the circle.

```@example geo
euler_points(t)
npc.center == nine_point_center(t), npc.r ≈ circumradius(t) / 2
```

Two more lines are naturally associated with this configuration:
[`orthic_axis`](@ref), the radical axis of the circumcircle and the
nine-point circle (always perpendicular to the Euler line), and
[`brocard_axis`](@ref), the line through `O` and the symmedian point,
whose polar line with respect to the circumcircle is, in turn, the
[`lemoine_axis`](@ref).

```@example geo
orthic_axis(t), brocard_axis(t), lemoine_axis(t)
```

```@raw html
<img src="../assets/img/triangles/obl_axis.svg" alt="A triangle with its orthic axis, Brocard axis and Lemoine axis" style="width:100%; max-width: 700px;">
```

```@raw html
<img src="../assets/img/triangles/orthic_axis.svg" alt="A triangle with its altitude feet, the lines joining them in pairs, and the orthic axis where those lines meet the extended sides" style="width:100%; max-width: 700px;">
```

!!! details "See script"
    ```julia
    using Apollonius, Luxor
    import Luxor: julia_red, julia_blue, julia_green, julia_purple
    import Apollonius: rotate, translate, distance, midpoint

    lxm = @prepare_to_picture! width=500 height=240 margin=20 begin  
        A, B, C = APPoint(0.0,0), APPoint(10,0), APPoint(7,5)
        t =  APTriangle(A, B, C)
        l1, l2, l3 = APLine.(sides(t))
        oa = orthic_axis(t)
        h1, h2, h3 = projection.([C, A, B], [l1, l2, l3])
        lh1, lh2, lh3 = APLine(h2, h3), APLine(h3, h1), APLine(h1, h2)
        ih1 = intersection(lh1, l1)
        ih2 = intersection(lh2, l2)
        ih3 = intersection(lh3, l3)
    end


    begin
    Drawing(lxm.width, lxm.height, :svg)
    origin()

    sethue("gray80")
    setdash(:dash)
    gsave()
    setline(1)
    h = APSegment.([C,A,B],[h1,h2,h3])
    path(h, action=:stroke)
    path([l1, l2, l3], action=:stroke)
    sethue(julia_green)
    path([lh1, lh2, lh3], action=:stroke)
    grestore()
    setdash(:solid)
    sethue(julia_purple)
    path(oa, action=:stroke)
    sethue(julia_blue)
    path(t, action=:stroke)
    sethue("white"); path([h1,h2,h3], action=:fillpreserve); sethue(julia_green); strokepath()
    sethue("white"); path([ih1 ih2 ih3], action=:fillpreserve); sethue(julia_purple); strokepath()
    sethue("white"); path(vertices(t), action=:fillpreserve); sethue(julia_blue); strokepath()

    finish()
    preview()
    end
    ```


## Excenters and excircles

Where the incircle is tangent to all three sides from *inside* the
triangle, each **excircle** is tangent to one side and to the
*extensions* of the other two, from outside. There are three of them, one
opposite each vertex. [`excenters`](@ref) and [`exradii`](@ref) return
all three as a named tuple `(A=..., B=..., C=...)`, and
[`excircles`](@ref) the actual circles.

```@example geo
ex = excenters(t)
exc = excircles(t)
er = exradii(t)
exc.A.r == er.A   # excircles(t).A already has radius exradii(t).A
```

```@raw html
<img src="../assets/img/triangles/excircles.svg" alt="A triangle with its three excircles and excenters, each excircle tangent to one side and to the extensions of the other two" style="width:100%; max-width: 700px;">
```

!!! details "See script"
    ```julia
    using Apollonius, Luxor
    import Luxor: julia_red, julia_blue, julia_green, julia_purple
    import Apollonius: rotate, translate, distance, midpoint

    lxm = @prepare_to_picture! width=500 height=240 margin=20 begin  
        A, B, C = APPoint(0.0,0), APPoint(10,0), APPoint(7,5)
        t = APTriangle(A, B, C)
        l = APLine.(sides(t))
        ex = collect(excenters(t))
        exc = collect(excircles(t))
        pp = projection.(ex, [l[2], l[3], l[1]])
        rangles = APAngle2.(pp, ex, getproperty.(l, :p2))
    end


    begin
    Drawing(lxm.width, lxm.height, :svg)
    origin()

    gsave()
    sethue("gray80")
    setdash(:dash)
    setline(1)
    path(l, action=:stroke)
    path(APTriangle(ex...), action=:stroke)
    sethue(julia_green)
    setdash(:solid)
    path(APSegment.(ex, pp), action=:stroke)
    grestore()
    sethue(julia_purple)
    path(exc, action=:stroke)
    sethue(julia_green)
    rquads = [APQuadrilateral(ang.vertex, only(marks(ang; style=:parallelogram, size=7)).vertices...) for ang in reverse.(rangles)]
    path(rquads, action=:fill)
    sethue(julia_blue)
    path(t, action=:stroke)
    sethue("white"); path(ex, action=:fillpreserve); sethue(julia_purple); strokepath()
    sethue("white"); path(vertices(t), action=:fillpreserve); sethue(julia_blue); strokepath()
    sethue("white"); path(pp, action=:fillpreserve); sethue(julia_green); strokepath()

    finish()
    preview()
    end
    ```
