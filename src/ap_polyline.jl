"""
    APPolyline2(vertices::AbstractVector{<:APPoint{2}})
    APPolyline2(vertices::APPoint{2}...)

The open curve through `vertices`, in order, joined by straight
[`APSegment`](@ref)s: [`APSegment`](@ref) generalized to any number of
points, and the open counterpart of [`APStraightNgon`](@ref) (which
always closes back to its first vertex; this never does).
"""
struct APPolyline2{T<:Real} <: APCurve{2,T}
    vertices::Vector{APPoint{2,T}}
    function APPolyline2{T}(vertices::Vector{APPoint{2,T}}) where {T<:Real}
        length(vertices) >= 2 || throw(ArgumentError("APPolyline2 needs at least 2 vertices"))
        return new{T}(vertices)
    end
end
function APPolyline2(vs::AbstractVector{<:APPoint{2}})
    T = promote_type(eltype.(vs)...)
    return APPolyline2{T}(APPoint{2,T}[convert(APPoint{2,T}, v) for v in vs])
end
APPolyline2(vs::APPoint{2}...) = APPolyline2(collect(vs))
vertices(pl::APPolyline2) = pl.vertices
Base.getindex(pl::APPolyline2, i::Integer) = pl.vertices[i]
Base.length(pl::APPolyline2) = length(pl.vertices)
Base.iterate(pl::APPolyline2, i::Int=1) = i > length(pl) ? nothing : (pl[i], i + 1)
Base.:(==)(x::APPolyline2, y::APPolyline2) = x.vertices == y.vertices
Base.isapprox(x::APPolyline2, y::APPolyline2; kwargs...) =
    length(x) == length(y) && all(isapprox(a, b; kwargs...) for (a, b) in zip(x.vertices, y.vertices))
Base.show(io::IO, pl::APPolyline2) = print(io, "APPolyline2(", pl.vertices, ")")
"""
    sides(pl::APPolyline2)

The `n-1` straight sides of `pl` (no closing side, unlike
[`sides(::APPolygon)`](@ref)).
"""
sides(pl::APPolyline2) = [APSegment(pl[i], pl[i+1]) for i in 1:length(pl)-1]
"""
    arc_length(pl::APPolyline2)

The total length of `pl`: the sum of its side lengths.
"""
arc_length(pl::APPolyline2) = sum(distance(pl[i], pl[i+1]) for i in 1:length(pl)-1)
APBoundingBox(pl::APPolyline2) = APBoundingBox(pl.vertices)
"""
    reverse(pl::APPolyline2)

`pl`, traversed from its last vertex to its first.
"""
Base.reverse(pl::APPolyline2) = APPolyline2(reverse(pl.vertices))
rotate(pl::APPolyline2, angle::Real, center::APPoint{2}=APPoint(0.0, 0.0)) =
    APPolyline2([rotate(p, angle, center) for p in pl.vertices])
homothety(pl::APPolyline2, k::Real, center::APPoint{2}=APPoint(0.0, 0.0)) =
    APPolyline2([homothety(p, k, center) for p in pl.vertices])
reflection(pl::APPolyline2, about) = APPolyline2([reflection(p, about) for p in pl.vertices])
translate(pl::APPolyline2, v::APVector) = APPolyline2([translate(p, v) for p in pl.vertices])
"""
    p in pl::APPolyline2

Whether `p` lies on one of `pl`'s sides.
"""
Base.in(p::APPoint, pl::APPolyline2; atol=1e-9) = any(s -> distance(p, s) <= atol * max(_side_length(s), 1.0), sides(pl))
"""
    distance(p::APPoint, pl::APPolyline2)

The distance from `p` to the nearest point on `pl`.
"""
distance(p::APPoint, pl::APPolyline2) = minimum(distance(p, s) for s in sides(pl))
distance(pl::APPolyline2, p::APPoint) = distance(p, pl)
"""
    APCurvilinearPolyline2(sides::AbstractVector)

The open curve made of `sides`, in order, each an [`APSegment`](@ref) or
one of the 4 conic arc types: the open counterpart of
[`APCurvilinearNgon2`](@ref) (which always closes back to its first
side's start; this never does), and the curved-sided counterpart of
[`APPolyline2`](@ref). Each side's own endpoint must match the next
side's own start (unlike [`APCurvilinearNgon2`](@ref), sides are taken in
the order given, not auto-reordered/matched).
"""
struct APCurvilinearPolyline2{T<:Real} <: APCurve{2,T}
    sides::Vector{APSide{T}}
    function APCurvilinearPolyline2{T}(sides::Vector{APSide{T}}) where {T<:Real}
        isempty(sides) && throw(ArgumentError("APCurvilinearPolyline2 needs at least 1 side"))
        scale = max(1.0, maximum(_side_scale, sides))
        for i in 1:length(sides)-1
            isapprox(_side_p2(sides[i]), _side_p1(sides[i+1]); atol=1e-9 * scale) ||
                throw(ArgumentError("APCurvilinearPolyline2: side $i's endpoint doesn't match side $(i + 1)'s start"))
        end
        return new{T}(sides)
    end
end
function APCurvilinearPolyline2(sides::AbstractVector)
    isempty(sides) && throw(ArgumentError("APCurvilinearPolyline2 needs at least 1 side"))
    T = promote_type(_side_eltype.(sides)...)
    return APCurvilinearPolyline2{T}(APSide{T}[_side_convert(s, T) for s in sides])
end
sides(pg::APCurvilinearPolyline2) = pg.sides
Base.getindex(pg::APCurvilinearPolyline2, i::Integer) = pg.sides[i]
Base.length(pg::APCurvilinearPolyline2) = length(pg.sides)
Base.iterate(pg::APCurvilinearPolyline2, i::Int=1) = i > length(pg) ? nothing : (pg[i], i + 1)
Base.:(==)(x::APCurvilinearPolyline2, y::APCurvilinearPolyline2) = x.sides == y.sides
Base.isapprox(x::APCurvilinearPolyline2, y::APCurvilinearPolyline2; kwargs...) =
    length(x) == length(y) && all(isapprox(a, b; kwargs...) for (a, b) in zip(x.sides, y.sides))
Base.show(io::IO, pg::APCurvilinearPolyline2) = print(io, "APCurvilinearPolyline2(", pg.sides, ")")
"""
    arc_length(pg::APCurvilinearPolyline2)

The total length of `pg`: the sum of its side lengths.
"""
arc_length(pg::APCurvilinearPolyline2) = sum(_side_length, pg.sides)
APBoundingBox(pg::APCurvilinearPolyline2) = reduce(bbox_union, APBoundingBox.(pg.sides); init=APBoundingBox())
"""
    reverse(pg::APCurvilinearPolyline2)

`pg`, traversed from its last side's end to its first side's start (each
side is itself reversed too, so it still runs start-to-end consistently).
"""
Base.reverse(pg::APCurvilinearPolyline2) = APCurvilinearPolyline2([reverse(s) for s in Base.reverse(pg.sides)])
rotate(pg::APCurvilinearPolyline2, angle::Real, center::APPoint{2}=APPoint(0.0, 0.0)) =
    APCurvilinearPolyline2([rotate(s, angle, center) for s in pg.sides])
homothety(pg::APCurvilinearPolyline2, k::Real, center::APPoint{2}=APPoint(0.0, 0.0)) =
    APCurvilinearPolyline2([homothety(s, k, center) for s in pg.sides])
reflection(pg::APCurvilinearPolyline2, about) = APCurvilinearPolyline2([reflection(s, about) for s in pg.sides])
translate(pg::APCurvilinearPolyline2, v::APVector) = APCurvilinearPolyline2([translate(s, v) for s in pg.sides])
"""
    p in pg::APCurvilinearPolyline2

Whether `p` lies on one of `pg`'s sides.
"""
Base.in(p::APPoint, pg::APCurvilinearPolyline2; atol=1e-9) = any(s -> distance(p, s) <= atol * max(_side_length(s), 1.0), pg.sides)
"""
    distance(p::APPoint, pg::APCurvilinearPolyline2)

The distance from `p` to the nearest point on `pg`.
"""
distance(p::APPoint, pg::APCurvilinearPolyline2) = minimum(distance(p, s) for s in pg.sides)
distance(pg::APCurvilinearPolyline2, p::APPoint) = distance(p, pg)
