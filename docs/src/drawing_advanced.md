```@meta
CurrentModule = Apollonius
```

# Drawing: Clipping, Dimensions & Reversing

## Reversing a path

Every `path` method for a curve takes `reverse::Bool=false`: the very same
points, traversed backwards. It matters wherever the direction of travel
shows: which end an arrow points to, where a dash pattern starts, and how
subpaths combine under a fill rule.

```julia
seg = APSegment(APPoint(-80.0, 0.0), APPoint(80.0, 0.0))
path(seg; as=:arrow)                  # the head is at seg.p2
path(seg; as=:arrow, reverse=true)    # the head is at seg.p1

arc = APCircularArc2(APCircle2(APPoint(0.0, 0.0), 60.0), APPoint(60.0, 0.0), APPoint(0.0, 60.0))
setdash("dash")
path(arc; action=:stroke)                 # the dashes start at arc.p1
path(arc; reverse=true, action=:stroke)   # the same arc, dashes starting at arc.p2
```

```@raw html
<img src="../assets/img/drawing/path_reverse.svg" alt="The same segment drawn with an arrow forward and reversed" style="width:100%; max-width: 700px;">
```


```@raw html
<img src="../assets/img/drawing/oe_rule.svg" style="width:100%;">
```


!!! details "See script"
    ```julia
    using Apollonius, Luxor
    import Apollonius: translate
    import Luxor: julia_red, julia_blue, julia_green, julia_purple


    lxm = @prepare_to_picture! flip=false width=500 height=240 margin=20 begin
        ta1 = APTriangle(APPoint(-80.0, 60.0), APPoint(80.0, 60.0), APPoint(-20.0, -80.0))
        ca = circumcenter(ta1)
        ta2 = homothety(ta1, 1/2, ca)
        tb1, cb, tb2 = translate.([ta1, ca, ta2], APVector(200.0, 0))
    end


    begin
    Drawing(lxm.width, lxm.height, :svg)
    origin()

    sethue(julia_blue)
    @layer begin
        setopacity(0.25)
        path([ta1])
        path(ta2)
        fillpath()
        
        path(tb1)
        path(tb2, reverse=true) #see fill-rule on Luxor doc.
        fillpath()
    end

    path([ta1, ta2, tb1, tb2], action=:stroke)

    finish()
    preview()
    end
    ```


!!! warning "`reverse=true` is not `reverse(obj)`"
    [`reverse`](@ref)`(obj)` builds a new object. For a circular or elliptic arc that object is the *complementary* arc, the rest of the circle. `path(arc; reverse=true)` draws the same arc, from the other end.

The keyword also exists on `APPoint` (a point has no direction, so it is
ignored), so `path(v; reverse=true)` works on a `Vector` that mixes points
with curves; it is forwarded to every element, without reversing the order
of the elements.

## Clipping the outside

`path(obj; action=:clip)` restricts later drawing to the inside of `obj`.
[`clip_out`](@ref)`(obj)` restricts it to the *outside*, which is what lunes,
arbelos and "a circle minus two circles" figures need. It works on anything
`path` draws as a closed shape (a circle, an ellipse, a polygon or curved
region, a bounding box, or an angle's marker wrapped as `APCircularSector2`/
`APQuadrilateral`, see [Marks, Labels & Decorations](@ref)), and without
approximating any arc.

[`APHalfPlane2`](@ref), [`APStrip2`](@ref), [`APAngle2`](@ref) (`as=:region`)
and [`APUnboundedPolygon2`](@ref) have no closed path to give either way (see
"Filling an unbounded region" below): both `path(region; action=:clip)` and
`clip_out(region)` work on them too, restricting drawing to the inside or
the outside of the same `bound`-sized box the fill uses.

```julia
@layer begin
    clip_out(APCircle2(APPoint(-50.0, 0.0), 30.0))
    clip_out(APCircle2(APPoint(50.0, 0.0), 30.0))   # a second call narrows it further
    sethue("red")
    paint()                                          # everything except the two discs
end
```

The same idea with two discs and a triangle, shading everything else:

```@raw html
<img src="../assets/img/drawing/clip_out.svg" alt="The outside of two circles and a triangle shaded" style="width:100%; max-width: 700px;">
```

Two calls keep what is outside both shapes, and a `Vector` argument does the
same in one call, one clip per element. Like any Luxor clip, it lasts until
`clipreset()` or the end of the enclosing `@layer`, so wrap it.

Internally it clips the region between a big box and the shape, using
Luxor's even-odd fill rule. The box has half-side `bound` (default `1e5`),
centered on the current origin, so raise `bound` if you have translated the
origin far from the drawing.

!!! warning "A clip stays until it is reset"
    Both `clip_out` and `path(obj; action=:clip)` last until `clipreset()` or the end of the enclosing `@layer`. Everything drawn after them is clipped, including the labels, so wrap the clip in a `@layer` and draw the rest outside it.

## Filling an unbounded region

[`APHalfPlane2`](@ref), [`APStrip2`](@ref) and [`APUnboundedPolygon2`](@ref)
have no finite shape to fill: `path(obj; action=:fill)` used to draw
nothing at all for them, since their ordinary path is just the boundary
line(s), with zero area. It now fills the part of `obj` inside a square of
half-side `bound` (default `1000.0`) centered on the current origin
instead, the same big-box idea `clip_out` already uses, just filling the
box's intersection with `obj` rather than clipping it out. `action=:fillstroke`
also strokes the true boundary, not the square's edges:

```julia
hp = APHalfPlane2(APLine(APPoint(-2.0, -5.0), APPoint(-2.0, 5.0)), APPoint(-10.0, 0.0))
s = APStrip2(APLine(APPoint(0.0, -6.0), APPoint(8.0, -6.0)), APLine(APPoint(0.0, -3.0), APPoint(8.0, -3.0)))
sethue(julia_purple); setopacity(0.25)
path(hp; action=:fill)
path(s; action=:fill)
```

```@raw html
<img src="../assets/img/drawing/fill_halfplane_strip.svg" alt="A half-plane and a strip, each shaded up to the edge of the picture" style="width:100%; max-width: 700px;">
```

An [`APUnboundedPolygon2`](@ref) (see [Unbounded Regions: Half-Planes,
Strips & Angles](@ref)) fills the same way, its mix of rays and segments
closing off a shape that's bounded on some sides and open on others:

```julia
u = APUnboundedPolygon2(APRay(APPoint(0.0, 3.0), APPoint(1.0, 3.0)), APPoint{2,Float64}[], APRay(APPoint(0.0, 0.0), APPoint(1.0, 0.0)))
sethue(julia_purple); setopacity(0.25)
path(u; action=:fill)
```

```@raw html
<img src="../assets/img/drawing/fill_unboundedpolygon.svg" alt="An unbounded polygon (bounded above and below, open on the right) shaded up to the edge of the picture" style="width:100%; max-width: 700px;">
```

[`APAngle2`](@ref) gets this as a new `as=:region` option (alongside its
own `as=:rays`; the decorative vertex markers, a small arc/pie-wedge/corner
marker regardless of `action`, live in [`marks`](@ref) instead, see
[Marks, Labels & Decorations](@ref)): it fills the true infinite wedge, not a
marker near the vertex:

```julia
ang = APAngle2(APPoint(0.0, 0.0), APPoint(4.0, 0.0), APPoint(0.0, 4.0))
sethue(julia_purple); setopacity(0.25)
path(ang; as=:region, action=:fill)
```

```@raw html
<img src="../assets/img/drawing/fill_angle_region.svg" alt="A convex angle's true wedge shaded up to the edge of the picture" style="width:100%; max-width: 700px;">
```

A *reflex* angle correctly fills as two pieces (everything except the
small excluded wedge), the same way it can come back as two pieces from
[`intersection`](@ref):

```julia
reflex = APAngle2(APPoint(0.0, 0.0), APPoint(0.0, 4.0), APPoint(4.0, 0.0))
sethue(julia_purple); setopacity(0.25)
path(reflex; as=:region, action=:fill)
```

```@raw html
<img src="../assets/img/drawing/fill_reflex_region.svg" alt="A reflex angle shaded everywhere except the small excluded wedge, as two filled pieces" style="width:100%; max-width: 700px;">
```

`as=:region` with `action` in `:path`/`:stroke`/`:strokepreserve` draws the
same two true rays as `as=:rays`, and raise `bound` the same way `clip_out`
suggests if the origin has moved far from the drawing.

`action=:clip` works the same way as `:fill`, restricting later drawing to
the region's part of the box instead of painting it, and `clip_out` does the
opposite, restricting to everything outside it (see "Clipping the outside"
above):

```julia
@layer begin
    path(hp; action=:clip)
    sethue(julia_purple); setopacity(0.25)
    paint()   # only the part of hp inside the box gets painted
end
```

## Dimensions, tick lines and labels

Three Luxor functions come with methods for `APPoint`s, the same way `label`
does, so you never convert by hand.

| Call | What it does |
|:-----|:-------------|
| `Luxor.label(text, alignment, p; kwargs...)` | Luxor's `label` at an `APPoint`. `alignment` is a compass symbol (`:N`, `:SE`, ...) or an angle. |
| `Luxor.text(text, p; halign, valign, angle, direction, upright)` | Luxor's `text` at an `APPoint`. Unlike `label` it can turn the text: `angle` and `direction` take a number in radians, or a vector, line, ray or segment to run the text along. |
| `Luxor.dimension(p1, p2; kwargs...)`, `Luxor.dimension(segment; kwargs...)` | the dimension line for the distance between two points, with extension lines, two arrowheads and the measured text. Drawn immediately; returns `(distance, text)`. |
| `Luxor.tickline(p1, p2; kwargs...)` | a line with ticks and numbers between two points. Returns the tick positions `(major, minor)` as vectors of `APPoint`; with `vertices=true` it draws nothing and only returns them. |

The keywords go straight to Luxor (`offset`, `format`, `major`, `minor`,
`startnumber`, and so on); see Luxor's own documentation for them. One
thing worth knowing from there: `dimension` expects `p1` to be the point
lower on the page, that is with the larger `y`.

```julia
d, text = Luxor.dimension(APPoint(-80.0, 60.0), APPoint(80.0, 60.0); offset=15)   # (160.0, "160.0")

major, minor = Luxor.tickline(APPoint(-100.0, 0.0), APPoint(100.0, 0.0);
    major=4, minor=1, vertices=true)                                              # positions only
path(major; radius=2, action=:fill)                                              # draw them as dots
```

Drawn immediately (`vertices=false`, the default), `tickline` adds its own
major/minor ticks and numbers along the way:

```julia
Luxor.tickline(a, b; major=7, minor=3, startnumber=0, finishnumber=7, rounding=0)
```

```@raw html
<img src="../assets/img/drawing/tickline.svg" alt="A tick-marked axis between two points, with major and minor ticks and numbered labels" style="width:100%; max-width: 700px;">
```

The measured text is the distance between the two points you pass, so on a
canvas it is a length in pixels. Use `format` to show the value in your own
units, and `textrotation=-pi/2` to keep the text upright on a horizontal
dimension line (Luxor rotates it with the line by default):

```julia
Luxor.dimension(a, b; offset=40, format=d -> "7.0", textrotation=-pi / 2, textgap=25)
```

```@raw html
<img src="../assets/img/drawing/dimension.svg" alt="A dimension line with its measured text" style="width:100%; max-width: 700px;">
```

`label` also takes a `LaTeXString` as the text once `LaTeXStrings` and
`MathTeXEngine` are loaded (Luxor draws it with its own LaTeX support), so a
label can be a formula:

```julia
using LaTeXStrings, MathTeXEngine
label(L"\alpha^2 + \beta_1", :N, APPoint(0.0, 0.0))
```

To choose where a label goes and how it is aligned, see
[`label_anchor`](@ref) on the [Marks, Labels & Decorations](@ref) page.

!!! warning "`dimension` measures the distance you pass"
    The text is the distance between the two points, in the units of those points. On fitted objects that is a length in drawing units, not in the units of your problem. Use `format` to show the value you mean, and `textrotation=-pi / 2` to keep the text upright on a horizontal line.
