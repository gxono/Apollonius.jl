# -------------------------------------------------------------------------
# Phase 7 (continued) of the EG-prefixed type hierarchy rewrite: mechanical
# port of predicates.jl's boolean/classification predicates onto
# EGPoint/EGLine/EGSegment/EGCircle2/EGTriangle. Formula bodies are
# unchanged from the Point2-based originals.
#
# `is_parallel`/`is_perpendicular` need no new methods here — they're
# already untyped in predicates.jl (dispatch purely via `direction(...)`,
# duck-typed), so they already work on EGLine/EGSegment/EGRay for free.
#
# `is_concyclic` (below) was originally deferred here pending
# `circumcenter`/`circumradius(::EGTriangle)` — now ported in
# eg_triangle.jl (included after this file; fine, since it's only
# referenced inside a function body, not a type signature).
# -------------------------------------------------------------------------

"""
    is_collinear(a::EGPoint, b::EGPoint, c::EGPoint; atol=1e-9)

Whether points `a`, `b` and `c` lie on a common line.
"""
is_collinear(a::EGPoint, b::EGPoint, c::EGPoint; atol=1e-9) =
    abs(cross2(b - a, c - a)) <= atol * norm(b - a) * norm(c - a)

"""
    on_line(p::EGPoint, l::EGLine; atol=1e-9)

Whether point `p` lies on the infinite line `l`.
"""
on_line(p::EGPoint, l::EGLine; atol=1e-9) =
    distance(p, l) <= sqrt(atol) * max(norm(p), norm(l.p1), norm(l.p2), 1.0)

"""
    on_segment(p::EGPoint, s::EGSegment; atol=1e-9)

Whether point `p` lies on the finite segment `s` (endpoints included).
"""
function on_segment(p::EGPoint, s::EGSegment; atol=1e-9)
    a, b = s[1], s[2]
    is_collinear(a, b, p; atol=atol) || return false
    ab2 = dot(b - a, b - a)
    ab2 <= atol^2 && return distance(p, a) <= atol
    t = dot(p - a, b - a) / ab2
    return -atol <= t <= 1 + atol
end

"""
    side_of_line(p::EGPoint, l::EGLine)

`+1` if `p` is to the left of `l` (oriented from `l.p1` to `l.p2`), `-1` if
to the right, `0` if `p` is on `l`.
"""
function side_of_line(p::EGPoint, l::EGLine)
    v = cross2(direction(l), p - l.p1)
    return v > 0 ? 1 : (v < 0 ? -1 : 0)
end

"""
    is_degenerate(t::EGTriangle; atol=1e-9)

Whether the three vertices of `t` are collinear (zero area).
"""
is_degenerate(t::EGTriangle; atol=1e-9) = is_collinear(t.a, t.b, t.c; atol=atol)

"""
    line_circle_position(l::EGLine, c::EGCircle2; atol=1e-9)

How `l` and `c` relate: `:disjoint` (no intersection), `:tangent` (touch at
exactly one point), or `:secant` (cross at two points).
"""
function line_circle_position(l::EGLine, c::EGCircle2; atol=1e-9)
    d = distance(c.center, l)
    tol = sqrt(atol) * max(c.r, norm(c.center), 1.0)
    d > c.r + tol && return :disjoint
    abs(d - c.r) <= tol && return :tangent
    return :secant
end

"""
    circles_position(c1::EGCircle2, c2::EGCircle2; atol=1e-9)

How `c1` and `c2` relate, as one of: `:identical` (same center and
radius), `:concentric` (same center, different radius), `:disjoint_ext`
(too far apart to meet), `:tangent_ext` (externally tangent),
`:secant` (cross at two points), `:tangent_int` (internally tangent), or
`:disjoint_int` (one strictly inside the other, not touching).
"""
function circles_position(c1::EGCircle2, c2::EGCircle2; atol=1e-9)
    d = distance(c1.center, c2.center)
    tol = sqrt(atol) * max(c1.r, c2.r, 1.0)
    if d <= tol
        return isapprox(c1.r, c2.r; atol=tol) ? :identical : :concentric
    end
    rsum, rdiff = c1.r + c2.r, abs(c1.r - c2.r)
    d > rsum + tol && return :disjoint_ext
    abs(d - rsum) <= tol && return :tangent_ext
    d < rdiff - tol && return :disjoint_int
    abs(d - rdiff) <= tol && return :tangent_int
    return :secant
end

"""
    is_concyclic(a::EGPoint, b::EGPoint, c::EGPoint, d::EGPoint; atol=1e-9)

Whether the four points lie on a common circle (or are collinear, treated
as a degenerate "circle" of infinite radius). `a`, `b`, `c` must not be
collinear unless `d` is collinear with them too.
"""
function is_concyclic(a::EGPoint, b::EGPoint, c::EGPoint, d::EGPoint; atol=1e-9)
    if is_degenerate(EGTriangle(a, b, c); atol=atol)
        return is_collinear(a, b, d; atol=atol)
    end
    t = EGTriangle(a, b, c)
    cc, cr = circumcenter(t), circumradius(t)
    return abs(distance(cc, d) - cr) <= sqrt(atol) * max(cr, norm(cc), 1.0)
end
