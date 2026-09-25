# APUnboundedPolygon2: the general shape an intersection of 3-4 halfplanes can
# produce when it isn't bounded and doesn't collapse to APHalfPlane2/APStrip2/
# APAngle2 either (see ap_region_intersections.jl, Phase 3). Two infinite rays
# capping a chain of 0+ straight segments in between.

"""
    APUnboundedPolygon2(ray1::APRay, vertices::Vector{<:APPoint}, ray2::APRay)

An unbounded convex region bounded by two rays and, in between them, a chain
of straight segments through `vertices`: `ray1.origin`, then `vertices` in
order, then `ray2.origin`, is the polygon's full vertex sequence, with
`ray1`/`ray2` continuing past their own origin out to infinity. Walking that
sequence (`ray1` backwards, from infinity in, then `vertices`, then `ray2`
forwards, out to infinity) keeps the interior on the left, the same
convention [`side_of_line`](@ref)/[`APHalfPlane2`](@ref)'s `side = +1` use.

This is what [`intersection`](@ref) returns for a pair of
[`APHalfPlane2`](@ref)/[`APStrip2`](@ref)/[`APAngle2`](@ref) regions when the
result is unbounded but not itself one of those three types (see
[Unbounded Regions: Half-Planes, Strips & Angles](@ref)); it's rare to build
one directly.
"""
struct APUnboundedPolygon2{T<:Real} <: APSet{2,T}
    ray1::APRay{2,T}
    vertices::Vector{APPoint{2,T}}
    ray2::APRay{2,T}
end
function APUnboundedPolygon2(ray1::APRay{2}, vertices::AbstractVector{<:APPoint{2}}, ray2::APRay{2})
    T = promote_type(eltype(ray1), eltype(ray2), isempty(vertices) ? Float64 : promote_type(eltype.(vertices)...))
    return APUnboundedPolygon2{T}(convert(APRay{2,T}, ray1), APPoint{2,T}[convert(APPoint{2,T}, v) for v in vertices], convert(APRay{2,T}, ray2))
end
Base.:(==)(x::APUnboundedPolygon2, y::APUnboundedPolygon2) =
    x.ray1 == y.ray1 && x.vertices == y.vertices && x.ray2 == y.ray2
Base.isapprox(x::APUnboundedPolygon2, y::APUnboundedPolygon2; kwargs...) =
    isapprox(x.ray1, y.ray1; kwargs...) && length(x.vertices) == length(y.vertices) &&
    all(isapprox(a, b; kwargs...) for (a, b) in zip(x.vertices, y.vertices)) &&
    isapprox(x.ray2, y.ray2; kwargs...)
Base.show(io::IO, u::APUnboundedPolygon2) =
    print(io, "APUnboundedPolygon2(", u.ray1, ", ", u.vertices, ", ", u.ray2, ")")

"""
    vertices(u::APUnboundedPolygon2)

`u`'s full vertex sequence: `u.ray1.origin`, then `u.vertices`, then
`u.ray2.origin`.
"""
vertices(u::APUnboundedPolygon2) = [u.ray1.origin; u.vertices; u.ray2.origin]

# The actual boundary pieces (for distance/rendering): ray1, the segments
# between consecutive vertices, ray2 -- geometrically as stored, unchanged.
function _boundary_edges(u::APUnboundedPolygon2)
    vs = vertices(u)
    segs = [APSegment(vs[i], vs[i+1]) for i in 1:length(vs)-1]
    return (u.ray1, segs..., u.ray2)
end

# Same edges, but each as (base, dir) with dir flipped so the interior is
# consistently on the left (side_of_line's convention): every edge already
# comes out of construction that way except ray1, whose own stored direction
# points away from the chain (toward -infinity, "backwards" relative to the
# walk), so only it needs negating here.
function _orientation_edges(u::APUnboundedPolygon2)
    vs = vertices(u)
    segs = [(vs[i], vs[i+1] - vs[i]) for i in 1:length(vs)-1]
    return ((u.ray1.origin, -direction(u.ray1)), segs..., (u.ray2.origin, direction(u.ray2)))
end

"""
    p in u::APUnboundedPolygon2

Whether `p` lies in the closed region `u` (on the boundary counts as inside).
"""
function Base.in(p::APPoint, u::APUnboundedPolygon2)
    for (base, dir) in _orientation_edges(u)
        cross2(dir, p - base) < 0 && return false
    end
    return true
end

"""
    distance(p::APPoint, u::APUnboundedPolygon2; mode::Symbol=:region)

Distance from `p` to `u`: `min` of the distances to each of `u`'s rays and
segments. With `mode = :region` (the default), `0.0` whenever `p in u`; with
`mode = :boundary`, always that `min`, even from inside.
"""
function distance(p::APPoint, u::APUnboundedPolygon2; mode::Symbol=:region)
    _check_distance_mode(mode)
    d = minimum(distance(p, edge) for edge in _boundary_edges(u))
    mode == :boundary && return d
    return p in u ? zero(d) : d
end
distance(u::APUnboundedPolygon2, p::APPoint; mode::Symbol=:region) = distance(p, u; mode=mode)

"""
    rotate(u::APUnboundedPolygon2, angle, center=APPoint(0.0, 0.0))
    homothety(u::APUnboundedPolygon2, k, center=APPoint(0.0, 0.0))
    translate(u::APUnboundedPolygon2, v::APVector)

Transform `u`'s rays and vertices pointwise.
"""
rotate(u::APUnboundedPolygon2, angle::Real, center::APPoint=APPoint(0.0, 0.0)) =
    APUnboundedPolygon2(rotate(u.ray1, angle, center), rotate.(u.vertices, angle, Ref(center)), rotate(u.ray2, angle, center))
homothety(u::APUnboundedPolygon2, k::Real, center::APPoint=APPoint(0.0, 0.0)) =
    APUnboundedPolygon2(homothety(u.ray1, k, center), homothety.(u.vertices, k, Ref(center)), homothety(u.ray2, k, center))
translate(u::APUnboundedPolygon2, v::APVector) =
    APUnboundedPolygon2(translate(u.ray1, v), translate.(u.vertices, Ref(v)), translate(u.ray2, v))
"""
    reflection(u::APUnboundedPolygon2, about::APPoint)
    reflection(u::APUnboundedPolygon2, about::APLine)

Reflect `u`. Reflecting about an `APLine` (a true mirror) reverses
orientation, so the walk direction flips: `ray1`/`ray2` swap ends (and
`vertices` reverses) so the result is a genuine mirror image, the same
convention [`APAngle2`](@ref)/[`APCircularArc2`](@ref) use for the same
reason. A point reflection needs no swap.
"""
reflection(u::APUnboundedPolygon2, about::APPoint) =
    APUnboundedPolygon2(reflection(u.ray1, about), reflection.(u.vertices, Ref(about)), reflection(u.ray2, about))
reflection(u::APUnboundedPolygon2, about::APLine) =
    APUnboundedPolygon2(reflection(u.ray2, about), reflection.(reverse(u.vertices), Ref(about)), reflection(u.ray1, about))
APBoundingBox(::APUnboundedPolygon2) = APBoundingBox()
(m::APAffineMap)(u::APUnboundedPolygon2) = APUnboundedPolygon2(m(u.ray1), [m(v) for v in u.vertices], m(u.ray2))
