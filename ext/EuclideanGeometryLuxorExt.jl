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
# the direct payoff of the EG type hierarchy: the old Point2-based
# extension needed 3 near-identical vertex-based methods (Triangle/Polygon/
# Quadrilateral) plus separate hand-written arc-walking methods per curved
# type (and no method at all for the 3 brand-new curved types); one method
# now covers all of them. The one behavior change from the old vertex-based
# methods: no more `close=false` (open-polyline) option, since a walked
# side sequence is always a closed loop — unexercised in this package's
# own tests/docs, and revisited if it turns out to matter.
# -------------------------------------------------------------------------

module EuclideanGeometryLuxorExt

using EuclideanGeometry
using Luxor

const EG = EuclideanGeometry

_lp(p::EG.EGPoint) = Luxor.Point(Float64(p[1]), Float64(p[2]))
_lp(pts::AbstractVector{<:EG.EGPoint}) = _lp.(pts)

"""
    path(p::EGPoint; radius=3, action=:path)

`p` as a small circle of the given `radius`.
"""
EG.path(p::EG.EGPoint; radius=3, action=:path) = Luxor.circle(_lp(p), radius, action)

"""
    path(s::EGSegment; action=:path)
"""
EG.path(s::EG.EGSegment; action=:path) = Luxor.line(_lp(s.p1), _lp(s.p2), action)

"""
    path(l::EGLine; extend=1000.0, action=:path)

`EGLine` is infinite, so it's added as a long finite segment: `extend`
units past each of `l.p1`/`l.p2` along its direction.
"""
function EG.path(l::EG.EGLine; extend=1000.0, action=:path)
    u = EG.direction(l) / EG.norm(EG.direction(l))
    Luxor.line(_lp(l.p1 - extend * u), _lp(l.p2 + extend * u), action)
end

"""
    path(r::EGRay; extend=1000.0, action=:path)

`EGRay` is half-infinite, so it's added from `r.origin` to `extend` units
past `r.through`.
"""
function EG.path(r::EG.EGRay; extend=1000.0, action=:path)
    u = EG.direction(r) / EG.norm(EG.direction(r))
    Luxor.line(_lp(r.origin), _lp(r.through + extend * u), action)
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

Uses Luxor's axis-aligned, Bézier-curve `ellipse(centerpoint, w, h)` —
smooth, not a polygon approximation — inside a rotated/translated frame
(`gsave`/`translate`/`rotate`/`grestore`) matching `e.center`/`e.angle`,
rather than Luxor's own *bifocal* `ellipse(focus1, focus2, k)` form (which
handles rotation for free but is, under the hood, a raw ~200-point
polygon sampled every `stepvalue` radians — noticeably coarser up close).
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
    arc = EG.EGCircularArc2(EG.EGCircle2(vertex, r), pa, pb)
    if as == :arc
        return EG.path(arc; action=action)
    elseif as == :sector
        return EG.path(EG.EGCircularSector2(arc); action=action)
    else
        throw(ArgumentError("path(::EGAngle2): as must be :rays, :arc or :sector, got $(repr(as))"))
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

# Adds `arc` to the current path in the given direction — forward traces
# `arc.p1 -> arc.p2` (Luxor's own `arc2r`); `reversed` retraces the exact
# same arc from `arc.p2` back to `arc.p1` (not its complement), via
# `carc2r`, Luxor's clockwise/decreasing-angle arc primitive.
function _add_arc!(arc::EG.EGCircularArc2, reversed::Bool)
    c = _lp(arc.circle.center)
    reversed ? Luxor.carc2r(c, _lp(arc.p2), _lp(arc.p1)) : Luxor.arc2r(c, _lp(arc.p1), _lp(arc.p2))
end

"""
    path(pg::EGPolygon; action=:path)

Traces every side of `pg` end to end into a single closed path — an
`EGSegment` side contributes a straight line, an `EGCircularArc2` side a
true arc (see [`path(::EGCircularArc2)`](@ref)). Sides are walked in
whichever direction continues from the previous one's last point (via
`_polygon_walk`, the same walk `area`/`perimeter` use), so this one method
covers the entire polygon family — `EGTriangle`, `EGQuadrilateral`,
`EGStraightNgon`, and every curved-region type (`EGCircularSector2`,
`EGCircularSegment2`, `EGAnnularSector2`, `EGInterstice2`,
`EGCurvilinearTriangle2`, `EGCurvilinearQuadrilateral2`,
`EGCurvilinearNgon2`).
"""
function EG.path(pg::EG.EGPolygon; action=:path)
    action != :path && Luxor.newpath()
    order = EG._polygon_walk(EG.sides(pg))
    first_side, first_reversed = order[1]
    start_pt = first_reversed ? EG._side_p2(first_side) : EG._side_p1(first_side)
    Luxor.move(_lp(start_pt))
    for (side, reversed) in order
        if side isa EG.EGSegment
            Luxor.line(_lp(reversed ? side.p1 : side.p2))
        else
            _add_arc!(side, reversed)
        end
    end
    Luxor.closepath()
    Luxor.do_action(action)
end

end # module EuclideanGeometryLuxorExt
