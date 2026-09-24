```@meta
CurrentModule = Apollonius
```

# Tangency: Fixing a Point, Radius or Center

## Through a point, tangent to two objects

[`tangent_circles`](@ref) covers the remaining
"one point + two circles/lines" cases (LLP, CCP, CLP). For example, tangent
to two circles and passing through a chosen point between them:

```@example geo
using Apollonius

c1 = APCircle2(APPoint(-4.0, 0.0), 1.5)
c2 = APCircle2(APPoint(4.0, 0.0), 1.5)
p = APPoint(0.0, 1.0)

sols_p = tangent_circles(c1, c2, p)
length(sols_p)
```

```@raw html
<img src="../assets/img/tangency/ccp.svg" alt="Two circles, a point between them, and the circles tangent to both that pass through the point" style="width:100%;">
```

## Fixing the radius in advance

[`tangent_circles_with_radius`](@ref)`(obj1, obj2, r)` is a different kind
of question from the rest of this page: instead of "find the tangent
circle(s), whatever their radius", it fixes the radius `r` up front and
asks for circles of exactly that radius tangent to two lines, a line and a
circle, or two circles:

```@example geo
l1 = APLine(APPoint(0.0, 0.0), APPoint(0.0, 1.0))   # the y-axis
l2 = APLine(APPoint(0.0, 0.0), APPoint(1.0, 0.0))   # the x-axis
sols_r = tangent_circles_with_radius(l1, l2, 3.0)   # radius 3, tangent to both axes
length(sols_r), all(s -> s.r == 3.0, sols_r)   # 4 solutions, one per quadrant
```

```@raw html
<img src="../assets/img/tangency/llr.svg" alt="Two intersecting lines and four circles of the same fixed radius, tangent to both, one in each quadrant" style="width:100%;">
```

(`l1`/`l2` need to actually meet somewhere for this to have solutions:
two *parallel* lines always return an empty vector, since then either no
radius works or, at the one radius that does, a whole line of centers
would qualify rather than finitely many circles, a degenerate case this
function doesn't handle.)

It's built internally via [`offset_line`](@ref)`(l, d)`, which shifts a
line by a signed distance along its own normal, turning "tangent to `l` at
distance `r`" into "passes through `l` shifted by `±r`", then intersecting
those shifted lines/circles directly:

```@example geo
offset_line(l1, 3.0) == APLine(APPoint(-3.0, 0.0), APPoint(-3.0, 1.0))   # shifted left of p1->p2
```

## Fixing the center in advance

[`tangent_circles_with_center`](@ref)`(center, obj)` is the mirror
question: instead of fixing the radius, it fixes the *center* and asks for
the radius (or radii) that make a circle there tangent to a line or
another circle. A line has exactly one answer, the perpendicular distance
from `center` to the line:

```@example geo
center = APPoint(0.0, 0.0)
l = APLine(APPoint(5.0, -5.0), APPoint(5.0, 5.0))
tangent_circles_with_center(center, l)
```

A circle has up to two: external tangency (`r = d + c.r`, wrapping
around the outside) and internal tangency (`r = |d - c.r|`, fitting
between `center` and the far side of `c`), where `d` is the distance
between the two centers:

```@example geo
c = APCircle2(APPoint(10.0, 0.0), 3.0)
sols = tangent_circles_with_center(center, c)
length(sols), sols[1].r, sols[2].r   # internal (7.0) then external (13.0)
```

```@raw html
<img src="../assets/img/tangency/center_fixed.svg" alt="A fixed center point, a circle, and the two circles centered there tangent to it, one internally and one externally" style="width:100%;">
```

The two solutions merge into one when `center` sits exactly on `c` (only
external tangency survives, at `r = 2*c.r`), and there are none at all
when `center` coincides with `c`'s own center: every circle centered
there is concentric with `c`, never tangent to it.

## Tangent at a given point

The circles of the sections above touch a line wherever the problem puts them.
When the point of contact is given, the circle is easier to find. With one more
point to pass through, [`tangent_circle_at_point`](@ref)`(l, p, q)` is the one
circle tangent to `l` at `p` and through `q`. With a radius instead,
[`tangent_circles_at_point`](@ref)`(l, p, r)` gives the two circles of that
radius, one on each side of the line:

```@example geo
lt = APLine(APPoint(-3.0, 0.0), APPoint(9.0, 0.0))
tangent_circle_at_point(lt, APPoint(2.0, 0.0), APPoint(0.0, 2.0))
```

```@example geo
[c.center for c in tangent_circles_at_point(lt, APPoint(2.0, 0.0), 1.2)]
```

```@raw html
<img src="../assets/img/tangency/tangent_at_point.svg" alt="A line, a point on it and a point off it, the circle tangent at the first through the second, and the two circles of radius 1.2 tangent at the first" style="width:100%; max-width: 700px;">
```

For a circle tangent to a line through *two* given points, see
[Through two points, tangent to a line](@ref).

## Related helpers

* [`external_similitude_center`](@ref) / [`internal_similitude_center`](@ref)
  and the common tangent lines from [Circles: How They Relate](@ref) are the two-circle
  building blocks these constructions are built from.
* The triangle-specific tangent-circle configurations ([`mixtilinear_incircle`](@ref),
  [`soddy_circles`](@ref), [`three_tangent_circles`](@ref) and
  [`thebault_circles`](@ref)) are covered in
  [Triangles: Further Named Centers](@ref), since they are defined in terms of
  a triangle's sides and angles rather than arbitrary circles.

