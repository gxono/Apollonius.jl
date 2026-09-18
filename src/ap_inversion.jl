"""
    inversion(p::APPoint, c::APCircle2)

The image of `p` under inversion with respect to circle `c` (center `O`,
radius `r`): the point `p'` on ray `O -> p` such that `|Op| * |Op'| = r^2`.
"""
function inversion(p::APPoint, c::APCircle2)
    v = p - c.center
    d2 = dot(v, v)
    d2 <= 0 && throw(ArgumentError("inversion: p coincides with the center of c"))
    return c.center + (c.r^2 / d2) * v
end
"""
    invert(p::APPoint, center::APPoint; k::Real=1.0, atol=1e-9)

The image of `p` under inversion with respect to the circle centered at
`center` with radius `k` -- i.e. `inversion(p, APCircle2(center, k))`,
spelled with the same `(shape, center; k, atol)` convention every other
`invert` method here uses (`atol` is accepted only for that symmetry;
there's no degenerate configuration for a bare point to guard against
beyond what `inversion` itself already throws for). Without this method,
`invert(p, center; k=...)` would silently match
[`invert(center::APPoint; k, atol)`](@ref)'s one-argument curried form
instead (built for `p |> invert(center)`), returning a *function* rather
than the inverted point.
"""
invert(p::APPoint, center::APPoint; k::Real=1.0, atol=1e-9) = inversion(p, APCircle2(center, k))
"""
    invert(l::APLine, center::APPoint; k::Real=1.0, atol=1e-9)

The image of `l` under inversion with respect to the circle centered at
`center` with radius `k`. A line not through the inversion center always
inverts to a circle through it. Throws an `ArgumentError` if `l` passes
through `center` (its image would be `l` itself, not a circle).
"""
function invert(l::APLine, center::APPoint; k::Real=1.0, atol=1e-9)
    f = projection(center, l)
    distance(center, f) <= sqrt(atol) * max(k, 1.0) &&
        throw(ArgumentError("invert: l passes through center; its image is itself, not a circle"))
    finv = inversion(f, APCircle2(center, k))
    return APCircle2(midpoint(center, finv), distance(center, finv) / 2)
end
"""
    invert(c::APCircle2, center::APPoint; k::Real=1.0, atol=1e-9)

The image of `c` under inversion with respect to the circle centered at
`center` with radius `k`. A circle through `center` inverts to an
`APLine` (the mirror image of [`invert(::APLine, ::APPoint)`](@ref)); any
other circle inverts to another `APCircle2` -- so this returns a
`Union{APCircle2,APLine}`.
"""
function invert(c::APCircle2, center::APPoint; k::Real=1.0, atol=1e-9)
    center == c.center && return APCircle2(center, k^2 / c.r)
    if abs(distance(center, c.center) - c.r) <= sqrt(atol) * max(c.r, k, 1.0)
        antipode = c.center + (c.center - center)
        antipode_inv = inversion(antipode, APCircle2(center, k))
        return perpendicular_through(APLine(center, c.center), antipode_inv)
    end
    axis = APLine(center, c.center)
    a, b = intersection(axis, c; atol=atol)
    ainv, binv = inversion(a, APCircle2(center, k)), inversion(b, APCircle2(center, k))
    return APCircle2(midpoint(ainv, binv), distance(ainv, binv) / 2)
end
function _arc_sweep_contains(arc::APCircularArc2, p::APPoint)
    a1 = atan(arc.p1[2] - arc.circle.center[2], arc.p1[1] - arc.circle.center[1])
    ap = atan(p[2] - arc.circle.center[2], p[1] - arc.circle.center[1])
    return mod(ap - a1, 2π) <= measure(arc)
end
"""
    invert(s::APSegment, center::APPoint; k::Real=1.0, atol=1e-9)

The image of `s` under inversion with respect to the circle centered at
`center` with radius `k`. A segment on a line through `center` inverts to
another `APSegment` (on the same line); any other segment inverts to an
[`APCircularArc2`](@ref) of [`invert(::APLine, ::APPoint)`](@ref)'s image
circle -- specifically the arc that does *not* pass through `center`, since
that point is the image of the line's own point at infinity, which the
segment (being finite) never reaches. So this returns a
`Union{APSegment,APCircularArc2}`.
"""
function invert(s::APSegment, center::APPoint; k::Real=1.0, atol=1e-9)
    p1, p2 = s[1], s[2]
    tol = sqrt(atol) * max(k, distance(p1, p2), 1.0)
    ci = APCircle2(center, k)
    if distance(center, APLine(p1, p2)) <= tol
        return APSegment(inversion(p1, ci), inversion(p2, ci))
    end
    circ = invert(APLine(p1, p2), center; k=k, atol=atol)
    ip1, ip2 = inversion(p1, ci), inversion(p2, ci)
    candidate = APCircularArc2(circ, ip1, ip2)
    return _arc_sweep_contains(candidate, center) ? APCircularArc2(circ, ip2, ip1) : candidate
end
"""
    invert(t::APTriangle, center::APPoint; k::Real=1.0, atol=1e-9)
    invert(pg::APStraightNgon, center::APPoint; k::Real=1.0, atol=1e-9)

The image of `t`/`pg` under inversion with respect to the circle centered
at `center` with radius `k`: each side inverts independently (see
[`invert(::APSegment, ::APPoint)`](@ref)) to a straight `APSegment` or an
`APCircularArc2`, and the results are collected into an
[`APCurvilinearNgon2`](@ref). Throws an `ArgumentError` if any vertex
coincides with `center` (that vertex has no image under inversion).
"""
invert(t::APTriangle, center::APPoint; k::Real=1.0, atol=1e-9) =
    APCurvilinearNgon2([invert(s, center; k=k, atol=atol) for s in sides(t)])
invert(pg::APStraightNgon, center::APPoint; k::Real=1.0, atol=1e-9) =
    APCurvilinearNgon2([invert(s, center; k=k, atol=atol) for s in sides(pg)])
"""
    inversion_neg(p::APPoint, c::APCircle2)

The image of `p` under inversion of *negative* ratio with respect to `c`:
the ordinary (positive) [`inversion`](@ref), point-reflected through
`c.center` -- i.e. the point on ray `p -> O` (not `O -> p`) at distance
`r^2/|Op|` from `O`.
"""
inversion_neg(p::APPoint, c::APCircle2) = reflection(inversion(p, c), c.center)
"""
    invert_neg(l::APLine, center::APPoint; k::Real=1.0, atol=1e-9)
    invert_neg(c::APCircle2, center::APPoint; k::Real=1.0, atol=1e-9)

The image of `l`/`c` under inversion of *negative* ratio with respect to
the circle centered at `center` with radius `k`: the ordinary
[`invert`](@ref) image, point-reflected through `center`.
"""
invert_neg(l::APLine, center::APPoint; k::Real=1.0, atol=1e-9) = reflection(invert(l, center; k=k, atol=atol), center)
invert_neg(c::APCircle2, center::APPoint; k::Real=1.0, atol=1e-9) = reflection(invert(c, center; k=k, atol=atol), center)
"""
    invert(center::APPoint; k::Real=1.0, atol=1e-9)

`p -> invert(p, center; k=k, atol=atol)` -- for composing with `|>`/`map`/`∘`,
same as [`rotate`](@ref)/[`homothety`](@ref)'s own single-argument forms.
Unlike those, this is *not* an [`APAffineMap`](@ref) (circle inversion
isn't affine), so it's a plain closure rather than a reusable, inspectable
value.
"""
invert(center::APPoint; k::Real=1.0, atol=1e-9) = shape -> invert(shape, center; k=k, atol=atol)
"""
    invert_neg(center::APPoint; k::Real=1.0, atol=1e-9)

`p -> invert_neg(p, center; k=k, atol=atol)` -- see the single-argument
[`invert`](@ref).
"""
invert_neg(center::APPoint; k::Real=1.0, atol=1e-9) = shape -> invert_neg(shape, center; k=k, atol=atol)
"""
    invert(v::AbstractVector{<:APObject}, center::APPoint; k::Real=1.0, atol=1e-9)
    invert_neg(v::AbstractVector{<:APObject}, center::APPoint; k::Real=1.0, atol=1e-9)

Invert every element of `v` -- see the `AbstractVector` forms of
[`translate`](@ref)/[`rotate`](@ref)/[`homothety`](@ref)/[`reflection`](@ref)
for why this exists (a plain `Vector` of shapes, e.g. from
[`intersection`](@ref)/[`tangent_points`](@ref), used as a single item).
The same overload exists for a `Tuple` of shapes (e.g. `vertices(t)`, or
a broadcast `f.(vertices(t), ...)`), for the same reason.
"""
invert(v::AbstractVector{<:APObject}, center::APPoint; k::Real=1.0, atol=1e-9) = invert.(v, center; k=k, atol=atol)
invert_neg(v::AbstractVector{<:APObject}, center::APPoint; k::Real=1.0, atol=1e-9) = invert_neg.(v, center; k=k, atol=atol)
invert(t::Tuple{Vararg{APObject}}, center::APPoint; k::Real=1.0, atol=1e-9) = invert.(t, center; k=k, atol=atol)
invert_neg(t::Tuple{Vararg{APObject}}, center::APPoint; k::Real=1.0, atol=1e-9) = invert_neg.(t, center; k=k, atol=atol)
"""
    polar_line(c::APCircle2, p::APPoint; atol=1e-9)

The polar line of `p` with respect to `c`: the line through `inversion(p, c)`
perpendicular to the line from `c.center` to `p`. When `p` is outside `c`,
this is the chord of contact of the two tangent lines from `p` (see
[`tangent_points`](@ref)); when `p` is on `c`, it's the tangent line at `p`.
`nothing` when `p` is `c`'s center (matching the
[`polar_line(::APEllipse2, ::APPoint)`](@ref)/`APHyperbola2`/`APParabola2`
methods), rather than throwing.
"""
function polar_line(c::APCircle2, p::APPoint; atol=1e-9)
    distance(p, c.center) <= sqrt(atol) * max(c.r, 1.0) && return nothing
    return perpendicular_through(APLine(c.center, p), inversion(p, c))
end
"""
    pole(c::APCircle2, l::APLine)

The pole of `l` with respect to `c`: the point whose polar line (see
[`polar_line`](@ref)) is `l`. Throws an `ArgumentError` if `l` passes
through `c.center` (its pole would be the point at infinity).
"""
function pole(c::APCircle2, l::APLine)
    foot = projection(c.center, l)
    isapprox(foot, c.center) && throw(ArgumentError("pole: l passes through the center of c; its pole is the point at infinity"))
    return inversion(foot, c)
end
