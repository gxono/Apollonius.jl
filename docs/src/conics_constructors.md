```@meta
CurrentModule = Apollonius
```

# Conics: Building From Other Data

## Building a conic from other data

Besides the constructors above, four functions build a conic from the data one
often has.

**A focus, a directrix and an eccentricity.** [`conic_with_focus`](@ref)`(focus,
directrix, e)` is the set of points whose distance to the focus is `e` times
their distance to the directrix. The eccentricity decides the type:

| `e` | Result |
|:----|:-------|
| `0 < e < 1` | an [`APEllipse2`](@ref) |
| `e = 1` | an [`APParabola2`](@ref) |
| `e > 1` | an [`APHyperbola2`](@ref) |

```@example geo
using Apollonius

fc, dc = APPoint(0.0, 0.0), APLine(APPoint(4.0, -1.0), APPoint(4.0, 1.0))
typeof(conic_with_focus(fc, dc, 0.5)), typeof(conic_with_focus(fc, dc, 1.0)), typeof(conic_with_focus(fc, dc, 2.0))
```

```@raw html
<img src="../assets/img/conics/focus_directrix.svg" alt="An ellipse, a parabola and a hyperbola with the same focus and directrix" style="width:100%; max-width: 700px;">
```

!!! details "See script"
    ```julia
    using Apollonius, Luxor
    import Luxor: julia_red, julia_blue, julia_green, julia_purple
    import Apollonius: rotate, translate, distance, midpoint

    lxm = @prepare_to_picture! width=560 height=240 margin=20 begin
        F = APPoint(0.0, 0.0)
        dl = APSegment(APPoint(4.0, -5.0), APPoint(4.0, 5.0))
        d = APLine(dl.p1, dl.p2)
        ell = conic_with_focus(F, d, 0.5)
        par = conic_with_focus(F, d, 1.0)
        hyp = conic_with_focus(F, d, 2.0)
        parc = APParabolicArc2(par, point_on(par, -6.0), point_on(par, 6.0))
        harc = APHyperbolicArc2(hyp, point_on(hyp, -1.1; branch=-1), point_on(hyp, 1.1; branch=-1))
    end


    begin
    Drawing(lxm.width, lxm.height, :svg)
    origin(); fontsize(15)
    sethue(julia_blue)
    path(dl, action=:stroke)
    sethue(julia_purple)
    path([ell, parc, harc], action=:stroke)
    sethue(julia_red)
    label("F", :W, F, offset=8)
    label("e = 1", :N, parc.p1)
    label("e = 2", :S, harc.p1)
    text("directrix", dl.p2 + APVector(5.0,0.0), angle=pi/2)
    label("e = 0.5", :W, point_on(ell, pi), offset=8)

    sethue("white")
    path(F, action=:fillpreserve)
    sethue(julia_blue); strokepath()

    finish()
    preview()
    end
    ```

**An ellipse from a center, a vertex and a point.** [`ellipse_with_axis`](@ref)`(center,
vertex, p)` has the segment from the center to the vertex as a semi-axis, and
passes through `p`. The point must be off the axis and inside the strip of the
tangents at the ends of the axis.

```@example geo
ea = ellipse_with_axis(APPoint(0.0, 0.0), APPoint(5.0, 0.0), APPoint(3.0, 2.4))
ea.a, ea.b
```

```@raw html
<img src="../assets/img/conics/ellipse_axis.svg" alt="An ellipse built from its center, one vertex and a point on it" style="width:100%; max-width: 700px;">
```

**A hyperbola from its asymptotes.** [`hyperbola_with_asymptotes`](@ref)`(l1, l2, p)`
has the two lines as asymptotes and passes through `p`. Its center is where the
lines cross, and its transverse axis is the bisector that lies in the angle
containing `p`.

```@example geo
ha = hyperbola_with_asymptotes(APLine(APPoint(0.0, 0.0), APPoint(1.0, 1.0)), APLine(APPoint(0.0, 0.0), APPoint(1.0, -1.0)), APPoint(2.0, 0.0))
ha.a, ha.b
```

```@raw html
<img src="../assets/img/conics/asymptotes_ctor.svg" alt="A hyperbola built from its two asymptotes and a point on it" style="width:100%; max-width: 700px;">
```

**A parabola from three points and an axis.** [`parabola_through_points`](@ref)`(p1,
p2, p3, axis)` is the parabola whose axis has the direction `axis` and that goes
through the three points. It throws an `ArgumentError` when none exists.

```@example geo
pt3 = parabola_through_points(APPoint(-2.0, 4.0), APPoint(0.0, 0.0), APPoint(1.0, 1.0), APVector(0.0, 1.0))
pt3.focus
```

```@raw html
<img src="../assets/img/conics/parabola_ctor.svg" alt="A parabola through three points with a vertical axis" style="width:100%; max-width: 700px;">
```
