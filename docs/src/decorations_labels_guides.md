```@meta
CurrentModule = Apollonius
```

# Decorations: Labels, Guides & Grids

The segment from [Marks, Labels & Decorations](@ref):

```@example geo
using Apollonius

s = APSegment(APPoint(0.0, 0.0), APPoint(10.0, 0.0))
nothing # hide
```

## Labels: `label_anchor`

Luxor places text with `label(text, alignment, point)`, where `alignment` is
a compass symbol such as `:N` or `:SE`. [`label_anchor`](@ref) picks both
the point and the alignment for you, so the text sits on the outside:

| Call | Anchor |
|:-----|:-------|
| `label_anchor(obj, t; side=:left)` | on a segment or arc at parameter `t`, on the left or right of the direction of travel |
| `label_anchor(ang; dist=nothing)` | on an angle's bisector, `dist` from the vertex (default `0.25 ×` the shorter ray), pointing away from the vertex |
| `label_anchor(circle, θ)` | on the circle at polar angle `θ`, outward |
| `label_anchor(p, from)` | at the point `p`, pointing away from the point `from`; use the centroid as `from` to keep vertex labels outside a figure |

The result is a `NamedTuple` `(alignment, point)` in the argument order of
Luxor's `label`. A brace's own label point is [`vertices`](@ref)`(dec)[2]`
instead: see [`APDecorationBrace2`](@ref) in
[Decorations: Arrowheads & Braces](@ref).

```@example geo
label_anchor(s), label_anchor(s; side=:right)
```

A horizontal segment going from left to right has its `:left` side on top
on screen, so the first is `:N` and the second `:S`. To label the vertices
of a triangle so none falls inside it, pass the centroid:

```@example geo
t = APTriangle(APPoint(0.0, 0.0), APPoint(8.0, 0.0), APPoint(3.0, 6.0))
[label_anchor(v, centroid(t)).alignment for v in vertices(t)]
```

```@raw html
<img src="../assets/img/decorations/label_anchor.svg" alt="A triangle with vertex, side and angle labels placed outside" style="width:100%; max-width: 700px;">
```

!!! details "See script"
    ```julia
    using Apollonius, Luxor
    import Luxor: julia_red, julia_blue, julia_green, julia_purple

    lxm = @prepare_to_picture! width=500 height=240 margin=20 begin  
        A, B, C = APPoint(0.0, 0.0), APPoint(8.0, 0.0), APPoint(3.0, 6.0)
        t = APTriangle(A, B, C)
        sides = [APSegment(A, B), APSegment(B, C), APSegment(C, A)]
        ang = APAngle2(A, B, C)
    end

    G = centroid(t)

    begin
    Drawing(lxm.width, lxm.height, :svg)
    origin(); fontsize(15)

    sethue(julia_blue)
    path(t, action=:stroke)

    sethue(julia_purple)
    path(marks(ang; count=1, size=40); action=:stroke)

    sethue(julia_red)
    for (v, n) in zip(vertices(t), ("A", "B", "C"))
        label(n, label_anchor(v, G)...)
    end
    for (s, n) in zip(sides, ("c", "a", "b"))
        label(n, label_anchor(s; side=:right)...)
    end

    label("α", label_anchor(ang; dist=20)...)

    finish()
    preview()
    end
    ```

!!! warning "Compass directions and sides are read as drawn"
    `:N` is above the point and `:left` is the left of the direction of travel as seen on the screen, with `y` growing downward. Call [`label_anchor`](@ref) and [`APDecorationBrace2`](@ref) on the fitted objects. On coordinates with `y` upward the same call gives the mirrored answer.

## Guides and grids

[`coordinate_guides`](@ref)`(p)` returns the two segments from `p` to the
axes, the ones drawn dotted to show a point's coordinates. A guide of length
zero is left out, so a point on an axis gets one segment and the origin
none. Pass `origin` to measure against other axes.

```@example geo
coordinate_guides(APPoint(3.0, 4.0))
```

[`grid_lines`](@ref)`(bb; step)` returns the lines of a grid over an
[`APBoundingBox`](@ref), vertical lines first. The grid is anchored at the
origin: its lines are at whole multiples of the step, not measured from the
corner of the box. `xstep` and `ystep` set the two directions apart, and a
finer subgrid is a second call with a smaller `step`. [`axes_lines`](@ref)
returns the axes that cross the box.

```@example geo
bb = APBoundingBox(APPoint(-2.0, -1.0), APPoint(3.0, 2.0))
length(grid_lines(bb)), length(grid_lines(bb; step=0.5)), length(axes_lines(bb))
```

```@raw html
<img src="../assets/img/decorations/guides_grid.svg" alt="A grid, the axes and dotted coordinate guides for a point" style="width:100%; max-width: 700px;">
```

!!! details "See script"
    ```julia
    using Apollonius, Luxor
    import Luxor: julia_red, julia_blue, julia_green, julia_purple

    lxm = @prepare_to_picture! width=500 height=240 margin=20 begin  
        grid = grid_lines(APBoundingBox(APPoint(-1.0, -1.0), APPoint(7.0, 5.0)); step=1.0)
        axes = axes_lines(APBoundingBox(APPoint(-1.0, -1.0), APPoint(7.0, 5.0)))
        P = APPoint(4.0, 3.0)
        guides = coordinate_guides(P)
    end


    begin
    Drawing(lxm.width, lxm.height, :svg)
    origin(); fontsize(15)

    @layer begin
    setline(1); sethue("gray80")
    path(grid, action=:stroke)
    end

    sethue(julia_blue)
    path(axes, action=:stroke)

    @layer begin
    setline(5); setdash("dot"); sethue(julia_purple)
    path(guides, action=:stroke)
    end

    sethue(julia_red)
    label("P", :NE, P)

    sethue("white")
    path(P, action=:fillpreserve)
    sethue(julia_blue); strokepath()

    finish()
    preview()
    end
    ```

!!! warning "The grid is anchored at the origin of the coordinates it receives"
    [`grid_lines`](@ref) puts its lines at whole multiples of the step, measured from the origin of the box you give it. Build the grid inside the block that is fitted, in your own coordinates, so the lines fall where the axes are. From an already fitted box, the multiples are in drawing units.

## Lengthening a line: `extend_line`

[`extend_line`](@ref)`(l, before, after)` lengthens the line through
`l.p1` and `l.p2` by fractions of `distance(l.p1, l.p2)` past each point,
and returns the resulting [`APSegment`](@ref). It is the relative
counterpart of the absolute `extend` of `path`: `0.2` adds a fifth of the
length at each end, whatever the length is. A negative fraction shortens
that end.

```@example geo
l = APLine(APPoint(0.0, 0.0), APPoint(10.0, 0.0))
extend_line(l, 0.2), extend_line(l, 0.0, -0.3)
```

```@raw html
<img src="../assets/img/decorations/extend_line.svg" alt="A segment lengthened at both ends and another shortened at one end" style="width:100%; max-width: 700px;">
```

## Drawing all of it

The decorations are ordinary objects, so `path` takes them directly, alone
or in a `Vector`. This is the usual pattern, on objects already returned by
[`@prepare_to_picture`](@ref):

```julia
using Apollonius, Luxor

lxm, lxo = @prepare_to_picture width=400.0 margin=30.0 begin
    seg = APSegment(APPoint(0.0, 0.0), APPoint(10.0, 0.0))
    ang = APAngle2(APPoint(0.0, 0.0), APPoint(10.0, 0.0), APPoint(4.0, 6.0))
end
(; seg, ang) = lxo

@svg begin
    path(seg; action=:stroke)
    path(marks(seg; count=2); action=:stroke)          # two ticks in the middle
    path(marks(ang; count=2); action=:stroke)          # two arcs on the angle
    path(arrow_head(seg; at=0.3); action=:fill)        # an arrow a third of the way
    dec = APDecorationBrace2(seg.p1, seg.p2)
    path(dec; action=:stroke)
    label("10", :N, vertices(dec)[2])
end lxm.width lxm.height
```

Put together, the pieces make a figure like this one: an isosceles triangle with equal-side marks, arcs on the equal angles, an arrow on the base and a brace with its label. The script is `docs/illustrations/decorations/full_figure.jl`.

```@raw html
<img src="../assets/img/decorations/full_figure.svg" alt="An isosceles triangle with marks, an arrow, a brace and labels" style="width:100%; max-width: 700px;">
```

!!! details "See script"
    ```julia
    using Apollonius, Luxor
    import Luxor: julia_red, julia_blue, julia_green, julia_purple

    lxm = @prepare_to_picture! width=500 height=240 margin=30 begin  
        A, B, C = APPoint(0.0, 0.0), APPoint(10.0, 0.0), APPoint(5.0, 6.0)
        t = APTriangle(A, B, C)
        base, right, left = sides(t)
        angA = APAngle2(A, B, C)
        angB = APAngle2(B, C, A)
        G = centroid(t)
    end



    begin
    Drawing(lxm.width, lxm.height, :svg)
    origin(); fontsize(15)

    sethue(julia_blue)
    path(t, action=:stroke)

    sethue(julia_purple)
    path(marks(left; size=14); action=:stroke)
    path(marks(right; size=14); action=:stroke)
    path(marks(angA; count=2, size=34, gap=6); action=:stroke)
    path(marks(angB; count=2, size=34, gap=6); action=:stroke)
    path(arrow_head(base; at=0.2, size=12); action=:fill)
    baseBrace = APDecorationBrace2(base.p1, base.p2; height=12, side=:right)
    path(baseBrace; action=:stroke)

    sethue(julia_red)
    label("b", :S, vertices(baseBrace)[2])
    for (v, n) in zip(vertices(t), ("A", "B", "C"))
        label(n, label_anchor(v, G)...)
    end

    finish()
    preview()
    end
    ```


The `label` method for `APPoint`s and the `dimension` and `tickline`
wrappers come with the Luxor extension; see [Drawing with Luxor.jl](@ref).
