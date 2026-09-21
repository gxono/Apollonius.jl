"""
    _solve_quadratic(a, b, c; atol=1e-9)

Real roots of `a*t^2 + b*t + c = 0`, as a `Vector{Float64}` with 0, 1 or 2
elements (falls back to the linear/constant cases when `a ≈ 0`).
"""
function _solve_quadratic(a::Real, b::Real, c::Real; atol=1e-9)
    if abs(a) <= atol
        abs(b) <= atol && return Float64[]
        return [Float64(-c / b)]
    end
    disc = b^2 - 4a * c
    disc < -atol && return Float64[]
    disc = max(disc, 0.0)
    sq = sqrt(disc)
    sq <= atol && return [Float64(-b / (2a))]
    return [Float64((-b + sq) / (2a)), Float64((-b - sq) / (2a))]
end
"""
    cross2(a, b)

The 2D (scalar) cross product `a[1]*b[2] - a[2]*b[1]`.
"""
cross2(a, b) = a[1] * b[2] - a[2] * b[1]
"""
    cross3(a, b)

The 3D (vector) cross product of `a` and `b`, as an [`APVector`](@ref):
the 3D counterpart of [`cross2`](@ref). Works on any indexable `a`/`b`
(`APPoint{3}` or `APVector{3}`), same duck-typed convention as `cross2`.
"""
cross3(a, b) = APVector(a[2] * b[3] - a[3] * b[2], a[3] * b[1] - a[1] * b[3], a[1] * b[2] - a[2] * b[1])
"""
    slope_angle(obj)

The angle (radians, in `(-π, π]`, counterclockwise from the positive x-axis) of
the [`direction`](@ref) of `obj`: an [`APLine`](@ref), [`APRay`](@ref) or
[`APSegment`](@ref), an [`APVector`](@ref) or an [`APEquipollentVector`](@ref).
For the angle of a point around a center, see [`polar_angle`](@ref).
"""
slope_angle(obj) = atan(direction(obj)[2], direction(obj)[1])
"""
    angle_measure_between(u, v)

The signed measure (in radians, in `(-π, π]`) of the rotation that takes
vector `u` onto `v` (counterclockwise positive).
"""
angle_measure_between(u, v) = atan(cross2(u, v), dot(u, v))
"""
    is_parallel(l1, l2; atol=1e-9)

Whether two `APLine`s (or `APRay`s / `APSegment`s) have the same direction.
"""
function is_parallel(l1, l2; atol=1e-9)
    d1, d2 = direction(l1), direction(l2)
    return abs(cross2(d1, d2)) <= atol * norm(d1) * norm(d2)
end
"""
    is_perpendicular(l1, l2; atol=1e-9)

Whether two `APLine`s (or `APRay`s / `APSegment`s) are orthogonal.
"""
function is_perpendicular(l1, l2; atol=1e-9)
    d1, d2 = direction(l1), direction(l2)
    return abs(dot(d1, d2)) <= atol * norm(d1) * norm(d2)
end
_other_two(i::Integer) = ((2, 3), (1, 3), (1, 2))[i]
