# -------------------------------------------------------------------------
# Package extension: a `path` method for every EuclideanGeometry type,
# implemented with Luxor.jl. This file only loads when both
# EuclideanGeometry and Luxor are loaded in the same session (Julia's
# weak-dependency mechanism, Project.toml's [weakdeps]/[extensions]) — so
# EuclideanGeometry itself never depends on Luxor.
#
# Luxor has its own `Luxor.Point` and doesn't accept `EGPoint` directly, so
# every method here goes through `_lp` to convert.
#
# Deliberately thin: every method just adds `obj` to Luxor's current path
# (via Luxor's own primitives) and takes an `action` keyword (`:path` by
# default) forwarded straight to Luxor — nothing here ever calls `sethue`,
# sets an opacity, or draws a label. Color, fill and labels are exactly
# what Luxor's own `sethue`/`setopacity`/`label` already do well; wrapping
# them would just be a second, redundant vocabulary to learn.
#
# `path(pg::EGPolygon)` is a single generic method covering the ENTIRE
# polygon family — straight (EGTriangle/EGQuadrilateral/EGStraightNgon) and
# curved (EGCircularSector2/EGCircularSegment2/EGAnnularSector2/
# EGInterstice2/EGCurvilinearTriangle2/EGCurvilinearQuadrilateral2/
# EGCurvilinearNgon2) alike — by walking `sides(pg)` via the same
# `_polygon_walk` the package's own `area`/`perimeter` already use. This is
# the direct payoff of the EG type hierarchy: one method, not one per
# concrete type. The path is always closed (no `close=false` open-polyline
# option), since a walked side sequence is inherently a loop.
# -------------------------------------------------------------------------

module EuclideanGeometryLuxorExt

using EuclideanGeometry
using Luxor

const EG = EuclideanGeometry

_lp(p::EG.EGPoint) = Luxor.Point(Float64(p[1]), Float64(p[2]))
_lp(pts::AbstractVector{<:EG.EGPoint}) = _lp.(pts)

"""
    label(txt::AbstractString, alignment::Symbol, p::EGPoint; kwargs...)
    label(txt::AbstractString, direction::Real, p::EGPoint; kwargs...)

Luxor's own `label`, accepting an `EGPoint` directly instead of requiring
a `Luxor.Point` (`kwargs` -- `offset`, `leader`, `leaderoffsets` -- are
forwarded straight through).
"""
Luxor.label(txt::AbstractString, alignment::Symbol, p::EG.EGPoint; kwargs...) = Luxor.label(txt, alignment, _lp(p); kwargs...)
Luxor.label(txt::AbstractString, direction::Real, p::EG.EGPoint; kwargs...) = Luxor.label(txt, direction, _lp(p); kwargs...)

"""
    path(p::EGPoint; radius=3, action=:path)

`p` as a small circle of the given `radius`.
"""
EG.path(p::EG.EGPoint; radius=3, action=:path) = Luxor.circle(_lp(p), radius, action)

"""
    path(v::EGVector, from::EGPoint=EGPoint(0.0, 0.0); as=:plain, action=:path, kwargs...)

`EGVector` has no position of its own, so it's drawn as the segment
`from -> from + v` (`from` defaults to the origin). `as=:arrow` draws it
as an arrow instead — see [`path(::EGSegment)`](@ref) for what that
changes.
"""
function EG.path(v::EG.EGVector, from::EG.EGPoint=EG.EGPoint(0.0, 0.0); as::Symbol=:plain, action=:path, kwargs...)
    as == :arrow && return Luxor.arrow(_lp(from), _lp(from + v); kwargs...)
    return Luxor.line(_lp(from), _lp(from + v), action)
end

"""
    path(s::EGSegment; as=:plain, action=:path, kwargs...)

`as=:arrow` draws `s.p1 -> s.p2` as an arrow via Luxor's own `arrow`
instead of a plain line. Unlike every other `path` method, this one
special case draws immediately (stroke plus an arrowhead fill) rather
than just adding to the current path — Luxor's `arrow` has no deferred
form, so `action` is ignored when `as=:arrow`. `kwargs`
(`arrowheadlength`, `arrowheadangle`, `linewidth`, ...) are forwarded
straight to `Luxor.arrow` in that case.
"""
function EG.path(s::EG.EGSegment; as::Symbol=:plain, action=:path, kwargs...)
    as == :arrow && return Luxor.arrow(_lp(s.p1), _lp(s.p2); kwargs...)
    return Luxor.line(_lp(s.p1), _lp(s.p2), action)
end

"""
    path(l::EGLine; extend=1000.0, as=:plain, action=:path, kwargs...)

`EGLine` is infinite, so it's added as a long finite segment: `extend`
units past each of `l.p1`/`l.p2` along its direction. Pass `extend=0.0`
to instead draw the exact finite segment between `l.p1` and `l.p2` (the
two points that happen to define `l`, with nothing added past them).

`extend` can also be a 2-tuple `(past_p1, past_p2)` to extend each end by
a different amount — e.g. `extend=(0.0, 50.0)` draws from `l.p1` itself
(nothing added there) to 50 units past `l.p2`. A bare number is short for
`(extend, extend)`, extending both ends equally, same as before.

`as=:arrow` draws it as an arrow instead — see
[`path(::EGSegment)`](@ref) for what that changes.
"""
function EG.path(l::EG.EGLine; extend::Union{Real,Tuple{Real,Real}}=1000.0, as::Symbol=:plain, action=:path, kwargs...)
    past_p1, past_p2 = extend isa Tuple ? extend : (extend, extend)
    u = EG.direction(l) / EG.norm(EG.direction(l))
    p1, p2 = l.p1 - past_p1 * u, l.p2 + past_p2 * u
    as == :arrow && return Luxor.arrow(_lp(p1), _lp(p2); kwargs...)
    return Luxor.line(_lp(p1), _lp(p2), action)
end

"""
    path(r::EGRay; extend=1000.0, as=:plain, action=:path, kwargs...)

`EGRay` is half-infinite, so it's added from `r.origin` to `extend` units
past `r.through`. Pass `extend=0.0` to instead draw the exact finite
segment from `r.origin` to `r.through`. `as=:arrow` draws it as an arrow
instead — see [`path(::EGSegment)`](@ref) for what that changes.
"""
function EG.path(r::EG.EGRay; extend=1000.0, as::Symbol=:plain, action=:path, kwargs...)
    u = EG.direction(r) / EG.norm(EG.direction(r))
    p2 = r.through + extend * u
    as == :arrow && return Luxor.arrow(_lp(r.origin), _lp(p2); kwargs...)
    return Luxor.line(_lp(r.origin), _lp(p2), action)
end

"""
    path(hp::EGHalfPlane2; extend=1000.0, action=:path)

`EGHalfPlane2` is an unbounded region, so there's no finite shape to add
to the path — this draws its boundary line instead (see
[`path(::EGLine)`](@ref)), the same way an infinite `EGLine` itself is
drawn.
"""
EG.path(hp::EG.EGHalfPlane2; extend=1000.0, action=:path) = EG.path(hp.boundary; extend=extend, action=action)

"""
    path(s::EGStrip2; extend=1000.0, action=:path)

`EGStrip2` is likewise unbounded, so this draws both of its boundary
lines (see [`path(::EGLine)`](@ref)), one call each — there's no way to
add two disjoint lines as a single Luxor path action, so `action` is
applied to each independently rather than to the pair as a whole.
"""
function EG.path(s::EG.EGStrip2; extend=1000.0, action=:path)
    EG.path(s.line1; extend=extend, action=action)
    EG.path(s.line2; extend=extend, action=action)
end

"""
    path(c::EGCircle2; action=:path)
"""
EG.path(c::EG.EGCircle2; action=:path) = Luxor.circle(_lp(c.center), c.r, action)

"""
    path(bb::EGBoundingBox; action=:path)
"""
EG.path(bb::EG.EGBoundingBox; action=:path) = Luxor.box(_lp(bb.min), _lp(bb.max), action)

"""
    path(e::EGEllipse2; action=:path)

Uses Luxor's axis-aligned, Bézier-curve `ellipse(centerpoint, w, h)`
inside a rotated/translated frame (`gsave`/`translate`/`rotate`/`grestore`)
matching `e.center`/`e.angle`, so the rendered path stays a true curve at
any zoom level.
"""
function EG.path(e::EG.EGEllipse2; action=:path)
    action != :path && Luxor.newpath()
    Luxor.gsave()
    Luxor.translate(_lp(e.center))
    Luxor.rotate(e.angle)
    Luxor.ellipse(Luxor.O, 2 * e.a, 2 * e.b; action=:path)
    Luxor.grestore()
    Luxor.do_action(action)
end

"""
    path(par::EGParabola2; srange=(-100.0, 100.0), n=60, action=:path)

Luxor has no native parabola primitive, so this samples `n` points via
[`point_on_parabola`](@ref) over `srange` and adds them as an open polyline.
"""
function EG.path(par::EG.EGParabola2; srange=(-100.0, 100.0), n=60, action=:path)
    pts = [_lp(EG.point_on_parabola(par, s)) for s in range(srange[1], srange[2]; length=n)]
    Luxor.poly(pts, action; close=false)
end

"""
    path(h::EGHyperbola2; trange=(-2.0, 2.0), n=60, branch=1, action=:path)

Luxor has no native hyperbola primitive, so this samples `n` points via
[`point_on_hyperbola`](@ref) on the given `branch` over `trange` and adds
them as an open polyline. Call twice (`branch=1` and `branch=-1`) for both
branches.
"""
function EG.path(h::EG.EGHyperbola2; trange=(-2.0, 2.0), n=60, branch::Int=1, action=:path)
    pts = [_lp(EG.point_on_hyperbola(h, t; branch=branch)) for t in range(trange[1], trange[2]; length=n)]
    Luxor.poly(pts, action; close=false)
end

"""
    path(ang::EGAngle2; as=:arc, radius=nothing, action=:path)

An `EGAngle2` doesn't have a single canonical path — it's genuinely the
space between two rays, but is conventionally *drawn* as a small arc (or a
filled wedge). `as` picks which:

  - `:rays` (open polyline `a -> vertex -> b`, the literal two half-lines
    that bound the angle, each extended `radius` units from the vertex)
  - `:arc` (default; a circular arc of the given `radius`, centered at the
    vertex, swept from `ang.a` to `ang.b` — the conventional angle marker)
  - `:sector` (closed pie-wedge: vertex, out to the arc, around it, and
    back — handy for `action=:fill` to shade the angle's interior)
  - `:rarc` (open polyline `pa -> pc -> pb`, generalizing the little
    square used to mark a *right* angle to any angle: `pa`/`pb` are the
    points at distance `radius` along each ray, and `pc = pa + pb -
    vertex` completes the parallelogram `vertex, pa, pc, pb` by the
    parallelogram law. At exactly 90° this parallelogram is the familiar
    square corner marker; at any other angle it's a rhombus (both `pa`/`pb`
    are `radius` from the vertex), tracing the same idea)
  - `:rsector` (closed version of `:rarc`: the whole parallelogram
    `vertex, pa, pc, pb` — handy for `action=:fill`, the same relationship
    `:sector` has to `:arc`)

`radius` defaults to `0.15` times the shorter of `distance(vertex, a)` and
`distance(vertex, b)`, so it looks reasonable at the triangle/figure's own
scale without having to think about it.
"""
function EG.path(ang::EG.EGAngle2; as::Symbol=:arc, radius=nothing, action=:path)
    vertex, a, b = ang.vertex, ang.a, ang.b
    r = radius === nothing ? 0.15 * min(EG.distance(vertex, a), EG.distance(vertex, b)) : radius
    if as == :rays
        ua = (a - vertex) / EG.norm(a - vertex)
        ub = (b - vertex) / EG.norm(b - vertex)
        return Luxor.poly(_lp([vertex + r * ua, vertex, vertex + r * ub]), action; close=false)
    end
    pa = vertex + r * (a - vertex) / EG.norm(a - vertex)
    pb = vertex + r * (b - vertex) / EG.norm(b - vertex)
    if as == :rarc
        pc = pa + pb - vertex
        return Luxor.poly(_lp([pa, pc, pb]), action; close=false)
    elseif as == :rsector
        pc = pa + pb - vertex
        return Luxor.poly(_lp([vertex, pa, pc, pb]), action; close=true)
    end
    arc = EG.EGCircularArc2(EG.EGCircle2(vertex, r), pa, pb)
    if as == :arc
        return EG.path(arc; action=action)
    elseif as == :sector
        return EG.path(EG.EGCircularSector2(arc); action=action)
    else
        throw(ArgumentError("path(::EGAngle2): as must be :rays, :arc, :sector, :rarc or :rsector, got $(repr(as))"))
    end
end

"""
    path(arc::EGCircularArc2; action=:path)

A true circular arc from `arc.p1` to `arc.p2`, via Luxor's own `arc2r`
(center + the two endpoints — no separate angle bookkeeping needed, and no
polygonal approximation: this draws with Cairo's native arc primitive).
"""
function EG.path(arc::EG.EGCircularArc2; action=:path)
    action != :path && Luxor.newpath()
    Luxor.move(_lp(arc.p1))
    Luxor.arc2r(_lp(arc.circle.center), _lp(arc.p1), _lp(arc.p2))
    Luxor.do_action(action)
end

"""
    path(arc::EGEllipticArc2; n=60, action=:path)
    path(arc::EGParabolicArc2; n=60, action=:path)
    path(arc::EGHyperbolicArc2; n=60, action=:path)

Luxor has no native primitive for a partial arc of an ellipse, parabola
or hyperbola, so each is added as an `n`-point open polyline, sampled via
[`point_on_arc`](@ref) over the arc's own parameter range `[0, 1]`
(`arc.p1` to `arc.p2`).
"""
function EG.path(arc::Union{EG.EGEllipticArc2,EG.EGParabolicArc2,EG.EGHyperbolicArc2}; n=60, action=:path)
    pts = [_lp(EG.point_on_arc(arc, t)) for t in range(0.0, 1.0; length=n)]
    Luxor.poly(pts, action; close=false)
end

# Adds `arc` to the current path in the given direction — forward traces
# `arc.p1 -> arc.p2` (Luxor's own `arc2r`); `reversed` retraces the exact
# same arc from `arc.p2` back to `arc.p1` (not its complement), via
# `carc2r`, Luxor's clockwise/decreasing-angle arc primitive.
function _add_arc!(arc::EG.EGCircularArc2, reversed::Bool; n=60)
    c = _lp(arc.circle.center)
    reversed ? Luxor.carc2r(c, _lp(arc.p2), _lp(arc.p1)) : Luxor.arc2r(c, _lp(arc.p1), _lp(arc.p2))
end

# The other three conic-arc types have no native Cairo primitive (see
# `path` above), so they're sampled the same way here, just continuing
# the already-open path (repeated `line`, no `move`) instead of starting
# a new one — the first sampled point coincides with wherever the walk
# already is, so this connects seamlessly to the previous side.
function _add_arc!(arc::Union{EG.EGEllipticArc2,EG.EGParabolicArc2,EG.EGHyperbolicArc2}, reversed::Bool; n=60)
    ts = reversed ? range(1.0, 0.0; length=n) : range(0.0, 1.0; length=n)
    for t in ts
        Luxor.line(_lp(EG.point_on_arc(arc, t)))
    end
end

"""
    path(pg::EGPolygon; n=60, action=:path)

Traces every side of `pg` end to end into a single closed path — an
`EGSegment` side contributes a straight line, an `EGCircularArc2` side a
true arc (see [`path(::EGCircularArc2)`](@ref)), and any other conic-arc
side (`EGEllipticArc2`/`EGParabolicArc2`/`EGHyperbolicArc2` — possible
after an [`EGAffineMap`](@ref), which can turn a circular-arc side
elliptic) an `n`-point sampled polyline, same as their own standalone
`path` method. Sides are walked in whichever direction continues from the
previous one's last point (via `_polygon_walk`, the same walk
`area`/`perimeter` use), so this one method covers the entire polygon
family — `EGTriangle`, `EGQuadrilateral`, `EGStraightNgon`, and every
curved-region type (`EGCircularSector2`, `EGCircularSegment2`,
`EGAnnularSector2`, `EGInterstice2`, `EGCurvilinearTriangle2`,
`EGCurvilinearQuadrilateral2`, `EGCurvilinearNgon2`).
"""
function EG.path(pg::EG.EGPolygon; n=60, action=:path)
    action != :path && Luxor.newpath()
    order = EG._polygon_walk(EG.sides(pg))
    first_side, first_reversed = order[1]
    start_pt = first_reversed ? EG._side_p2(first_side) : EG._side_p1(first_side)
    Luxor.move(_lp(start_pt))
    for (side, reversed) in order
        if side isa EG.EGSegment
            Luxor.line(_lp(reversed ? side.p1 : side.p2))
        else
            _add_arc!(side, reversed; n=n)
        end
    end
    Luxor.closepath()
    Luxor.do_action(action)
end

"""
    path(v::AbstractVector{<:EGObject}; kwargs...)

`path` for each element of `v` in turn, with the same `kwargs` every time.
This is what lets a plain `Vector` -- what `intersection`/`tangent_points`
return, since they can give 0, 1 or 2 points depending on the geometry --
get drawn directly as a single argument, without unwrapping it by hand
first.

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
function EG.path(v::AbstractVector{<:EG.EGObject}; kwargs...)
    for x in v
        Luxor.newsubpath()
        EG.path(x; kwargs...)
    end
end

function EG.current_path_bbox()
    x1, y1, x2, y2 = Luxor.path_extents(Luxor.currentdrawing().cr)
    return EG.EGBoundingBox(EG.EGPoint(x1, y1), EG.EGPoint(x2, y2))
end

end # module EuclideanGeometryLuxorExt
