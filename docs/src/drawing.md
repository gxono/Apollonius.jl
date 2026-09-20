```@meta
CurrentModule = Apollonius
```

# Drawing with Luxor.jl

!!! warning "Optional add-on, not core functionality"
    Everything on this page comes from a **package extension**, not from
    `Apollonius.jl` itself. The package never depends on
    [Luxor.jl](https://github.com/JuliaGraphics/Luxor.jl); `path` has *no
    methods at all* until your own code also loads Luxor. Everything
    described on the rest of this site (points, lines, circles, triangles,
    conics, tangency, affine maps...) is unaffected either way.

This page is not a Luxor tutorial. For `Drawing`, `sethue`, colors, fonts
and everything else that belongs to Luxor itself, read
[Luxor's own documentation](https://juliagraphics.github.io/Luxor.jl/stable/).
What follows is just what this package adds on top: the `path` function
and the `@to_luxor_picture` macro. Read the next three sections in order
to get going; the rest of the page is reference material for later.

## Activating it

Julia's package-extension mechanism (`[weakdeps]`/`[extensions]` in
`Project.toml`, available since Julia 1.9) is what makes this possible:
`path` is declared in `Apollonius.jl` but given no methods there.
The moment your own session also has Luxor loaded, those methods
materialize automatically, no configuration needed on your part beyond
loading both packages:

```julia
using Apollonius, Luxor

t = APTriangle(APPoint(-80.0, 60.0), APPoint(80.0, 60.0), APPoint(-20.0, -80.0))

Drawing(250, 250, "triangle.png")
origin()
background("white")

sethue(Luxor.julia_blue)
path([t, circumcircle(t)]; action=:stroke)

sethue(Luxor.julia_red) 
path([incenter(t), vertices(t)...], action=:fill)

finish()
preview()
```

```@raw html
<img src="../assets/img/drawing/ej1.png" alt="" style="width:100%; max-width: 400px;">
```

If you only ever `using Apollonius` and never load Luxor, `path`
simply doesn't exist as a callable function (`methods(path)` is empty).
There is no partial/broken state to worry about.

## `path` is deliberately thin

`path(obj; action=:path, kwargs...)` only ever does one thing: it adds
`obj` to Luxor's *current path*, using Luxor's own primitives underneath
(`Luxor.circle`, `Luxor.line`, `Luxor.poly`, `Luxor.arc2r`, ...). It never
calls `sethue`, never sets an opacity, and never draws a label; those are
already exactly what Luxor's own `sethue`, `setopacity` and `label` do
well, and giving `path` its own parallel vocabulary for them would just be
a second thing to learn for no benefit. Every example on this page is
`path(...)` interleaved with plain Luxor calls, the same way you'd combine
any two of Luxor's own shape functions.

The one keyword every method shares is `action`, forwarded straight to
Luxor exactly the way Luxor's own shape functions (`circle`, `poly`, ...)
take it:

* `:path` (the default): add to the current path and do nothing else.
  Use this when you're about to style it yourself (`Luxor.strokepath()`,
  `Luxor.fillpath()`, `Luxor.clip()`, or add more shapes to the same path
  first) or when you're going to reuse the same call with several actions.
* `:stroke`, `:fill`, `:fillstroke`: build the path *and* render it
  immediately, the one-call convenience.
* `:fillpreserve`, `:strokepreserve`: render it and *keep* the path, so the
  next call can use it again: the way to fill and stroke the same shape
  with two colors, without building it twice (see below).
* `:clip`: use the path as the clip region, see [Clipping the outside](@ref).

```julia
sethue("steelblue")
path(t; action=:stroke)       # outline only, one call

path(t)                        # action=:path: just builds the path...
Luxor.strokepath()              # ...you render it, same effect
```

For a translucent fill *underneath* a solid outline (a common combination
that used to be its own `fillcolor` keyword on this page in an earlier
version of this interface), just do what you'd do with any Luxor shape:
build the path once, fill it, then stroke a fresh copy:

```julia
sethue("steelblue"); setopacity(0.15)
path(t; action=:fill)
sethue("steelblue"); setopacity(1.0)
path(t; action=:stroke)
```

Or keep the path after the fill, so the outline needs no second call to
`path`:

```julia
sethue("steelblue"); setopacity(0.15)
path(t; action=:fillpreserve)   # fills and keeps the path
sethue("steelblue"); setopacity(1.0)
Luxor.strokepath()               # strokes the same path and clears it
```

A preserved path stays until something renders it or `Luxor.newpath()`
clears it. Any action other than `:path` starts a new path for the shape it
is given, so a second `path(obj; action=...)` replaces it. To preserve
several shapes together, give them as a vector:
`path([a, b, c]; action=:fillpreserve)` adds all of them to one path, fills
it once and keeps it.

And for a label, `Luxor.label` (or plain `Luxor.text`) at whatever anchor
point makes sense for that shape, which is almost always a point the
package already gives you a name for, so there's nothing to look up.
`Luxor.label` accepts an `APPoint` directly (both the alignment-`Symbol`
form and the direction-angle one), no `Luxor.Point(p...)` conversion
needed, and so does `Luxor.text`, which also turns the text, with `angle` or `direction`, a number or a vector:

```julia
Luxor.label("I", :N, incenter(t))
Luxor.label("O", :N, circumcenter(t))
side = APSegment(t[2], t[3])
Luxor.text("a", midpoint(side); halign=:center, direction=side, upright=true)   # along the side
```

## Sizing a canvas automatically

Setting up a `Drawing` normally means guessing values by hand: how wide
and tall does the canvas need to be, how far do the shapes need to shift
so nothing ends up off-canvas, how much breathing room to leave around
the edges? [`@to_luxor_picture`](@ref) (from the core package; see
[Transforming in Bulk: Macros](@ref) for the full option reference)
answers all of that in one call: it translates and uniformly scales a
whole set of shapes so they fit centered on `(0, 0)`, and hands back the
exact canvas size directly. Centering on `(0, 0)` matches Luxor's own
`origin()` convention, so the result is ready to draw right after
`origin()`, which `@png` already calls for you:

The macro returns two `NamedTuple`s, and this documentation always calls
them `lxm` (the "Luxor meta": the canvas size, the fitting function `fct` and
the drawable area `bb`) and `lxo` (the "Luxor objects": everything the block
built, already fitted, under the names it was given):

```julia
using Apollonius, Luxor

lxm, lxo = @to_luxor_picture width=300.0 margin=10.0 begin
    t = APTriangle(APPoint(2.0, -5.0), APPoint(9.0, 3.0), APPoint(-1.0, 6.0))
    circ = APCircle2(APPoint(4.0, 1.0), 4.0)
end
# (lxm.width, lxm.height) = (300.0, 328.0): exactly 300 wide (as requested), tall enough
# to keep t/circ's own aspect ratio, plus a 10-unit margin on every side

@png begin
    sethue("steelblue")
    path(lxo.t; action=:stroke)
    path(lxo.circ; action=:stroke)
end lxm.width lxm.height
```

```@raw html
<img src="../assets/img/drawing/to_luxor1.svg" alt="" style="width:100%;">
```

Building the `Drawing` by hand instead needs its own `origin()` call
first, since `Drawing` itself doesn't move `(0, 0)`:

```julia
Drawing(lxm.width, lxm.height, "figure.png")
origin()
background("white")
sethue("steelblue")
path(lxo.t; action=:stroke)
path(lxo.circ; action=:stroke)
finish()
```

`t`/`circ` inside the block are ordinary variables and stay as they were: the
fitted copies are in `lxo`. To bring them into scope under their own names,
`(; t, circ) = lxo`. [`@to_luxor_picture!`](@ref) is the mutating form, which
rebinds the names in place instead.

When the requested `width`/`height` don't match the content's own aspect
ratio, the content is scaled (still uniformly; a circle never becomes an
ellipse) to fit inside both, and centered, leaving extra blank space
beyond `margin` on whichever axis has slack: the same "contain fit" a
CSS `object-fit: contain` or an image viewer's "fit to window" would give:

```julia
lxm, lxo = @to_luxor_picture width=400.0 height=200.0 margin=10.0 begin
    t = APTriangle(APPoint(2.0, -5.0), APPoint(9.0, 3.0), APPoint(-1.0, 6.0))
    circ = APCircle2(APPoint(4.0, 1.0), 4.0)
end
Drawing(lxm.width, lxm.height, "figure_wide.png")
origin()
background("white")
sethue("steelblue")
path(lxo.t; action=:stroke)
path(lxo.circ; action=:stroke)
finish()
```

As an additional comment, every illustration under `docs/illustrations/`
shares the same Luxor imports and `Drawing`/`finish`/`preview`
boilerplate, factored out once into `docs/illustrations/default_config.jl`
(a shared `include`) and its `@svg_doc` macro. `docs/illustrations/template.jl`
is the copy-paste starting point for a new one: copy it into the right
subfolder (`triangles/`, `circles/`, ...) and fill in the two blanks:

```julia
include("../default_config.jl")

lxm, lxo = @to_luxor_picture width=500 height=240 margin=20 begin
    # build the objects: name = APObject(...)
end
# bring them into scope: (; name1, name2) = lxo

@svg_doc(lxm, @__FILE__, begin
    # plot the objects
end)
```

`@svg_doc` derives both the output filename and its subfolder under
`docs/src/assets/img/` from `@__FILE__`, which is why it has to be passed
in literally at the call site (a macro can never recover *its caller's*
file on its own, only its own defining file), rather than typed as a
`fmt_name`/path computation in every single illustration file by hand.

### Excluding a shape from sizing: `@unbounded`

Every shape named in a `@to_luxor_picture` block counts toward the
canvas's size and scale, including a large auxiliary shape you built only
to construct something else, and never meant to set the picture's own
scale. [`@unbounded`](@ref) marks one line as exempt from that sizing,
without changing anything else about it: it still binds/translates/scales
along with everything else, only its own `APBoundingBox` is left out of
the union that decides how far to zoom out:

```julia
lxm, lxo = @to_luxor_picture width=500.0 height=240.0 margin=20.0 begin
    A = APPoint(1.0, 1.0)
    @unbounded locus = APCircle2(APPoint(0.0, 0.0), 1000.0)   # huge, but not the picture's scale
    B = intersection(locus, APLine(A, APPoint(2.0, 2.0)))[1]
end
# sized by A/B alone (locus's radius-1000 bounding box never counts):
# without @unbounded here, A/B would shrink to a speck next to it instead
lxo.A, lxo.locus, lxo.B
```

Wrap either the whole line (`@unbounded locus = APCircle2(...)`) or just
the right-hand side (`locus = @unbounded APCircle2(...)`), both read the
same way. The object is still in `lxo`, fitted like the rest. Outside a picture block, `@unbounded expr` is simply `expr`, a
harmless no-op, so it's always safe to leave in place regardless of
context.

Note here how `@unbounded` allows me to ignore the circumcenter when computing the bounding box of the entire figure.

```julia
lxm, lxo = @to_luxor_picture width=500 height=240 margin=20 begin
    A, B, C = APPoint(0.0,0), APPoint(10,0), APPoint(7,5)
    triangle =  APTriangle(A, B, C)
    G = centroid(triangle)
    O = circumcenter(triangle)
    I = incenter(triangle)
    H = orthocenter(triangle)
    l = euler_line(triangle)
    tsides = APLine.(sides(triangle))
    @unbounded cc = circumcircle(triangle) #<---
    ic = incircle(triangle)
    iv = projection.(I, tsides)
    npc = nine_point_circle(triangle)
    npc_c = nine_point_center(triangle)
    ep = euler_points(triangle)   # a Tuple of 3 points, no `collect` needed
    ips = reduce(vcat, intersection.(npc, tsides))
end
(; A, B, C, triangle, G, O, I, H, l, tsides, cc, ic, iv, npc, npc_c, ep, ips) = lxo
```

```@raw html
<img src="../assets/img/triangles/tri_cen.svg" alt="" style="width:100%;">
```

!!! warning "A block with no extent cannot be fitted to a width"
    If everything in the block has zero size, a single point for example, and `width` or `height` is given, the scale would be infinite and the macro throws an `ArgumentError`. Add another object, or drop `width` and `height`.

### Applying the same transform outside the block: `lxm.fct`

Both macros' returned size `NamedTuple` also carries `fct`: the exact same
translate + homothety + (if `flip`) reflection pipeline applied to every
shape in the block, as a plain function, so it can be applied to
something that was never one of the block's own shapes and still land in
the same transformed coordinate space (a label position computed after
the fact, a point from unrelated data, ...):

```julia
lxm, lxo = @to_luxor_picture width=300.0 margin=10.0 begin
    t = APTriangle(APPoint(2.0, -5.0), APPoint(9.0, 3.0), APPoint(-1.0, 6.0))
    circ = APCircle2(APPoint(4.0, 1.0), 4.0)
end
lxm.fct(centroid(t))   # matches where `centroid(lxo.t)` lands, since t was never re-transformed itself
```

### The drawable area itself: `lxm.bb`

Both macros' returned size `NamedTuple` also carries `bb`: the
[`APBoundingBox`](@ref) of the canvas's own drawable area, centered on the
origin the same way `origin()` centers it, with `margin` already
subtracted from every side. It depends only on `width`/`height`/`margin`,
never on the block's own shapes, so it's there even when nothing in the
block reaches anywhere near the canvas edges.

The typical use is clipping: something that legitimately extends past the
canvas on purpose, most often an unbounded region or a large auxiliary
shape marked [`@unbounded`](@ref), can be clipped to `lxm.bb` before
stroking or filling it, instead of letting Cairo render (and spend time
on) geometry that falls outside the printable area anyway:

```julia
lxm, lxo = @to_luxor_picture width=300.0 height=200.0 margin=10.0 begin
    t = APTriangle(APPoint(2.0, -5.0), APPoint(9.0, 3.0), APPoint(-1.0, 6.0))
    circ = APCircle2(APPoint(4.0, 1.0), 4.0)
end
bbox_width(lxm.bb) == lxm.width - 20.0    # true: margin subtracted from both sides
bbox_height(lxm.bb) == lxm.height - 20.0  # true
path(lxm.bb; action=:clip)
path(lxo.t; action=:stroke)   # now clipped to the margin-adjusted drawable area
```

### Known limitation: plain numbers never scale

A bare number gets a well-defined empty [`APBoundingBox`](@ref) (it
contributes nothing to a picture's sizing, on purpose; see
[`APBoundingBox`](@ref)`()`), but a `Vector`/`Tuple` of numbers as a
single named binding has *no* `APBoundingBox` method at all (it isn't a
`Vector{<:APPoint}` or `Vector{<:APObject}`), so it errors unless wrapped
in [`@unbounded`](@ref), after which it passes through completely
unchanged, regardless of the picture's own scale factor:

```julia
lxm, lxo = @to_luxor_picture width=400.0 begin
    t = APTriangle(A, B, C)
    @unbounded ns = [1.2, 3.2, 5.3]   # e.g. hand-typed side lengths
end
lxo.ns == ns   # true: untouched, regardless of the picture's scale factor
```

This is a fundamental limitation, not a bug that could be fixed by making
`@to_luxor_picture` smarter: there is no way to tell, from a bare
`Vector{Float64}`, whether its numbers are *lengths* (which should scale
with the picture) or something purely combinatorial like vertex counts or
indices (which must not). Both are indistinguishable `Float64`s by the
time they reach the macro; `@unbounded` only silences the sizing error,
it can't retroactively make the numbers scale correctly.

**The alternative** is to never scale a number directly: instead,
compute it *from already-transformed shapes*, after the block has done
its scaling. A distance between two already-scaled points is correctly
scaled by construction, with no separate "scale this number" step needed
at all:

```julia
lxm, lxo = @to_luxor_picture width=400.0 begin
    t = APTriangle(A, B, C)
end
side_len_on_canvas = distance(lxo.t[1], lxo.t[2])   # correct: lxo.t is already in canvas space
```

or, for a point that was never one of the block's own shapes, `lxm.fct`
(see above) applied to each point before measuring between them:

```julia
distance(lxm.fct(A), lxm.fct(B))
```

### `current_path_bbox`

[`current_path_bbox`](@ref) is the Luxor-side complement: the
[`APBoundingBox`](@ref) of whatever is currently on the active `Drawing`'s
Cairo path, via `Luxor.path_extents`. Unlike computing an `APBoundingBox`
straight from the AP shapes (exact, and needs no `Drawing` open at all),
this reflects whatever Cairo itself measured, useful as a sanity check,
or when the path also has plain Luxor calls mixed in that
`Apollonius` has no way to know about:

```julia
Drawing(lxm.width, lxm.height, "figure.png")
origin()
path(lxo.t; action=:path)      # action=:path: build the path, don't render yet
path(lxo.circ; action=:path)

current_path_bbox()   # APBoundingBox([-140.0, -154.0] .. [140.0, 154.0])
                       # matches bbox_union(APBoundingBox(lxo.t), APBoundingBox(lxo.circ)) exactly here,
                       # since both draw via a native Cairo primitive (no sampling)

strokepath()
current_path_bbox()   # APBoundingBox([0.0, 0.0] .. [0.0, 0.0]): stroking consumes the path,
                       # same as most of Luxor's own shape functions
finish()
```

Call it *before* a non-`:path` action: `:stroke`/`:fill`/etc. clear the
current path as a side effect of actually rendering it, so
`current_path_bbox()` reads as an empty (all-zero) box afterward, as shown
above. For a shape whose `path` method samples points rather than using a
native Cairo primitive (`APParabola2`, `APHyperbola2`, the non-circular
conic arcs), `current_path_bbox()` only approximates the true extent, to
the same accuracy as that sampling.

## What each type builds

`path(obj; action=:path, kwargs...)` dispatches on the type of `obj`.
Besides `action`, every method also accepts whatever *structural* (not
styling) keywords that curve needs: how far to extend an infinite line,
how finely to sample a curve Luxor has no native primitive for, and so on:

| Type | Adds to the path as | Type-specific keywords |
|:-----|:---------------------|:------------------------|
| `APPoint` | a small mark: a circle by default, or a square, an `x` or a `+` | `radius=3`; `as=:circle` (also `:square`, `:cross`, `:plus`; the last two are two strokes, so they only show with `action=:stroke`) |
| `APSegment` | a straight line between its two points, or (pass `as=:arrow`) an arrow (see [Arrows](@ref) below) | `as=:plain` (default) |
| `APLine` | a long finite segment, since the line itself is infinite; `extend=0.0` draws the exact finite segment between `l.p1`/`l.p2` instead | `extend=1000.0`: how far past each defining point, or a 2-tuple `(past_p1, past_p2)` to extend each end by a different amount; `as=:plain`/`:arrow` ; `add=(before, after)`: lengthen by fractions of `distance(l.p1, l.p2)` instead of absolute units (see [`extend_line`](@ref)), replacing `extend` |
| `APRay` | likewise, extended only past `through` (not past `origin`); `extend=0.0` draws the exact finite segment from `origin` to `through` | `extend=1000.0`; `as=:plain`/`:arrow`; `add=(before, after)`: lengthen the segment `origin`-`through` by fractions of its length, replacing `extend` |
| `APCircle2` | Luxor's native circle | (none) |
| any [`APPolygon`](@ref) | every side, chained end to end into one closed path: a straight line for an `APSegment` side, a true arc for an `APCircularArc2` side, an `n`-point sampled polyline for any other conic-arc side (see below); covers `APTriangle`, `APQuadrilateral`, `APStraightNgon`, `APCircularSector2`, `APCircularSegment2`, `APAnnularSector2`, `APInterstice2`, `APCurvilinearTriangle2`, `APCurvilinearQuadrilateral2` and `APCurvilinearNgon2`, **one** method for the whole family | `n=60` (only matters if some side needs sampling) |
| `APBoundingBox` | an axis-aligned box | (none) |
| `APEllipse2` | a smooth, Bézier-curve ellipse (Luxor's own axis-aligned `ellipse(center, w, h)`, `w = 2a`, `h = 2b`) inside a rotated/translated frame matching `e.center`/`e.angle`, so the path stays a true curve at any zoom level | (none) |
| `APParabola2` | Luxor has no native parabola primitive: sampled at `n` points via [`point_on_parabola`](@ref) over the parameter range `srange`, added as an open polyline | `srange=(-100.0, 100.0)`, `n=60` |
| `APHyperbola2` | likewise (no native primitive), sampled via [`point_on_hyperbola`](@ref) on one branch at a time | `trange=(-2.0, 2.0)`, `n=60`, `branch=1` (pass `branch=-1` and call again for the other branch) |
| `APCircularArc2` | a true circular arc from `p1` to `p2`, via Luxor's own `arc2r` (Cairo's native arc primitive, not a polygonal approximation) | (none) |
| `APEllipticArc2`, `APParabolicArc2`, `APHyperbolicArc2` | none of these has a native Cairo primitive either, so each is sampled at `n` points via [`point_on_arc`](@ref) over its own parameter range `[0, 1]` (`arc.p1` to `arc.p2`), added as an open polyline | `n=60` |
| `APAngle2` | see below; it has no single canonical path | `as=:arc` (default; also `:rays`/`:sector`/`:rarc`/`:rsector`), `radius` |
| `APVector` | has no position of its own, so it's drawn as the segment `from -> from + v` | `from=APPoint(0.0, 0.0)`, `as=:plain`/`:arrow` |
| `APHalfPlane2` | unbounded, so this draws its boundary line only (see `APLine` above) | `extend=1000.0`, `add` |
| `APStrip2` | likewise unbounded: both boundary lines, one call each | `extend=1000.0`, `add` |
| `APEquipollentVector` | the segment from its point of application to its tip | `as=:plain`/`:arrow` |
| `APPolyline2` | an open chain of straight sides through its vertices, never closed | (none) |
| `APCurvilinearPolyline2` | an open chain of straight and curved sides in the order given: a line for an `APSegment`, a true arc for an `APCircularArc2`, a sampled polyline for any other conic arc | `n=60` |
| `AbstractVector{<:APObject}` | each element in turn, with the same `kwargs` every time (see below) | whatever that element's own type takes |

The four point shapes, drawn with `action=:stroke`:

```@raw html
<img src="../assets/img/drawing/point_shapes.svg" alt="The four point shapes: circle, square, cross and plus" style="width:100%; max-width: 700px;">
```

Every method for a curve also takes `reverse=true` (see [Reversing a path](@ref)). The last row is what lets a plain `Vector` (what [`intersection`](@ref)/
[`tangent_points`](@ref) return, since they can give 0, 1 or 2 points
depending on the geometry) get drawn directly, without unwrapping it by
hand first:

```julia
pts = intersection(l, c)   # a Vector{APPoint}, however many points there are
path(pts; action=:fill)    # each point drawn as its own small circle
```

It also calls `Luxor.newsubpath()` before each element, so this is the
safe way to batch several shapes into *one* combined path with the
default `action=:path`, e.g. to fill them one color and outline them
another with a single `fillpreserve()`/`strokepath()` pair, rather than
drawing each one twice:

```julia
path(pts; action=:path)   # builds all the circles into one path
sethue("white"); fillpreserve()
sethue("blue"); strokepath()
```

Without the `newsubpath()`, Cairo's own circle/arc primitives connect to
wherever the current path left off with a straight line the moment a
second one starts, a well-known Cairo gotcha, not something specific to
this package, but one `path(::AbstractVector)` takes care of for you.

!!! warning "`path(v)` is not the same as `path.(v)`"
    Broadcasting (`path.(pts; action=:path)`, with the dot) calls the
    scalar `path` method on each point directly; it never reaches
    `path(::AbstractVector)` at all, so none of the `newsubpath()`
    handling above applies. For an immediately-rendering action
    (`:stroke`, `:fill`, `:fillstroke`) the two look identical, since each
    element renders and clears on its own regardless of how it got there.
    The `preserve` actions are the exception in the other direction: with the
    dot, every element starts a new path, so only the last one is kept.
    But for the default `action=:path`, only the no-dot form `path(pts)`
    batches safely; `path.(pts)` (or a hand-written loop without its own
    `newsubpath()` calls) reproduces the stray-line bug this method exists
    to avoid.

Most types default effectively to an outline when you pass `action=:stroke`
(`APPoint` would need `action=:fill` to actually show up, since an
unfilled single-pixel-radius circle is invisible, but that choice is now
yours to make, same as with any other type).

The single `path(pg::APPolygon)` method is the direct payoff of building
a real [`APPolygon`](@ref) hierarchy: it walks `sides(pg)` via the same
`_polygon_walk` [`area`](@ref)/[`perimeter`](@ref) already use, so one
method (not seven, one per concrete type) covers every straight-sided
*and* curved-region shape in the package. The one behavior difference
from a hand-rolled per-vertex path: it always produces a *closed* path (no
`close=false` open-polyline option), since a walked side sequence is
inherently a loop.

**A subtlety worth knowing, inherited from Luxor itself rather than
anything this package adds**: with a non-`:path` action, most of Luxor's
own shape-building functions (`circle`, `poly`, and so the types built on
them here: `APCircle2`, every `APPolygon`, `APEllipse2`) clear the current
path first, so calling one always draws *only* that shape. A few of
Luxor's own primitives don't: `line` (hence `APSegment`/`APLine`/`APRay`
here) and `box` (hence `APBoundingBox`) add to whatever path is already
there instead. In practice this rarely matters: a prior call with a real
action (`:stroke`, `:fill`, ...) already emptied the path as a side effect
of drawing it, regardless of which behavior the next call has. It only
shows up if you deliberately chain several `path(...; action=:path)` calls
to build one compound shape across multiple types and finish with a single
action on the last call; in that case, a final
`APSegment`/`APLine`/`APRay`/`APBoundingBox` call correctly includes
everything built so far, while a final `APCircle2`/`APPolygon`/etc. call
would silently discard it first.

### Arrows

`APSegment`/`APLine`/`APRay` take `as=:arrow` to draw as an arrow instead
of a plain line, via Luxor's own `arrow`:

```julia
path(APSegment(APPoint(-80.0, 0.0), APPoint(80.0, 0.0)); as=:arrow)

l = APLine(APPoint(0.0, -60.0), APPoint(0.0, 60.0))
path(l; extend=0.0, as=:arrow, arrowheadlength=15)   # extend=0.0: the exact finite segment
```

```@raw html
<img src="../assets/img/drawing/arrows.svg" alt="" style="width:100%; max-width: 700px;">
```

This is the one case where `path` doesn't just add to the current path:
Luxor's `arrow` always strokes the shaft and fills the arrowhead
immediately, with no deferred form, so `action` is ignored when
`as=:arrow`. Keyword arguments other than `as`/`extend` (`arrowheadlength`,
`arrowheadangle`, `linewidth`, ...) are forwarded straight to `Luxor.arrow`.

`as=:arrow` always puts the head at the end of a straight shaft. For an
arrowhead in the middle of a line, or at the end of an arc, build it with
[`arrow_head`](@ref) and draw it like any other shape; see
[Marks, Labels & Decorations](@ref).

### `APAngle2`: rays, arc, sector, or the parallelogram-law marker

An `APAngle2` is genuinely just the space between two rays, but it's
conventionally *drawn* as a small arc, a filled wedge, or (especially for
a right angle) a small square in the corner. `as` picks which:

```julia
ang = APAngle2(t[2], t[1], t[3])   # the angle at vertex t[2]

path(ang; as=:rays, action=:stroke)      # the literal two half-lines, a-vertex-b
path(ang; as=:arc, action=:stroke)       # the conventional small arc (default)
path(ang; as=:sector, action=:fill)      # closed pie-wedge, for shading
path(ang; as=:rarc, action=:stroke)      # the parallelogram-law corner marker (open)
path(ang; as=:rsector, action=:fill)     # ...and its closed, fillable version
```

```@raw html
<img src="../assets/img/drawing/angles.svg" alt="" style="width:100%; max-width: 700px;">
```

`radius` defaults to `0.15` times the shorter of the distances from the
vertex to `ang.a` and `ang.b`, so it looks reasonable at the figure's own
scale without having to think about it; pass it explicitly to override.
`as=:arc` and `as=:sector` are, in fact, nothing more than
`path(APCircularArc2(...))` and `path(APCircularSector2(...))` under the
hood (see below); `APAngle2` just works out the right circle and
endpoints first.

`as=:rarc`/`:rsector` generalize the little square textbooks use to mark
a *right* angle to any angle, via the parallelogram law: `pa`/`pb` are the
points at distance `radius` along each ray, and `pc = pa + pb - vertex`
completes the parallelogram `vertex, pa, pc, pb`. At exactly 90° that
parallelogram is the familiar square corner marker (`pa`/`pb` are
perpendicular and equal in length); at any other angle it's still a
rhombus (`pa`/`pb` are always exactly `radius` from the vertex), tracing
the same idea. `:rarc` draws just the two "far" sides, `pa -> pc -> pb`
(open, so it doesn't retrace the rays themselves); `:rsector` closes the
whole parallelogram, for filling.

## Circular arcs, sectors, segments, interstices and curvilinear polygons

[`APCircularArc2`](@ref), [`APCircularSector2`](@ref),
[`APCircularSegment2`](@ref), [`APAnnularSector2`](@ref) and
[`APInterstice2`](@ref) (see [Circles](@ref),
[Tangency & Apollonius Problems](@ref)) draw exactly like everything else,
all through the same generic `path(pg::APPolygon)` method described
above:

```julia
circ = APCircle2(APPoint(0.0, 0.0), 30.0)
arc = APCircularArc2(circ, APPoint(30.0, 0.0), APPoint(0.0, 30.0))
path(arc; action=:stroke)

sethue("steelblue"); setopacity(0.4)
path(APCircularSector2(arc); action=:fill)   # the pie slice
path(APCircularSegment2(arc); action=:fill)  # the cap cut off by the chord

c1 = APCircle2(APPoint(0.0, 0.0), 40.0)
c2 = APCircle2(APPoint(90.0, 0.0), 50.0)   # tangent to c1: distance 90 == 40 + 50
c3_center = intersection(APCircle2(c1.center, c1.r + 35.0), APCircle2(c2.center, c2.r + 35.0))[1]
c3 = APCircle2(c3_center, 35.0)            # tangent to both c1 and c2

sethue("red"); setopacity(0.5)
path(interstices(c1, c2, c3); action=:fill)

sethue("purple")
path(invert(APTriangle(APPoint(50.0, 20.0), APPoint(90.0, 30.0), APPoint(60.0, 80.0)), APPoint(0.0, 0.0), k=100.0); action=:fill)
```

```@raw html
<img src="../assets/img/drawing/curves.svg" alt="" style="width:100%;">
```

Every curved side here is built from Luxor's own `arc2r`/`carc2r` (Cairo's
native circular-arc path primitive, driven by a center and the two
endpoints), never a sampled polyline standing in for the arc, the way
`APParabola2`/`APHyperbola2` above have to (Luxor has no native primitive
for *those* curves, so sampling is the only option there).

## Elliptic, parabolic and hyperbolic arcs

[`APEllipticArc2`](@ref), `APParabolicArc2`, `APHyperbolicArc2` (see
[Conics: Ellipse, Parabola & Hyperbola](@ref)) draw the same way as
`APCircularArc2`, just sampled rather than a native Cairo primitive (like
`APParabola2`/`APHyperbola2` themselves):

```julia
e = APEllipse2(APPoint(0.0, 0.0), 40.0, 20.0, pi / 6)
earc = APEllipticArc2(e, point_on_ellipse(e, 0.2), point_on_ellipse(e, 2.0))
path(earc; action=:stroke)
```

```@raw html
<img src="../assets/img/drawing/earcs.svg" alt="" style="width:100%;">
```

They can also turn up as a *side* of a curvilinear region, not from
building one directly (there's no `APEllipticSector2`), but as the result
of an [`APAffineMap`](@ref) applied to a circular-arc region, since a
non-conformal map turns a circular arc elliptic:

```julia
sec = APCircularSector2(APCircularArc2(APCircle2(APPoint(0.0, 0.0), 30.0), APPoint(30.0, 0.0), APPoint(0.0, 30.0)))
skew = APAffineMap(1.3, 0.4, -0.2, 0.9, 0.0, 0.0)
path(skew(sec); action=:stroke)   # an APCurvilinearTriangle2 with one elliptic-arc side
```

```@raw html
<img src="../assets/img/drawing/affine_skew.svg" alt="" style="width:100%;">
```

`path(::APPolygon)` handles this transparently: a side is drawn with
`arc2r` if it's an `APCircularArc2`, or sampled at `n` points (the same
`n` `path` itself takes) if it's any of the other three arc types.

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
region, a bounding box, or an angle drawn with `as=:sector` or `as=:rsector`), and without approximating any arc.

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

## Worked example: the package logo

![Apollonius.jl logo](assets/logo.svg)

The logo is a **Steiner chain**: `K1` and `K2` are two circles internally
tangent to a big circle `K` (and externally tangent to each other), and the
chain is every further circle also tangent to both `K` and `K2`, each one
also tangent to the previous. Rather than re-solving the 3-circle
Apollonius problem (up to 8 candidate solutions) at every step of the
chain, this inverts about the point where `K` and `K2` touch: both become
**parallel lines**, and in that inverted picture the whole chain collapses
to a trivial row of *equal* circles translated along them: invert each
one back and the real, naturally-shrinking chain falls out, one
[`invert`](@ref) per new circle instead of a full Apollonius solve.
`delta_r` then perturbs each circle's own already-inverted (real-space)
radius by a constant amount before it's kept: a negative value shrinks
every circle a bit further, opening up the gaps between them, which is
what gives the logo its current look; it has to be applied there and not
inside the inverted-space construction, since that construction only
produces a valid chain when every one of *those* circles shares exactly
the same radius. `r_min` stops the chain once a circle's own
(already-perturbed) radius would no longer be a sensible circle to draw.
[`reflection`](@ref) across the radial axis through `K1` then gives the
mirror-image chain trailing the other way, and three [`rotate`](@ref)
copies (paired with `Luxor.julia_green`/`julia_purple`/`julia_red`, in
that order) complete the 3-fold symmetric figure. `A` is placed at angle
`270°`, not `90°`, because Luxor's y-axis points downward (screen
coordinates), so `270°` is the direction that reads as "up" once drawn:

```julia
begin
using Apollonius
using Luxor: Drawing, finish, origin,
    sethue, julia_blue, julia_green, julia_red, julia_purple
import Luxor
end

colors = [julia_red, julia_purple, julia_green]

begin
Δr = 5
p1, p2 = polar_point_deg.(100, [30, 30+120])
t = equilateral_triangle_on_segment(p1, p2)
three_circles = APCircle2.(vertices(t), distance(p1, p2) / 2)
outer_circle = argmax(c -> c.r, tangent_circles(three_circles...))
circles = [three_circles[2]]

while true
    tc = argmin(c -> c.r, tangent_circles(outer_circle, three_circles[1], circles[end]))
    tc.r > Δr ? push!(circles, tc) : break
end

map!(c -> APCircle2(c.center, c.r - Δr), circles)

end

begin
Drawing(500, 500, "docs/src/assets/img/examples/logo.svg")
origin()

for (i, color) in enumerate(colors)
    sethue(color)
    path(rotate(circles, (1-i)*2pi/3), action=:fill)
end

finish()
end
```

## Name collisions with Luxor

Every AP-prefixed *type* in this package (`APPoint`, `APCircle2`,
`APBoundingBox`, ...) is safe to use unqualified alongside Luxor, precisely
because the `AP` prefix keeps it out of Luxor's own namespace. What still
collides is a handful of *function* names both packages independently
export: `midpoint`, `distance` and `rotate`. Plain `using Apollonius,
Luxor` still works (that's exactly what every example on this page does),
but calling any of those three names *unqualified* is ambiguous and throws
an `UndefVarError` pointing out the clash, rather than silently picking
one:

```julia
julia> using Apollonius, Luxor

julia> midpoint(APPoint(0.0, 0.0), APPoint(4.0, 4.0))
ERROR: UndefVarError: `midpoint` not defined in `Main`
Hint: It looks like two or more modules export different bindings with this name, resulting in ambiguity. Try explicitly importing it from a particular module, or qualifying the name with the module it should come from.
Hint: a global variable of this name also exists in Apollonius.
Hint: a global variable of this name also exists in Luxor.
```

Two ways to resolve it, depending on which package's version you mean at
that call site:

* Qualify it explicitly: `Apollonius.midpoint(...)` or
  `Luxor.rotate(...)`.
* In your own scripts (not needed just to follow this page), prefer
  `using Apollonius` together with `import Luxor` instead of
  `using Luxor`; then only `Apollonius`'s bindings are unqualified,
  and every Luxor call is written as `Luxor.something`, which sidesteps
  the ambiguity entirely rather than resolving it case by case. This is
  the convention this package's own test suite uses internally.
* Or the other way around: plain `using Apollonius` (every one of
  its names unqualified, colliding or not), plus `using Luxor: f1, f2, ...`
  naming only the handful of Luxor functions actually called, instead of
  blanket `using Luxor`, since `distance`/`rotate` are then never brought
  in from Luxor at all, there's no collision left to resolve. Add a plain
  `import Luxor` alongside so `Luxor.something` (e.g. `Luxor.julia_green`)
  still works for anything not explicitly named. This is what the logo
  example above does: `using Luxor: Drawing, origin, sethue, finish` for
  the few Luxor calls it makes, `Apollonius` dominant and
  unqualified everywhere else.
