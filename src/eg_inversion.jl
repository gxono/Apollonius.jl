# -------------------------------------------------------------------------
# Phase 7 (continued): mechanical port of inversion.jl onto
# EGPoint/EGLine/EGSegment/EGCircle2/EGCircularArc2. Formula bodies are
# unchanged from the Point2-based originals.
# -------------------------------------------------------------------------

"""
    inversion(p::EGPoint, c::EGCircle2)

The image of `p` under inversion with respect to circle `c` (center `O`,
radius `r`): the point `p'` on ray `O -> p` such that `|Op| * |Op'| = r^2`.
"""
function inversion(p::EGPoint, c::EGCircle2)
    v = p - c.center
    d2 = dot(v, v)
    d2 <= 0 && throw(ArgumentError("inversion: p coincides with the center of c"))
    return c.center + (c.r^2 / d2) * v
end

"""
    invert(l::EGLine, center::EGPoint; k::Real=1.0, atol=1e-9)

The image of `l` under inversion with respect to the circle centered at
`center` with radius `k`. A line not through the inversion center always
inverts to a circle through it. Throws an `ArgumentError` if `l` passes
through `center` (its image would be `l` itself, not a circle).
"""
function invert(l::EGLine, center::EGPoint; k::Real=1.0, atol=1e-9)
    f = projection(center, l)
    distance(center, f) <= sqrt(atol) * max(norm(center), norm(l.p1), norm(l.p2), 1.0) &&
        throw(ArgumentError("invert: l passes through center; its image is itself, not a circle"))
    finv = inversion(f, EGCircle2(center, k))
    return EGCircle2(midpoint(center, finv), distance(center, finv) / 2)
end

"""
    invert(c::EGCircle2, center::EGPoint; k::Real=1.0, atol=1e-9)

The image of `c` under inversion with respect to the circle centered at
`center` with radius `k`. A circle through `center` inverts to an
`EGLine` (the mirror image of [`invert(::EGLine, ::EGPoint)`](@ref)); any
other circle inverts to another `EGCircle2` — so this returns a
`Union{EGCircle2,EGLine}`.
"""
function invert(c::EGCircle2, center::EGPoint; k::Real=1.0, atol=1e-9)
    center == c.center && return EGCircle2(center, k^2 / c.r)
    if abs(distance(center, c.center) - c.r) <= sqrt(atol) * max(c.r, norm(center), norm(c.center), 1.0)
        antipode = 2 * c.center - center  # the point of c diametrically opposite center
        antipode_inv = inversion(antipode, EGCircle2(center, k))
        return perpendicular_through(EGLine(center, c.center), antipode_inv)
    end
    axis = EGLine(center, c.center)
    a, b = intersection(axis, c; atol=atol)
    ainv, binv = inversion(a, EGCircle2(center, k)), inversion(b, EGCircle2(center, k))
    return EGCircle2(midpoint(ainv, binv), distance(ainv, binv) / 2)
end

# Whether `p` (assumed to lie on `arc.circle`) falls within `arc`'s own
# counterclockwise sweep from `arc.p1` to `arc.p2`.
function _arc_sweep_contains(arc::EGCircularArc2, p::EGPoint)
    a1 = atan(arc.p1[2] - arc.circle.center[2], arc.p1[1] - arc.circle.center[1])
    ap = atan(p[2] - arc.circle.center[2], p[1] - arc.circle.center[1])
    return mod(ap - a1, 2π) <= measure(arc)
end

"""
    invert(s::EGSegment, center::EGPoint; k::Real=1.0, atol=1e-9)

The image of `s` under inversion with respect to the circle centered at
`center` with radius `k`. A segment on a line through `center` inverts to
another `EGSegment` (on the same line); any other segment inverts to an
[`EGCircularArc2`](@ref) of [`invert(::EGLine, ::EGPoint)`](@ref)'s image
circle — specifically the arc that does *not* pass through `center`, since
that point is the image of the line's own point at infinity, which the
segment (being finite) never reaches. So this returns a
`Union{EGSegment,EGCircularArc2}`.
"""
function invert(s::EGSegment, center::EGPoint; k::Real=1.0, atol=1e-9)
    p1, p2 = s[1], s[2]
    tol = sqrt(atol) * max(norm(center), norm(p1), norm(p2), 1.0)
    ci = EGCircle2(center, k)
    if distance(center, EGLine(p1, p2)) <= tol
        return EGSegment(inversion(p1, ci), inversion(p2, ci))
    end
    circ = invert(EGLine(p1, p2), center; k=k, atol=atol)
    ip1, ip2 = inversion(p1, ci), inversion(p2, ci)
    candidate = EGCircularArc2(circ, ip1, ip2)
    return _arc_sweep_contains(candidate, center) ? EGCircularArc2(circ, ip2, ip1) : candidate
end

"""
    invert(t::EGTriangle, center::EGPoint; k::Real=1.0, atol=1e-9)
    invert(pg::EGStraightNgon, center::EGPoint; k::Real=1.0, atol=1e-9)

The image of `t`/`pg` under inversion with respect to the circle centered
at `center` with radius `k`: each side inverts independently (see
[`invert(::EGSegment, ::EGPoint)`](@ref)) to a straight `EGSegment` or an
`EGCircularArc2`, and the results are collected into an
[`EGCurvilinearNgon2`](@ref). Throws an `ArgumentError` if any vertex
coincides with `center` (that vertex has no image under inversion).
"""
invert(t::EGTriangle, center::EGPoint; k::Real=1.0, atol=1e-9) =
    EGCurvilinearNgon2([invert(s, center; k=k, atol=atol) for s in sides(t)])
invert(pg::EGStraightNgon, center::EGPoint; k::Real=1.0, atol=1e-9) =
    EGCurvilinearNgon2([invert(s, center; k=k, atol=atol) for s in sides(pg)])

"""
    inversion_neg(p::EGPoint, c::EGCircle2)

The image of `p` under inversion of *negative* ratio with respect to `c`:
the ordinary (positive) [`inversion`](@ref), point-reflected through
`c.center` — i.e. the point on ray `p -> O` (not `O -> p`) at distance
`r^2/|Op|` from `O`.
"""
inversion_neg(p::EGPoint, c::EGCircle2) = reflection(inversion(p, c), c.center)

"""
    invert_neg(l::EGLine, center::EGPoint; k::Real=1.0, atol=1e-9)
    invert_neg(c::EGCircle2, center::EGPoint; k::Real=1.0, atol=1e-9)

The image of `l`/`c` under inversion of *negative* ratio with respect to
the circle centered at `center` with radius `k`: the ordinary
[`invert`](@ref) image, point-reflected through `center`.
"""
invert_neg(l::EGLine, center::EGPoint; k::Real=1.0, atol=1e-9) = reflection(invert(l, center; k=k, atol=atol), center)
invert_neg(c::EGCircle2, center::EGPoint; k::Real=1.0, atol=1e-9) = reflection(invert(c, center; k=k, atol=atol), center)

"""
    polar_line(c::EGCircle2, p::EGPoint; atol=1e-9)

The polar line of `p` with respect to `c`: the line through `inversion(p, c)`
perpendicular to the line from `c.center` to `p`. When `p` is outside `c`,
this is the chord of contact of the two tangent lines from `p` (see
[`tangent_points`](@ref)); when `p` is on `c`, it's the tangent line at `p`.
`nothing` when `p` is `c`'s center (matching the `EGEllipse2`/`EGHyperbola2`/
`EGParabola2` methods, once ported), rather than throwing.
"""
function polar_line(c::EGCircle2, p::EGPoint; atol=1e-9)
    distance(p, c.center) <= sqrt(atol) * max(c.r, norm(p), norm(c.center), 1.0) && return nothing
    return perpendicular_through(EGLine(c.center, p), inversion(p, c))
end

"""
    pole(c::EGCircle2, l::EGLine)

The pole of `l` with respect to `c`: the point whose polar line (see
[`polar_line`](@ref)) is `l`. Throws an `ArgumentError` if `l` passes
through `c.center` (its pole would be the point at infinity).
"""
function pole(c::EGCircle2, l::EGLine)
    foot = projection(c.center, l)
    isapprox(foot, c.center) && throw(ArgumentError("pole: l passes through the center of c; its pole is the point at infinity"))
    return inversion(foot, c)
end
