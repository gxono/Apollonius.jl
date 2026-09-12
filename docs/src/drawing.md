```@meta
CurrentModule = EuclideanGeometry
```

# Drawing with Luxor.jl

!!! warning "Optional add-on, not core functionality"
    Everything on this page comes from a **package extension**, not from
    `EuclideanGeometry.jl` itself. The package never depends on
    [Luxor.jl](https://github.com/JuliaGraphics/Luxor.jl) — `path` has *no
    methods at all* until your own code also loads Luxor. This is also the
    newest, least settled corner of the package: keyword names and default
    behavior may still change. Everything described on the rest of this
    site (points, lines, circles, triangles, conics, tangency, affine
    maps...) is unaffected either way.

## Activating it

Julia's package-extension mechanism (`[weakdeps]`/`[extensions]` in
`Project.toml`, available since Julia 1.9) is what makes this possible:
`path` is declared in `EuclideanGeometry.jl` but given no methods there.
The moment your own session also has Luxor loaded, those methods
materialize automatically — no configuration needed on your part beyond
loading both packages:

```julia
using EuclideanGeometry, Luxor

t = EGTriangle(EGPoint(-80.0, 60.0), EGPoint(80.0, 60.0), EGPoint(-20.0, -80.0))

Drawing(400, 400, "triangle.png")
origin()
background("white")

sethue("steelblue")
path(t; action=:stroke)
path(circumcircle(t); action=:stroke)

sethue("orangered")
path(incenter(t); action=:fill)

finish()
```

If you only ever `using EuclideanGeometry` and never load Luxor, `path`
simply doesn't exist as a callable function (`methods(path)` is empty) —
there is no partial/broken state to worry about.

## `path` is deliberately thin

`path(obj; action=:path, kwargs...)` only ever does one thing: it adds
`obj` to Luxor's *current path*, using Luxor's own primitives underneath
(`Luxor.circle`, `Luxor.line`, `Luxor.poly`, `Luxor.arc2r`, ...). It never
calls `sethue`, never sets an opacity, and never draws a label — those are
already exactly what Luxor's own `sethue`, `setopacity` and `label` do
well, and giving `path` its own parallel vocabulary for them would just be
a second thing to learn for no benefit. Every example on this page is
`path(...)` interleaved with plain Luxor calls, the same way you'd combine
any two of Luxor's own shape functions.

The one keyword every method shares is `action`, forwarded straight to
Luxor exactly the way Luxor's own shape functions (`circle`, `poly`, ...)
take it:

* `:path` (the default) — add to the current path and do nothing else.
  Use this when you're about to style it yourself (`Luxor.strokepath()`,
  `Luxor.fillpath()`, `Luxor.clip()`, or add more shapes to the same path
  first) or when you're going to reuse the same call with several actions.
* `:stroke`, `:fill`, `:fillstroke` — build the path *and* render it
  immediately, the one-call convenience:

```julia
sethue("steelblue")
path(t; action=:stroke)       # outline only, one call

path(t)                        # action=:path: just builds the path...
Luxor.strokepath()              # ...you render it, same effect
```

For a translucent fill *underneath* a solid outline (a common combination
that used to be its own `fillcolor` keyword on this page in an earlier
version of this interface), just do what you'd do with any Luxor shape —
build the path once, fill it, then stroke a fresh copy:

```julia
sethue("steelblue"); setopacity(0.15)
path(t; action=:fill)
sethue("steelblue"); setopacity(1.0)
path(t; action=:stroke)
```

And for a label, `Luxor.label` (or plain `Luxor.text`) at whatever anchor
point makes sense for that shape — which is almost always a point the
package already gives you a name for, so there's nothing to look up:

```julia
Luxor.label("I", :N, Luxor.Point(incenter(t)...))
Luxor.label("O", :N, Luxor.Point(circumcenter(t)...))
```

## What each type builds

`path(obj; action=:path, kwargs...)` dispatches on the type of `obj`.
Besides `action`, every method also accepts whatever *structural* (not
styling) keywords that curve needs — how far to extend an infinite line,
how finely to sample a curve Luxor has no native primitive for, and so on:

| Type | Adds to the path as | Type-specific keywords |
|:-----|:---------------------|:------------------------|
| `EGPoint` | a small circle | `radius=3` |
| `EGSegment` | a straight line between its two points, or — pass `as=:arrow` — an arrow (see [Arrows](@ref) below) | `as=:plain` (default) |
| `EGLine` | a long finite segment, since the line itself is infinite; `extend=0.0` draws the exact finite segment between `l.p1`/`l.p2` instead | `extend=1000.0`: how far past each defining point; `as=:plain`/`:arrow` |
| `EGRay` | likewise, extended only past `through` (not past `origin`); `extend=0.0` draws the exact finite segment from `origin` to `through` | `extend=1000.0`; `as=:plain`/`:arrow` |
| `EGCircle2` | Luxor's native circle | — |
| any [`EGPolygon`](@ref) | every side, chained end to end into one closed path — a straight line for an `EGSegment` side, a true arc for an `EGCircularArc2` side, an `n`-point sampled polyline for any other conic-arc side (see below); covers `EGTriangle`, `EGQuadrilateral`, `EGStraightNgon`, `EGCircularSector2`, `EGCircularSegment2`, `EGAnnularSector2`, `EGInterstice2`, `EGCurvilinearTriangle2`, `EGCurvilinearQuadrilateral2` and `EGCurvilinearNgon2` — **one** method for the whole family | `n=60` (only matters if some side needs sampling) |
| `EGBoundingBox` | an axis-aligned box | — |
| `EGEllipse2` | a smooth, Bézier-curve ellipse (Luxor's own axis-aligned `ellipse(center, w, h)`, `w = 2a`, `h = 2b`) inside a rotated/translated frame matching `e.center`/`e.angle`, so the path stays a true curve at any zoom level | — |
| `EGParabola2` | Luxor has no native parabola primitive: sampled at `n` points via [`point_on_parabola`](@ref) over the parameter range `srange`, added as an open polyline | `srange=(-100.0, 100.0)`, `n=60` |
| `EGHyperbola2` | likewise (no native primitive), sampled via [`point_on_hyperbola`](@ref) on one branch at a time | `trange=(-2.0, 2.0)`, `n=60`, `branch=1` (pass `branch=-1` and call again for the other branch) |
| `EGCircularArc2` | a true circular arc from `p1` to `p2`, via Luxor's own `arc2r` (Cairo's native arc primitive — not a polygonal approximation) | — |
| `EGEllipticArc2`, `EGParabolicArc2`, `EGHyperbolicArc2` | none of these has a native Cairo primitive either, so each is sampled at `n` points via [`point_on_arc`](@ref) over its own parameter range `[0, 1]` (`arc.p1` to `arc.p2`), added as an open polyline | `n=60` |
| `EGAngle2` | see below — it has no single canonical path | `as=:arc` (default), `radius` |
| `EGVector` | has no position of its own, so it's drawn as the segment `from -> from + v` | `from=EGPoint(0.0, 0.0)`, `as=:plain`/`:arrow` |
| `EGHalfPlane2` | unbounded, so this draws its boundary line only (see `EGLine` above) | `extend=1000.0` |
| `EGStrip2` | likewise unbounded: both boundary lines, one call each | `extend=1000.0` |

Most types default effectively to an outline when you pass `action=:stroke`
(`EGPoint` would need `action=:fill` to actually show up, since an
unfilled single-pixel-radius circle is invisible — but that choice is now
yours to make, same as with any other type).

The single `path(pg::EGPolygon)` method is the direct payoff of building
a real [`EGPolygon`](@ref) hierarchy: it walks `sides(pg)` via the same
`_polygon_walk` [`area`](@ref)/[`perimeter`](@ref) already use, so one
method — not seven, one per concrete type — covers every straight-sided
*and* curved-region shape in the package. The one behavior difference
from a hand-rolled per-vertex path: it always produces a *closed* path (no
`close=false` open-polyline option), since a walked side sequence is
inherently a loop.

**A subtlety worth knowing, inherited from Luxor itself rather than
anything this package adds**: with a non-`:path` action, most of Luxor's
own shape-building functions (`circle`, `poly`, and so the types built on
them here — `EGCircle2`, every `EGPolygon`, `EGEllipse2`) clear the current
path first, so calling one always draws *only* that shape. A few of
Luxor's own primitives don't — `line` (hence `EGSegment`/`EGLine`/`EGRay`
here) and `box` (hence `EGBoundingBox`) add to whatever path is already
there instead. In practice this rarely matters: a prior call with a real
action (`:stroke`, `:fill`, ...) already emptied the path as a side effect
of drawing it, regardless of which behavior the next call has. It only
shows up if you deliberately chain several `path(...; action=:path)` calls
to build one compound shape across multiple types and finish with a single
action on the last call — in that case, a final
`EGSegment`/`EGLine`/`EGRay`/`EGBoundingBox` call correctly includes
everything built so far, while a final `EGCircle2`/`EGPolygon`/etc. call
would silently discard it first.

### Arrows

`EGSegment`/`EGLine`/`EGRay` take `as=:arrow` to draw as an arrow instead
of a plain line, via Luxor's own `arrow`:

```julia
path(EGSegment(EGPoint(-80.0, 0.0), EGPoint(80.0, 0.0)); as=:arrow)

l = EGLine(EGPoint(0.0, -60.0), EGPoint(0.0, 60.0))
path(l; extend=0.0, as=:arrow, arrowheadlength=15)   # extend=0.0: the exact finite segment
```

This is the one case where `path` doesn't just add to the current path:
Luxor's `arrow` always strokes the shaft and fills the arrowhead
immediately, with no deferred form, so `action` is ignored when
`as=:arrow`. Keyword arguments other than `as`/`extend` (`arrowheadlength`,
`arrowheadangle`, `linewidth`, ...) are forwarded straight to `Luxor.arrow`.

### `EGAngle2`: rays, arc, or sector

An `EGAngle2` is genuinely just the space between two rays — but it's
conventionally *drawn* as a small arc, or a filled wedge. `as` picks which:

```julia
ang = EGAngle2(t[2], t[1], t[3])   # the angle at vertex t[2]

path(ang; as=:rays, action=:stroke)   # the literal two half-lines, a-vertex-b
path(ang; as=:arc, action=:stroke)    # the conventional small arc (default)
path(ang; as=:sector, action=:fill)   # closed pie-wedge, for shading
```

`radius` defaults to `0.15` times the shorter of the distances from the
vertex to `ang.a` and `ang.b`, so it looks reasonable at the figure's own
scale without having to think about it — pass it explicitly to override.
`as=:arc` and `as=:sector` are, in fact, nothing more than
`path(EGCircularArc2(...))` and `path(EGCircularSector2(...))` under the
hood (see below) — `EGAngle2` just works out the right circle and
endpoints first.

## Circular arcs, sectors, segments, interstices and curvilinear polygons

[`EGCircularArc2`](@ref), [`EGCircularSector2`](@ref),
[`EGCircularSegment2`](@ref), [`EGAnnularSector2`](@ref) and
[`EGInterstice2`](@ref) (see [Circles](@ref),
[Tangency & Apollonius Problems](@ref)) draw exactly like everything else
— all through the same generic `path(pg::EGPolygon)` method described
above:

```julia
circ = EGCircle2(EGPoint(0.0, 0.0), 30.0)
arc = EGCircularArc2(circ, EGPoint(30.0, 0.0), EGPoint(0.0, 30.0))
path(arc; action=:stroke)

sethue("steelblue"); setopacity(0.4)
path(EGCircularSector2(arc); action=:fill)   # the pie slice
path(EGCircularSegment2(arc); action=:fill)  # the cap cut off by the chord

c1 = EGCircle2(EGPoint(0.0, 0.0), 40.0)
c2 = EGCircle2(EGPoint(90.0, 0.0), 50.0)   # tangent to c1: distance 90 == 40 + 50
c3_center = intersection(EGCircle2(c1.center, c1.r + 35.0), EGCircle2(c2.center, c2.r + 35.0))[1]
c3 = EGCircle2(c3_center, 35.0)            # tangent to both c1 and c2

for gap in interstices(c1, c2, c3)
    sethue("red"); setopacity(0.5)
    path(gap; action=:fill)
end

sethue("purple"); setopacity(0.5)
path(invert(EGTriangle(EGPoint(50.0, 20.0), EGPoint(90.0, 30.0), EGPoint(60.0, 80.0)), EGPoint(0.0, 0.0)); action=:fill)
```

Every curved side here is built from Luxor's own `arc2r`/`carc2r` (Cairo's
native circular-arc path primitive, driven by a center and the two
endpoints) — never a sampled polyline standing in for the arc, the way
`EGParabola2`/`EGHyperbola2` above have to (Luxor has no native primitive
for *those* curves, so sampling is the only option there).

## Elliptic, parabolic and hyperbolic arcs

[`EGEllipticArc2`](@ref), `EGParabolicArc2`, `EGHyperbolicArc2` (see
[Conics: Ellipse, Parabola & Hyperbola](@ref)) draw the same way as
`EGCircularArc2`, just sampled rather than a native Cairo primitive (like
`EGParabola2`/`EGHyperbola2` themselves):

```julia
e = EGEllipse2(EGPoint(0.0, 0.0), 40.0, 20.0, pi / 6)
earc = EGEllipticArc2(e, point_on_ellipse(e, 0.2), point_on_ellipse(e, 2.0))
path(earc; action=:stroke)
```

They can also turn up as a *side* of a curvilinear region — not from
building one directly (there's no `EGEllipticSector2`), but as the result
of an [`EGAffineMap`](@ref) applied to a circular-arc region, since a
non-conformal map turns a circular arc elliptic:

```julia
sec = EGCircularSector2(EGCircularArc2(EGCircle2(EGPoint(0.0, 0.0), 30.0), EGPoint(30.0, 0.0), EGPoint(0.0, 30.0)))
skew = EGAffineMap(1.3, 0.4, -0.2, 0.9, 0.0, 0.0)
path(skew(sec); action=:stroke)   # an EGCurvilinearTriangle2 with one elliptic-arc side
```

`path(::EGPolygon)` handles this transparently — a side is drawn with
`arc2r` if it's an `EGCircularArc2`, or sampled at `n` points (the same
`n` `path` itself takes) if it's any of the other three arc types.

## Worked example: the package logo

![EuclideanGeometry.jl logo](assets/logo.svg)

The logo is a **Steiner chain**: `K1` and `K2` are two circles internally
tangent to a big circle `K` (and externally tangent to each other), and the
chain is every further circle also tangent to both `K` and `K2`, each one
also tangent to the previous. Rather than re-solving the 3-circle
Apollonius problem (up to 8 candidate solutions) at every step of the
chain, this inverts about the point where `K` and `K2` touch: both become
**parallel lines**, and in that inverted picture the whole chain collapses
to a trivial row of *equal* circles translated along them — invert each
one back and the real, naturally-shrinking chain falls out, one
[`invert`](@ref) per new circle instead of a full Apollonius solve.
`delta_r` then perturbs each circle's own already-inverted (real-space)
radius by a constant amount before it's kept — a negative value shrinks
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
using EuclideanGeometry
using Luxor: Drawing, origin, sethue, finish
import Luxor

delta_r = -2.0    # subtracted from each circle's own real-space radius
r_min = 0.01      # stops the chain once that radius is no longer usable
max_circles = 100

A = polar_point_deg(100.0, 270.0, EGPoint(0.0, 0.0))
B = polar_point_deg(100.0, 30.0, EGPoint(0.0, 0.0))
diametro = distance(A, B)
K1 = EGCircle2(A, diametro / 2)
K2 = EGCircle2(B, diametro / 2)
K = EGCircle2(EGPoint(0.0, 0.0), 100.0 + diametro / 2)

T = K.center + K.r * (K2.center - K.center) / distance(K.center, K2.center)
k_inv = diametro
u = direction(invert(K, T; k=k_inv))
u = u / norm(u)

prev_inv = invert(K1, T; k=k_inv)
step = 2 * prev_inv.r

V = [EGCircle2(K1.center, K1.r + delta_r)]
for _ in 1:max_circles
    global prev_inv
    prev_inv = EGCircle2(prev_inv.center + step * u, prev_inv.r)
    real_circle = invert(prev_inv, T; k=k_inv)
    r = real_circle.r + delta_r
    r <= r_min && break
    push!(V, EGCircle2(real_circle.center, r))
end

V = reflection.(V, Ref(EGLine(K.center, A)))

Drawing(400, 400, "logo.svg")
origin()

colors = (Luxor.julia_green, Luxor.julia_purple, Luxor.julia_red)
for (i, color) in enumerate(colors)
    sethue(color)
    path.(rotate.(V, deg2rad((i - 1) * 120)); action=:fill)
end

finish()
```

## Name collisions with Luxor

Every EG-prefixed *type* in this package (`EGPoint`, `EGCircle2`,
`EGBoundingBox`, ...) is safe to use unqualified alongside Luxor, precisely
because the `EG` prefix keeps it out of Luxor's own namespace. What still
collides is a handful of *function* names both packages independently
export: `midpoint`, `distance` and `rotate`. Plain `using EuclideanGeometry,
Luxor` still works (that's exactly what every example on this page does),
but calling any of those three names *unqualified* is ambiguous and throws
an `UndefVarError` pointing out the clash, rather than silently picking
one:

```julia
julia> using EuclideanGeometry, Luxor

julia> midpoint(EGPoint(0.0, 0.0), EGPoint(4.0, 4.0))
ERROR: UndefVarError: `midpoint` not defined in `Main`
Hint: It looks like two or more modules export different bindings with this name, resulting in ambiguity. Try explicitly importing it from a particular module, or qualifying the name with the module it should come from.
Hint: a global variable of this name also exists in EuclideanGeometry.
Hint: a global variable of this name also exists in Luxor.
```

Two ways to resolve it, depending on which package's version you mean at
that call site:

* Qualify it explicitly: `EuclideanGeometry.midpoint(...)` or
  `Luxor.rotate(...)`.
* In your own scripts (not needed just to follow this page), prefer
  `using EuclideanGeometry` together with `import Luxor` instead of
  `using Luxor` — then only `EuclideanGeometry`'s bindings are unqualified,
  and every Luxor call is written as `Luxor.something`, which sidesteps
  the ambiguity entirely rather than resolving it case by case. This is
  the convention this package's own test suite uses internally.
* Or the other way around: plain `using EuclideanGeometry` (every one of
  its names unqualified, colliding or not), plus `using Luxor: f1, f2, ...`
  naming only the handful of Luxor functions actually called, instead of
  blanket `using Luxor` — since `distance`/`rotate` are then never brought
  in from Luxor at all, there's no collision left to resolve. Add a plain
  `import Luxor` alongside so `Luxor.something` (e.g. `Luxor.julia_green`)
  still works for anything not explicitly named. This is what the logo
  example above does: `using Luxor: Drawing, origin, sethue, finish` for
  the few Luxor calls it makes, `EuclideanGeometry` dominant and
  unqualified everywhere else.
