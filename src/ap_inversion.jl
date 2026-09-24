"""
    invert(shape, c::APCircle2)
    invert(shape, center::APPoint; k::Real=1.0, atol=1e-9)

The image of `shape` under inversion with respect to a circle: `c` directly,
or the circle centered at `center` with radius `k`. Defined for a point, a
line, a ray, a segment, a circle, a triangle, a quadrilateral, a straight
n-gon and every conic arc; an ellipse, a hyperbola or a parabola (and their
arcs) do not generally invert to another conic, so those return a sampled
[`APParametricCurve2`](@ref) instead. See [`invert_neg`](@ref) for the
negative-ratio variant.

| Keyword | Default | Meaning |
|:--------|:--------|:--------|
| `k` | `1.0` | radius of the circle of inversion, when given by `center` |
| `atol` | `1e-9` | tolerance for the degenerate configurations below |
"""
function invert(p::APPoint, c::APCircle2; atol=1e-9)
    v = p - c.center
    d2 = dot(v, v)
    d2 <= 0 && throw(ArgumentError("invert: p coincides with the center of c"))
    return c.center + (c.r^2 / d2) * v
end
invert(shape, center::APPoint; k::Real=1.0, atol=1e-9) = invert(shape, APCircle2(center, k); atol=atol)
"""
    invert(l::APLine, c::APCircle2; atol=1e-9)

A line not through `c.center` always inverts to a circle through it.
Throws an `ArgumentError` if `l` passes through `c.center` (its image
would be `l` itself, not a circle).
"""
function invert(l::APLine, c::APCircle2; atol=1e-9)
    f = projection(c.center, l)
    distance(c.center, f) <= sqrt(atol) * max(c.r, 1.0) &&
        throw(ArgumentError("invert: l passes through the center of c; its image is itself, not a circle"))
    finv = invert(f, c)
    return APCircle2(midpoint(c.center, finv), distance(c.center, finv) / 2)
end
"""
    invert(circ::APCircle2, c::APCircle2; atol=1e-9)

A circle through `c.center` inverts to an `APLine` (the mirror image of
[`invert(::APLine, ::APCircle2)`](@ref)); any other circle inverts to
another `APCircle2`: so this returns a `Union{APCircle2,APLine}`.
"""
function invert(circ::APCircle2, c::APCircle2; atol=1e-9)
    c.center == circ.center && return APCircle2(c.center, c.r^2 / circ.r)
    if abs(distance(c.center, circ.center) - circ.r) <= sqrt(atol) * max(circ.r, c.r, 1.0)
        antipode = circ.center + (circ.center - c.center)
        antipode_inv = invert(antipode, c)
        return perpendicular_through(APLine(c.center, circ.center), antipode_inv)
    end
    axis = APLine(c.center, circ.center)
    a, b = intersection(axis, circ; atol=atol)
    ainv, binv = invert(a, c), invert(b, c)
    return APCircle2(midpoint(ainv, binv), distance(ainv, binv) / 2)
end
function _arc_sweep_contains(arc::APCircularArc2, p::APPoint)
    a1 = atan(arc.p1[2] - arc.circle.center[2], arc.p1[1] - arc.circle.center[1])
    ap = atan(p[2] - arc.circle.center[2], p[1] - arc.circle.center[1])
    return mod(ap - a1, 2π) <= measure(arc)
end
"""
    invert(s::APSegment, c::APCircle2; atol=1e-9)

A segment on a line through `c.center` inverts to another `APSegment` (on
the same line); any other segment inverts to an [`APCircularArc2`](@ref)
of [`invert(::APLine, ::APCircle2)`](@ref)'s image circle: specifically
the arc that does *not* pass through `c.center`, since that point is the
image of the line's own point at infinity, which the segment (being
finite) never reaches. So this returns a `Union{APSegment,APCircularArc2}`.
"""
function invert(s::APSegment, c::APCircle2; atol=1e-9)
    p1, p2 = s[1], s[2]
    tol = sqrt(atol) * max(c.r, distance(p1, p2), 1.0)
    if distance(c.center, APLine(p1, p2)) <= tol
        return APSegment(invert(p1, c), invert(p2, c))
    end
    circ = invert(APLine(p1, p2), c; atol=atol)
    ip1, ip2 = invert(p1, c), invert(p2, c)
    candidate = APCircularArc2(circ, ip1, ip2)
    return _arc_sweep_contains(candidate, c.center) ? APCircularArc2(circ, ip2, ip1) : candidate
end
"""
    invert(r::APRay, c::APCircle2; atol=1e-9)

The image of a ray, built the same way as [`invert(::APSegment, ::APCircle2)`](@ref)
from its two defining points, except that a ray not through `c.center`
inverts to an [`APCircularArc2`](@ref) that *does* end at `c.center`'s
image side: the point at infinity the ray reaches becomes `c.center`
itself, one endpoint of the image arc.
"""
function invert(r::APRay, c::APCircle2; atol=1e-9)
    o, t = r.origin, r.through
    tol = sqrt(atol) * max(c.r, distance(o, t), 1.0)
    distance(c.center, APLine(o, t)) <= tol && throw(ArgumentError("invert: a ray on a line through c.center has an unbounded image"))
    circ = invert(APLine(o, t), c; atol=atol)
    io = invert(o, c)
    return APCircularArc2(circ, io, c.center)
end
"""
    invert(t::APTriangle, c::APCircle2; atol=1e-9)
    invert(q::APQuadrilateral, c::APCircle2; atol=1e-9)
    invert(pg::APStraightNgon, c::APCircle2; atol=1e-9)

Each side inverts independently (see [`invert(::APSegment, ::APCircle2)`](@ref))
to a straight `APSegment` or an `APCircularArc2`, and the results are
collected into an [`APCurvilinearNgon2`](@ref). Throws an `ArgumentError`
if any vertex coincides with `c.center` (that vertex has no image).
"""
invert(t::Union{APTriangle,APQuadrilateral,APStraightNgon}, c::APCircle2; atol=1e-9) =
    APCurvilinearNgon2([invert(s, c; atol=atol) for s in sides(t)])
"""
    invert(arc::APCircularArc2, c::APCircle2; atol=1e-9)

The image of a circular arc: if its own circle doesn't pass through
`c.center`, the image is an arc of [`invert(arc.circle, c)`](@ref),
found via [`arc_through_points`](@ref) on the two inverted endpoints and
the inverted midpoint (so no separate sweep bookkeeping is needed). If the
circle does pass through `c.center` but the arc's own sweep does not
reach it, the image is the `APSegment` between the two inverted endpoints
of the resulting line. Throws an `ArgumentError` when the arc's sweep
does reach `c.center` (its image would be unbounded).
"""
function invert(arc::APCircularArc2, c::APCircle2; atol=1e-9)
    onpole = abs(distance(c.center, arc.circle.center) - arc.circle.r) <= sqrt(atol) * max(arc.circle.r, c.r, 1.0)
    ip1, ip2 = invert(arc.p1, c), invert(arc.p2, c)
    if onpole
        _arc_sweep_contains(arc, c.center) &&
            throw(ArgumentError("invert: the arc's sweep reaches the center of c; its image is unbounded"))
        return APSegment(ip1, ip2)
    end
    return arc_through_points(ip1, invert(point_on(arc, 0.5), c), ip2)
end
"""
    invert(conic, c::APCircle2)

The image of an ellipse, a hyperbola, a parabola, or an arc of one, under
inversion with respect to `c`: generally a curve of higher degree, not
another conic, so the result is a sampled [`APParametricCurve2`](@ref)
(`invert(point_on(conic, t), c)` at each `t`) rather than a value of the
conic's own type.
"""
invert(e::APEllipse2, c::APCircle2; atol=1e-9) = APParametricCurve2(t -> invert(point_on(e, t), c), (0.0, 2π))
invert(h::APHyperbola2, c::APCircle2; branch::Int=1, atol=1e-9) = APParametricCurve2(t -> invert(point_on(h, t; branch=branch), c), (-2.0, 2.0))
invert(par::APParabola2, c::APCircle2; atol=1e-9) = APParametricCurve2(t -> invert(point_on(par, t), c), (-100.0, 100.0))
invert(arc::Union{APEllipticArc2,APParabolicArc2,APHyperbolicArc2}, c::APCircle2; atol=1e-9) =
    APParametricCurve2(t -> invert(point_on(arc, t), c), (0.0, 1.0))
"""
    invert_neg(shape, c::APCircle2)
    invert_neg(shape, center::APPoint; k::Real=1.0, atol=1e-9)

The image of `shape` under inversion of *negative* ratio with respect to
`c` (or to the circle centered at `center` with radius `k`): the ordinary
[`invert`](@ref) image, point-reflected through the center of inversion.
For a point, this is the point on ray `p -> center` (not `center -> p`)
at distance `r² / |center p|` from `center`.
"""
invert_neg(p::APPoint, c::APCircle2) = reflection(invert(p, c), c.center)
invert_neg(shape, c::APCircle2; kwargs...) = reflection(invert(shape, c; kwargs...), c.center)
invert_neg(shape, center::APPoint; k::Real=1.0, atol=1e-9) = invert_neg(shape, APCircle2(center, k); atol=atol)
"""
    invert(v::AbstractVector{<:APObject}, c::APCircle2)
    invert_neg(v::AbstractVector{<:APObject}, c::APCircle2)

Invert every element of `v`: see the `AbstractVector` forms of
[`translate`](@ref)/[`rotate`](@ref)/[`homothety`](@ref)/[`reflection`](@ref)
for why this exists (a plain `Vector` of shapes, e.g. from
[`intersection`](@ref)/[`tangent_points`](@ref), used as a single item).
The same overload exists for a `Tuple` of shapes (e.g. `vertices(t)`, or
a broadcast `f.(vertices(t), ...)`), for the same reason.
"""
invert(v::AbstractVector{<:APObject}, c::APCircle2; kwargs...) = invert.(v, Ref(c); kwargs...)
invert_neg(v::AbstractVector{<:APObject}, c::APCircle2; kwargs...) = invert_neg.(v, Ref(c); kwargs...)
invert(t::Tuple{Vararg{APObject}}, c::APCircle2; kwargs...) = invert.(t, Ref(c); kwargs...)
invert_neg(t::Tuple{Vararg{APObject}}, c::APCircle2; kwargs...) = invert_neg.(t, Ref(c); kwargs...)
"""
    invert(center::APPoint; k::Real=1.0, atol=1e-9)
    invert(c::APCircle2)
    invert_neg(center::APPoint; k::Real=1.0, atol=1e-9)
    invert_neg(c::APCircle2)

`shape -> invert(shape, c; ...)`: for composing with `|>`/`map`/`∘`, same
as [`rotate`](@ref)/[`homothety`](@ref)'s own single-argument forms.
Unlike those, this is *not* an [`APAffineMap`](@ref) (circle inversion
isn't affine), so it's a plain closure rather than a reusable, inspectable
value.
"""
invert(center::APPoint; k::Real=1.0, atol=1e-9) = shape -> invert(shape, center; k=k, atol=atol)
invert(c::APCircle2) = shape -> invert(shape, c)
invert_neg(center::APPoint; k::Real=1.0, atol=1e-9) = shape -> invert_neg(shape, center; k=k, atol=atol)
invert_neg(c::APCircle2) = shape -> invert_neg(shape, c)
"""
    polar_line(c::APCircle2, p::APPoint; atol=1e-9)

The polar line of `p` with respect to `c`: the line through `invert(p, c)`
perpendicular to the line from `c.center` to `p`. When `p` is outside `c`,
this is the chord of contact of the two tangent lines from `p` (see
[`tangent_points`](@ref)); when `p` is on `c`, it's the tangent line at `p`.
`nothing` when `p` is `c`'s center (matching the
[`polar_line(::APEllipse2, ::APPoint)`](@ref)/`APHyperbola2`/`APParabola2`
methods), rather than throwing.
"""
function polar_line(c::APCircle2, p::APPoint; atol=1e-9)
    distance(p, c.center) <= sqrt(atol) * max(c.r, 1.0) && return nothing
    return perpendicular_through(APLine(c.center, p), invert(p, c))
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
    return invert(foot, c)
end
