```@meta
CurrentModule = Apollonius
```

# Cookbook: Lines

## Working with lines

### The perpendicular from a point, and its foot

```@example geo
using Apollonius

l = APLine(APPoint(0.0, 0.0), APPoint(4.0, 1.0))
p = APPoint(3.0, 4.0)
perp = perpendicular_through(l, p)
projection(p, l), is_perpendicular(perp, l)
```

```@raw html
<img src="../assets/img/cookbook/perpendicular_foot.svg" alt="A line, a point off it, the perpendicular from the point and its foot" style="width:100%; max-width: 700px;">
```

### The parallel through a point, and a line shifted sideways

```@example geo
l = APLine(APPoint(0.0, 0.0), APPoint(4.0, 1.0))
par = parallel_through(l, APPoint(0.0, 3.0))
is_parallel(par, l), offset_line(l, 2.0)
```

```@raw html
<img src="../assets/img/cookbook/parallels.svg" alt="A line, the parallel through a point above it and a line shifted by a fixed distance" style="width:100%; max-width: 700px;">
```

### The perpendicular bisector of a segment

```@example geo
A, B = APPoint(0.0, 0.0), APPoint(6.0, 2.0)
m = perpendicular_bisector(A, B)
distance(A, m) ≈ distance(B, m), is_on_line(midpoint(A, B), m)
```

```@raw html
<img src="../assets/img/cookbook/perp_bisector.svg" alt="A segment, its perpendicular bisector and a point on it equally far from both ends" style="width:100%; max-width: 700px;">
```

### Reflect a point in a line

```@example geo
l = APLine(APPoint(0.0, 0.0), APPoint(1.0, 1.0))
reflection(APPoint(3.0, 0.0), l)
```

```@raw html
<img src="../assets/img/cookbook/reflect_point.svg" alt="A point, a line and the mirror image of the point across it" style="width:100%; max-width: 700px;">
```

### Where two lines meet, or whether they do

```@example geo
l1 = APLine(APPoint(0.0, 0.0), APPoint(4.0, 2.0))
l2 = APLine(APPoint(0.0, 3.0), APPoint(4.0, 1.0))
intersection(l1, l2), intersection(l1, offset_line(l1, 1.0))
```

```@raw html
<img src="../assets/img/cookbook/lines_meet.svg" alt="Two lines that cross at a point, and a parallel to one of them that does not meet it" style="width:100%; max-width: 700px;">
```

The second is empty because the lines are parallel. See
[Intersections](@ref).

### Bisect an angle, or split it in three

```@example geo
O, P1, P2 = APPoint(0.0, 0.0), APPoint(4.0, 0.0), APPoint(0.0, 4.0)
ang = APAngle2(O, P1, P2)
first(angle_bisectors(ang)), length(angle_trisectors(ang))
```

```@raw html
<img src="../assets/img/points_lines/angle_split.svg" alt="A right angle with its two trisectors and its bisector" style="width:100%; max-width: 700px;">
```

