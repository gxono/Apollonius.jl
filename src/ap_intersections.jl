"""
    intersection(a, b; atol=1e-9)

Intersection points of two `APLine`s, an `APLine` and an `APCircle2`, two
`APSegment`s, two `APCircle2`s, or an `APSegment`/`APLine`/`APRay` and any
conic (`APCircle2`, `APEllipse2`, `APParabola2`, `APHyperbola2`). Returns
a `Vector{APPoint{2,Float64}}` with 0, 1 or 2 points; an `APSegment`
against anything only keeps the points that fall within its own two
endpoints, and an `APRay` only the points on its own side of `origin`,
unlike the infinite `APLine` through the same defining points.
"""
function intersection(l1::APLine, l2::APLine; atol=1e-9)
    d1, d2 = direction(l1), direction(l2)
    denom = cross2(d1, d2)
    abs(denom) <= atol * norm(d1) * norm(d2) && return APPoint{2,Float64}[]
    diff = l2.p1 - l1.p1
    t = cross2(diff, d2) / denom
    return [APPoint((l1.p1 + t * d1)[1], (l1.p1 + t * d1)[2])]
end
function intersection(l::APLine, c::APCircle2; atol=1e-9)
    f = projection(c.center, l)
    d = distance(c.center, f)
    r = c.r
    tol = sqrt(atol) * max(r, norm(c.center), 1.0)
    d > r + tol && return APPoint{2,Float64}[]
    u = direction(l) / norm(direction(l))
    abs(d - r) <= tol && return [APPoint(f[1], f[2])]
    h = sqrt(max(r^2 - d^2, 0.0))
    p1, p2 = f - h * u, f + h * u
    return [APPoint(p1[1], p1[2]), APPoint(p2[1], p2[2])]
end
intersection(c::APCircle2, l::APLine; atol=1e-9) = intersection(l, c; atol=atol)
"""
    intersection(s1::APSegment, s2::APSegment; atol=1e-9)

Intersection point of two finite segments (empty if they don't actually
cross, even if the lines they lie on would). Returns a
`Vector{APPoint{2,Float64}}` with 0 or 1 points; overlapping collinear
segments are treated as having no (single-point) intersection.
"""
function intersection(s1::APSegment, s2::APSegment; atol=1e-9)
    p1, p2 = s1[1], s1[2]
    p3, p4 = s2[1], s2[2]
    d1, d2 = p2 - p1, p4 - p3
    denom = cross2(d1, d2)
    abs(denom) <= atol * norm(d1) * norm(d2) && return APPoint{2,Float64}[]
    diff = p3 - p1
    t = cross2(diff, d2) / denom
    u = cross2(diff, d1) / denom
    (-atol <= t <= 1 + atol && -atol <= u <= 1 + atol) || return APPoint{2,Float64}[]
    q = p1 + t * d1
    return [APPoint(q[1], q[2])]
end
"""
    intersection(s::APSegment, x; atol=1e-9)

Intersection of the finite segment `s` with `x` (an `APLine`, `APCircle2`,
or any conic), as a `Vector{APPoint{2,Float64}}`: the intersection of the
*infinite* line through `s` with `x`, filtered down to the points that
actually fall within `s`'s own two endpoints.
"""
intersection(s::APSegment, l::APLine; atol=1e-9) = filter(p -> on_segment(p, s; atol=atol), intersection(APLine(s), l; atol=atol))
intersection(l::APLine, s::APSegment; atol=1e-9) = intersection(s, l; atol=atol)
intersection(s::APSegment, c::APCircle2; atol=1e-9) = filter(p -> on_segment(p, s; atol=atol), intersection(APLine(s), c; atol=atol))
intersection(c::APCircle2, s::APSegment; atol=1e-9) = intersection(s, c; atol=atol)

"""
    intersection(r::APRay, x; atol=1e-9)

Intersection of the half-line `r` with `x` (an `APLine`, `APSegment`,
`APCircle2`, any conic, or another `APRay`): the same idea as
[`intersection(::APSegment, x)`](@ref), filtered down to the points that
fall on `r`'s own side of its `origin`.
"""
intersection(r::APRay, l::APLine; atol=1e-9) = filter(p -> on_ray(p, r; atol=atol), intersection(APLine(r), l; atol=atol))
intersection(l::APLine, r::APRay; atol=1e-9) = intersection(r, l; atol=atol)
intersection(r::APRay, s::APSegment; atol=1e-9) = filter(p -> on_ray(p, r; atol=atol), intersection(APLine(r), s; atol=atol))
intersection(s::APSegment, r::APRay; atol=1e-9) = intersection(r, s; atol=atol)
intersection(r::APRay, c::APCircle2; atol=1e-9) = filter(p -> on_ray(p, r; atol=atol), intersection(APLine(r), c; atol=atol))
intersection(c::APCircle2, r::APRay; atol=1e-9) = intersection(r, c; atol=atol)
intersection(r1::APRay, r2::APRay; atol=1e-9) = filter(p -> on_ray(p, r2; atol=atol), intersection(r1, APLine(r2); atol=atol))

function _radical_foot(c1::APCircle2, c2::APCircle2)
    d = distance(c1.center, c2.center)
    u = (c2.center - c1.center) / d
    a = (c1.r^2 - c2.r^2 + d^2) / (2d)
    return c1.center + a * u, u, d, a
end
function intersection(c1::APCircle2, c2::APCircle2; atol=1e-9)
    r1, r2 = c1.r, c2.r
    d = distance(c1.center, c2.center)
    scale = max(r1, r2, norm(c1.center), norm(c2.center), 1.0)
    tol = sqrt(atol) * scale
    d <= atol * max(r1, r2, 1.0) && return APPoint{2,Float64}[]
    (d > r1 + r2 + tol || d < abs(r1 - r2) - tol) && return APPoint{2,Float64}[]
    m, u, _, a = _radical_foot(c1, c2)
    h = sqrt(max(r1^2 - a^2, 0.0))
    h <= tol && return [APPoint(m[1], m[2])]
    perp = orthogonal(u)
    p1, p2 = m + h * perp, m - h * perp
    return [APPoint(p1[1], p1[2]), APPoint(p2[1], p2[2])]
end
