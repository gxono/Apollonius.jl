# -------------------------------------------------------------------------
# EGPolyline2 / EGCurvilinearPolyline2 (<: EGCurve{2,T}): open curves made
# of consecutive sides -- the open counterparts of EGStraightNgon/
# EGCurvilinearNgon2 (which always close back to their own first vertex).
# -------------------------------------------------------------------------

"""
    EGPolyline2(vertices::AbstractVector{<:EGPoint{2}})
    EGPolyline2(vertices::EGPoint{2}...)

The open curve through `vertices`, in order, joined by straight
[`EGSegment`](@ref)s — [`EGSegment`](@ref) generalized to any number of
points, and the open counterpart of [`EGStraightNgon`](@ref) (which
always closes back to its first vertex; this never does).
"""
struct EGPolyline2{T<:Real} <: EGCurve{2,T}
    vertices::Vector{EGPoint{2,T}}
    function EGPolyline2{T}(vertices::Vector{EGPoint{2,T}}) where {T<:Real}
        length(vertices) >= 2 || throw(ArgumentError("EGPolyline2 needs at least 2 vertices"))
        return new{T}(vertices)
    end
end
function EGPolyline2(vs::AbstractVector{<:EGPoint{2}})
    T = promote_type(eltype.(vs)...)
    return EGPolyline2{T}(EGPoint{2,T}[convert(EGPoint{2,T}, v) for v in vs])
end
EGPolyline2(vs::EGPoint{2}...) = EGPolyline2(collect(vs))

vertices(pl::EGPolyline2) = pl.vertices
Base.getindex(pl::EGPolyline2, i::Integer) = pl.vertices[i]
Base.length(pl::EGPolyline2) = length(pl.vertices)
Base.iterate(pl::EGPolyline2, i::Int=1) = i > length(pl) ? nothing : (pl[i], i + 1)
Base.:(==)(x::EGPolyline2, y::EGPolyline2) = x.vertices == y.vertices
Base.isapprox(x::EGPolyline2, y::EGPolyline2; kwargs...) =
    length(x) == length(y) && all(isapprox(a, b; kwargs...) for (a, b) in zip(x.vertices, y.vertices))
Base.show(io::IO, pl::EGPolyline2) = print(io, "EGPolyline2(", pl.vertices, ")")

"""
    sides(pl::EGPolyline2)

The `n-1` straight sides of `pl` (no closing side, unlike
[`sides(::EGPolygon)`](@ref)).
"""
sides(pl::EGPolyline2) = [EGSegment(pl[i], pl[i+1]) for i in 1:length(pl)-1]

"""
    arc_length(pl::EGPolyline2)

The total length of `pl`: the sum of its side lengths.
"""
arc_length(pl::EGPolyline2) = sum(distance(pl[i], pl[i+1]) for i in 1:length(pl)-1)

EGBoundingBox(pl::EGPolyline2) = EGBoundingBox(pl.vertices)

"""
    reverse(pl::EGPolyline2)

`pl`, traversed from its last vertex to its first.
"""
Base.reverse(pl::EGPolyline2) = EGPolyline2(reverse(pl.vertices))

rotate(pl::EGPolyline2, angle::Real, center::EGPoint{2}=EGPoint(0.0, 0.0)) =
    EGPolyline2([rotate(p, angle, center) for p in pl.vertices])
homothety(pl::EGPolyline2, k::Real, center::EGPoint{2}=EGPoint(0.0, 0.0)) =
    EGPolyline2([homothety(p, k, center) for p in pl.vertices])
reflection(pl::EGPolyline2, about) = EGPolyline2([reflection(p, about) for p in pl.vertices])
translate(pl::EGPolyline2, v::EGVector) = EGPolyline2([translate(p, v) for p in pl.vertices])

"""
    p in pl::EGPolyline2

Whether `p` lies on one of `pl`'s sides.
"""
Base.in(p::EGPoint, pl::EGPolyline2; atol=1e-9) = any(s -> distance(p, s) <= atol * max(norm(p), 1.0), sides(pl))

"""
    distance(p::EGPoint, pl::EGPolyline2)

The distance from `p` to the nearest point on `pl`.
"""
distance(p::EGPoint, pl::EGPolyline2) = minimum(distance(p, s) for s in sides(pl))
distance(pl::EGPolyline2, p::EGPoint) = distance(p, pl)

# -------------------------------------------------------------------------

"""
    EGCurvilinearPolyline2(sides::AbstractVector)

The open curve made of `sides`, in order, each an [`EGSegment`](@ref) or
one of the 4 conic arc types — the open counterpart of
[`EGCurvilinearNgon2`](@ref) (which always closes back to its first
side's start; this never does), and the curved-sided counterpart of
[`EGPolyline2`](@ref). Each side's own endpoint must match the next
side's own start (unlike [`EGCurvilinearNgon2`](@ref), sides are taken in
the order given, not auto-reordered/matched).
"""
struct EGCurvilinearPolyline2{T<:Real} <: EGCurve{2,T}
    sides::Vector{EGSide{T}}
    function EGCurvilinearPolyline2{T}(sides::Vector{EGSide{T}}) where {T<:Real}
        isempty(sides) && throw(ArgumentError("EGCurvilinearPolyline2 needs at least 1 side"))
        scale = max(1.0, maximum(_side_scale, sides))
        for i in 1:length(sides)-1
            isapprox(_side_p2(sides[i]), _side_p1(sides[i+1]); atol=1e-9 * scale) ||
                throw(ArgumentError("EGCurvilinearPolyline2: side $i's endpoint doesn't match side $(i + 1)'s start"))
        end
        return new{T}(sides)
    end
end
function EGCurvilinearPolyline2(sides::AbstractVector)
    isempty(sides) && throw(ArgumentError("EGCurvilinearPolyline2 needs at least 1 side"))
    T = promote_type(_side_eltype.(sides)...)
    return EGCurvilinearPolyline2{T}(EGSide{T}[_side_convert(s, T) for s in sides])
end

sides(pg::EGCurvilinearPolyline2) = pg.sides
Base.getindex(pg::EGCurvilinearPolyline2, i::Integer) = pg.sides[i]
Base.length(pg::EGCurvilinearPolyline2) = length(pg.sides)
Base.iterate(pg::EGCurvilinearPolyline2, i::Int=1) = i > length(pg) ? nothing : (pg[i], i + 1)
Base.:(==)(x::EGCurvilinearPolyline2, y::EGCurvilinearPolyline2) = x.sides == y.sides
Base.isapprox(x::EGCurvilinearPolyline2, y::EGCurvilinearPolyline2; kwargs...) =
    length(x) == length(y) && all(isapprox(a, b; kwargs...) for (a, b) in zip(x.sides, y.sides))
Base.show(io::IO, pg::EGCurvilinearPolyline2) = print(io, "EGCurvilinearPolyline2(", pg.sides, ")")

"""
    arc_length(pg::EGCurvilinearPolyline2)

The total length of `pg`: the sum of its side lengths.
"""
arc_length(pg::EGCurvilinearPolyline2) = sum(_side_length, pg.sides)

EGBoundingBox(pg::EGCurvilinearPolyline2) = reduce(bbox_union, EGBoundingBox.(pg.sides); init=EGBoundingBox())

"""
    reverse(pg::EGCurvilinearPolyline2)

`pg`, traversed from its last side's end to its first side's start (each
side is itself reversed too, so it still runs start-to-end consistently).
"""
Base.reverse(pg::EGCurvilinearPolyline2) = EGCurvilinearPolyline2([reverse(s) for s in Base.reverse(pg.sides)])

rotate(pg::EGCurvilinearPolyline2, angle::Real, center::EGPoint{2}=EGPoint(0.0, 0.0)) =
    EGCurvilinearPolyline2([rotate(s, angle, center) for s in pg.sides])
homothety(pg::EGCurvilinearPolyline2, k::Real, center::EGPoint{2}=EGPoint(0.0, 0.0)) =
    EGCurvilinearPolyline2([homothety(s, k, center) for s in pg.sides])
reflection(pg::EGCurvilinearPolyline2, about) = EGCurvilinearPolyline2([reflection(s, about) for s in pg.sides])
translate(pg::EGCurvilinearPolyline2, v::EGVector) = EGCurvilinearPolyline2([translate(s, v) for s in pg.sides])

"""
    p in pg::EGCurvilinearPolyline2

Whether `p` lies on one of `pg`'s sides.
"""
Base.in(p::EGPoint, pg::EGCurvilinearPolyline2; atol=1e-9) = any(s -> distance(p, s) <= atol * max(norm(p), 1.0), pg.sides)

"""
    distance(p::EGPoint, pg::EGCurvilinearPolyline2)

The distance from `p` to the nearest point on `pg`.
"""
distance(p::EGPoint, pg::EGCurvilinearPolyline2) = minimum(distance(p, s) for s in pg.sides)
distance(pg::EGCurvilinearPolyline2, p::EGPoint) = distance(p, pg)
