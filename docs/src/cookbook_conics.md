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

!!! details "See script"
    ```julia
    using Apollonius, Luxor
    import Luxor: julia_red, julia_blue, julia_green, julia_purple
    import Apollonius: rotate, translate, distance, midpoint

    lxm = @prepare_to_picture! width=500 height=240 margin=20 begin
        e = APEllipse2(APPoint(0.0, 0.0), 5.0, 3.0)
        c = e.center
        f1, f2 = foci(e)
        v1, v2 = vertices(e)
        p = point_on(e, 1.0)
        od = orthoptic(e)
    end


    begin
    Drawing(lxm.width, lxm.height, :svg)
    origin(); fontsize(15)

    @layer begin
        setline(1); setdash(:dash)
        sethue("gray80")
        path(od, action=:stroke)
        sethue(julia_green)
        path([APSegment(p, f1), APSegment(p, f2)], action=:stroke)
    end

    sethue(julia_blue)
    path(e, action=:stroke)
    sethue(julia_purple)
    sethue(julia_red)
    label("F1", :SW, f1, offset=8)
    label("F2", :SE, f2, offset=8)
    label("P", :N, p, offset=8)

    sethue("white")
    path(c, action=:fillpreserve)
    sethue(julia_blue); strokepath()
    sethue("white")
    path([f1, f2, v1, v2, p], action=:fillpreserve)
    sethue(julia_purple); strokepath()

    finish()
    preview()
    end
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

!!! details "See script"
    ```julia
    using Apollonius, Luxor
    import Luxor: julia_red, julia_blue, julia_green, julia_purple
    import Apollonius: rotate, translate, distance, midpoint

    lxm = @prepare_to_picture! width=500 height=260 margin=30 begin  
        e = APEllipse2(APPoint(0.0, 0.0), 5.0, 3.0)
        p = APPoint(13.0, 0.0)
        tp = tangent_points(e, p)
        tl = tangent_lines(e, p)
        pol = polar_line(e, p)
    end


    begin
    Drawing(lxm.width, lxm.height, :svg)
    origin(); fontsize(15)
    gsave()
    setline(1); setdash("dash")
    sethue(julia_green)
    path(pol, action=:stroke)
    grestore()
    sethue(julia_blue)
    path(e, action=:stroke)
    sethue(julia_purple)
    path(tl, action=:stroke, extend=0)
    sethue(julia_red)
    label("P", :N, p)
    sethue("white"); path(tp, action=:fillpreserve); sethue(julia_purple); strokepath()
    sethue("white"); path([p], action=:fillpreserve); sethue(julia_blue); strokepath()

    finish()
    preview()
    end
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

!!! details "See script"
    ```julia
    using Apollonius, Luxor
    import Luxor: julia_red, julia_blue, julia_green, julia_purple
    import Apollonius: rotate, translate, distance, midpoint

    lxm = @prepare_to_picture! width=500 height=240 margin=20 begin
        focus = APPoint(0.0, 1.0)
        dl = APSegment(APPoint(-6.0, -1.0), APPoint(6.0, -1.0))
        par = APParabola2(focus, APLine(dl.p1, dl.p2))
        arc = APParabolicArc2(par, point_on(par, -5.0), point_on(par, 5.0))
        p = point_on(par, 3.0)
        foot = projection(p, APLine(dl.p1, dl.p2))
        vtx = vertex(par)
    end


    begin
    Drawing(lxm.width, lxm.height, :svg)
    origin(); fontsize(15)
    sethue(julia_blue)
    path(dl, action=:stroke)

    @layer begin
        setline(1); setdash("dash")
        sethue(julia_green)
        path([APSegment(p, focus), APSegment(p, foot)], action=:stroke)
    end

    sethue(julia_purple)
    path(arc, action=:stroke)

    sethue(julia_red)
    label("F", :N, focus, offset=8)
    label("P", :NE, p, offset=8)
    text("directrix", dl.p2 + APVector(0.0,5.0), halign=:right, valign=:top)

    sethue("white")
    path([vtx, p, foot], action=:fillpreserve)
    sethue(julia_purple); strokepath()

    sethue("white")
    path(focus, action=:fillpreserve)
    sethue(julia_blue); strokepath()

    finish()
    preview()
    end
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

