```@meta
CurrentModule = Apollonius
```

# Cookbook: Tangent Circles

## Working with tangent circles

### The circle through two points tangent to a line

```@example geo
using Apollonius

A, B = APPoint(0.0, 0.0), APPoint(4.0, 1.0)
l = APLine(APPoint(-3.0, 3.0), APPoint(8.0, 3.0))
sols = tangent_circles(A, B, l)
length(sols), all(c -> line_circle_position(l, c) == :tangent, sols)
```

```@raw html
<img src="../assets/img/tangency/ppl.svg" alt="Two points, a line, and the circles through the points tangent to the line" style="width:100%; max-width: 700px;">
```

### The circle through a point tangent to two lines

```@example geo
l1, l2 = APLine(APPoint(0.0, 0.0), APPoint(1.0, 0.0)), APLine(APPoint(0.0, 0.0), APPoint(0.0, 1.0))
sols = tangent_circles(l1, l2, APPoint(3.0, 1.0))
length(sols), all(c -> line_circle_position(l1, c) == :tangent, sols)
```

```@raw html
<img src="../assets/img/cookbook/tangent_two_lines_point.svg" alt="Two lines, a point, and the two circles through the point tangent to both lines" style="width:100%; max-width: 700px;">
```

### The circles tangent to three circles

```@example geo
c1, c2, c3 = APCircle2(APPoint(0.0, 0.0), 2.0), APCircle2(APPoint(6.0, 0.0), 1.5), APCircle2(APPoint(2.0, 5.0), 1.0)
length(tangent_circles(c1, c2, c3))
```

```@raw html
<img src="../assets/img/tangency/ccc.svg" alt="Three circles and the circles tangent to all of them" style="width:100%; max-width: 700px;">
```

Up to eight solutions. The order is not fixed: choose with
[`nearest_point`](@ref) on the centers. See
[Tangency & Apollonius Problems](@ref).

### The circle tangent to two lines with a given radius

```@example geo
l1, l2 = APLine(APPoint(0.0, 0.0), APPoint(1.0, 0.0)), APLine(APPoint(0.0, 0.0), APPoint(0.0, 1.0))
tangent_circles_with_radius(l1, l2, 2.0)
```

```@raw html
<img src="../assets/img/cookbook/tangent_radius.svg" alt="Two perpendicular lines and the four circles of radius 2 tangent to both" style="width:100%; max-width: 700px;">
```

### The circle with a given center tangent to a line

```@example geo
l = APLine(APPoint(0.0, 0.0), APPoint(1.0, 0.0))
tangent_circles_with_center(APPoint(2.0, 3.0), l)
```

```@raw html
<img src="../assets/img/tangency/center_fixed.svg" alt="A circle with a fixed center tangent to a line" style="width:100%; max-width: 700px;">
```

### The second point where a line meets a circle

When you already know one of the points, `other_intersection` gives the
other, or `nothing` if the line is tangent there:

```@example geo
c = APCircle2(APPoint(0.0, 0.0), 5.0)
l = APLine(APPoint(-5.0, 0.0), APPoint(0.0, 3.0))
other_intersection(l, c, APPoint(-5.0, 0.0))
```

```@raw html
<img src="../assets/img/circles/intersection_choice.svg" alt="Choosing the second point where a line meets a circle" style="width:100%; max-width: 700px;">
```

### Circles that touch each other in a ring

The three circles centered at the vertices of a triangle that touch pairwise
at the points where the incircle touches the sides:

```@example geo
t = APTriangle(APPoint(0.0, 0.0), APPoint(8.0, 0.0), APPoint(3.0, 6.0))
ring = three_tangent_circles(t)
circles_position(ring[1], ring[2]), circles_position(ring[2], ring[3])
```

```@raw html
<img src="../assets/img/triangles/three_tangent.svg" alt="Three pairwise tangent circles centered at the vertices" style="width:100%; max-width: 700px;">
```

