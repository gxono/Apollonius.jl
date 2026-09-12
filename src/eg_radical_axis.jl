# -------------------------------------------------------------------------
# Phase 7 (continued): mechanical port of radical_axis.jl onto
# EGPoint/EGCircle2. Formula bodies are unchanged from the Point2-based
# originals; `_radical_foot` is already defined for EGCircle2 in
# eg_intersections.jl.
# -------------------------------------------------------------------------

"""
    power_of_point(p::EGPoint, c::EGCircle2)

The power of `p` with respect to `c`: `distance(p, c.center)^2 - c.r^2`.
Negative inside `c`, zero on `c`, positive outside.
"""
power_of_point(p::EGPoint, c::EGCircle2) = dot(p - c.center, p - c.center) - c.r^2

"""
    radical_axis(c1::EGCircle2, c2::EGCircle2; atol=1e-9)

The radical axis of `c1` and `c2`: the line of points with equal power
with respect to both circles, perpendicular to the line joining their
centers. Defined even when the circles don't intersect (it coincides with
`intersection(c1, c2)` when they do, and with `perpendicular_bisector` of
the centers when `c1.r == c2.r`).
"""
function radical_axis(c1::EGCircle2, c2::EGCircle2; atol=1e-9)
    tol = sqrt(atol) * max(norm(c1.center), norm(c2.center), 1.0)
    distance(c1.center, c2.center) <= tol && throw(ArgumentError("radical_axis: c1 and c2 are concentric"))
    m, _, _, _ = _radical_foot(c1, c2)
    return perpendicular_through(EGLine(c1.center, c2.center), m)
end

"""
    radical_center(c1::EGCircle2, c2::EGCircle2, c3::EGCircle2)

The radical center of `c1`, `c2` and `c3`: the common point of their three
pairwise radical axes (they always concur, unless the three centers are
collinear).
"""
radical_center(c1::EGCircle2, c2::EGCircle2, c3::EGCircle2) =
    only(intersection(radical_axis(c1, c2), radical_axis(c2, c3)))

"""
    radical_circle(c1::EGCircle2, c2::EGCircle2, c3::EGCircle2)

The radical circle of `c1`, `c2` and `c3`: centered at their
[`radical_center`](@ref), orthogonal to all three (its radius squared
equals their common power with respect to the radical center). Throws an
`ArgumentError` if that power is negative (the radical center lies inside
the circles, so no real orthogonal circle exists).
"""
function radical_circle(c1::EGCircle2, c2::EGCircle2, c3::EGCircle2)
    rc = radical_center(c1, c2, c3)
    p = power_of_point(rc, c1)
    p < 0 && throw(ArgumentError("radical_circle: radical center is inside the circles (negative power); no real orthogonal circle exists"))
    return EGCircle2(rc, sqrt(p))
end
