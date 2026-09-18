"""
    power_of_point(p::APPoint, c::APCircle2)

The power of `p` with respect to `c`: `distance(p, c.center)^2 - c.r^2`.
Negative inside `c`, zero on `c`, positive outside.
"""
power_of_point(p::APPoint, c::APCircle2) = dot(p - c.center, p - c.center) - c.r^2
"""
    radical_axis(c1::APCircle2, c2::APCircle2; atol=1e-9)

The radical axis of `c1` and `c2`: the line of points with equal power
with respect to both circles, perpendicular to the line joining their
centers. Defined even when the circles don't intersect (it coincides with
`intersection(c1, c2)` when they do, and with `perpendicular_bisector` of
the centers when `c1.r == c2.r`).
"""
function radical_axis(c1::APCircle2, c2::APCircle2; atol=1e-9)
    tol = sqrt(atol) * max(norm(c1.center), norm(c2.center), 1.0)
    distance(c1.center, c2.center) <= tol && throw(ArgumentError("radical_axis: c1 and c2 are concentric"))
    m, _, _, _ = _radical_foot(c1, c2)
    return perpendicular_through(APLine(c1.center, c2.center), m)
end
"""
    radical_center(c1::APCircle2, c2::APCircle2, c3::APCircle2)

The radical center of `c1`, `c2` and `c3`: the common point of their three
pairwise radical axes (they always concur, unless the three centers are
collinear).
"""
radical_center(c1::APCircle2, c2::APCircle2, c3::APCircle2) =
    only(intersection(radical_axis(c1, c2), radical_axis(c2, c3)))
"""
    radical_circle(c1::APCircle2, c2::APCircle2, c3::APCircle2)

The radical circle of `c1`, `c2` and `c3`: centered at their
[`radical_center`](@ref), orthogonal to all three (its radius squared
equals their common power with respect to the radical center). Throws an
`ArgumentError` if that power is negative (the radical center lies inside
the circles, so no real orthogonal circle exists).
"""
function radical_circle(c1::APCircle2, c2::APCircle2, c3::APCircle2)
    rc = radical_center(c1, c2, c3)
    p = power_of_point(rc, c1)
    p < 0 && throw(ArgumentError("radical_circle: radical center is inside the circles (negative power); no real orthogonal circle exists"))
    return APCircle2(rc, sqrt(p))
end
"""
    orthogonal_circle(c::APCircle2, p::APPoint)

The circle centered at `p`, orthogonal to `c` (its radius squared equals
`p`'s power with respect to `c`, same idea as [`radical_circle`](@ref)).
Throws `ArgumentError` when `p` isn't strictly outside `c`, since no real
circle centered there can be orthogonal to `c`.
"""
function orthogonal_circle(c::APCircle2, p::APPoint)
    pw = power_of_point(p, c)
    pw <= 0 && throw(ArgumentError("orthogonal_circle: p must lie strictly outside c"))
    return APCircle2(p, sqrt(pw))
end
"""
    orthogonal_circle(c::APCircle2, p1::APPoint, p2::APPoint; atol=1e-9)

The circle orthogonal to `c`, passing through `p1` and `p2`: built from the
classical inversive-geometry fact that the circle through `p1`, `p2` and
the [`inversion`](@ref) of `p1` with respect to `c` is orthogonal to `c`.

Throws `ArgumentError` in the two configurations this construction can't
resolve on its own: `p1`/`p2` sitting exactly on `c` (its own inverse,
collapsing the 3-point circumcircle), or `p1`/`p2` being an exact inverse
pair with respect to `c` (same collapse, from the other side) -- both
have genuine solutions (a whole family, in the first case), but picking
one needs extra case analysis this package doesn't implement yet. Any
other collinear-degenerate input surfaces as the ordinary `ArgumentError`
from [`APCircle2`](@ref)`(p1, p2, p3)`.
"""
function orthogonal_circle(c::APCircle2, p1::APPoint, p2::APPoint; atol=1e-9)
    tol = sqrt(atol) * max(c.r, norm(c.center), 1.0)
    (abs(distance(p1, c.center) - c.r) <= tol || abs(distance(p2, c.center) - c.r) <= tol) &&
        throw(ArgumentError("orthogonal_circle: p1/p2 exactly on c isn't supported (infinite family of solutions)"))
    z = inversion(p1, c)
    distance(z, p2) <= tol &&
        throw(ArgumentError("orthogonal_circle: p1/p2 are an exact inverse pair with respect to c, not supported yet"))
    return APCircle2(p1, p2, z)
end
