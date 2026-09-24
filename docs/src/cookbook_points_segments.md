```@meta
CurrentModule = Apollonius
```

# Cookbook: Points & Segments

Short recipes for things people ask of a geometry package: a goal, the call
that does it, and its result. Each block defines what it needs, so you can
copy one without reading the ones before it. The recipes point to the page
that explains the function in depth.

```@example geo
using Apollonius
```

## Working with points and segments

### The midpoint, or a point a fraction of the way along

```@example geo
A, B = APPoint(1.0, 2.0), APPoint(7.0, 5.0)
s = APSegment(A, B)
midpoint(s), point_on(s, 0.25)
```

```@raw html
<img src="../assets/img/cookbook/midpoint_fraction.svg" alt="A segment with its midpoint and the point a quarter of the way from A" style="width:100%; max-width: 700px;">
```

[`point_on`](@ref)`(s, t)` takes a fraction of the way from the first end to the
second. It works on a line, a segment or a ray, and `t` can leave `[0, 1]` to go
past the ends.

### A point at a given distance and direction

```@example geo
polar_point(4.0, pi / 3), polar_point_deg(4.0, 60.0), polar_point_deg(4.0, 60.0, APPoint(1.0, 1.0))
```

```@raw html
<img src="../assets/img/points_lines/polar.svg" alt="A point at distance 4 and angle 40 degrees from a center" style="width:100%; max-width: 700px;">
```

### Divide a segment in the golden ratio, or find a harmonic conjugate

```@example geo
A, B = APPoint(0.0, 0.0), APPoint(10.0, 0.0)
golden_ratio_point(A, B), harmonic_conjugate(A, B, APPoint(2.0, 0.0))
```

```@raw html
<img src="../assets/img/points_lines/harmonic.svg" alt="Two points, a third between them, its harmonic conjugate and the golden ratio point" style="width:100%; max-width: 700px;">
```

### The distance from a point to a segment, a line or a polygon

```@example geo
p = APPoint(5.0, 4.0)
distance(p, APSegment(APPoint(0.0, 0.0), APPoint(3.0, 0.0))), distance(p, APLine(APPoint(0.0, 0.0), APPoint(1.0, 0.0)))
```

```@raw html
<img src="../assets/img/points_lines/distance_curves.svg" alt="The distance from a point to a line, a segment and a ray" style="width:100%; max-width: 700px;">
```

See [Measurements & Queries](@ref) for what `distance` means for each type.

