```@meta
CurrentModule = Apollonius
```

# Points, Lines & Rays: Direction & Transforms

These use the segment, line and ray from [Points, Lines & Rays: Creating Them](@ref):

```@example geo
using Apollonius

A = APPoint(3.0, 4.0)
O = APPoint(0.0, 0.0)
s = APSegment(O, A)
l = APLine(O, A)
r = APRay(O, A)
nothing # hide
```

## Direction, slope and predicates

```@example geo
direction(l)                    # ⟨3.0, 4.0⟩: l.p2 - l.p1, as an APVector
rad2deg(slope_angle(l))         # ≈ 53.13°
v = APVector(1.0, 1.0)
rad2deg(slope_angle(v))
is_collinear(O, A, APPoint(6.0, 8.0))
is_on_line(APPoint(6.0, 8.0), l)
is_on_segment(APPoint(6.0, 8.0), s) # false: beyond A
```

| Function | Returns | Meaning |
|:---------|:--------|:--------|
| [`direction`](@ref) | `APVector` | non-normalized direction of an `APLine`/`APRay`/`APSegment` |
| [`slope_angle`](@ref) | angle | `atan(dy, dx)` of that direction, in radians; also for an `APVector` |
| [`orthogonal`](@ref) | `APVector` | the vector rotated 90° counterclockwise |
| [`cross2`](@ref) | number | the 2D cross product `u[1]*v[2] - u[2]*v[1]` (twice the signed area of the triangle `0,u,v`) |
| [`is_collinear`](@ref) | `Bool` | do three points lie on a common line? |
| [`is_parallel`](@ref) / [`is_perpendicular`](@ref) | `Bool` | relation between two lines |
| [`is_on_line`](@ref) / [`is_on_segment`](@ref) / [`is_on_ray`](@ref) | `Bool` | is a point on this line / this finite segment / this half-line? |
| [`side_of_line`](@ref) | `-1`, `0` or `1` | which side of a line a point falls on |

```@example geo
w = orthogonal(v)
dot(v, w) ≈ 0.0, cross2(v, w)   # perpendicular, and the sign says which way it turned
```

```@example geo
l_horiz = APLine(APPoint(0.0, 0.0), APPoint(4.0, 0.0))
side_of_line(APPoint(2.0, 1.0), l_horiz)   #  1 : "above"
side_of_line(APPoint(2.0, -1.0), l_horiz)  # -1 : "below"
```

```@example geo
l_vert = APLine(APPoint(0.0, 0.0), APPoint(0.0, 4.0))
is_parallel(l, APLine(APPoint(1.0, 0.0), APPoint(4.0, 4.0))), is_perpendicular(l_horiz, l_vert)
```

```@example geo
r = APRay(APPoint(0.0, 0.0), APPoint(4.0, 0.0))
is_on_ray(APPoint(10.0, 0.0), r)    # true: ahead of the origin, same direction
is_on_ray(APPoint(-1.0, 0.0), r)    # false: on the line, but behind the origin
```

`is_on_line`/`is_on_segment`/`is_on_ray` are also exactly what `Base.in` uses under
the hood, so the more natural `p in l` reads just as well:

```@example geo
APPoint(6.0, 8.0) in l, APPoint(10.0, 0.0) in r
```

```@raw html
<img src="../assets/img/points_lines/direction_slope.svg" alt="A line with its direction vector, its slope angle and a point on it" style="width:100%; max-width: 700px;">
```

## Lengthening a line or segment

[`extend_line`](@ref)`(l, before, after)` lengthens the line through
`l.p1` and `l.p2` by fractions of `distance(l.p1, l.p2)` past each point
and returns the resulting [`APSegment`](@ref). The fractions are relative to
the two defining points, so the same value adds more length to a longer
line. A negative fraction shortens that end, and an [`APSegment`](@ref) is
accepted too.

```@example geo
base = APLine(APPoint(0.0, 0.0), APPoint(10.0, 0.0))
ext = extend_line(base, 0.5)         # half of 10.0 more, at each end
ext.p1, ext.p2, distance(ext.p1, ext.p2)
```

```@raw html
<img src="../assets/img/decorations/extend_line.svg" alt="A segment lengthened at both ends" style="width:100%; max-width: 700px;">
```

The same lengthening is available when drawing, as the `add` keyword of
`path`; see [Drawing with Luxor.jl](@ref). More on this function is in
[Marks, Labels & Decorations](@ref).

## Distance to a line, segment or ray

[`distance`](@ref) also works between a point and any of `APLine`,
`APSegment` or `APRay`: the perpendicular distance to the *infinite* line
in the first case, but clamped to the finite extent for the other two (so
a point "past the end" measures to the nearest endpoint, not along the
infinite extension):

```@example geo
far_point = APPoint(10.0, 10.0)
distance(far_point, l), distance(far_point, s), distance(far_point, r)
# perpendicular to the infinite line; clamped to the finite segment [O,A]; clamped to the ray
```

`is_on_line`/`is_on_segment`/`is_on_ray` each also take just the line/segment/ray
(no point) to build a reusable one-argument predicate, for `filter`:

```@example geo
pts = [APPoint(2.0, 0.0), APPoint(2.0, 1.0), APPoint(-1.0, 0.0)]
filter(is_on_ray(r), pts)   # only the point that's on r
```

```@raw html
<img src="../assets/img/points_lines/distance_curves.svg" alt="The distance from a point to a line, a segment and a ray" style="width:100%; max-width: 700px;">
```

## Projection, reflection and the perpendicular foot

[`projection`](@ref) drops a point onto a line at a right angle;
[`reflection`](@ref) mirrors a point through another point (its use for
mirroring *across a line* is: project first, then reflect through the
foot).

```@example geo
P, Q = APPoint(1.0, 1.0), APPoint(6.0, 3.0)
l = APLine(P, Q)
C = APPoint(2.0, 6.0)

foot = projection(C, l)      # the perpendicular foot of C on l
Cref = reflection(C, foot)   # C mirrored through that foot, i.e. across l
```

```@raw html
<img src="../assets/img/points_lines/projection_reflection.svg" alt="A line l, a point C, its perpendicular foot on l, and C reflected through that foot to the other side of l, joined by a dashed segment" style="width:100%; max-width: 700px;">
```

`projection` also takes an `angle` keyword (radians, default `pi/2`,
measured counterclockwise from `l`'s own direction) for the **oblique**
projection of `p` onto `l`: the point where a line through `p` at that
angle meets `l`, instead of the perpendicular:

```@example geo
projection(C, l; angle=pi / 2) == foot   # pi/2 is the ordinary case
projection(C, l; angle=pi / 3)            # a genuinely oblique projection
```

`angle` must be strictly between `0` and `π`. At either end the
projecting line would be parallel to `l` itself, so there'd be no single
intersection point:

```@example geo
try
    projection(C, l; angle=0.0)
catch e
    e
end
```

Like the predicates above, `projection(l; angle=...)` (no point) builds a
reusable one-argument function, for `map`/`|>`:

```@example geo
map(projection(l), [C, P, Q])   # project a whole collection onto l at once
```

## Rotation, homothety and translation

[`rotate`](@ref) turns a point about a center by an angle (radians,
counter-clockwise); [`homothety`](@ref) scales it by a factor `k` about a
center (`k = -1` is a point reflection, `0 < k < 1` shrinks towards the
center); [`translate`](@ref) shifts it by an [`APVector`](@ref) (the
fourth member of this quartet, and the only one with no `center`: a
translation has none). `rotate`/`homothety` default to the origin when no
center is given.

```@example geo
rotate(C, pi / 2, P)     # C rotated 90° about P
homothety(C, 2.0, P)     # C scaled by 2 about P
translate(C, APVector(1.0, -1.0))   # C shifted by (1,-1)
barycenter([P, Q, C], [1.0, 1.0, 2.0])   # weighted average of the three
```

```@raw html
<img src="../assets/img/points_lines/rotation_homothety_translation.svg" alt="A triangle P, Q, C with its side midpoints, and the images of vertex C under a rotation, a homothety and a translation, labeled R, H and T, with the barycenter B and the rotation angle marked" style="width:100%; max-width: 700px;">
```


## Parallels, perpendiculars and bisectors

```@example geo
midpoint(P, Q)                      # [3.5, 2.0]: the plain average of the two
parallel_through(l, C)             # line through C, parallel to l
perpendicular_through(l, C)        # line through C, perpendicular to l
pb = perpendicular_bisector(P, Q)  # perpendicular to [P,Q] through its midpoint
```

[`vertical_line`](@ref) and [`horizontal_line`](@ref) build the line `x = x0`
or `y = y0` directly, from the number or from a point to pass through:

```@example geo
vertical_line(3.0) ≈ vertical_line(APPoint(3.0, -8.0))
horizontal_line(APPoint(3.0, -8.0))
```

```@raw html
<img src="../assets/img/points_lines/par_per_bis.svg" alt="A line through two labeled points and a third labeled point, with the parallel and perpendicular lines through that point and the perpendicular bisector of the first two" style="width:100%; max-width: 700px;">
```


[`angle_bisectors`](@ref) is the analogous construction for two intersecting
lines: it returns *both* bisectors (they are always perpendicular to each
other), as a 2-element vector.

```@example geo
xaxis = APLine(APPoint(0.0, 0.0), APPoint(4.0, 0.0))
yaxis = APLine(APPoint(0.0, 0.0), APPoint(0.0, 4.0))
angle_bisectors(xaxis, yaxis)   # the two diagonals y = x and y = -x
```

```@raw html
<img src="../assets/img/points_lines/ang_bis.svg" alt="Two intersecting lines through three labeled points and their two mutually perpendicular angle bisectors" style="width:100%; max-width: 700px;">
```

