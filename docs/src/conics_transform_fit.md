```@meta
CurrentModule = Apollonius
```

# Conics: Transforming & Fitting

The ellipse and parabola from [Conics: Ellipse, Parabola & Hyperbola](@ref):

```@example geo
using Apollonius

e = APEllipse2(APPoint(0.0, 0.0), 5.0, 3.0)
focus = APPoint(0.0, 1.0)
directrix = APLine(APPoint(-5.0, -1.0), APPoint(5.0, -1.0))
par = APParabola2(focus, directrix)
nothing # hide
```

## Transforming conics

`rotate`, `reflection` and `homothety` work on all three types. For
`APEllipse2`/`APHyperbola2`, `center` transforms pointwise; `rotate` adds its
angle onto `angle` too; `homothety` scales `a`/`b` by `abs(k)` (never
negative, and never swaps which axis is which) while leaving `angle`
alone, even for a negative `k`: a homothety, negative ratio included,
never reverses orientation:

```@example geo
rotate(e, pi / 6)
homothety(e, -2.0)   # a, b both scale by 2 (abs(-2.0)); angle unchanged
```

```@raw html
<img src="../assets/img/conics/transform.svg" alt="An ellipse, its rotation and its homothety of ratio -0.5" style="width:100%; max-width: 700px;">
```

`reflection` needs two separate methods here, the same way the base
`reflection(::APPoint, about)` itself does:

* `reflection(conic, about::APPoint)` is a point reflection (a 180°
  rotation): orientation-preserving, so `angle` is unchanged.
* `reflection(conic, about::APLine)` is a true mirror: orientation-reversing,
  so the new `angle` is `2φ - conic.angle`, where `φ` is the line's own
  angle from the x-axis (not simply `conic.angle` unchanged, nor its
  negation; the formula accounts for the mirror line's own orientation).

```@example geo
reflection(e, APPoint(1.0, 1.0))                              # angle unchanged
reflection(e, APLine(APPoint(0.0, 0.0), APPoint(1.0, 1.0)))       # angle: 2φ - e.angle
```

An `APParabola2` is entirely determined by its `focus` and `directrix`, and
both already transform correctly on their own (an `APPoint` and an `APLine`),
so its `rotate`/`reflection`/`homothety` just transform each of the two
and rebuild:

```@example geo
rotate(par, pi / 4)
```

## Fitting a conic through five points

[`conic_through_points`](@ref) takes five points in general position and
returns the unique `APEllipse2` or `APHyperbola2` passing through all of them
(five points determine a conic, the same way three determine a circle or
two a line):

```@example geo
pts = [point_on(APEllipse2(APPoint(1.0, 2.0), 6.0, 4.0, 0.3), t) for t in (0.1, 1.0, 2.0, 3.0, 4.5)]
conic_through_points(pts...)
```

```@raw html
<img src="../assets/img/conics/fit.svg" alt="Five points and the ellipse through them" style="width:100%; max-width: 700px;">
```

It throws an `ArgumentError` when the five points don't determine a unique
conic (a degenerate configuration, e.g. four of them collinear), or when
they do determine a conic but it's a parabola (discriminant ≈ 0): a
parabola isn't representable by this function, since it isn't a
`(center, a, b, angle)`-style object the way the other two are.

Internally, the points are first centered on their own centroid and
rescaled to unit average distance before the linear system is solved, and
the fitted center/axes are transformed back afterwards. Fitting directly
in the original coordinates would badly ill-condition the underlying
linear algebra for points far from the origin or spread far apart, since
the quadratic terms of the conic's equation would then dwarf the linear
and constant ones.
