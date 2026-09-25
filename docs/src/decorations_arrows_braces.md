```@meta
CurrentModule = Apollonius
```

# Decorations: Arrowheads & Braces

The arc from [Marks, Labels & Decorations](@ref):

```@example geo
using Apollonius

circ = APCircle2(APPoint(0.0, 0.0), 5.0)
arc = APCircularArc2(circ, APPoint(5.0, 0.0), APPoint(0.0, 5.0))
nothing # hide
```

## Arrowheads: `arrow_head`

`path(segment; as=:arrow)` puts an arrowhead at the end of a segment, and
`as=:doublearrow` at both ends, and nowhere else. [`arrow_head`](@ref) places one anywhere on a segment, a line,
a ray or an arc, as a shape you draw yourself.

| Keyword | Default | Meaning |
|:--------|:--------|:--------|
| `at` | `0.5` | where along `obj` |
| `size` | `10.0` | length of each side arm |
| `angle` | `π/8` | half the opening angle |
| `place` | `:center` | `:center` puts the head's middle on the point, `:tip` puts its tip there |
| `style` | `:triangle` | see below |

| `style` | Head | Returns | Draw with |
|:--------|:-----|:--------|:----------|
| `:triangle` | a filled triangle | [`APTriangle`](@ref) | `action=:fill` |
| `:stealth` | a triangle with a notch in the back | [`APStraightNgon`](@ref) | `action=:fill` |
| `:open` | two arms, a `>` | [`APPolyline2`](@ref) | `action=:stroke` |

Use `place=:center` for an arrow in the middle of a line, and `place=:tip`
with `at=1.0` for an arrow at the end of an arc:

```@example geo
head = arrow_head(arc; at=1.0, place=:tip)
isapprox(head[1], arc.p2; atol=1e-9)
```

```@raw html
<img src="../assets/img/decorations/arrow_heads.svg" alt="The three arrowhead styles on segments, and a tip arrow on an arc" style="width:100%; max-width: 700px;">
```

!!! details "See script"
    ```julia
    using Apollonius, Luxor
    import Luxor: julia_red, julia_blue, julia_green, julia_purple

    lxm = @prepare_to_picture! width=500 height=240 margin=20 begin  
        segs = [APSegment(APPoint(0.0, 2.0 * (3 - i)), APPoint(7.0, 2.0 * (3 - i))) for i in 1:3]
        names = [APPoint(-2.5, 2.0 * (3 - i)) for i in 1:3]
        arc = APCircularArc2(
                        APCircle2(APPoint(11.0, 0.0), 3.0), 
                        APPoint(14.0, 0.0), 
                        APPoint(8.0, 0.0))
    end


    begin
    Drawing(lxm.width, lxm.height, :svg)
    origin(); fontsize(15)

    sethue(julia_blue)
    path([segs..., arc], action=:stroke)

    sethue(julia_purple)
    path(arrow_head(segs[1]; style=:triangle, size=14); action=:fill)
    path(arrow_head(segs[2]; style=:stealth, size=14); action=:fill)
    path(arrow_head(segs[3]; style=:open, size=14); action=:stroke)
    path(arrow_head(arc; at=1.0, place=:tip, size=14); action=:fill)

    sethue(julia_red)
    for (p, style) in zip(names, (:triangle, :stealth, :open))
        label(":" * string(style), :E, p)
    end

    finish()
    preview()
    end
    ```


## Braces: `APDecorationBrace2`

[`APDecorationBrace2`](@ref)`(p1, p2)` is a curly brace along the segment,
`height` deep (default `10`, or half the length if that is smaller) on the
`side` (`:left` or `:right`) of `p1 → p2`. [`path`](@ref) draws it as one
continuous curve, and [`vertices`](@ref) gives `(p1, tip, p2)`: the tip is
where a label goes, no separate function needed for it.

```@example geo
dec = APDecorationBrace2(APPoint(0.0, 0.0), APPoint(100.0, 0.0); height=10.0)
vertices(dec)
```

```@raw html
<img src="../assets/img/decorations/braces.svg" alt="Braces on the left and right of a segment, horizontal and diagonal, with labels" style="width:100%; max-width: 700px;">
```

!!! details "See script"
    ```julia
    using Apollonius, Luxor
    import Luxor: julia_red, julia_blue, julia_green, julia_purple

    lxm = @prepare_to_picture! width=500 height=240 margin=20 begin  
        s1 = APSegment(APPoint(0.0, 4.0), APPoint(7.0, 4.0))
        s2 = APSegment(APPoint(0.0, 0.0), APPoint(7.0, 0.0))
        s3 = APSegment(APPoint(10.0, 0.0), APPoint(13.0, 5.0))
        b1 = APDecorationBrace2(s1.p1, s1.p2; height=14, side=:left)
        b2 = APDecorationBrace2(s2.p1, s2.p2; height=14, side=:right)
        b3 = APDecorationBrace2(s3.p1, s3.p2; height=14, side=:right)
    end


    begin
    Drawing(lxm.width, lxm.height, :svg)
    origin(); fontsize(15)

    sethue(julia_blue)
    path([s1, s2, s3], action=:stroke)

    sethue(julia_purple)
    path(b1; action=:stroke)
    path(b2; action=:stroke)
    path(b3; action=:stroke)

    sethue(julia_red)
    label("a", :N, vertices(b1)[2])
    label("b", :S, vertices(b2)[2])
    label("c", :S, vertices(b3)[2])

    finish()
    preview()
    end
    ```

[`direction`](@ref)/[`slope_angle`](@ref)/[`distance`](@ref) all work on a
brace directly, the same as on the segment `[p1, p2]` it decorates:

```@example geo
direction(dec), distance(dec)
```

`pos` (default `0.5`, the middle) moves the tip along `[p1, p2]`: at
`pos = 0` it sits `height / 2` past `p1` (not on `p1` itself, there is no
room for its corner arc any closer), at `pos = 1` symmetrically near `p2`:

```@example geo
off_center = APDecorationBrace2(APPoint(0.0, 0.0), APPoint(100.0, 0.0); height=10.0, pos=0.2)
vertices(off_center)[2]
```

`APDecorationBrace2` is transformable like any other object:
`rotate`/`translate`/`homothety`/`reflection` all work on it, moving `p1`
and `p2` the way they would on the plain segment; `homothety` also scales
its arc radius (never negative, same as any radius in this package), and
`side` only flips under a reflection about a line, not about a point or
under a homothety with a negative factor (both of those preserve
orientation in the plane).

!!! warning "A brace cannot be deeper than half its length"
    A `height` greater than half of `distance(p1, p2)` throws an `ArgumentError`. Only the default is reduced by itself, to half the length when that is smaller than `10`.
