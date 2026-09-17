# -------------------------------------------------------------------------
# Tangency and Apollonius-problem constructions on EGPoint/EGLine/EGCircle2.
# -------------------------------------------------------------------------

"""
    tangent_length(c::EGCircle2, p::EGPoint)

Length of the tangent segment from `p` to `c` (`0` if `p` is inside `c`).
"""
tangent_length(c::EGCircle2, p::EGPoint) = sqrt(max(distance(c.center, p)^2 - c.r^2, 0.0))
tangent_length(p::EGPoint, c::EGCircle2) = tangent_length(c, p)

"""
    tangent_points(c::EGCircle2, p::EGPoint; atol=1e-9)

Points of tangency on `c` of the lines from `p` tangent to `c`. Returns a
`Vector{EGPoint{2,Float64}}` with 0 points (`p` strictly inside `c`), 1
point (`p` on `c`) or 2 points (`p` outside `c`).
"""
function tangent_points(c::EGCircle2, p::EGPoint; atol=1e-9)
    d = distance(c.center, p)
    r = c.r
    tol = sqrt(atol) * max(r, norm(c.center), 1.0)

    d < r - tol && return EGPoint{2,Float64}[]
    abs(d - r) <= tol && return [EGPoint(p[1], p[2])]

    u = (p - c.center) / d
    base = c.center + r * u
    alpha = acos(clamp(r / d, -1.0, 1.0))
    return [EGPoint(rotate(base, alpha, c.center)[1], rotate(base, alpha, c.center)[2]),
        EGPoint(rotate(base, -alpha, c.center)[1], rotate(base, -alpha, c.center)[2])]
end
tangent_points(p::EGPoint, c::EGCircle2; atol=1e-9) = tangent_points(c, p; atol=atol)

"""
    tangent_lines(c::EGCircle2, p::EGPoint; atol=1e-9)

The line(s) through `p` tangent to `c` (0, 1 or 2 of them, see [`tangent_points`](@ref)).
When `p` is on `c`, this is the single tangent line *at* `p` (perpendicular
to the radius there) rather than the degenerate `EGLine(p, p)`.
"""
function tangent_lines(c::EGCircle2, p::EGPoint; atol=1e-9)
    tps = tangent_points(c, p; atol=atol)
    length(tps) == 1 && isapprox(tps[1], p; atol=atol) && return [EGLine(p, p + orthogonal(p - c.center))]
    return [EGLine(p, t) for t in tps]
end
tangent_lines(p::EGPoint, c::EGCircle2; atol=1e-9) = tangent_lines(c, p; atol=atol)

"""
    tangent_parallel(c::EGCircle2, l::EGLine)

The two tangent lines to `c` that are parallel to `l`: the tangents at the
two points where the diameter perpendicular to `l` meets `c`.
"""
function tangent_parallel(c::EGCircle2, l::EGLine)
    perp = perpendicular_through(l, c.center)
    p1, p2 = intersection(perp, c)
    tangent_at(p) = perpendicular_through(EGLine(c.center, p), p)
    return (tangent_at(p1), tangent_at(p2))
end

"""
    external_similitude_center(c1::EGCircle2, c2::EGCircle2; atol=1e-9)

The external center of similitude of `c1` and `c2`: the point dividing the
segment of centers *externally* in ratio `c1.r : c2.r` (the common
intersection of the external tangent lines, and of any line through both
centers' "same-direction" homothety images). Throws an `ArgumentError` if
the radii are equal (the external tangents are then parallel, with no
finite center).
"""
function external_similitude_center(c1::EGCircle2, c2::EGCircle2; atol=1e-9)
    abs(c1.r - c2.r) <= atol * max(c1.r, c2.r, 1.0) &&
        throw(ArgumentError("external_similitude_center: c1 and c2 have equal radii (no finite external center)"))
    return c1.center - (c1.r / (c2.r - c1.r)) * (c2.center - c1.center)
end

"""
    internal_similitude_center(c1::EGCircle2, c2::EGCircle2; atol=1e-9)

The internal center of similitude of `c1` and `c2`: the point dividing the
segment of centers *internally* in ratio `c1.r : c2.r`. Throws an
`ArgumentError` if both radii are (near) zero.
"""
function internal_similitude_center(c1::EGCircle2, c2::EGCircle2; atol=1e-9)
    s = c1.r + c2.r
    s <= atol && throw(ArgumentError("internal_similitude_center: c1 and c2 have zero total radius"))
    return c1.center + (c1.r / s) * (c2.center - c1.center)
end

"""
    external_tangent_lines(c1::EGCircle2, c2::EGCircle2; atol=1e-9)

The common external tangent lines of `c1` and `c2` (the ones that don't
cross the segment between the centers). Returns 0, 1 or 2 lines, each as
`EGLine(p1, p2)` with `p1` the point of tangency on `c1` and `p2` the
point of tangency on `c2`.
"""
function external_tangent_lines(c1::EGCircle2, c2::EGCircle2; atol=1e-9)
    if abs(c1.r - c2.r) <= atol * max(c1.r, c2.r, 1.0)
        d = c2.center - c1.center
        len = norm(d)
        len <= atol * max(norm(c1.center), norm(c2.center), 1.0) && return EGLine{2,Float64}[]
        n = orthogonal(d / len)
        return [EGLine(c1.center + c1.r * n, c2.center + c1.r * n),
            EGLine(c1.center - c1.r * n, c2.center - c1.r * n)]
    end

    # The external similitude center is the fixed point of the homothety
    # (ratio c2.r/c1.r) that sends c1 onto c2, so it maps each tangent
    # point on c1 to the matching tangent point on the *same* common
    # tangent line, on c2 -- giving both endpoints on their own circle
    # instead of one of them being the (off-circle) similitude center.
    center_e = external_similitude_center(c1, c2; atol=atol)
    k = c2.r / c1.r
    return [EGLine(t, homothety(t, k, center_e)) for t in tangent_points(c1, center_e; atol=atol)]
end

"""
    internal_tangent_lines(c1::EGCircle2, c2::EGCircle2; atol=1e-9)

The common internal tangent lines of `c1` and `c2` (the ones that cross the
segment between the centers). Returns 0, 1 or 2 lines; empty when the
circles overlap (no internal tangents exist). Each is `EGLine(p1, p2)`
with `p1` the point of tangency on `c1` and `p2` the point of tangency on
`c2` (see [`external_tangent_lines`](@ref) for the same convention there).
"""
function internal_tangent_lines(c1::EGCircle2, c2::EGCircle2; atol=1e-9)
    c1.r + c2.r <= atol && return EGLine{2,Float64}[]
    center_i = internal_similitude_center(c1, c2; atol=atol)
    k = -c2.r / c1.r
    return [EGLine(t, homothety(t, k, center_i)) for t in tangent_points(c1, center_i; atol=atol)]
end

# -------------------------------------------------------------------------
# Circles of a *given* radius tangent to two lines / a line and a circle /
# two circles.
# -------------------------------------------------------------------------

"""
    offset_line(l::EGLine, d::Real)

The line parallel to `l`, shifted by signed distance `d` along its normal
(positive `d` shifts towards the left of `l.p1 -> l.p2`).
"""
function offset_line(l::EGLine, d::Real)
    n = orthogonal(direction(l) / norm(direction(l)))
    return EGLine(l.p1 + d * n, l.p2 + d * n)
end

function _circles_coincide(a::EGCircle2, b::EGCircle2; atol=1e-9)
    tol = sqrt(atol) * max(norm(a.center), norm(b.center), a.r, b.r, 1.0)
    distance(a.center, b.center) <= tol && abs(a.r - b.r) <= tol
end

function _dedupe_circles(cs::Vector{EGCircle2{Float64}}; atol=1e-9)
    out = EGCircle2{Float64}[]
    for c in cs
        any(o -> _circles_coincide(o, c; atol=atol), out) || push!(out, c)
    end
    return out
end

# Drop solutions that coincide with one of the given circles: a circle is
# technically (degenerately) "tangent" to itself under `_tangent_ok`'s
# formula, so highly symmetric inputs (e.g. three mutually tangent circles)
# can otherwise return one of the given circles back as a spurious solution.
# Untyped — works via `_circles_coincide`, overloaded per circle type above.
_exclude_given(sols, given...; atol=1e-9) =
    filter(s -> !any(g -> _circles_coincide(s, g; atol=atol), given), sols)

"""
    tangent_circles_with_radius(l1::EGLine, l2::EGLine, r::Real; atol=1e-9)
    tangent_circles_with_radius(l::EGLine, c::EGCircle2, r::Real; atol=1e-9)
    tangent_circles_with_radius(c1::EGCircle2, c2::EGCircle2, r::Real; atol=1e-9)

The circles of given radius `r` tangent to both `l1`/`l2` (or `l`/`c`, or
`c1`/`c2`). Returns a `Vector{EGCircle2{Float64}}` with up to 4 solutions
(duplicates removed). If `l1` and `l2` are parallel, this always returns an
empty vector: the only radius with solutions is `r = distance(l1,l2)/2`,
for which there is a whole line of valid centers rather than finitely many
circles, and that degenerate case is not handled.
"""
function tangent_circles_with_radius(l1::EGLine, l2::EGLine, r::Real; atol=1e-9)
    results = EGCircle2{Float64}[]
    for s1 in (1, -1), s2 in (1, -1)
        ol1, ol2 = offset_line(l1, s1 * r), offset_line(l2, s2 * r)
        for p in intersection(ol1, ol2; atol=atol)
            push!(results, EGCircle2(p, Float64(r)))
        end
    end
    return _dedupe_circles(results; atol=atol)
end

function tangent_circles_with_radius(l::EGLine, c::EGCircle2, r::Real; atol=1e-9)
    results = EGCircle2{Float64}[]
    for s in (1, -1), R in (c.r + r, abs(c.r - r))
        R < 0 && continue
        ol = offset_line(l, s * r)
        aux = EGCircle2(c.center, R)
        for p in intersection(ol, aux; atol=atol)
            push!(results, EGCircle2(p, Float64(r)))
        end
    end
    return _dedupe_circles(results; atol=atol)
end
tangent_circles_with_radius(c::EGCircle2, l::EGLine, r::Real; atol=1e-9) = tangent_circles_with_radius(l, c, r; atol=atol)

function tangent_circles_with_radius(c1::EGCircle2, c2::EGCircle2, r::Real; atol=1e-9)
    results = EGCircle2{Float64}[]
    for R1 in (c1.r + r, abs(c1.r - r)), R2 in (c2.r + r, abs(c2.r - r))
        (R1 < 0 || R2 < 0) && continue
        aux1, aux2 = EGCircle2(c1.center, R1), EGCircle2(c2.center, R2)
        for p in intersection(aux1, aux2; atol=atol)
            push!(results, EGCircle2(p, Float64(r)))
        end
    end
    return _dedupe_circles(results; atol=atol)
end
