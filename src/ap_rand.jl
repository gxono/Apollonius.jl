"""
    rand([rng,] s)
    rand([rng,] s, dims...)

A random point on `s`'s own boundary/perimeter (never the interior).
Defined for [`APSegment`](@ref), [`APCircle2`](@ref), [`APEllipse2`](@ref),
every conic arc ([`APCircularArc2`](@ref) and the rest), every
[`APPolygon`](@ref) (straight-sided or curved) and [`APBoundingBox`](@ref).
Not defined for `APLine`/`APRay` (infinite), `APParabola2`/`APHyperbola2`
as full curves (also infinite), or the unbounded `APSet` family
(`APAngle2`/`APHalfPlane2`/`APStrip2`): there is no uniform distribution
on an infinite set.

Exact (truly uniform in arc length) for `APSegment` and `APCircularArc2`.
For `APEllipse2` and the elliptic/parabolic/hyperbolic arcs, this is
uniform in the curve's own parameter instead: exact arc-length
parametrization needs elliptic integrals for those three, so points
cluster slightly more near the flatter parts of the curve. An
`APPolygon`/`APBoundingBox` picks one side with probability proportional
to its own length, then a point on that side by the rule above: so the
result is uniform along the whole perimeter (up to that same per-arc-type
caveat for any curved side).
"""
Random.rand(rng::Random.AbstractRNG, s::Random.SamplerTrivial{<:APObject}) = _rand_point(rng, s[])
for T in (:APCircle2, :APEllipse2, :APCircularArc2, :APEllipticArc2, :APParabolicArc2, :APHyperbolicArc2,
    :APBoundingBox, :APTriangle, :APQuadrilateral, :APStraightNgon,
    :APCircularSector2, :APCircularSegment2, :APAnnularSector2,
    :APCurvilinearTriangle2, :APCurvilinearQuadrilateral2)
    @eval Base.eltype(::Type{<:$T}) = APPoint{2,Float64}
end
_rand_point(rng::Random.AbstractRNG, s::APSegment) = s.p1 + rand(rng) * (s.p2 - s.p1)
_rand_point(rng::Random.AbstractRNG, c::APCircle2) = polar_point(c.r, 2π * rand(rng), c.center)
_rand_point(rng::Random.AbstractRNG, e::APEllipse2) = point_on(e, 2π * rand(rng))
_rand_point(rng::Random.AbstractRNG, arc::APCircularArc2) = point_on(arc, rand(rng))
_rand_point(rng::Random.AbstractRNG, arc::Union{APEllipticArc2,APParabolicArc2,APHyperbolicArc2}) =
    point_on(arc, rand(rng))
function _rand_point_on_sides(rng::Random.AbstractRNG, sides)
    weights = cumsum(_side_length.(sides))
    return _rand_point(rng, sides[searchsortedfirst(weights, rand(rng) * weights[end])])
end
_rand_point(rng::Random.AbstractRNG, pg::APPolygon) = _rand_point_on_sides(rng, sides(pg))
function _rand_point(rng::Random.AbstractRNG, bb::APBoundingBox)
    p1, p2, p3, p4 = bb.min, APPoint(bb.max[1], bb.min[2]), bb.max, APPoint(bb.min[1], bb.max[2])
    return _rand_point_on_sides(rng, [APSegment(p1, p2), APSegment(p2, p3), APSegment(p3, p4), APSegment(p4, p1)])
end
"""
    rand_inside([rng,] s)

A random point in the *interior* of `s`, uniformly distributed over its
area, where [`rand`](@ref) gives a point on its boundary. Defined for
[`APCircle2`](@ref) (the disk), [`APEllipse2`](@ref), [`APBoundingBox`](@ref),
[`APTriangle`](@ref), [`APQuadrilateral`](@ref) and [`APStraightNgon`](@ref)
(the last two by triangulating first, so a concave polygon works too).
"""
rand_inside(s) = rand_inside(Random.default_rng(), s)
function rand_inside(rng::Random.AbstractRNG, c::APCircle2)
    return polar_point(c.r * sqrt(rand(rng)), 2π * rand(rng), c.center)
end
function rand_inside(rng::Random.AbstractRNG, e::APEllipse2)
    ρ, θ = sqrt(rand(rng)), 2π * rand(rng)
    return _from_ellipse_local(e.a * ρ * cos(θ), e.b * ρ * sin(θ), e)
end
function rand_inside(rng::Random.AbstractRNG, bb::APBoundingBox)
    return APPoint(bb.min[1] + rand(rng) * (bb.max[1] - bb.min[1]), bb.min[2] + rand(rng) * (bb.max[2] - bb.min[2]))
end
function rand_inside(rng::Random.AbstractRNG, t::APTriangle)
    u, v = rand(rng), rand(rng)
    u + v > 1 && ((u, v) = (1 - u, 1 - v))
    a, b, c = vertices(t)
    return a + u * (b - a) + v * (c - a)
end
function rand_inside(rng::Random.AbstractRNG, pg::Union{APQuadrilateral,APStraightNgon})
    vs = collect(vertices(pg))
    tris = [APTriangle(vs[a], vs[b], vs[c]) for (a, b, c) in _ear_triangulate(vs)]
    areas = area.(tris)
    w = rand(rng) * sum(areas)
    acc = 0.0
    for (t, ar) in zip(tris, areas)
        acc += ar
        w <= acc && return rand_inside(rng, t)
    end
    return rand_inside(rng, last(tris))
end
