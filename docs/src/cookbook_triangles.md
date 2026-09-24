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

The same idea, with other data: [`triangle_on_segment_sas`](@ref) (an angle
and a side), [`triangle_on_segment_sss`](@ref) (three sides) and the named
ones such as [`equilateral_triangle_on_segment`](@ref). See
[Triangles: The Classical Centers](@ref).

### An equilateral triangle on a segment, or a square

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

