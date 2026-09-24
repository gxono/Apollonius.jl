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
<img src="../assets/img/triangles/tri_cen.svg" alt="" style="width:100%;">
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
<img src="../assets/img/triangles/obl_axis.svg" alt="" style="width:100%; max-width: 700px;">
```

```@raw html
<img src="../assets/img/triangles/orthic_axis.svg" alt="" style="width:100%; max-width: 700px;">
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
<img src="../assets/img/triangles/excircles.svg" alt="" style="width:100%; max-width: 700px;">
```
