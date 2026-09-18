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
"""
    midcircle(c1::APCircle2, c2::APCircle2; atol=1e-9)

The circle(s) of antisimilitude of `c1` and `c2`: circle(s) `M` such that
inverting in `M` (`invert(c1, M.center; k=M.r)`, see [`invert`](@ref))
swaps `c1` and `c2`. How many, and how they're built, depends on how the
two circles relate ([`circles_position`](@ref)):

  - externally disjoint or externally tangent: one, centered at the
    [`external_similitude_center`](@ref), with radius the geometric mean
    of the tangent lengths ([`tangent_length`](@ref)) from that center to
    `c1` and to `c2`;
  - secant: two, centered at the external and internal similitude
    centers respectively, both passing through either intersection point
    of `c1` and `c2` (and so, by symmetry, through both);
  - one strictly inside the other (disjoint or internally tangent): one,
    centered at the internal similitude center, [`orthogonal_circle`](@ref)
    to whichever of two candidate "diameter circles" (built from where
    the line through both centers crosses `c1` and `c2`) turns out
    smaller.

Throws `ArgumentError` for `c1`/`c2` identical or concentric (no
similitude center exists either way).
"""
function midcircle(c1::APCircle2, c2::APCircle2; atol=1e-9)
    pos = circles_position(c1, c2; atol=atol)
    if pos in (:disjoint_ext, :tangent_ext)
        i = external_similitude_center(c1, c2; atol=atol)
        return [APCircle2(i, sqrt(tangent_length(c1, i) * tangent_length(c2, i)))]
    elseif pos == :secant
        i = external_similitude_center(c1, c2; atol=atol)
        j = internal_similitude_center(c1, c2; atol=atol)
        p = intersection(c1, c2; atol=atol)[1]
        return [APCircle2(i, distance(i, p)), APCircle2(j, distance(j, p))]
    elseif pos in (:disjoint_int, :tangent_int)
        r1, r2 = c1.r, c2.r
        centerline = APLine(c1.center, c2.center)
        a, b = intersection(centerline, c1; atol=atol)
        cc, dd = intersection(centerline, c2; atol=atol)
        u, v, rr, ss = r1 < r2 ? (a, b, cc, dd) : (cc, dd, a, b)
        if on_segment(u, APSegment(ss, v); atol=atol)
            cand1 = APCircle2(midpoint(rr, v), distance(rr, v) / 2)
            cand2 = APCircle2(midpoint(u, ss), distance(u, ss) / 2)
        else
            cand1 = APCircle2(midpoint(ss, v), distance(ss, v) / 2)
            cand2 = APCircle2(midpoint(u, rr), distance(u, rr) / 2)
        end
        smaller = cand1.r < cand2.r ? cand1 : cand2
        j = internal_similitude_center(c1, c2; atol=atol)
        return [orthogonal_circle(smaller, j)]
    else
        throw(ArgumentError("midcircle: c1 and c2 must not be identical or concentric"))
    end
end
"""
    midcircle(c::APCircle2, l::APLine; atol=1e-9)
    midcircle(l::APLine, c::APCircle2; atol=1e-9)

The circle(s) of antisimilitude of `c` and `l`: circle(s) `M`, centered
*on* `c` itself, such that inverting in `M` sends `c` to `l` (a line is
the degenerate "circle through infinity", and this is the analogue of
[`midcircle(::APCircle2, ::APCircle2)`](@ref) for that case; see there
for the general idea). How many, and where, depends on
[`line_circle_position`](@ref):

  - disjoint: one, centered at whichever of the two points where the
    perpendicular from `c.center` to `l` meets `c` is *farther* from `l`;
  - tangent: one, centered at the [`antipode`](@ref) (on `c`) of the
    tangency point;
  - secant: two, centered at the same two perpendicular-foot points as
    the disjoint case, each passing through either intersection point of
    `l` and `c` (and so, by symmetry, through both).

Note on the disjoint case: tkz-elements (the reference this package's
Adams/Soddy/symmedial-style additions were checked against) returns two
circles here, one centered at each of the two perpendicular-foot points.
Deriving the *nearer* point's radius from first principles and checking
the result by inverting `c` back through it shows that circle never
actually maps `c` onto `l` -- there is only one real solution in the
disjoint case, mirroring how [`midcircle`](@ref)`(::APCircle2,
::APCircle2)` also has exactly one solution for externally disjoint
circles (a line is the "infinite-radius, externally disjoint" case, so
this is consistent rather than an unrelated one-off).
"""
function midcircle(c::APCircle2, l::APLine; atol=1e-9)
    pos = line_circle_position(l, c; atol=atol)
    O, r = c.center, c.r
    A, B = intersection(perpendicular_through(l, O), c; atol=atol)
    if pos == :disjoint
        far = distance(A, l) > distance(B, l) ? A : B
        return [APCircle2(far, sqrt(2 * r * distance(far, l)))]
    elseif pos == :tangent
        S = only(intersection(l, c; atol=atol))
        K = antipode(S, c)
        return [APCircle2(K, distance(K, S))]
    else
        p = intersection(l, c; atol=atol)[1]
        return [APCircle2(A, distance(A, p)), APCircle2(B, distance(B, p))]
    end
end
midcircle(l::APLine, c::APCircle2; atol=1e-9) = midcircle(c, l; atol=atol)
