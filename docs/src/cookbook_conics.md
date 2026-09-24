```@meta
CurrentModule = Apollonius
```

# Cookbook: Conics

## Working with conics

### An ellipse from its foci

```@example geo
using Apollonius

e = APEllipse2(APPoint(-3.0, 0.0), APPoint(3.0, 0.0), 5.0)
e.a, e.b, foci(e)
```

```@raw html
<img src="../assets/img/conics/ellipse_foci.svg" alt="An ellipse with its foci and the two focal distances of a point" style="width:100%; max-width: 700px;">
```

The last argument is the semi-major axis `a`, so the sum of the distances from a point of the ellipse to the two foci is `2a`.

### The tangent to a conic at a point, and from a point

The polar of a point on a conic is its tangent there, and the tangents from
an outside point are two:

```@example geo
e = APEllipse2(APPoint(0.0, 0.0), 5.0, 3.0)
p = point_on(e, 1.0)
at_p = polar_line(e, p)
is_on_line(p, at_p), length(tangent_lines(e, APPoint(8.0, 0.0)))
```

```@raw html
<img src="../assets/img/conics/tangents.svg" alt="An ellipse with a tangent at a point and the two tangents from an outside point" style="width:100%; max-width: 700px;">
```

### A parabola from a focus and a directrix

```@example geo
par = APParabola2(APPoint(0.0, 1.0), APLine(APPoint(0.0, -1.0), APPoint(1.0, -1.0)))
p = point_on(par, 0.7)
distance(p, par.focus) ≈ distance(p, par.directrix)
```

```@raw html
<img src="../assets/img/conics/parabola.svg" alt="A parabola with its focus, directrix and the equal distances of a point" style="width:100%; max-width: 700px;">
```

### The conic through five points

```@example geo
pts = [APPoint(5.0, 0.0), APPoint(0.0, 3.0), APPoint(-5.0, 0.0), APPoint(0.0, -3.0), APPoint(3.0, 2.4)]
conic_through_points(pts...)
```

```@raw html
<img src="../assets/img/conics/fit.svg" alt="A conic through five points" style="width:100%; max-width: 700px;">
```

See [Conics: Ellipse, Parabola & Hyperbola](@ref).

