```@meta
CurrentModule = Apollonius
```

# Triangles: Vertex-Indexed Lines

The running example, the scalene triangle used throughout this page:

```@example geo
using Apollonius

A, B, C = APPoint(0.0, 0.0), APPoint(8.0, 0.0), APPoint(3.0, 6.0)
t = APTriangle(A, B, C)
nothing # hide
```

## Vertex-indexed lines

Four of the classical triangle lines (the altitude, median, and internal
and external angle bisectors) plus the perpendicular bisector of the
opposite side and the angle trisectors, all come in threes, one per vertex.
Rather than one function per vertex, each is a single function taking the
triangle and a vertex index `i ∈ {1,2,3}`:

| Function | The line through `t[i]`... |
|:---------|:----------------------------|
| [`altitude`](@ref)`(t, i)` | ...perpendicular to the opposite side (concurs at `orthocenter`) |
| [`median`](@ref)`(t, i)` | ...through the opposite side's midpoint (concurs at `centroid`) |
| [`bisector`](@ref)`(t, i)` | ...the internal angle bisector (concurs at `incenter`) |
| [`bisector_ext`](@ref)`(t, i)` | ...the external angle bisector (perpendicular to `bisector(t, i)`) |
| [`mediator`](@ref)`(t, i)` | the perpendicular bisector of the side *opposite* `t[i]` (concurs at `circumcenter`) |
| [`trisector`](@ref)`(t, i)` | the 2 rays from `t[i]` trisecting the interior angle there |

```@example geo
altitude(t, 1), median(t, 1), bisector(t, 1)
```

```@example geo
altitude.(t, 1:3)
```

```@raw html
<img src="../assets/img/triangles/altitude.svg" alt="" style="width:100%;">
```


```@example geo
bisector.(t, 1:3)
```

```@raw html
<img src="../assets/img/triangles/median.svg" alt="" style="width:100%;">
```




```@example geo
median.(t, 1:3)
```

```@raw html
<img src="../assets/img/triangles/median.svg" alt="" style="width:100%;">
```



```@example geo
is_on_line(orthocenter(t), altitude(t, 1)), is_on_line(centroid(t), median(t, 1)), is_on_line(incenter(t), bisector(t, 1))
```

`bisector_ext(t, i)` and `mediator(t, i)` complete the set. The external
bisector is always perpendicular to the internal one at the same vertex,
and the mediator (the perpendicular bisector of the *opposite* side) is
what all three concur at to give the circumcenter:

```@example geo
is_perpendicular(bisector(t, 1), bisector_ext(t, 1))
```

```@example geo
is_on_line(circumcenter(t), mediator(t, 1)), is_on_line(circumcenter(t), mediator(t, 2)), is_on_line(circumcenter(t), mediator(t, 3))
```

```@example geo
bisector_ext.(t, 1:3)
```

```@raw html
<img src="../assets/img/triangles/bisector_ext.svg" alt="" style="width:100%;">
```

```@example geo
mediator.(t, 1:3)
```

```@raw html
<img src="../assets/img/triangles/mediator.svg" alt="" style="width:100%;">
```


The free function [`angle_trisectors`](@ref)`(vertex, p1, p2)` (see
[Angles](@ref) on the previous page) is what `trisector(t, i)` is built
from; use it directly when the two rays don't come from a triangle's own
vertices.

```@example geo
trisector.(t, 1:3)
```

```@raw html
<img src="../assets/img/triangles/trisector.svg" alt="" style="width:100%;">
```
