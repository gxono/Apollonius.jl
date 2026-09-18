"""
    polar_point(r, angle, center::APPoint)

The point at distance `r` from `center`, at `angle` radians counterclockwise
from the positive x-axis: `center + (r*cos(angle), r*sin(angle))`.

No zero-argument default for `center` here (unlike the `Point2`-based
`polar_point`, which already claims the `(r::Real, angle::Real)`
default-elided fallback — see [`rotation_map`](@ref) for why an AP-typed
default would collide with it): pass `center` explicitly.
"""
polar_point(r::Real, angle::Real, center::APPoint{2}) =
    center + APVector(r * cos(angle), r * sin(angle))
polar_point(r::Real, angle::Real) = polar_point(r, angle, APPoint(0.0,0.0))
"""
    polar_point_deg(r, angle, center::APPoint)

Like [`polar_point`](@ref), but `angle` is given in degrees.
"""
polar_point_deg(r::Real, angle::Real, center::APPoint{2}) =
    polar_point(r, deg2rad(angle), center)
polar_point_deg(r::Real, angle::Real) = polar_point_deg(r, angle, APPoint(0.0,0.0))
"""
    barycenter(points, weights)

The weighted barycenter (center of mass) of `points` with the given
`weights` — `points` an `AbstractVector`/`Tuple` of `APPoint`, `weights`
an `AbstractVector`/`Tuple` of `Real` (e.g. `barycenter(vertices(t),
[1.0, 1.0, 2.0])` works directly, even though `vertices(::APTriangle)`
returns a `Tuple` rather than a `Vector`).
"""
function barycenter(points::Union{AbstractVector{<:APPoint},NTuple{N,<:APPoint} where N},
    weights::Union{AbstractVector{<:Real},NTuple{N,<:Real} where N})
    length(points) == length(weights) ||
        throw(ArgumentError("points and weights must have the same length"))
    W = sum(weights)
    p0 = first(points)
    return p0 + sum(w * (p - p0) for (w, p) in zip(weights, points)) / W
end
"""
    parallel_through(l::APLine, p::APPoint)

The line through `p` parallel to `l`.
"""
parallel_through(l::APLine, p::APPoint) = APLine(p, p + direction(l))
"""
    perpendicular_through(l::APLine, p::APPoint)

The line through `p` perpendicular to `l`.
"""
perpendicular_through(l::APLine, p::APPoint) = APLine(p, p + orthogonal(direction(l)))
"""
    perpendicular_bisector(a::APPoint, b::APPoint)
    perpendicular_bisector(s::APSegment)

The perpendicular bisector (mediatrix) of segment `[a, b]`.
"""
perpendicular_bisector(a::APPoint, b::APPoint) = perpendicular_through(APLine(a, b), midpoint(a, b))
perpendicular_bisector(s::APSegment) = perpendicular_bisector(s[1], s[2])
"""
    angle_bisectors(l1::APLine, l2::APLine; atol=1e-9)

The angle bisector(s) of `l1` and `l2`: two mutually perpendicular lines
through their intersection point (the internal and external bisectors) if
they intersect, or a single midline if they're parallel.
"""
function angle_bisectors(l1::APLine, l2::APLine; atol=1e-9)
    pts = intersection(l1, l2; atol=atol)
    if isempty(pts)
        foot = projection(l1.p1, l2)
        m = midpoint(l1.p1, foot)
        return [APLine(m, m + direction(l1))]
    end
    x = pts[1]
    u1 = direction(l1) / norm(direction(l1))
    u2 = direction(l2) / norm(direction(l2))
    return [APLine(x, x + (u1 + u2)), APLine(x, x + (u1 - u2))]
end
"""
    angle_trisectors(vertex::APPoint, p1::APPoint, p2::APPoint)

The two rays from `vertex` that trisect the angle `∠(p1, vertex, p2)` into
three equal parts (the oriented angle from `vertex -> p1` to
`vertex -> p2`, i.e. going counterclockwise when that angle is positive).
Always exactly 2 rays, so returned as a `Tuple` (unlike
[`angle_bisectors`](@ref)`(l1, l2)`, whose count genuinely varies with the
input and so must be a `Vector`).
"""
function angle_trisectors(vertex::APPoint, p1::APPoint, p2::APPoint)
    θ = angle_between(p1 - vertex, p2 - vertex)
    return (APRay(vertex, rotate(p1, θ / 3, vertex)), APRay(vertex, rotate(p1, 2θ / 3, vertex)))
end
"""
    angle_bisectors(ang::APAngle2)

`ang` split into its two equal halves by its bisector, each as its own
`APAngle2`: `(APAngle2(vertex, a, bis), APAngle2(vertex, bis, b))`.
"""
function angle_bisectors(ang::APAngle2)
    bis = rotate(ang.a, measure(ang) / 2, ang.vertex)
    return (APAngle2(ang.vertex, ang.a, bis), APAngle2(ang.vertex, bis, ang.b))
end
"""
    angle_trisectors(ang::APAngle2)

`ang` split into its three equal thirds by its two trisectors, each as its
own `APAngle2`: `(APAngle2(vertex, a, r1), APAngle2(vertex, r1, r2),
APAngle2(vertex, r2, b))`.
"""
function angle_trisectors(ang::APAngle2)
    θ = measure(ang)
    r1 = rotate(ang.a, θ / 3, ang.vertex)
    r2 = rotate(ang.a, 2θ / 3, ang.vertex)
    return (APAngle2(ang.vertex, ang.a, r1), APAngle2(ang.vertex, r1, r2), APAngle2(ang.vertex, r2, ang.b))
end
"""
    golden_ratio_point(a::APPoint, b::APPoint)
    golden_ratio_point(l::APLine)

The point on segment `[a, b]` (or `[l.p1, l.p2]`) dividing it in the golden
ratio from `a`, i.e. `a + (b - a) / φ`.
"""
golden_ratio_point(a::APPoint, b::APPoint) = a + (b - a) / golden
golden_ratio_point(l::APLine) = golden_ratio_point(l.p1, l.p2)
"""
    harmonic_conjugate(a::APPoint, b::APPoint, p::APPoint; atol=1e-9)
    harmonic_conjugate(l::APLine, p::APPoint; atol=1e-9)

The harmonic conjugate of `p` with respect to `a` and `b`: the point `q`
(collinear with `a`, `b`, `p`) such that the cross-ratio `(a, b; p, q)`
equals `-1`. Throws an error if `p` is the midpoint of `[a, b]` (its
harmonic conjugate is the point at infinity).
"""
function harmonic_conjugate(a::APPoint, b::APPoint, p::APPoint; atol=1e-9)
    d = b - a
    t = dot(p - a, d) / dot(d, d)
    denom = 2t - 1
    abs(denom) <= atol && throw(ArgumentError(
        "harmonic_conjugate: p is the midpoint of (a, b); its harmonic conjugate is the point at infinity"))
    return a + (t / denom) * d
end
harmonic_conjugate(l::APLine, p::APPoint; atol=1e-9) = harmonic_conjugate(l.p1, l.p2, p; atol=atol)
"""
    apollonius_circle(a::APPoint, b::APPoint, k::Real; atol=1e-9)

The Apollonius circle of `a`, `b` and ratio `k`: the locus of points `p`
with `distance(p, a) / distance(p, b) == k`. Its diameter endpoints are the
points dividing `[a, b]` internally and externally in ratio `k`. Throws an
`ArgumentError` if `k ≈ 1` (the locus is then the perpendicular bisector of
`[a, b]`, a line rather than a circle).
"""
function apollonius_circle(a::APPoint, b::APPoint, k::Real; atol=1e-9)
    k <= 0 && throw(ArgumentError("apollonius_circle: k must be positive (it's a ratio of distances)"))
    abs(k - 1) <= atol && throw(ArgumentError(
        "apollonius_circle: k ≈ 1; the locus is the perpendicular bisector of [a,b], not a circle"))
    p_int = a + k * (b - a) / (1 + k)
    p_ext = a + k * (b - a) / (k - 1)
    return APCircle2(midpoint(p_int, p_ext), distance(p_int, p_ext) / 2)
end
