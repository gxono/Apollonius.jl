# -------------------------------------------------------------------------
# Phase 7 (continued): mechanical port of intersections.jl onto
# EGLine/EGSegment/EGCircle2. Formula bodies are unchanged from the
# Point2-based originals; `intersection` still always returns a
# `Vector{EGPoint{2,Float64}}` with 0, 1 or 2 points regardless of which
# pair of objects is intersected.
# -------------------------------------------------------------------------

"""
    intersection(a, b; atol=1e-9)

Intersection points of two `EGLine`s, an `EGLine` and an `EGCircle2`, two
`EGSegment`s, or two `EGCircle2`s. Returns a `Vector{EGPoint{2,Float64}}`
with 0, 1 or 2 points.
"""
function intersection(l1::EGLine, l2::EGLine; atol=1e-9)
    d1, d2 = direction(l1), direction(l2)
    denom = cross2(d1, d2)
    abs(denom) <= atol * norm(d1) * norm(d2) && return EGPoint{2,Float64}[]

    diff = l2.p1 - l1.p1
    t = cross2(diff, d2) / denom
    return [EGPoint((l1.p1 + t * d1)[1], (l1.p1 + t * d1)[2])]
end

function intersection(l::EGLine, c::EGCircle2; atol=1e-9)
    f = projection(c.center, l)
    d = distance(c.center, f)
    r = c.r
    tol = sqrt(atol) * max(r, norm(c.center), 1.0)

    d > r + tol && return EGPoint{2,Float64}[]

    u = direction(l) / norm(direction(l))
    abs(d - r) <= tol && return [EGPoint(f[1], f[2])]

    h = sqrt(max(r^2 - d^2, 0.0))
    p1, p2 = f - h * u, f + h * u
    return [EGPoint(p1[1], p1[2]), EGPoint(p2[1], p2[2])]
end
intersection(c::EGCircle2, l::EGLine; atol=1e-9) = intersection(l, c; atol=atol)

"""
    intersection(s1::EGSegment, s2::EGSegment; atol=1e-9)

Intersection point of two finite segments (empty if they don't actually
cross, even if the lines they lie on would). Returns a
`Vector{EGPoint{2,Float64}}` with 0 or 1 points; overlapping collinear
segments are treated as having no (single-point) intersection.
"""
function intersection(s1::EGSegment, s2::EGSegment; atol=1e-9)
    p1, p2 = s1[1], s1[2]
    p3, p4 = s2[1], s2[2]
    d1, d2 = p2 - p1, p4 - p3
    denom = cross2(d1, d2)
    abs(denom) <= atol * norm(d1) * norm(d2) && return EGPoint{2,Float64}[]

    diff = p3 - p1
    t = cross2(diff, d2) / denom
    u = cross2(diff, d1) / denom
    (-atol <= t <= 1 + atol && -atol <= u <= 1 + atol) || return EGPoint{2,Float64}[]
    q = p1 + t * d1
    return [EGPoint(q[1], q[2])]
end

# The point where the radical axis of `c1` and `c2` crosses the line
# joining their centers, plus the unit vector along that line, the
# distance between the centers, and the signed offset of the point from
# `c1.center` along that unit vector. Shared by `intersection(::EGCircle2,
# ::EGCircle2)` (the intersection points, if any, are symmetric about this
# point) and `radical_axis` (which is the perpendicular through it).
function _radical_foot(c1::EGCircle2, c2::EGCircle2)
    d = distance(c1.center, c2.center)
    u = (c2.center - c1.center) / d
    a = (c1.r^2 - c2.r^2 + d^2) / (2d)
    return c1.center + a * u, u, d, a
end

function intersection(c1::EGCircle2, c2::EGCircle2; atol=1e-9)
    r1, r2 = c1.r, c2.r
    d = distance(c1.center, c2.center)
    scale = max(r1, r2, norm(c1.center), norm(c2.center), 1.0)
    tol = sqrt(atol) * scale

    d <= atol * max(r1, r2, 1.0) && return EGPoint{2,Float64}[]  # concentric: no or infinite solutions
    (d > r1 + r2 + tol || d < abs(r1 - r2) - tol) && return EGPoint{2,Float64}[]

    m, u, _, a = _radical_foot(c1, c2)
    h = sqrt(max(r1^2 - a^2, 0.0))

    h <= tol && return [EGPoint(m[1], m[2])]

    perp = orthogonal(u)
    p1, p2 = m + h * perp, m - h * perp
    return [EGPoint(p1[1], p1[2]), EGPoint(p2[1], p2[2])]
end
