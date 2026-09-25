```@meta
CurrentModule = Apollonius
```

# Triangles: Further Named Centers

The running example, the scalene triangle used throughout this page:

```@example geo
using Apollonius

A, B, C = APPoint(0.0, 0.0), APPoint(8.0, 0.0), APPoint(3.0, 6.0)
t = APTriangle(A, B, C)
nothing # hide
```

## Further named centers

Beyond the classical four, this package implements a large catalogue of
triangle centers and associated circles from classical triangle geometry.
Two, as a sample:

```@example geo
Na = nagel_point(t)     # point where the excircle-tangency cevians meet
Ge = gergonne_point(t)  # point where the incircle-tangency cevians meet
```

```@raw html
<img src="../assets/img/triangles/nagel_gergonne.svg" alt="The Gergonne and Nagel points, where the cevians to the incircle and excircle touch points meet" style="width:100%; max-width: 700px;">
```

!!! details "See script"
    ```julia
    using Apollonius, Luxor
    import Luxor: julia_red, julia_blue, julia_green, julia_purple
    import Apollonius: rotate, translate, distance, midpoint

    lxm = @prepare_to_picture! width=500 height=300 margin=30 begin  
        A, B, C = APPoint(0.0, 0.0), APPoint(8.0, 0.0), APPoint(3.0, 6.0)
        t = APTriangle(A, B, C)
        ct = contact_triangle(t)
        et = extouch_triangle(t)
        Na = nagel_point(t)
        Ge = gergonne_point(t)
        gcev = [APSegment(v, p) for (v, p) in zip((A, B, C), vertices(ct))]
        ncev = [APSegment(v, p) for (v, p) in zip((A, B, C), vertices(et))]
    end


    begin
    Drawing(lxm.width, lxm.height, :svg)
    origin(); fontsize(15)

    gsave()
    setline(1); setdash("dash")
    sethue(julia_green)
    path(gcev, action=:stroke)
    grestore()
    gsave()
    setline(1); setdash("dash")
    sethue("gray80")
    path(ncev, action=:stroke)
    grestore()
    sethue(julia_blue)
    path(t, action=:stroke)
    sethue(julia_purple)
    sethue(julia_red)
    label("Ge", :N, Ge); label("Na", :S, Na)
    sethue("white"); path([A, B, C], action=:fillpreserve); sethue(julia_blue); strokepath()
    sethue("white"); path([Ge, Na], action=:fillpreserve); sethue(julia_purple); strokepath()

    finish()
    preview()
    end
    ```

The rest, grouped by what they're built from:

| Group | Functions |
|:------|:----------|
| Cevian-intersection points | [`nagel_point`](@ref), [`gergonne_point`](@ref), [`symmedian_point`](@ref), [`fermat_point`](@ref), [`second_fermat_point`](@ref) |
| Conjugates of a point | [`isogonal_conjugate`](@ref), [`isotomic_conjugate`](@ref) |
| Complement/anticomplement of a point | [`complement`](@ref), [`anticomplement`](@ref) |
| Built from the incenter/excenters | [`mittenpunkt`](@ref), [`spieker_center`](@ref), [`spieker_circle`](@ref), [`bevan_point`](@ref), [`de_longchamps_point`](@ref) |
| Trilinear/barycentric formula, no simpler description | [`clawson_point`](@ref) |
| On the circumcircle or Euler line | [`feuerbach_point`](@ref), [`feuerbach_points`](@ref), [`isodynamic_points`](@ref) |
| Brocard configuration | [`first_brocard_point`](@ref), [`second_brocard_point`](@ref), [`angle_measure_brocard`](@ref), [`brocard_circle`](@ref), [`brocard_midpoint`](@ref) |
| Congruent-squares / conjugate-of-classical-center points | [`kenmotu_point`](@ref)/[`kenmotu_circle`](@ref), [`macbeath_point`](@ref) |
| A 4th point's common nine-point-circle point | [`poncelet_point`](@ref) |
| Pedal-type constructions | [`simson_line`](@ref), [`steiner_line`](@ref), [`orthopole`](@ref), [`pedal_triangle`](@ref)/[`pedal_circle`](@ref) |
| Named auxiliary circles | [`conway_points`](@ref)/[`conway_circle`](@ref), [`taylor_points`](@ref)/[`taylor_circle`](@ref), [`first_lemoine_points`](@ref)/[`first_lemoine_circle`](@ref)/[`second_lemoine_circle`](@ref)/[`symmedial_circle`](@ref), [`van_lamoen_points`](@ref)/[`van_lamoen_circle`](@ref), [`adams_points`](@ref)/[`adams_circle`](@ref) |
| Mutually tangent circle systems | [`mixtilinear_incircle`](@ref), [`three_tangent_circles`](@ref)/[`soddy_circles`](@ref)/[`soddy_line`](@ref)/[`soddy_center`](@ref)/[`soddy_points`](@ref), [`thebault_circles`](@ref) |
| Apollonius circles of a triangle | [`three_apollonius_circles`](@ref) (one per vertex; their common points are the [`isodynamic_points`](@ref)); [`apollonius_circle_of_triangle`](@ref)/[`apollonius_point_of_triangle`](@ref) (one circle, tangent to the three excircles instead) |
| Axis-like lines | [`fermat_axis`](@ref) (through [`fermat_point`](@ref) and [`second_fermat_point`](@ref)); see also [`orthic_axis`](@ref)/[`brocard_axis`](@ref)/[`lemoine_axis`](@ref) above and [`soddy_line`](@ref) |

All of these take the `APTriangle` as their (only, or first) argument and
return an `APPoint`, an `APCircle2`, an `APLine`, or (where there's naturally more
than one, like `soddy_circles` or `three_apollonius_circles`) a tuple or
named tuple. See the [API Reference](@ref) for exact signatures.

### Simson and Steiner lines

[`steiner_line`](@ref)`(t, p)` is closely related to [`simson_line`](@ref)`(t,
p)`: reflecting (rather than projecting) `p` across the three side-lines
gives three points that are collinear exactly when `p` is on the
circumcircle, and that Steiner line always passes through the orthocenter,
parallel to the Simson line of the same point.

```@example geo
p_on_circ = polar_point(circumradius(t), 0.7, circumcenter(t))   # any point on t's circumcircle
sl = simson_line(t, p_on_circ)
stl = steiner_line(t, p_on_circ)
is_on_line(orthocenter(t), stl), is_parallel(sl, stl)
```

```@raw html
<img src="../assets/img/triangles/simson_steiner.svg" alt="The Simson and Steiner lines of a point on the circumcircle" style="width:100%; max-width: 700px;">
```

!!! details "See script"
    ```julia
    using Apollonius, Luxor
    import Luxor: julia_red, julia_blue, julia_green, julia_purple
    import Apollonius: rotate, translate, distance, midpoint

    lxm = @prepare_to_picture! width=500 height=320 margin=30 begin  
        A, B, C = APPoint(0.0, 0.0), APPoint(8.0, 0.0), APPoint(3.0, 6.0)
        t = APTriangle(A, B, C)
        cc = circumcircle(t)
        P = polar_point(circumradius(t), 0.7, circumcenter(t))
        feet = [projection(P, APLine(s.p1, s.p2)) for s in sides(t)]
        sl = simson_line(t, P)
        stl = steiner_line(t, P)
        H = orthocenter(t)
    end


    begin
    Drawing(lxm.width, lxm.height, :svg)
    origin(); fontsize(15)

    gsave()
    sethue("gray80")
    path(cc, action=:stroke)
    grestore()
    sethue(julia_blue)
    path(t, action=:stroke)
    sethue(julia_purple)
    path(sl, action=:stroke, extend=30)
    gsave()
    setline(1); setdash("dash")
    path(stl, action=:stroke, extend=30)
    grestore()
    sethue(julia_red)
    label("P", :NE, P); label("H", :E, H)
    sethue("white"); path([A, B, C], action=:fillpreserve); sethue(julia_blue); strokepath()
    sethue("white"); path(feet, action=:fillpreserve); sethue(julia_purple); strokepath()
    sethue("white"); path([P, H], action=:fillpreserve); sethue(julia_blue); strokepath()

    finish()
    preview()
    end
    ```

[`orthopole`](@ref)`(l, t)` is the point where the three perpendiculars
(one per vertex, dropped from that vertex's projection onto `l`, to the
*opposite* side) always concur. [`pedal_triangle`](@ref)`(t, p)` (the feet
of the perpendiculars from `p` to the three side-lines) generalizes
[`orthic_triangle`](@ref)/[`contact_triangle`](@ref), which are just the
pedal triangles of the orthocenter/incenter:

```@example geo
orthopole(APLine(t[2], t[3]), t) isa APPoint
pedal_triangle(t, incenter(t)) ≈ contact_triangle(t)
```

```@raw html
<img src="../assets/img/triangles/orthopole.svg" alt="The orthopole of a line with respect to a triangle: each vertex is projected onto the line, and the perpendicular from that projection to the opposite side; the three perpendiculars concur at the orthopole" style="width:100%; max-width: 700px;">
```

!!! details "See script"
    ```julia
    using Apollonius, Luxor
    import Luxor: julia_red, julia_blue, julia_green, julia_purple
    import Apollonius: rotate, translate, distance, midpoint

    lxm = @prepare_to_picture! width=500 height=300 margin=30 begin  
        A, B, C = APPoint(0.0, 0.0), APPoint(8.0, 0.0), APPoint(3.0, 6.0)
        t = APTriangle(A, B, C)
        l = APLine(APPoint(-2.0, -1.0), APPoint(10.0, 6.0))

        projA = projection(A, l)
        projB = projection(B, l)
        projC = projection(C, l)

        lA = perpendicular_through(APLine(B, C), projA)
        lB = perpendicular_through(APLine(C, A), projB)
        lC = perpendicular_through(APLine(A, B), projC)

        op = orthopole(l, t)
    end


    begin
    Drawing(lxm.width, lxm.height, :svg)
    origin(); fontsize(15)

    gsave()
    setline(1); setdash("dash")
    sethue(julia_green)
    path([APSegment(A, projA), APSegment(B, projB), APSegment(C, projC)], action=:stroke)
    path([lA, lB, lC], action=:stroke)
    grestore()

    sethue(julia_blue)
    path(t, action=:stroke)
    path(l, action=:stroke)

    sethue(julia_red)
    label("l", :N, l.p2)
    label("orthopole", :SE, op)

    sethue("white"); path([A, B, C], action=:fillpreserve); sethue(julia_blue); strokepath()
    sethue("white"); path([projA, projB, projC], action=:fillpreserve); sethue(julia_green); strokepath()
    sethue("white"); path([op], action=:fillpreserve); sethue(julia_purple); strokepath()

    finish()
    preview()
    end
    ```

[`pedal_circle`](@ref)`(t, p)` is just the circumcircle of that pedal
triangle:

```@example geo
pedal_circle(t, incenter(t)) ≈ incircle(t)   # the incircle is the pedal circle of the incenter
```

```@raw html
<img src="../assets/img/triangles/pedal.svg" alt="The pedal triangle and pedal circle of a point" style="width:100%; max-width: 700px;">
```

!!! details "See script"
    ```julia
    using Apollonius, Luxor
    import Luxor: julia_red, julia_blue, julia_green, julia_purple
    import Apollonius: rotate, translate, distance, midpoint

    lxm = @prepare_to_picture! width=500 height=300 margin=30 begin  
        A, B, C = APPoint(0.0, 0.0), APPoint(8.0, 0.0), APPoint(3.0, 6.0)
        t = APTriangle(A, B, C)
        P = APPoint(4.0, 2.0)
        pt = pedal_triangle(t, P)
        pc = pedal_circle(t, P)
        feet = collect(vertices(pt))
        legs = [APSegment(P, f) for f in feet]
    end


    begin
    Drawing(lxm.width, lxm.height, :svg)
    origin(); fontsize(15)

    gsave()
    setline(1); setdash("dash")
    sethue(julia_green)
    path(legs, action=:stroke)
    grestore()
    sethue(julia_blue)
    path(t, action=:stroke)
    sethue(julia_purple)
    path([pt, pc], action=:stroke)
    sethue(julia_red)
    label("P", :NE, P)
    sethue("white"); path([A, B, C], action=:fillpreserve); sethue(julia_blue); strokepath()
    sethue("white"); path(feet, action=:fillpreserve); sethue(julia_purple); strokepath()
    sethue("white"); path([P], action=:fillpreserve); sethue(julia_blue); strokepath()

    finish()
    preview()
    end
    ```

### Brocard, Kenmotu and MacBeath

```@example geo
brocard_midpoint(t)   # midpoint of the two Brocard points (Kimberling X(39))
kenmotu_point(t)       # X(371): common vertex of 3 congruent inscribed squares
macbeath_point(t)      # X(264): isotomic conjugate of the circumcenter
```

```@raw html
<img src="../assets/img/triangles/macbeath.svg" alt="A triangle, its circumcenter, and the MacBeath point (the isotomic conjugate of the circumcenter)" style="width:100%; max-width: 700px;">
```

### The symmedian point

[`symmedian_point`](@ref) is the fourth cevian-intersection point, built
from barycentric coordinates `a² : b² : c²` the same way `nagel_point`/
`gergonne_point` are built from their own:

```@example geo
symmedian_point(t)
```

### Conjugates of a point

[`isogonal_conjugate`](@ref)`(t, p)` reflects each cevian `vertex -> p`
across the internal bisector at that vertex; [`isotomic_conjugate`](@ref)`(t,
p)` instead reflects the cevian's foot across the opposite side's midpoint.
Both are involutions (applying either twice returns `p`), and
`isogonal_conjugate` swaps orthocenter↔circumcenter and centroid↔symmedian
point while fixing the incenter:

```@example geo
isogonal_conjugate(t, isogonal_conjugate(t, incenter(t))) ≈ incenter(t)   # incenter is a fixed point
isogonal_conjugate(t, orthocenter(t)) ≈ circumcenter(t)
isogonal_conjugate(t, centroid(t)) ≈ symmedian_point(t)
```

```@raw html
<img src="../assets/img/triangles/isogonal.svg" alt="A point and its isogonal conjugate" style="width:100%; max-width: 700px;">
```

!!! details "See script"
    ```julia
    using Apollonius, Luxor
    import Luxor: julia_red, julia_blue, julia_green, julia_purple
    import Apollonius: rotate, translate, distance, midpoint

    lxm = @prepare_to_picture! width=500 height=300 margin=30 begin  
        A, B, C = APPoint(0.0, 0.0), APPoint(8.0, 0.0), APPoint(3.0, 6.0)
        t = APTriangle(A, B, C)
        P = APPoint(4.0, 2.0)
        Q = isogonal_conjugate(t, P)
        toP = [APSegment(v, P) for v in (A, B, C)]
        toQ = [APSegment(v, Q) for v in (A, B, C)]
    end


    begin
    Drawing(lxm.width, lxm.height, :svg)
    origin(); fontsize(15)

    gsave()
    setline(1)
    sethue("gray80")
    path(toP, action=:stroke)
    sethue(julia_purple)
    path(toQ, action=:stroke)
    grestore()
    sethue(julia_blue)
    path(t, action=:stroke)
    sethue(julia_red)
    label("P", :NE, P); label("P*", :N, Q)
    sethue("white"); path([A, B, C], action=:fillpreserve); sethue(julia_blue); strokepath()
    sethue("white"); path([P], action=:fillpreserve); sethue("gray80"); strokepath()
    sethue("white"); path([Q], action=:fillpreserve); sethue(julia_purple); strokepath()

    finish()
    preview()
    end
    ```

```@example geo
isotomic_conjugate(t, isotomic_conjugate(t, incenter(t))) ≈ incenter(t)
```

```@raw html
<img src="../assets/img/triangles/isotomic.svg" alt="A point and its isotomic conjugate" style="width:100%; max-width: 700px;">
```

!!! details "See script"
    ```julia
    using Apollonius, Luxor
    import Luxor: julia_red, julia_blue, julia_green, julia_purple
    import Apollonius: rotate, translate, distance, midpoint

    lxm = @prepare_to_picture! width=500 height=300 margin=30 begin  
        A, B, C = APPoint(0.0, 0.0), APPoint(8.0, 0.0), APPoint(3.0, 6.0)
        t = APTriangle(A, B, C)
        P = APPoint(4.0, 2.0)
        Q = isotomic_conjugate(t, P)
        toP = [APSegment(v, P) for v in (A, B, C)]
        toQ = [APSegment(v, Q) for v in (A, B, C)]
    end


    begin
    Drawing(lxm.width, lxm.height, :svg)
    origin(); fontsize(15)

    gsave()
    setline(1)
    sethue("gray80")
    path(toP, action=:stroke)
    sethue(julia_purple)
    path(toQ, action=:stroke)
    grestore()
    sethue(julia_blue)
    path(t, action=:stroke)
    sethue(julia_red)
    label("P", :NE, P); label("P'", :N, Q)
    sethue("white"); path([A, B, C], action=:fillpreserve); sethue(julia_blue); strokepath()
    sethue("white"); path([P], action=:fillpreserve); sethue("gray80"); strokepath()
    sethue("white"); path([Q], action=:fillpreserve); sethue(julia_purple); strokepath()

    finish()
    preview()
    end
    ```

### Complement and anticomplement

[`anticomplement`](@ref)`(t, p)` is the inverse of [`complement`](@ref)`(t,
p)`: homothety by `-2` instead of `-1/2` about the centroid:

```@example geo
anticomplement(t, complement(t, incenter(t))) ≈ incenter(t)
```

### Incenter and excenters

Built from the incenter/excenters: [`spieker_center`](@ref) (the incenter
of the medial triangle) and [`spieker_circle`](@ref) (its incircle);
[`bevan_point`](@ref) (circumcenter of the excentral triangle); and
[`de_longchamps_point`](@ref) (the orthocenter reflected across the
circumcenter, so it always lies on the Euler line):

```@example geo
spieker_center(t) ≈ incenter(medial_triangle(t))
spieker_circle(t) ≈ incircle(medial_triangle(t))
bevan_point(t) ≈ circumcenter(excentral_triangle(t))
is_on_line(de_longchamps_point(t), euler_line(t))
```

```@raw html
<img src="../assets/img/triangles/spieker.svg" alt="The medial triangle with its incircle, the Spieker circle" style="width:100%; max-width: 700px;">
```

!!! details "See script"
    ```julia
    using Apollonius, Luxor
    import Luxor: julia_red, julia_blue, julia_green, julia_purple
    import Apollonius: rotate, translate, distance, midpoint

    lxm = @prepare_to_picture! width=500 height=300 margin=30 begin  
        A, B, C = APPoint(0.0, 0.0), APPoint(8.0, 0.0), APPoint(3.0, 6.0)
        t = APTriangle(A, B, C)
        mt = medial_triangle(t)
        sc = spieker_circle(t)
        S = spieker_center(t)
    end


    begin
    Drawing(lxm.width, lxm.height, :svg)
    origin(); fontsize(15)

    sethue("gray80")
    path(mt, action=:stroke)
    sethue(julia_blue)
    path(t, action=:stroke)
    sethue(julia_purple)
    path(sc, action=:stroke)
    sethue(julia_red)
    label("S", :N, S)
    sethue("white"); path([A, B, C], action=:fillpreserve); sethue(julia_blue); strokepath()
    sethue("white"); path([S], action=:fillpreserve); sethue(julia_purple); strokepath()

    finish()
    preview()
    end
    ```

```@raw html
<img src="../assets/img/triangles/bevan.svg" alt="The excentral triangle with its circumcircle, centered at the Bevan point" style="width:100%; max-width: 700px;">
```

!!! details "See script"
    ```julia
    using Apollonius, Luxor
    import Luxor: julia_red, julia_blue, julia_green, julia_purple
    import Apollonius: rotate, translate, distance, midpoint

    lxm = @prepare_to_picture! width=500 height=320 margin=30 begin  
        A, B, C = APPoint(0.0, 0.0), APPoint(8.0, 0.0), APPoint(3.0, 6.0)
        t = APTriangle(A, B, C)
        ext = excentral_triangle(t)
        bc = circumcircle(ext)
        Be = bevan_point(t)
    end


    begin
    Drawing(lxm.width, lxm.height, :svg)
    origin(); fontsize(15)

    sethue("gray80")
    path(ext, action=:stroke)
    sethue(julia_blue)
    path(t, action=:stroke)
    sethue(julia_purple)
    path(bc, action=:stroke)
    sethue(julia_red)
    label("Be", :N, Be)
    sethue("white"); path([A, B, C], action=:fillpreserve); sethue(julia_blue); strokepath()
    sethue("white"); path([Be], action=:fillpreserve); sethue(julia_purple); strokepath()

    finish()
    preview()
    end
    ```

```@raw html
<img src="../assets/img/triangles/de_longchamps.svg" alt="The orthocenter, circumcenter and de Longchamps point on the Euler line" style="width:100%; max-width: 700px;">
```

### Apollonius circles and isodynamic points

The two [`isodynamic_points`](@ref) are where the three
[`three_apollonius_circles`](@ref) (one per vertex, for points whose
distances to the other two vertices are in the same ratio as the two sides
meeting at that vertex) all meet:

```@example geo
apo = three_apollonius_circles(t)
iso1, iso2 = isodynamic_points(t)
all(c -> distance(c.center, iso1) ≈ c.r, apo), all(c -> distance(c.center, iso2) ≈ c.r, apo)
```

```@raw html
<img src="../assets/img/triangles/isodynamic.svg" alt="The three Apollonius circles of a triangle and the two isodynamic points" style="width:100%; max-width: 700px;">
```

!!! details "See script"
    ```julia
    using Apollonius, Luxor
    import Luxor: julia_red, julia_blue, julia_green, julia_purple
    import Apollonius: rotate, translate, distance, midpoint

    lxm = @prepare_to_picture! width=500 height=340 margin=30 begin  
        A, B, C = APPoint(0.0, 0.0), APPoint(8.0, 0.0), APPoint(3.0, 6.0)
        t = APTriangle(A, B, C)
        apo = collect(three_apollonius_circles(t))
        iso1, iso2 = isodynamic_points(t)
    end


    begin
    Drawing(lxm.width, lxm.height, :svg)
    origin(); fontsize(15)

    sethue(julia_purple)
    path(apo, action=:stroke)
    sethue(julia_blue)
    path(t, action=:stroke)
    sethue(julia_red)
    label("1", :N, iso1); label("2", :N, iso2)
    sethue("white"); path([A, B, C], action=:fillpreserve); sethue(julia_blue); strokepath()
    sethue("white"); path([iso1, iso2], action=:fillpreserve); sethue(julia_purple); strokepath()

    finish()
    preview()
    end
    ```

### The Apollonius circle and point

Despite the shared name, [`apollonius_circle_of_triangle`](@ref) is a
different construction: the circle tangent to and enclosing all three
excircles of `t`. Take that circle's point of tangency with each excircle,
draw the line from the excircle's own vertex (the one it sits opposite)
through that tangency point, and the three lines meet at
[`apollonius_point_of_triangle`](@ref) (Kimberling X(181)):

```@example geo
ap_circle = apollonius_circle_of_triangle(t)
ex = excircles(t)
distance(ap_circle.center, ex.A.center) ≈ ap_circle.r - ex.A.r  # internally tangent
```

```@raw html
<img src="../assets/img/triangles/apollonius_triangle.svg" alt="The three excircles and the circle tangent to all of them" style="width:100%; max-width: 700px;">
```

!!! details "See script"
    ```julia
    using Apollonius, Luxor
    import Luxor: julia_red, julia_blue, julia_green, julia_purple
    import Apollonius: rotate, translate, distance, midpoint

    lxm = @prepare_to_picture! width=500 height=340 margin=30 begin  
        A, B, C = APPoint(0.0, 0.0), APPoint(8.0, 0.0), APPoint(3.0, 6.0)
        t = APTriangle(A, B, C)
        ex = excircles(t)
        exc = [ex.A, ex.B, ex.C]
        apc = apollonius_circle_of_triangle(t)
        ap = apollonius_point_of_triangle(t)
    end


    begin
    Drawing(lxm.width, lxm.height, :svg)
    origin(); fontsize(15)

    sethue("gray80")
    path(exc, action=:stroke)
    sethue(julia_blue)
    path(t, action=:stroke)
    sethue(julia_purple)
    path(apc, action=:stroke)
    sethue("white"); path([A, B, C], action=:fillpreserve); sethue(julia_blue); strokepath()
    sethue("white"); path([ap], action=:fillpreserve); sethue(julia_purple); strokepath()

    finish()
    preview()
    end
    ```

```@example geo
apollonius_point_of_triangle(t)
```

### The Brocard configuration

The Brocard configuration: [`first_brocard_point`](@ref)/
[`second_brocard_point`](@ref) are the two points seeing all three sides at
the same angle, whose measure is [`angle_measure_brocard`](@ref); [`brocard_circle`](@ref) passes through
both (and through the symmedian point):

```@example geo
Om1, Om2 = first_brocard_point(t), second_brocard_point(t)
bc = brocard_circle(t)
rad2deg(angle_measure_brocard(t)), distance(bc.center, Om1) ≈ bc.r, distance(bc.center, Om2) ≈ bc.r
```

```@raw html
<img src="../assets/img/triangles/brocard.svg" alt="The Brocard points, the symmedian point and the Brocard circle" style="width:100%; max-width: 700px;">
```

### Named auxiliary circles

Named auxiliary circles: [`conway_points`](@ref)/[`conway_circle`](@ref)
(extend the two sides at each vertex outward by the length of the
opposite side; all 6 endpoints lie on a circle centered at the incenter),
[`taylor_circle`](@ref) (through the 6 [`taylor_points`](@ref)),
[`first_lemoine_points`](@ref)/[`first_lemoine_circle`](@ref) and
[`second_lemoine_circle`](@ref) (both centered differently, both built
from the symmedian point), [`symmedial_circle`](@ref) (circumcircle of
the cevian triangle of the symmedian point, a third circle built from the
same point), [`van_lamoen_circle`](@ref) (through the 6
[`van_lamoen_points`](@ref)), and [`adams_circle`](@ref) (through the 6
[`adams_points`](@ref), centered at the incenter):

```@example geo
on_circ(p, c) = distance(p, c.center) ≈ c.r   # "p is exactly on c", not just inside the disk

all(p -> on_circ(p, conway_circle(t)), conway_points(t)),
    all(p -> on_circ(p, taylor_circle(t)), taylor_points(t)),
    all(p -> on_circ(p, first_lemoine_circle(t)), first_lemoine_points(t)),
    symmedian_point(t) ≈ second_lemoine_circle(t).center,
    all(v -> on_circ(v, symmedial_circle(t)), cevian_triangle(t, symmedian_point(t))),
    all(p -> on_circ(p, van_lamoen_circle(t)), van_lamoen_points(t)),
    all(p -> on_circ(p, adams_circle(t)), adams_points(t))
```

```@raw html
<img src="../assets/img/triangles/conway_adams.svg" alt="The Conway and Adams circles, both centered at the incenter" style="width:100%; max-width: 700px;">
```

!!! details "See script"
    ```julia
    using Apollonius, Luxor
    import Luxor: julia_red, julia_blue, julia_green, julia_purple
    import Apollonius: rotate, translate, distance, midpoint

    lxm = @prepare_to_picture! width=500 height=340 margin=30 begin  
        A, B, C = APPoint(0.0, 0.0), APPoint(8.0, 0.0), APPoint(3.0, 6.0)
        t = APTriangle(A, B, C)
        inc = incircle(t)
        cwc = conway_circle(t)
        cwp = collect(conway_points(t))
        adc = adams_circle(t)
        adp = collect(adams_points(t))
    end


    begin
    Drawing(lxm.width, lxm.height, :svg)
    origin()

    sethue("gray80")
    path(inc, action=:stroke)
    sethue(julia_blue)
    path(t, action=:stroke)
    sethue(julia_purple)
    path([cwc, adc], action=:stroke)
    sethue("white"); path([A, B, C], action=:fillpreserve); sethue(julia_blue); strokepath()
    sethue("white"); path(cwp, action=:fillpreserve); sethue(julia_purple); strokepath()
    sethue("white"); path(adp, action=:fillpreserve); sethue(julia_purple); strokepath()

    finish()
    preview()
    end
    ```

```@raw html
<img src="../assets/img/triangles/lemoine_circles.svg" alt="The first Lemoine, second Lemoine and symmedial circles" style="width:100%; max-width: 700px;">
```

!!! details "See script"
    ```julia
    using Apollonius, Luxor
    import Luxor: julia_red, julia_blue, julia_green, julia_purple
    import Apollonius: rotate, translate, distance, midpoint

    lxm = @prepare_to_picture! width=500 height=300 margin=30 begin  
        A, B, C = APPoint(0.0, 0.0), APPoint(8.0, 0.0), APPoint(3.0, 6.0)
        t = APTriangle(A, B, C)
        K = symmedian_point(t)
        c1 = first_lemoine_circle(t)
        c2 = second_lemoine_circle(t)
        c3 = symmedial_circle(t)
        p1 = collect(first_lemoine_points(t))
    end


    begin
    Drawing(lxm.width, lxm.height, :svg)
    origin(); fontsize(15)

    sethue(julia_blue)
    path(t, action=:stroke)
    sethue(julia_purple)
    path([c1, c2, c3], action=:stroke)
    sethue(julia_red)
    label("K", :N, K)
    sethue("white"); path([A, B, C], action=:fillpreserve); sethue(julia_blue); strokepath()
    sethue("white"); path(p1, action=:fillpreserve); sethue(julia_purple); strokepath()
    sethue("white"); path([K], action=:fillpreserve); sethue(julia_purple); strokepath()

    finish()
    preview()
    end
    ```

### Mixtilinear incircles and Soddy circles

[`mixtilinear_incircle`](@ref)`(t, i)` is tangent to the two sides through
`t[i]` and internally tangent to the circumcircle; [`soddy_circles`](@ref)
(`inner`/`outer`) and [`soddy_line`](@ref) extend
[`three_tangent_circles`](@ref) (see [Tangency & Apollonius Problems](@ref)):

```@example geo
mixt = mixtilinear_incircle(t, 1)
sc = soddy_circles(t)
is_on_line(sc.inner.center, soddy_line(t)), is_on_line(sc.outer.center, soddy_line(t))
```

```@raw html
<img src="../assets/img/triangles/mixtilinear.svg" alt="The vertex A mixtilinear incircle" style="width:100%; max-width: 700px;">
```

```@raw html
<img src="../assets/img/triangles/soddy.svg" alt="The three tangent circles, the inner Soddy circle and the Soddy line" style="width:100%; max-width: 700px;">
```

!!! details "See script"
    ```julia
    using Apollonius, Luxor
    import Luxor: julia_red, julia_blue, julia_green, julia_purple
    import Apollonius: rotate, translate, distance, midpoint

    lxm = @prepare_to_picture! width=500 height=340 margin=30 begin  
        A, B, C = APPoint(0.0, 0.0), APPoint(8.0, 0.0), APPoint(3.0, 6.0)
        t = APTriangle(A, B, C)
        base = collect(three_tangent_circles(t))
        sc = soddy_circles(t)
        sdl = soddy_line(t)
        soddy_pts = [sc.inner.center, sc.outer.center]
        inner = sc.inner
    end


    begin
    Drawing(lxm.width, lxm.height, :svg)
    origin()

    sethue("gray80")
    path(base, action=:stroke)
    sethue(julia_blue)
    path(t, action=:stroke)
    sethue(julia_purple)
    path(inner, action=:stroke)
    path(sdl, action=:stroke, extend=30)
    sethue("white"); path([A, B, C], action=:fillpreserve); sethue(julia_blue); strokepath()
    sethue("white"); path(soddy_pts, action=:fillpreserve); sethue(julia_purple); strokepath()

    finish()
    preview()
    end
    ```

[`soddy_center`](@ref)`(t; outer=false)` is just the center of one of
those two circles, as a point on its own (Kimberling X(176) for the
inner one, the default, and X(175) for `outer=true`); [`soddy_points`](@ref)
gives both at once, as `(inner=..., outer=...)`:

```@example geo
soddy_center(t) == sc.inner.center
soddy_points(t) == (inner=sc.inner.center, outer=sc.outer.center)
```

### The second Fermat point

[`second_fermat_point`](@ref) is built exactly like [`fermat_point`](@ref)
but with the three equilateral triangles erected *inward* instead of
outward; [`fermat_axis`](@ref) is the line through both:

```@example geo
fermat_axis(t)   # APLine(fermat_point(t), second_fermat_point(t))
```

```@raw html
<img src="../assets/img/triangles/fermat.svg" alt="The two Fermat points and the line through them" style="width:100%; max-width: 700px;">
```

### The Poncelet point

[`poncelet_point`](@ref)`(t, p)` uses a striking fact about *any* 4 points
in general position (here, `t`'s 3 vertices plus a 4th, `p`): the
nine-point circles of the 4 triangles obtained by leaving out one point
each time always share a single common point.

```@example geo
poncelet_point(t, APPoint(5.0, -2.0))
```

```@raw html
<img src="../assets/img/triangles/poncelet.svg" alt="The nine-point circles of four triangles meeting at the Poncelet point" style="width:100%; max-width: 700px;">
```

!!! details "See script"
    ```julia
    using Apollonius, Luxor
    import Luxor: julia_red, julia_blue, julia_green, julia_purple
    import Apollonius: rotate, translate, distance, midpoint

    lxm = @prepare_to_picture! width=500 height=320 margin=30 begin  
        A, B, C = APPoint(0.0, 0.0), APPoint(8.0, 0.0), APPoint(3.0, 6.0)
        t = APTriangle(A, B, C)
        D = APPoint(5.0, -2.0)
        tris = [APTriangle(A, B, C), APTriangle(A, B, D), APTriangle(B, C, D), APTriangle(C, A, D)]
        npc = [nine_point_circle(x) for x in tris]
        pp = poncelet_point(t, D)
    end


    begin
    Drawing(lxm.width, lxm.height, :svg)
    origin(); fontsize(15)

    sethue(julia_blue)
    path(t, action=:stroke)
    sethue(julia_purple)
    path(npc, action=:stroke)
    sethue(julia_red)
    label("D", :S, D)
    sethue("white"); path([A, B, C], action=:fillpreserve); sethue(julia_blue); strokepath()
    sethue("white"); path([pp], action=:fillpreserve); sethue(julia_purple); strokepath()
    sethue("white"); path([D], action=:fillpreserve); sethue(julia_blue); strokepath()

    finish()
    preview()
    end
    ```

### The Thébault circles

[`thebault_circles`](@ref) builds the two circles of the classical
**Sawayama–Thébault configuration**: given a point `p` on side `[t[2],
t[3]]`, each is tangent to the cevian `t[1] -> p`, to that side, and
internally tangent to the circumcircle: one nestled against `t[2]`, the
other against `t[3]`.

```@example geo
D = B + 0.4 * (C - B)   # a point on side [B, C]
th = thebault_circles(t, D)
```

No matter where `p` sits on the side, the incenter always lies
exactly on the segment joining the two circles' centers (the theorem the
construction is named for):

```@example geo
is_on_line(incenter(t), APLine(th.near_b.center, th.near_c.center))
```

```@raw html
<img src="../assets/img/triangles/thebault.svg" alt="The two Thébault circles and the line through their centers, which passes through the incenter" style="width:100%; max-width: 700px;">
```

!!! details "See script"
    ```julia
    using Apollonius, Luxor
    import Luxor: julia_red, julia_blue, julia_green, julia_purple
    import Apollonius: rotate, translate, distance, midpoint

    lxm = @prepare_to_picture! width=500 height=340 margin=30 begin  
        A, B, C = APPoint(0.0, 0.0), APPoint(8.0, 0.0), APPoint(3.0, 6.0)
        t = APTriangle(A, B, C)
        cc = circumcircle(t)
        D = B + 0.4 * (C - B)
        th = thebault_circles(t, D)
        nb, nc = th.near_b, th.near_c
        I = incenter(t)
        lk = APLine(nb.center, nc.center)
        cev = APSegment(A, D)
    end


    begin
    Drawing(lxm.width, lxm.height, :svg)
    origin(); fontsize(15)

    sethue("gray80")
    path(cc, action=:stroke)
    gsave()
    setline(1); setdash("dash")
    sethue(julia_green)
    path(cev, action=:stroke)
    grestore()
    sethue(julia_blue)
    path(t, action=:stroke)
    sethue(julia_purple)
    path([nb, nc], action=:stroke)
    path(lk, action=:stroke, extend=30)
    sethue(julia_red)
    label("D", :S, D)
    sethue("white"); path([A, B, C], action=:fillpreserve); sethue(julia_blue); strokepath()
    sethue("white"); path([I], action=:fillpreserve); sethue(julia_purple); strokepath()
    sethue("white"); path([D], action=:fillpreserve); sethue(julia_blue); strokepath()

    finish()
    preview()
    end
    ```

### Three tangent circles

[`three_tangent_circles`](@ref) is the simpler configuration
[`soddy_circles`](@ref) is itself built from: one circle per vertex,
radius equal to the tangent length from that vertex to the incircle, each
pair meeting exactly where the incircle touches the side between them.

```@example geo
base = three_tangent_circles(t)
distance(base[1].center, base[2].center) ≈ base[1].r + base[2].r   # pairwise externally tangent
```

```@raw html
<img src="../assets/img/triangles/three_tangent.svg" alt="Three pairwise tangent circles centered at the vertices" style="width:100%; max-width: 700px;">
```

### The Taylor points

[`taylor_points`](@ref) is the full 6-point construction behind
[`taylor_circle`](@ref): project each vertex of the [`orthic_triangle`](@ref)
onto each of the two sides *not* used to define it; all 6 results are
concyclic.

```@example geo
length(taylor_points(t))   # 6
```

```@raw html
<img src="../assets/img/triangles/taylor.svg" alt="The orthic triangle and the Taylor circle through six projections" style="width:100%; max-width: 700px;">
```

### The Van Lamoen points

[`van_lamoen_points`](@ref) is another 6-concyclic-points theorem: the
circumcenters of the 6 small triangles the 3 medians cut `t` into (each
formed by one vertex, one non-adjacent side midpoint, and the centroid)
always lie on a common circle, [`van_lamoen_circle`](@ref).

```@example geo
length(van_lamoen_points(t))   # 6
```

```@raw html
<img src="../assets/img/triangles/van_lamoen.svg" alt="The three medians and the Van Lamoen circle" style="width:100%; max-width: 700px;">
```

!!! details "See script"
    ```julia
    using Apollonius, Luxor
    import Luxor: julia_red, julia_blue, julia_green, julia_purple
    import Apollonius: rotate, translate, distance, midpoint

    lxm = @prepare_to_picture! width=500 height=300 margin=30 begin  
        A, B, C = APPoint(0.0, 0.0), APPoint(8.0, 0.0), APPoint(3.0, 6.0)
        t = APTriangle(A, B, C)
        vc = van_lamoen_circle(t)
        vp = collect(van_lamoen_points(t))
        meds = [APSegment(v, midpoint(w1, w2)) for (v, w1, w2) in ((A, B, C), (B, C, A), (C, A, B))]
    end


    begin
    Drawing(lxm.width, lxm.height, :svg)
    origin()

    gsave()
    setline(1); setdash("dash")
    sethue("gray80")
    path(meds, action=:stroke)
    grestore()
    sethue(julia_blue)
    path(t, action=:stroke)
    sethue(julia_purple)
    path(vc, action=:stroke)
    sethue("white"); path([A, B, C], action=:fillpreserve); sethue(julia_blue); strokepath()
    sethue("white"); path(vp, action=:fillpreserve); sethue(julia_purple); strokepath()

    finish()
    preview()
    end
    ```

### The medial triangle

[`complement`](@ref)`(t, p)` and [`anticomplement`](@ref)`(t, p)` are the
homotheties of ratio `-1/2` and `-2` about the centroid, inverses of each
other. Applied to `t`'s own vertices they give the [`medial_triangle`](@ref)
and the anticomplementary triangle (see [Derived triangles](@ref))
respectively:

```@example geo
complement(t, A) ≈ midpoint(B, C)
```

### The Kenmotu circle

[`kenmotu_circle`](@ref) is centered at the [`kenmotu_point`](@ref), with
radius `√2·a·b·c / (4·Area + a²+b²+c²)`; it passes through the 6 points
where the three congruent inscribed squares of the Kenmotu configuration
meet the sides.

```@example geo
kenmotu_circle(t)
```

```@raw html
<img src="../assets/img/triangles/kenmotu.svg" alt="The Kenmotu point and the Kenmotu circle" style="width:100%; max-width: 700px;">
```

### The Feuerbach point

[`feuerbach_point`](@ref) is where the incircle and the nine-point circle
touch, internally:

```@example geo
fp = feuerbach_point(t)
distance(fp, incenter(t)) ≈ inradius(t), distance(fp, nine_point_center(t)) ≈ nine_point_circle(t).r
```

[`feuerbach_points`](@ref) is its excircle analogue: besides that internal
tangency with the incircle, the nine-point circle is *externally* tangent
to each of the three excircles too, at these three points.

```@example geo
feuerbach_points(t)
```

```@raw html
<img src="../assets/img/triangles/feuerbach.svg" alt="The nine-point circle tangent to the incircle and the three excircles" style="width:100%; max-width: 700px;">
```

!!! details "See script"
    ```julia
    using Apollonius, Luxor
    import Luxor: julia_red, julia_blue, julia_green, julia_purple
    import Apollonius: rotate, translate, distance, midpoint

    lxm = @prepare_to_picture! width=500 height=360 margin=30 begin  
        A, B, C = APPoint(0.0, 0.0), APPoint(8.0, 0.0), APPoint(3.0, 6.0)
        t = APTriangle(A, B, C)
        np = nine_point_circle(t)
        inc = incircle(t)
        ex = excircles(t)
        exc = [ex.A, ex.B, ex.C]
        fp = feuerbach_point(t)
        fps = collect(feuerbach_points(t))
    end


    begin
    Drawing(lxm.width, lxm.height, :svg)
    origin()

    sethue("gray80")
    path([inc; exc], action=:stroke)
    sethue(julia_blue)
    path(t, action=:stroke)
    sethue(julia_purple)
    path(np, action=:stroke)
    sethue("white"); path([A, B, C], action=:fillpreserve); sethue(julia_blue); strokepath()
    sethue("white"); path([fp; fps], action=:fillpreserve); sethue(julia_purple); strokepath()

    finish()
    preview()
    end
    ```

### The Kiepert hyperbola and parabola

[`kiepert_hyperbola`](@ref) is the unique rectangular hyperbola through
`t`'s 3 vertices, its centroid and its orthocenter (built directly via
[`conic_through_points`](@ref) on those 5 points); [`kiepert_parabola`](@ref)
has focus Kimberling center X(110) and directrix the [`euler_line`](@ref)
(undefined for an isosceles triangle, where X(110) doesn't exist):

```@example geo
kiepert_hyperbola(t) isa APHyperbola2
kiepert_parabola(t) isa APParabola2
```

```@raw html
<img src="../assets/img/triangles/kiepert.svg" alt="The Kiepert hyperbola through the vertices, the centroid and the orthocenter" style="width:100%; max-width: 700px;">
```
