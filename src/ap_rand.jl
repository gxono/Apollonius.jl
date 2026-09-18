# -------------------------------------------------------------------------
# `rand` for every FINITE point-set in the package
#-------------------------------------------------------------------------

"""
    rand([rng,] s)
    rand([rng,] s, dims...)

A random point on `s`'s own boundary/perimeter (never the interior).
Defined for [`APSegment`](@ref), [`APCircle2`](@ref), [`APEllipse2`](@ref),
every conic arc ([`APCircularArc2`](@ref) and the rest), every
[`APPolygon`](@ref) (straight-sided or curved) and [`APBoundingBox`](@ref).
Not defined for `APLine`/`APRay` (infinite), `APParabola2`/`APHyperbola2`
as full curves (also infinite), or the unbounded `APSet` family
(`APAngle2`/`APHalfPlane2`/`APStrip2`) -- there is no uniform distribution
on an infinite set.

Exact (truly uniform in arc length) for `APSegment` and `APCircularArc2`.
For `APEllipse2` and the elliptic/parabolic/hyperbolic arcs, this is
uniform in the curve's own parameter instead: exact arc-length
parametrization needs elliptic integrals for those three, so points
cluster slightly more near the flatter parts of the curve. An
`APPolygon`/`APBoundingBox` picks one side with probability proportional
to its own length, then a point on that side by the rule above -- so the
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
_rand_point(rng::Random.AbstractRNG, e::APEllipse2) = point_on_ellipse(e, 2π * rand(rng))
_rand_point(rng::Random.AbstractRNG, arc::APCircularArc2) = point_on_arc(arc, rand(rng))
_rand_point(rng::Random.AbstractRNG, arc::Union{APEllipticArc2,APParabolicArc2,APHyperbolicArc2}) =
    point_on_arc(arc, rand(rng))


function _rand_point_on_sides(rng::Random.AbstractRNG, sides)
    weights = cumsum(_side_length.(sides))
    return _rand_point(rng, sides[searchsortedfirst(weights, rand(rng) * weights[end])])
end

_rand_point(rng::Random.AbstractRNG, pg::APPolygon) = _rand_point_on_sides(rng, sides(pg))

function _rand_point(rng::Random.AbstractRNG, bb::APBoundingBox)
    p1, p2, p3, p4 = bb.min, APPoint(bb.max[1], bb.min[2]), bb.max, APPoint(bb.min[1], bb.max[2])
    return _rand_point_on_sides(rng, [APSegment(p1, p2), APSegment(p2, p3), APSegment(p3, p4), APSegment(p4, p1)])
end
