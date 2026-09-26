```@meta
CurrentModule = Apollonius
```

# Euclid's Elements, Book I

Euclid's first book builds the geometry of the plane from three tools: a
straightedge that draws the line through two points, a compass that draws a
circle with a given center through a given point, and the eye that sees where
two of these cross. This tutorial does the same constructions with Apollonius,
using nothing else. Each proposition is built step by step, checked with a
number, and drawn with the compass traces that make the steps visible.

It is a good way to learn the package, because the whole vocabulary fits in a
table:

| Euclid | Apollonius |
|:-------|:-----------|
| Join two points by a straight line | [`APSegment`](@ref)`(a, b)`, [`APLine`](@ref)`(a, b)` |
| Extend a line without limit | [`APRay`](@ref)`(a, b)`, or the [`APLine`](@ref) |
| Draw a circle with a center and radius | [`APCircle2`](@ref)`(center, r)` |
| See where two figures cross | [`intersection`](@ref)`(a, b)` |
| Equal things | `≈` on lengths and angles |

`intersection` returns a `Vector`, because two figures can cross in several
points, and the order is only fixed in two cases (see
[Choosing among the intersections](@ref)). Where Euclid says "either of the
points", we take the first. Where he needs a particular one, we pick it by where
it is.

Three helpers keep the code short. `circ(c, p)` is the postulate of the
compass: the circle centered at `c` through `p`. `far(points, from)` picks the
point farthest from a reference, and `equilateral(a, b)` is proposition I.1:

```@example geo
using Apollonius

circ(center, through) = APCircle2(center, distance(center, through))
far(points, from) = argmax(p -> distance(p, from), points)
equilateral(a, b; left=true) = (pts = intersection(circ(a, b), circ(b, a)); left ? first(pts) : last(pts))
```

## I.1: an equilateral triangle on a given segment

Draw the circle centered at `A` through `B`, and the circle centered at `B`
through `A`. They cross at two points, above and below the segment, and either
is the third vertex. The first point returned is the one on the left as you go
from `A` to `B`. Its figure is on the page
[Compass & Ruler Constructions](@ref).

```@example geo
A, B = APPoint(0.0, 0.0), APPoint(6.0, 0.0)
C = equilateral(A, B)
distance(A, C) ≈ distance(A, B) ≈ distance(B, C)
```

## I.2: place a segment equal to a given one at a given point

Given a point `A` and a segment `BC`, find `L` such that `AL` equals `BC`.
The compass cannot be carried from place to place, so Euclid goes around it.

1. Build the equilateral triangle `ABD` on `AB` (I.1).
2. Extend `DB` beyond `B`, and draw the circle centered at `B` through `C`.
   Where it meets the extension is `G`, and `BG = BC`.
3. Draw the circle centered at `D` through `G`. Where it meets the extension of
   `DA` beyond `A` is `L`. Then `DL = DG`, and taking away `DA = DB` from both
   leaves `AL = BG = BC`.

```@example geo
A, B, C = APPoint(1.0, 4.0), APPoint(6.0, 1.0), APPoint(9.0, 3.0)
D = equilateral(A, B)
G = far(intersection(APRay(D, B), circ(B, C)), D)
L = only(intersection(APRay(D, A), circ(D, G)))
distance(A, L) ≈ distance(B, C)
```

The ray `APRay(D, B)` meets the circle at two points, one on each side of `B`,
and the farther from `D` is the one beyond `B`. The ray from `D` through `A`
meets the circle around `D` at a single point, which is `L`.

```@raw html
<img src="../assets/img/euclid/i2.svg" alt="The segment BC, the equilateral triangle ABD, and the segment AL equal to BC found with two compass arcs" style="width:100%; max-width: 700px;">
```

!!! details "See script"
    ```julia
    using Apollonius, Luxor
    import Luxor: julia_red, julia_blue, julia_green, julia_purple
    import Apollonius: rotate, translate, distance, midpoint

    circ(center, through) = APCircle2(center, distance(center, through))
    far(points, from) = argmax(p -> distance(p, from), points)
    equilateral(A, B; left=true) = (pts = intersection(circ(A, B), circ(B, A)); left ? first(pts) : last(pts))
    function bisect(V, P, Q)
        r = min(distance(V, P), distance(V, Q)) / 2
        D = only(intersection(APCircle2(V, r), APSegment(V, P)))
        E = only(intersection(APCircle2(V, r), APSegment(V, Q)))
        F = far(intersection(circ(D, E), circ(E, D)), V)
        return APLine(V, F)
    end
    lxm = @prepare_to_picture! width=500 height=320 margin=30 begin  
        A, B, C = APPoint(1.0, 4.0), APPoint(6.0, 1.0), APPoint(9.0, 3.0)
        D = equilateral(A, B)
        G = far(intersection(APRay(D, B), circ(B, C)), D)
        L = only(intersection(APRay(D, A), circ(D, G)))
        BC = APSegment(B, C); AL = APSegment(A, L)
        aids = [APSegment(D, G), APSegment(D, L), APSegment(A, D), APSegment(D, B), APSegment(A, B)]
        traces = [compass_trace(B, G; angle=pi / 5), compass_trace(D, L; angle=pi / 6)]
    end


    begin
    Drawing(lxm.width, lxm.height, :svg)
    origin(); fontsize(15)

    gsave()
    setline(1); setdash("dash")
    sethue(julia_green)
    path(aids, action=:stroke)
    setdash("solid")
    path(traces, action=:stroke)
    grestore()
    sethue(julia_blue)
    path(BC, action=:stroke)
    sethue(julia_green)
    sethue(julia_purple)
    path(AL, action=:stroke)
    sethue(julia_red)
    label("A", :NW, A); label("B", :S, B); label("C", :E, C); label("D", :N, D); label("G", :S, G); label("L", :W, L)
    sethue("white"); path([A, B, C], action=:fillpreserve); sethue(julia_blue); strokepath()
    sethue("white"); path([D, G], action=:fillpreserve); sethue(julia_green); strokepath()
    sethue("white"); path([L], action=:fillpreserve); sethue(julia_purple); strokepath()

    finish()
    preview()
    end
    ```

## I.3: cut off a segment equal to a shorter one

From the longer segment `AB`, cut off a piece equal to `CD`. This is one step of
the previous proposition, and every construction below uses it: the circle
centered at `A` through the length `CD` meets `AB` at `E`.

```@example geo
A, B = APPoint(0.0, 0.0), APPoint(9.0, 0.0)
C, D = APPoint(1.0, 3.0), APPoint(4.0, 4.0)
E = only(intersection(APCircle2(A, distance(C, D)), APSegment(A, B)))
distance(A, E) ≈ distance(C, D)
```

## I.9: bisect an angle

Take any point `D` on one side of the angle, and the point `E` on the other
side at the same distance from the vertex (I.3). Build an equilateral triangle
`DEF` on the side of `DE` away from the vertex (I.1). Then `AF` bisects the angle,
because the triangles `ADF` and `AEF` have three equal sides.

```@example geo
function bisect(V, P, Q)
    r = min(distance(V, P), distance(V, Q)) / 2
    D = only(intersection(APCircle2(V, r), APSegment(V, P)))
    E = only(intersection(APCircle2(V, r), APSegment(V, Q)))
    F = far(intersection(circ(D, E), circ(E, D)), V)
    return APLine(V, F)
end

A, B, C = APPoint(0.0, 0.0), APPoint(7.0, 1.0), APPoint(2.0, 6.0)
F = bisect(A, B, C).p2
angle_measure_at(A, B, F) ≈ angle_measure_at(A, F, C)
```

`far(..., V)` picks the apex of the equilateral triangle that lies away from the
vertex. This function is reused in the rest of the page.

```@raw html
<img src="../assets/img/euclid/i9.svg" alt="An angle at A with points D and E at the same distance, the equilateral triangle DEF and the bisector AF" style="width:100%; max-width: 700px;">
```

!!! details "See script"
    ```julia
    using Apollonius, Luxor
    import Luxor: julia_red, julia_blue, julia_green, julia_purple
    import Apollonius: rotate, translate, distance, midpoint

    circ(center, through) = APCircle2(center, distance(center, through))
    far(points, from) = argmax(p -> distance(p, from), points)
    equilateral(A, B; left=true) = (pts = intersection(circ(A, B), circ(B, A)); left ? first(pts) : last(pts))
    function bisect(V, P, Q)
        r = min(distance(V, P), distance(V, Q)) / 2
        D = only(intersection(APCircle2(V, r), APSegment(V, P)))
        E = only(intersection(APCircle2(V, r), APSegment(V, Q)))
        F = far(intersection(circ(D, E), circ(E, D)), V)
        return APLine(V, F)
    end
    lxm = @prepare_to_picture! width=500 height=320 margin=30 begin  
        A, B, C = APPoint(0.0, 0.0), APPoint(7.0, 1.0), APPoint(2.0, 6.0)
        r = min(distance(A, B), distance(A, C)) / 2
        D = only(intersection(APCircle2(A, r), APSegment(A, B)))
        E = only(intersection(APCircle2(A, r), APSegment(A, C)))
        F = far(intersection(circ(D, E), circ(E, D)), A)
        rays = [APSegment(A, B), APSegment(A, C)]
        bis = APSegment(A, F)
        aids = [APSegment(D, E), APSegment(D, F), APSegment(E, F)]
        traces = [APCircularArc2(circ(A, D), D, E), compass_trace(D, F; angle=pi / 6), compass_trace(E, F; angle=pi / 6)]
    end


    begin
    Drawing(lxm.width, lxm.height, :svg)
    origin(); fontsize(15)

    gsave()
    setline(1); setdash("dash")
    sethue(julia_green)
    path(aids, action=:stroke)
    setdash("solid")
    path(traces, action=:stroke)
    grestore()
    sethue(julia_blue)
    path(rays, action=:stroke)
    sethue(julia_green)
    sethue(julia_purple)
    path(bis, action=:stroke)
    sethue(julia_red)
    label("A", :SW, A); label("B", :E, B); label("C", :N, C); label("D", :S, D); label("E", :W, E); label("F", :N, F)
    sethue("white"); path([A, B, C], action=:fillpreserve); sethue(julia_blue); strokepath()
    sethue("white"); path([D, E, F], action=:fillpreserve); sethue(julia_green); strokepath()

    finish()
    preview()
    end
    ```

The package has this as [`angle_bisectors`](@ref), and as
[`bisector_construction`](@ref) when you want the traces.

## I.10: bisect a segment

Build an equilateral triangle `ABC` on the segment (I.1) and bisect its angle at
`C` (I.9). The bisector meets `AB` at its midpoint.

```@example geo
A, B = APPoint(0.0, 0.0), APPoint(6.0, 2.0)
C = equilateral(A, B)
M = only(intersection(bisect(C, A, B), APSegment(A, B)))
M ≈ midpoint(A, B)
```

```@raw html
<img src="../assets/img/euclid/i10.svg" alt="A segment AB, the equilateral triangle ABC on it and the bisector CM meeting AB at its midpoint M" style="width:100%; max-width: 700px;">
```

!!! details "See script"
    ```julia
    using Apollonius, Luxor
    import Luxor: julia_red, julia_blue, julia_green, julia_purple
    import Apollonius: rotate, translate, distance, midpoint

    circ(center, through) = APCircle2(center, distance(center, through))
    far(points, from) = argmax(p -> distance(p, from), points)
    equilateral(A, B; left=true) = (pts = intersection(circ(A, B), circ(B, A)); left ? first(pts) : last(pts))
    function bisect(V, P, Q)
        r = min(distance(V, P), distance(V, Q)) / 2
        D = only(intersection(APCircle2(V, r), APSegment(V, P)))
        E = only(intersection(APCircle2(V, r), APSegment(V, Q)))
        F = far(intersection(circ(D, E), circ(E, D)), V)
        return APLine(V, F)
    end
    lxm = @prepare_to_picture! width=500 height=300 margin=30 begin  
        A, B = APPoint(0.0, 0.0), APPoint(6.0, 2.0)
        C = equilateral(A, B)
        M = only(intersection(bisect(C, A, B), APSegment(A, B)))
        AB = APSegment(A, B)
        aids = [APSegment(A, C), APSegment(B, C)]
        traces = [compass_trace(A, C; angle=pi / 6), compass_trace(B, C; angle=pi / 6)]
        cm = APSegment(C, M)
    end


    begin
    Drawing(lxm.width, lxm.height, :svg)
    origin(); fontsize(15)

    gsave()
    setline(1); setdash("dash")
    sethue(julia_green)
    path(aids, action=:stroke)
    setdash("solid")
    path(traces, action=:stroke)
    grestore()
    sethue(julia_blue)
    path(AB, action=:stroke)
    sethue(julia_green)
    sethue(julia_purple)
    path(cm, action=:stroke)
    sethue(julia_red)
    label("A", :SW, A); label("B", :SE, B); label("C", :N, C); label("M", :S, M)
    sethue("white"); path([A, B], action=:fillpreserve); sethue(julia_blue); strokepath()
    sethue("white"); path([C], action=:fillpreserve); sethue(julia_green); strokepath()
    sethue("white"); path([M], action=:fillpreserve); sethue(julia_purple); strokepath()

    finish()
    preview()
    end
    ```

## I.11: a perpendicular to a line at a point on it

Mark `D` and `E` on the line on each side of `C` at the same distance (I.3).
Build the equilateral triangle `DEF` (I.1). Then `CF` is perpendicular to the
line, because `C` is the midpoint of `DE` and `F` is equally far from `D` and
`E`.

```@example geo
A, B, C = APPoint(0.0, 0.0), APPoint(8.0, 0.0), APPoint(3.0, 0.0)
D, E = intersection(APCircle2(C, 2.0), APLine(A, B))
F = equilateral(D, E)
is_perpendicular(APLine(C, F), APLine(A, B))
```

```@raw html
<img src="../assets/img/euclid/i11.svg" alt="A line with a point C, the points D and E on either side, the equilateral triangle DEF and the perpendicular CF" style="width:100%; max-width: 700px;">
```

!!! details "See script"
    ```julia
    using Apollonius, Luxor
    import Luxor: julia_red, julia_blue, julia_green, julia_purple
    import Apollonius: rotate, translate, distance, midpoint

    circ(center, through) = APCircle2(center, distance(center, through))
    far(points, from) = argmax(p -> distance(p, from), points)
    equilateral(A, B; left=true) = (pts = intersection(circ(A, B), circ(B, A)); left ? first(pts) : last(pts))
    function bisect(V, P, Q)
        r = min(distance(V, P), distance(V, Q)) / 2
        D = only(intersection(APCircle2(V, r), APSegment(V, P)))
        E = only(intersection(APCircle2(V, r), APSegment(V, Q)))
        F = far(intersection(circ(D, E), circ(E, D)), V)
        return APLine(V, F)
    end
    lxm = @prepare_to_picture! width=500 height=300 margin=30 begin  
        A, B, C = APPoint(0.0, 0.0), APPoint(8.0, 0.0), APPoint(3.0, 0.0)
        D, E = intersection(APCircle2(C, 2.0), APLine(A, B))
        F = equilateral(D, E)
        AB = APSegment(A, B)
        aids = [APSegment(D, F), APSegment(E, F)]
        traces = [compass_trace(C, D; angle=pi / 4), compass_trace(C, E; angle=pi / 4), compass_trace(D, F; angle=pi / 6), compass_trace(E, F; angle=pi / 6)]
        cf = APSegment(C, F)
    end


    begin
    Drawing(lxm.width, lxm.height, :svg)
    origin(); fontsize(15)

    gsave()
    setline(1); setdash("dash")
    sethue(julia_green)
    path(aids, action=:stroke)
    setdash("solid")
    path(traces, action=:stroke)
    grestore()
    sethue(julia_blue)
    path(AB, action=:stroke)
    sethue(julia_green)
    sethue(julia_purple)
    path(cf, action=:stroke)
    sethue(julia_red)
    label("A", :SW, A); label("B", :SE, B); label("C", :S, C); label("D", :S, D); label("E", :S, E); label("F", :N, F)
    sethue("white"); path([A, B, C], action=:fillpreserve); sethue(julia_blue); strokepath()
    sethue("white"); path([D, E, F], action=:fillpreserve); sethue(julia_green); strokepath()

    finish()
    preview()
    end
    ```

## I.12: a perpendicular to a line from a point not on it

Take a point `D` on the other side of the line from `C`. The circle centered at
`C` through `D` meets the line at `E` and `G`. Bisect `EG` at `H` (I.10). Then
`CH` is perpendicular to the line.

```@example geo
A, B, C, D = APPoint(-3.0, 0.0), APPoint(9.0, 0.0), APPoint(3.0, 4.0), APPoint(5.0, -2.0)
E, G = intersection(circ(C, D), APLine(A, B))
K = equilateral(E, G)
H = only(intersection(bisect(K, E, G), APSegment(E, G)))
is_perpendicular(APLine(C, H), APLine(A, B)), H ≈ projection(C, APLine(A, B))
```

The second test compares with [`projection`](@ref), the function that finds the
same foot directly.

```@raw html
<img src="../assets/img/euclid/i12.svg" alt="A line, a point C above it, the circle around C that cuts the line at E and G, and the perpendicular CH" style="width:100%; max-width: 700px;">
```

!!! details "See script"
    ```julia
    using Apollonius, Luxor
    import Luxor: julia_red, julia_blue, julia_green, julia_purple
    import Apollonius: rotate, translate, distance, midpoint

    circ(center, through) = APCircle2(center, distance(center, through))
    far(points, from) = argmax(p -> distance(p, from), points)
    equilateral(A, B; left=true) = (pts = intersection(circ(A, B), circ(B, A)); left ? first(pts) : last(pts))
    function bisect(V, P, Q)
        r = min(distance(V, P), distance(V, Q)) / 2
        D = only(intersection(APCircle2(V, r), APSegment(V, P)))
        E = only(intersection(APCircle2(V, r), APSegment(V, Q)))
        F = far(intersection(circ(D, E), circ(E, D)), V)
        return APLine(V, F)
    end
    lxm = @prepare_to_picture! width=500 height=320 margin=30 begin  
        A, B, C, D = APPoint(-3.0, 0.0), APPoint(9.0, 0.0), APPoint(3.0, 4.0), APPoint(5.0, -2.0)
        E, G = intersection(circ(C, D), APLine(A, B))
        K = equilateral(E, G)
        H = only(intersection(bisect(K, E, G), APSegment(E, G)))
        AB = APSegment(A, B)
        aids = [APSegment(E, K), APSegment(G, K)]
        traces = [compass_trace(C, D; angle=pi / 3), compass_trace(C, E; angle=pi / 8), compass_trace(C, G; angle=pi / 8), compass_trace(E, K; angle=pi / 6), compass_trace(G, K; angle=pi / 6)]
        ch = APSegment(C, H)
    end


    begin
    Drawing(lxm.width, lxm.height, :svg)
    origin(); fontsize(15)

    gsave()
    setline(1); setdash("dash")
    sethue(julia_green)
    path(aids, action=:stroke)
    setdash("solid")
    path(traces, action=:stroke)
    grestore()
    sethue(julia_blue)
    path(AB, action=:stroke)
    sethue(julia_green)
    sethue(julia_purple)
    path(ch, action=:stroke)
    sethue(julia_red)
    label("C", :N, C); label("D", :S, D); label("E", :SW, E); label("G", :SE, G); label("H", :SE, H); label("K", :S, K)
    sethue("white"); path([A, B, C, D], action=:fillpreserve); sethue(julia_blue); strokepath()
    sethue("white"); path([E, G, K], action=:fillpreserve); sethue(julia_green); strokepath()
    sethue("white"); path([H], action=:fillpreserve); sethue(julia_purple); strokepath()

    finish()
    preview()
    end
    ```

## I.23: copy an angle onto a line at a point

Given the angle `BAC`, and a ray `DE`, build at `D` an angle equal to it. Mark
`X` on `AB` and `Y` on `AC`, and build the triangle `DE'F` with the three sides
of `AXY` (I.22): `DE' = AX` on the ray, `DF = AY`, and `E'F = XY`. The two
triangles are equal, so the angle at `D` equals the angle at `A`.

```@example geo
A, B, C = APPoint(0.0, 0.0), APPoint(6.0, 1.0), APPoint(2.0, 5.0)
D, E = APPoint(10.0, 0.0), APPoint(16.0, -1.0)
X, Y = A + 0.6 * (B - A), A + 0.6 * (C - A)
E2 = only(intersection(APCircle2(D, distance(A, X)), APRay(D, E)))
F = first(intersection(APCircle2(D, distance(A, Y)), APCircle2(E2, distance(X, Y))))
angle_measure_at(D, E2, F) ≈ angle_measure_at(A, B, C)
```

`first` picks the point on the left of the ray, which is the same side as `AC` is
of `AB`, so the copy has the same orientation.

```@raw html
<img src="../assets/img/euclid/i23.svg" alt="An angle BAC and a ray DE, and the angle at D copied onto the ray with the compass" style="width:100%; max-width: 700px;">
```

!!! details "See script"
    ```julia
    using Apollonius, Luxor
    import Luxor: julia_red, julia_blue, julia_green, julia_purple
    import Apollonius: rotate, translate, distance, midpoint

    circ(center, through) = APCircle2(center, distance(center, through))
    far(points, from) = argmax(p -> distance(p, from), points)
    equilateral(A, B; left=true) = (pts = intersection(circ(A, B), circ(B, A)); left ? first(pts) : last(pts))
    function bisect(V, P, Q)
        r = min(distance(V, P), distance(V, Q)) / 2
        D = only(intersection(APCircle2(V, r), APSegment(V, P)))
        E = only(intersection(APCircle2(V, r), APSegment(V, Q)))
        F = far(intersection(circ(D, E), circ(E, D)), V)
        return APLine(V, F)
    end
    lxm = @prepare_to_picture! width=560 height=300 margin=30 begin  
        A, B, C = APPoint(0.0, 0.0), APPoint(6.0, 1.0), APPoint(2.0, 5.0)
        D, E = APPoint(10.0, 0.0), APPoint(16.0, -1.0)
        X, Y = A + 0.6 * (B - A), A + 0.6 * (C - A)
        E2 = only(intersection(APCircle2(D, distance(A, X)), APRay(D, E)))
        F = first(intersection(APCircle2(D, distance(A, Y)), APCircle2(E2, distance(X, Y))))
        given = [APSegment(A, B), APSegment(A, C), APSegment(D, E)]
        aids = [APSegment(X, Y), APSegment(E2, F)]
        traces = [compass_trace(D, E2; angle=pi / 6), compass_trace(D, F; angle=pi / 6), compass_trace(E2, F; angle=pi / 6)]
        dup = APSegment(D, F)
        angs = [APAngle2(A, B, C), APAngle2(D, E2, F)]
    end


    begin
    Drawing(lxm.width, lxm.height, :svg)
    origin(); fontsize(15)

    gsave()
    setline(1); setdash("dash")
    sethue(julia_green)
    path(aids, action=:stroke)
    setdash("solid")
    path(traces, action=:stroke)
    grestore()
    sethue(julia_blue)
    path(given, action=:stroke)
    sethue(julia_green)
    sethue(julia_purple)
    path(dup, action=:stroke)
    path(marks(angs[1]; size=40); action=:stroke)
    path(marks(angs[2]; size=40); action=:stroke)
    sethue(julia_red)
    label("A", :SW, A); label("B", :E, B); label("C", :N, C); label("D", :SW, D); label("E", :E, E); label("F", :N, F)
    sethue("white"); path([A, B, C, D, E], action=:fillpreserve); sethue(julia_blue); strokepath()
    sethue("white"); path([X, Y, E2], action=:fillpreserve); sethue(julia_green); strokepath()
    sethue("white"); path([F], action=:fillpreserve); sethue(julia_purple); strokepath()

    finish()
    preview()
    end
    ```

## I.47: the theorem of Pythagoras

In a right triangle, the square on the side opposite the right angle equals the
sum of the squares on the other two. [`square_on_segment`](@ref) builds the
square on a segment, and `ccw=false` puts it on the outside of a triangle
listed counterclockwise.

```@example geo
A, B, C = APPoint(0.0, 0.0), APPoint(4.0, 0.0), APPoint(0.0, 3.0)
sq(p, q) = square_on_segment(p, q; ccw=false)
area(sq(A, B)), area(sq(C, A)), area(sq(B, C)), area(sq(A, B)) + area(sq(C, A)) ≈ area(sq(B, C))
```

```@raw html
<img src="../assets/img/euclid/i47.svg" alt="A right triangle with the three squares on its sides, with areas 16, 9 and 25" style="width:100%; max-width: 700px;">
```

!!! details "See script"
    ```julia
    using Apollonius, Luxor
    import Luxor: julia_red, julia_blue, julia_green, julia_purple
    import Apollonius: rotate, translate, distance, midpoint

    lxm = @prepare_to_picture! width=520 height=360 margin=30 begin  
        A, B, C = APPoint(0.0, 0.0), APPoint(4.0, 0.0), APPoint(0.0, 3.0)
        t = APTriangle(A, B, C)
        sqs = [square_on_segment(A, B; ccw=false), square_on_segment(B, C; ccw=false), square_on_segment(C, A; ccw=false)]
        labs = [centroid(s) for s in sqs]
    end


    begin
    Drawing(lxm.width, lxm.height, :svg)
    origin(); fontsize(15)

    sethue(julia_blue)
    path(t, action=:stroke)
    sethue(julia_purple)
    path(sqs, action=:stroke)
    sethue(julia_red)
    for (n, p) in zip(("16", "25", "9"), labs)
        Luxor.text(n, Luxor.Point(p[1], p[2]); halign=:center, valign=:middle)
    end

    finish()
    preview()
    end
    ```

## The shorter way

The constructions above use the compass and nothing more, which is the point of
the exercise. When you only want the result, the package has it directly:

| Proposition | Result | Direct call |
|:------------|:-------|:------------|
| I.1 | equilateral triangle on a segment | [`equilateral_triangle_on_segment`](@ref) |
| I.9 | angle bisector | [`angle_bisectors`](@ref) |
| I.10 | midpoint, perpendicular bisector | [`midpoint`](@ref), [`perpendicular_bisector`](@ref) |
| I.11, I.12 | perpendicular through a point | [`perpendicular_through`](@ref) |
| I.12 | foot of the perpendicular | [`projection`](@ref) |
| I.31 | parallel through a point | [`parallel_through`](@ref) |

And when you want the compass traces in the figure, the *shown* versions
([`mediator_construction`](@ref), [`perpendicular_construction`](@ref),
[`parallel_construction`](@ref), [`bisector_construction`](@ref)) return them
with the result. They are on the page
[Compass & Ruler Constructions](@ref).

## Drawing the compass traces

The green arcs in the figures are made with [`compass_trace`](@ref)`(center, p; angle)`:
the arc of the circle centered at `center` that passes through `p`, with `p` in
its middle. For instance, the two arcs that cross at `F` in I.9 are
`compass_trace(D, F; angle=pi / 6)` and `compass_trace(E, F; angle=pi / 6)`.
The colors are the ones used all through the manual: blue for what is given,
green for the construction, purple for the result.
