module ApolloniusLuxorExt
using Apollonius
using Luxor
const AP = Apollonius
_lp(p::AP.APPoint) = Luxor.Point(Float64(p[1]), Float64(p[2]))
_lp(pts::AbstractVector{<:AP.APPoint}) = _lp.(pts)
_arrow(p1, p2; kwargs...) =
    haskey(kwargs, :linewidth) ? Luxor.arrow(p1, p2; kwargs...) : Luxor.arrow(p1, p2; linewidth=Luxor.getline(), kwargs...)
"""
    label(txt::AbstractString, alignment::Symbol, p::APPoint; kwargs...)
    label(txt::AbstractString, direction::Real, p::APPoint; kwargs...)

Luxor's own `label`, accepting an `APPoint` directly instead of requiring
a `Luxor.Point` (`kwargs` -- `offset`, `leader`, `leaderoffsets` -- are
forwarded straight through).
"""
Luxor.label(txt::AbstractString, alignment::Symbol, p::AP.APPoint; kwargs...) = Luxor.label(txt, alignment, _lp(p); kwargs...)
Luxor.label(txt::AbstractString, direction::Real, p::AP.APPoint; kwargs...) = Luxor.label(txt, direction, _lp(p); kwargs...)
"""
    path(p::APPoint; radius=3, action=:path)

`p` as a small circle of the given `radius`.
"""
AP.path(p::AP.APPoint; radius=3, action=:path) = Luxor.circle(_lp(p), radius, action)
"""
    path(v::APVector, from::APPoint=APPoint(0.0, 0.0); as=:plain, action=:path, kwargs...)

`APVector` has no position of its own, so it's drawn as the segment
`from -> from + v` (`from` defaults to the origin). `as=:arrow` draws it
as an arrow instead -- see [`path(::APSegment)`](@ref) for what that
changes.
"""
function AP.path(v::AP.APVector, from::AP.APPoint=AP.APPoint(0.0, 0.0); as::Symbol=:plain, action=:path, kwargs...)
    as == :arrow && return _arrow(_lp(from), _lp(from + v); kwargs...)
    return Luxor.line(_lp(from), _lp(from + v), action)
end
"""
    path(ev::APEquipollentVector; as=:plain, action=:path, kwargs...)

Draws the segment `ev.point -> tip(ev)` -- the [`APEquipollentVector`](@ref)
analogue of `path(::APVector, ::APPoint)` above, with the point of
application already built into the value instead of a separate `from`
argument (and, unlike a bare `APVector`, correctly scaled/placed by
`@to_luxor_picture` beforehand, since this type has a real
`APBoundingBox`). `as=:arrow` draws it as an arrow instead.
"""
function AP.path(ev::AP.APEquipollentVector; as::Symbol=:plain, action=:path, kwargs...)
    as == :arrow && return _arrow(_lp(ev.point), _lp(AP.tip(ev)); kwargs...)
    return Luxor.line(_lp(ev.point), _lp(AP.tip(ev)), action)
end
"""
    path(s::APSegment; as=:plain, action=:path, kwargs...)

`as=:arrow` draws `s.p1 -> s.p2` as an arrow via Luxor's own `arrow`
instead of a plain line. Unlike every other `path` method, this one
special case draws immediately (stroke plus an arrowhead fill) rather
than just adding to the current path -- Luxor's `arrow` has no deferred
form, so `action` is ignored when `as=:arrow`. `kwargs`
(`arrowheadlength`, `arrowheadangle`, `linewidth`, ...) are forwarded
straight to `Luxor.arrow` in that case; unlike calling `Luxor.arrow`
directly, `linewidth` here defaults to the currently active `setline()`
width (Luxor's own default is a flat `1.0`, ignoring `setline()`
entirely -- see `Luxor.arrow`'s own docstring), so switching a shape from
`as=:plain` to `as=:arrow` doesn't silently thin its line. Pass
`linewidth=...` explicitly to override that.
"""
function AP.path(s::AP.APSegment; as::Symbol=:plain, action=:path, kwargs...)
    as == :arrow && return _arrow(_lp(s.p1), _lp(s.p2); kwargs...)
    return Luxor.line(_lp(s.p1), _lp(s.p2), action)
end
"""
    path(l::APLine; extend=1000.0, as=:plain, action=:path, kwargs...)

`APLine` is infinite, so it's added as a long finite segment: `extend`
units past each of `l.p1`/`l.p2` along its direction. Pass `extend=0.0`
to instead draw the exact finite segment between `l.p1` and `l.p2` (the
two points that happen to define `l`, with nothing added past them).

`extend` can also be a 2-tuple `(past_p1, past_p2)` to extend each end by
a different amount -- e.g. `extend=(0.0, 50.0)` draws from `l.p1` itself
(nothing added there) to 50 units past `l.p2`. A bare number is short for
`(extend, extend)`, extending both ends equally, same as before.

`as=:arrow` draws it as an arrow instead -- see
[`path(::APSegment)`](@ref) for what that changes.
"""
function AP.path(l::AP.APLine; extend::Union{Real,Tuple{Real,Real}}=1000.0, as::Symbol=:plain, action=:path, kwargs...)
    past_p1, past_p2 = extend isa Tuple ? extend : (extend, extend)
    u = AP.direction(l) / AP.norm(AP.direction(l))
    p1, p2 = l.p1 - past_p1 * u, l.p2 + past_p2 * u
    as == :arrow && return _arrow(_lp(p1), _lp(p2); kwargs...)
    return Luxor.line(_lp(p1), _lp(p2), action)
end
"""
    path(r::APRay; extend=1000.0, as=:plain, action=:path, kwargs...)

`APRay` is half-infinite, so it's added from `r.origin` to `extend` units
past `r.through`. Pass `extend=0.0` to instead draw the exact finite
segment from `r.origin` to `r.through`. `as=:arrow` draws it as an arrow
instead -- see [`path(::APSegment)`](@ref) for what that changes.
"""
function AP.path(r::AP.APRay; extend=1000.0, as::Symbol=:plain, action=:path, kwargs...)
    u = AP.direction(r) / AP.norm(AP.direction(r))
    p2 = r.through + extend * u
    as == :arrow && return _arrow(_lp(r.origin), _lp(p2); kwargs...)
    return Luxor.line(_lp(r.origin), _lp(p2), action)
end
"""
    path(hp::APHalfPlane2; extend=1000.0, action=:path)

`APHalfPlane2` is an unbounded region, so there's no finite shape to add
to the path -- this draws its boundary line instead (see
[`path(::APLine)`](@ref)), the same way an infinite `APLine` itself is
drawn.
"""
AP.path(hp::AP.APHalfPlane2; extend=1000.0, action=:path) = AP.path(hp.boundary; extend=extend, action=action)
"""
    path(s::APStrip2; extend=1000.0, action=:path)

`APStrip2` is likewise unbounded, so this draws both of its boundary
lines (see [`path(::APLine)`](@ref)), one call each -- there's no way to
add two disjoint lines as a single Luxor path action, so `action` is
applied to each independently rather than to the pair as a whole.
"""
function AP.path(s::AP.APStrip2; extend=1000.0, action=:path)
    AP.path(s.line1; extend=extend, action=action)
    AP.path(s.line2; extend=extend, action=action)
end
"""
    path(c::APCircle2; action=:path)
"""
AP.path(c::AP.APCircle2; action=:path) = Luxor.circle(_lp(c.center), c.r, action)
"""
    path(bb::APBoundingBox; action=:path)
"""
AP.path(bb::AP.APBoundingBox; action=:path) = Luxor.box(_lp(bb.min), _lp(bb.max), action)
"""
    path(e::APEllipse2; action=:path)

Uses Luxor's axis-aligned, Bézier-curve `ellipse(centerpoint, w, h)`
inside a rotated/translated frame (`gsave`/`translate`/`rotate`/`grestore`)
matching `e.center`/`e.angle`, so the rendered path stays a true curve at
any zoom level.
"""
function AP.path(e::AP.APEllipse2; action=:path)
    action != :path && Luxor.newpath()
    Luxor.gsave()
    Luxor.translate(_lp(e.center))
    Luxor.rotate(e.angle)
    Luxor.ellipse(Luxor.O, 2 * e.a, 2 * e.b; action=:path)
    Luxor.grestore()
    Luxor.do_action(action)
end
"""
    path(par::APParabola2; srange=(-100.0, 100.0), n=60, action=:path)

Luxor has no native parabola primitive, so this samples `n` points via
[`point_on_parabola`](@ref) over `srange` and adds them as an open polyline.
"""
function AP.path(par::AP.APParabola2; srange=(-100.0, 100.0), n=60, action=:path)
    pts = [_lp(AP.point_on_parabola(par, s)) for s in range(srange[1], srange[2]; length=n)]
    Luxor.poly(pts, action; close=false)
end
"""
    path(h::APHyperbola2; trange=(-2.0, 2.0), n=60, branch=1, action=:path)

Luxor has no native hyperbola primitive, so this samples `n` points via
[`point_on_hyperbola`](@ref) on the given `branch` over `trange` and adds
them as an open polyline. Call twice (`branch=1` and `branch=-1`) for both
branches.
"""
function AP.path(h::AP.APHyperbola2; trange=(-2.0, 2.0), n=60, branch::Int=1, action=:path)
    pts = [_lp(AP.point_on_hyperbola(h, t; branch=branch)) for t in range(trange[1], trange[2]; length=n)]
    Luxor.poly(pts, action; close=false)
end
"""
    path(ang::APAngle2; as=:arc, radius=nothing, action=:path)

An `APAngle2` doesn't have a single canonical path -- it's genuinely the
space between two rays, but is conventionally *drawn* as a small arc (or a
filled wedge). `as` picks which:

  - `:rays` (open polyline `a -> vertex -> b`, the literal two half-lines
    that bound the angle, each extended `radius` units from the vertex)
  - `:arc` (default; a circular arc of the given `radius`, centered at the
    vertex, swept from `ang.a` to `ang.b` -- the conventional angle marker)
  - `:sector` (closed pie-wedge: vertex, out to the arc, around it, and
    back -- handy for `action=:fill` to shade the angle's interior)
  - `:rarc` (open polyline `pa -> pc -> pb`, generalizing the little
    square used to mark a *right* angle to any angle: `pa`/`pb` are the
    points at distance `radius` along each ray, and `pc = pa + pb -
    vertex` completes the parallelogram `vertex, pa, pc, pb` by the
    parallelogram law. At exactly 90° this parallelogram is the familiar
    square corner marker; at any other angle it's a rhombus (both `pa`/`pb`
    are `radius` from the vertex), tracing the same idea)
  - `:rsector` (closed version of `:rarc`: the whole parallelogram
    `vertex, pa, pc, pb` -- handy for `action=:fill`, the same relationship
    `:sector` has to `:arc`)

`radius` defaults to `0.15` times the shorter of `distance(vertex, a)` and
`distance(vertex, b)`, so it looks reasonable at the triangle/figure's own
scale without having to think about it.
"""
function AP.path(ang::AP.APAngle2; as::Symbol=:arc, radius=nothing, action=:path)
    vertex, a, b = ang.vertex, ang.a, ang.b
    r = radius === nothing ? 0.15 * min(AP.distance(vertex, a), AP.distance(vertex, b)) : radius
    if as == :rays
        ua = (a - vertex) / AP.norm(a - vertex)
        ub = (b - vertex) / AP.norm(b - vertex)
        return Luxor.poly(_lp([vertex + r * ua, vertex, vertex + r * ub]), action; close=false)
    end
    pa = vertex + r * (a - vertex) / AP.norm(a - vertex)
    pb = vertex + r * (b - vertex) / AP.norm(b - vertex)
    if as == :rarc
        pc = pa + (pb - vertex)
        return Luxor.poly(_lp([pa, pc, pb]), action; close=false)
    elseif as == :rsector
        pc = pa + (pb - vertex)
        return Luxor.poly(_lp([vertex, pa, pc, pb]), action; close=true)
    end
    arc = AP.APCircularArc2(AP.APCircle2(vertex, r), pa, pb)
    if as == :arc
        return AP.path(arc; action=action)
    elseif as == :sector
        return AP.path(AP.APCircularSector2(arc); action=action)
    else
        throw(ArgumentError("path(::APAngle2): as must be :rays, :arc, :sector, :rarc or :rsector, got $(repr(as))"))
    end
end
"""
    path(arc::APCircularArc2; action=:path)

A true circular arc from `arc.p1` to `arc.p2`, via Luxor's own `arc2r`
(center + the two endpoints -- no separate angle bookkeeping needed, and no
polygonal approximation: this draws with Cairo's native arc primitive).
"""
function AP.path(arc::AP.APCircularArc2; action=:path)
    action != :path && Luxor.newpath()
    Luxor.move(_lp(arc.p1))
    Luxor.arc2r(_lp(arc.circle.center), _lp(arc.p1), _lp(arc.p2))
    Luxor.do_action(action)
end
"""
    path(arc::APEllipticArc2; n=60, action=:path)
    path(arc::APParabolicArc2; n=60, action=:path)
    path(arc::APHyperbolicArc2; n=60, action=:path)

Luxor has no native primitive for a partial arc of an ellipse, parabola
or hyperbola, so each is added as an `n`-point open polyline, sampled via
[`point_on_arc`](@ref) over the arc's own parameter range `[0, 1]`
(`arc.p1` to `arc.p2`).
"""
function AP.path(arc::Union{AP.APEllipticArc2,AP.APParabolicArc2,AP.APHyperbolicArc2}; n=60, action=:path)
    pts = [_lp(AP.point_on_arc(arc, t)) for t in range(0.0, 1.0; length=n)]
    Luxor.poly(pts, action; close=false)
end
"""
    path(curve::APParametricCurve2; n=60, action=:path)

Luxor has no native primitive for an arbitrary parametrized curve, so
it's added as an `n`-point open polyline, sampled via
[`point_on_curve`](@ref) over `curve.trange` -- same idea as the sampled
conic-arc types above.
"""
function AP.path(curve::AP.APParametricCurve2; n=60, action=:path)
    pts = [_lp(AP.point_on_curve(curve, t)) for t in range(curve.trange[1], curve.trange[2]; length=n)]
    Luxor.poly(pts, action; close=false)
end
"""
    path(pl::APPolyline2; action=:path)

An open chain of straight sides: one polyline through `pl`'s vertices in
order (never closed, unlike an [`APStraightNgon`](@ref)).
"""
function AP.path(pl::AP.APPolyline2; action=:path)
    Luxor.poly([_lp(p) for p in pl.vertices], action; close=false)
end
"""
    path(pg::APCurvilinearPolyline2; n=60, action=:path)

An open chain of straight and curved sides, in the order given (each side
already starts where the previous one ends): a straight line for an
`APSegment` side, a true arc for an `APCircularArc2` side, and an
`n`-point sampled polyline for any other conic-arc side.
"""
function AP.path(pg::AP.APCurvilinearPolyline2; n=60, action=:path)
    action != :path && Luxor.newpath()
    Luxor.move(_lp(AP._side_p1(pg.sides[1])))
    for side in pg.sides
        if side isa AP.APSegment
            Luxor.line(_lp(side.p2))
        else
            _add_arc!(side, false; n=n)
        end
    end
    Luxor.do_action(action)
end
function _add_arc!(arc::AP.APCircularArc2, reversed::Bool; n=60)
    c = _lp(arc.circle.center)
    reversed ? Luxor.carc2r(c, _lp(arc.p2), _lp(arc.p1)) : Luxor.arc2r(c, _lp(arc.p1), _lp(arc.p2))
end
function _add_arc!(arc::Union{AP.APEllipticArc2,AP.APParabolicArc2,AP.APHyperbolicArc2}, reversed::Bool; n=60)
    ts = reversed ? range(1.0, 0.0; length=n) : range(0.0, 1.0; length=n)
    for t in ts
        Luxor.line(_lp(AP.point_on_arc(arc, t)))
    end
end
"""
    path(pg::APPolygon; n=60, action=:path)

Traces every side of `pg` end to end into a single closed path -- an
`APSegment` side contributes a straight line, an `APCircularArc2` side a
true arc (see [`path(::APCircularArc2)`](@ref)), and any other conic-arc
side (`APEllipticArc2`/`APParabolicArc2`/`APHyperbolicArc2` -- possible
after an [`APAffineMap`](@ref), which can turn a circular-arc side
elliptic) an `n`-point sampled polyline, same as their own standalone
`path` method. Sides are walked in whichever direction continues from the
previous one's last point (via `_polygon_walk`, the same walk
`area`/`perimeter` use), so this one method covers the entire polygon
family -- `APTriangle`, `APQuadrilateral`, `APStraightNgon`, and every
curved-region type (`APCircularSector2`, `APCircularSegment2`,
`APAnnularSector2`, `APInterstice2`, `APCurvilinearTriangle2`,
`APCurvilinearQuadrilateral2`, `APCurvilinearNgon2`).
"""
function AP.path(pg::AP.APPolygon; n=60, action=:path)
    action != :path && Luxor.newpath()
    order = AP._polygon_walk(AP.sides(pg))
    first_side, first_reversed = order[1]
    start_pt = first_reversed ? AP._side_p2(first_side) : AP._side_p1(first_side)
    Luxor.move(_lp(start_pt))
    for (side, reversed) in order
        if side isa AP.APSegment
            Luxor.line(_lp(reversed ? side.p1 : side.p2))
        else
            _add_arc!(side, reversed; n=n)
        end
    end
    Luxor.closepath()
    Luxor.do_action(action)
end
"""
    path(v::AbstractArray{<:APObject}; kwargs...)
    path(v::Tuple{Vararg{<:APObject}}; kwargs...)

`path` for each element of `v` in turn, with the same `kwargs` every time.
This is what lets a plain `Vector` -- what `intersection`/`tangent_points`
return, since they can give 0, 1 or 2 points depending on the geometry --
get drawn directly as a single argument, without unwrapping it by hand
first. Any shape works, not just a `Vector`: a `Tuple` (e.g.
`vertices(::APTriangle)`, which isn't a `Vector`) or a `Matrix` (e.g.
`[ext_lines int_lines]`, hcat-ing two tangent-line pairs together) are
both just iterated over in the order Julia already iterates them in --
reshape/flatten it yourself first if a specific order matters.

It also calls `Luxor.newsubpath()` before each element, so `path(v)` is
the safe way to batch several elements into *one* combined path with the
default `action=:path` (e.g. to `fillpreserve()` then `strokepath()` once
for all of them) -- without it, Cairo's own circle/arc primitives connect
to wherever the current path left off with a stray straight line, a
well-known Cairo gotcha whenever a new arc starts without its own fresh
subpath.

**`path(v)` is *not* the same as `path.(v)`** (with the dot): broadcasting
calls the scalar `path` method on each element directly and never reaches
this method at all, so it gets none of the `newsubpath()` handling above.
For an immediately-rendering action (`:stroke`, `:fill`, `:fillstroke`)
the two happen to look identical, since each element renders and clears
on its own regardless -- but for the default `action=:path`, only `path(v)`
batches safely; `path.(v)` (or a hand-written loop without `newsubpath()`)
reproduces the stray-line bug this method exists to avoid.
"""
function AP.path(v::Union{AbstractArray{<:AP.APObject},NTuple{N,<:AP.APObject} where N}; kwargs...)
    for x in v
        Luxor.newsubpath()
        AP.path(x; kwargs...)
    end
end
function AP.current_path_bbox()
    x1, y1, x2, y2 = Luxor.path_extents(Luxor.currentdrawing().cr)
    return AP.APBoundingBox(AP.APPoint(x1, y1), AP.APPoint(x2, y2))
end
end
