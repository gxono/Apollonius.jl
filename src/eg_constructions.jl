# -------------------------------------------------------------------------
# Phase 7 (continued): mechanical port of constructions.jl's derived-line/
# point constructions onto EGPoint/EGLine. Formula bodies are unchanged
# from the Point2-based originals. `midpoint`/`distance`/`projection`/
# `reflection`/`rotate`/`homothety` for EGPoint/EGSegment/EGLine/EGRay
# already exist (Phase 2); this file adds the rest.
# -------------------------------------------------------------------------

"""
    polar_point(r, angle, center::EGPoint)

The point at distance `r` from `center`, at `angle` radians counterclockwise
from the positive x-axis: `center + (r*cos(angle), r*sin(angle))`.

No zero-argument default for `center` here (unlike the `Point2`-based
`polar_point`, which already claims the `(r::Real, angle::Real)`
default-elided fallback — see [`rotation_map`](@ref) for why an EG-typed
default would collide with it): pass `center` explicitly.
"""
polar_point(r::Real, angle::Real, center::EGPoint{2}) =
    center + EGPoint(r * cos(angle), r * sin(angle))

"""
    polar_point_deg(r, angle, center::EGPoint)

Like [`polar_point`](@ref), but `angle` is given in degrees.
"""
polar_point_deg(r::Real, angle::Real, center::EGPoint{2}) =
    polar_point(r, deg2rad(angle), center)

"""
    barycenter(points::AbstractVector{<:EGPoint}, weights::AbstractVector{<:Real})

The weighted barycenter (center of mass) of `points` with the given `weights`.
"""
function barycenter(points::AbstractVector{<:EGPoint}, weights::AbstractVector{<:Real})
    length(points) == length(weights) ||
        throw(ArgumentError("points and weights must have the same length"))
    W = sum(weights)
    return sum(w * p for (w, p) in zip(weights, points)) / W
end

"""
    parallel_through(l::EGLine, p::EGPoint)

The line through `p` parallel to `l`.
"""
parallel_through(l::EGLine, p::EGPoint) = EGLine(p, p + direction(l))

"""
    perpendicular_through(l::EGLine, p::EGPoint)

The line through `p` perpendicular to `l`.
"""
perpendicular_through(l::EGLine, p::EGPoint) = EGLine(p, p + orthogonal(direction(l)))

"""
    perpendicular_bisector(a::EGPoint, b::EGPoint)
    perpendicular_bisector(s::EGSegment)

The perpendicular bisector (mediatrix) of segment `[a, b]`.
"""
perpendicular_bisector(a::EGPoint, b::EGPoint) = perpendicular_through(EGLine(a, b), midpoint(a, b))
perpendicular_bisector(s::EGSegment) = perpendicular_bisector(s[1], s[2])

"""
    angle_bisectors(l1::EGLine, l2::EGLine; atol=1e-9)

The angle bisector(s) of `l1` and `l2`: two mutually perpendicular lines
through their intersection point (the internal and external bisectors) if
they intersect, or a single midline if they're parallel.
"""
function angle_bisectors(l1::EGLine, l2::EGLine; atol=1e-9)
    pts = intersection(l1, l2; atol=atol)
    if isempty(pts)
        foot = projection(l1.p1, l2)
        m = midpoint(l1.p1, foot)
        return [EGLine(m, m + direction(l1))]
    end
    x = pts[1]
    u1 = direction(l1) / norm(direction(l1))
    u2 = direction(l2) / norm(direction(l2))
    return [EGLine(x, x + (u1 + u2)), EGLine(x, x + (u1 - u2))]
end

"""
    angle_trisectors(vertex::EGPoint, p1::EGPoint, p2::EGPoint)

The two rays from `vertex` that trisect the angle `∠(p1, vertex, p2)` into
three equal parts (the oriented angle from `vertex -> p1` to
`vertex -> p2`, i.e. going counterclockwise when that angle is positive).
"""
function angle_trisectors(vertex::EGPoint, p1::EGPoint, p2::EGPoint)
    θ = angle_between(p1 - vertex, p2 - vertex)
    return [EGRay(vertex, rotate(p1, θ / 3, vertex)), EGRay(vertex, rotate(p1, 2θ / 3, vertex))]
end

"""
    golden_ratio_point(a::EGPoint, b::EGPoint)
    golden_ratio_point(l::EGLine)

The point on segment `[a, b]` (or `[l.p1, l.p2]`) dividing it in the golden
ratio from `a`, i.e. `a + (b - a) / φ`.
"""
golden_ratio_point(a::EGPoint, b::EGPoint) = a + (b - a) / golden
golden_ratio_point(l::EGLine) = golden_ratio_point(l.p1, l.p2)

"""
    harmonic_conjugate(a::EGPoint, b::EGPoint, p::EGPoint; atol=1e-9)
    harmonic_conjugate(l::EGLine, p::EGPoint; atol=1e-9)

The harmonic conjugate of `p` with respect to `a` and `b`: the point `q`
(collinear with `a`, `b`, `p`) such that the cross-ratio `(a, b; p, q)`
equals `-1`. Throws an error if `p` is the midpoint of `[a, b]` (its
harmonic conjugate is the point at infinity).
"""
function harmonic_conjugate(a::EGPoint, b::EGPoint, p::EGPoint; atol=1e-9)
    d = b - a
    t = dot(p - a, d) / dot(d, d)
    denom = 2t - 1
    abs(denom) <= atol && throw(ArgumentError(
        "harmonic_conjugate: p is the midpoint of (a, b); its harmonic conjugate is the point at infinity"))
    return a + (t / denom) * d
end
harmonic_conjugate(l::EGLine, p::EGPoint; atol=1e-9) = harmonic_conjugate(l.p1, l.p2, p; atol=atol)

"""
    apollonius_circle(a::EGPoint, b::EGPoint, k::Real; atol=1e-9)

The Apollonius circle of `a`, `b` and ratio `k`: the locus of points `p`
with `distance(p, a) / distance(p, b) == k`. Its diameter endpoints are the
points dividing `[a, b]` internally and externally in ratio `k`. Throws an
`ArgumentError` if `k ≈ 1` (the locus is then the perpendicular bisector of
`[a, b]`, a line rather than a circle).
"""
function apollonius_circle(a::EGPoint, b::EGPoint, k::Real; atol=1e-9)
    k <= 0 && throw(ArgumentError("apollonius_circle: k must be positive (it's a ratio of distances)"))
    abs(k - 1) <= atol && throw(ArgumentError(
        "apollonius_circle: k ≈ 1; the locus is the perpendicular bisector of [a,b], not a circle"))
    p_int = (a + k * b) / (1 + k)
    p_ext = (k * b - a) / (k - 1)
    return EGCircle2(midpoint(p_int, p_ext), distance(p_int, p_ext) / 2)
end
