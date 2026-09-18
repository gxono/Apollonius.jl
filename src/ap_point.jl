"""
    APObject{Dim,T}

The root of every type this package defines: anything that lives in
`Dim`-dimensional space with coordinates of element type `T`. Every
concrete AP-prefixed type — points, vectors, curves, regions, bounding
boxes — is an `APObject`. [`APTransform`](@ref) (affine maps and friends)
is deliberately *not* part of this tree: a transform isn't itself a
geometric object, it's a function between them.
"""
abstract type APObject{Dim,T<:Real} end
"""
    APLocus{Dim,T} <: APObject{Dim,T}

Anything definable as the set of points satisfying some geometric
condition — the parent of both [`APCurve`](@ref) (1-dimensional loci:
lines, conics, arcs) and [`APSet`](@ref) (regions with interior area:
half-planes, angles, polygons). `APPoint`/`APVector` and
[`APBoundingBox`](@ref) sit outside this branch — a single point isn't
usefully a "locus", and a bounding box is an axis-aligned convenience
object rather than a rotation/reflection-covariant one (see its own
docstring for why).
"""
abstract type APLocus{Dim,T} <: APObject{Dim,T} end
"""
    APCurve{Dim,T} <: APLocus{Dim,T}

A one-dimensional locus: [`APLine`](@ref), [`APRay`](@ref),
[`APSegment`](@ref), the conics ([`APCircle2`](@ref), [`APEllipse2`](@ref),
[`APParabola2`](@ref), [`APHyperbola2`](@ref), grouped under
[`APConic2`](@ref)), and the conic arcs ([`APCircularArc2`](@ref) and
friends, grouped under `APConicArc2`). Has no interior — it bounds a
region rather than being one.
"""
abstract type APCurve{Dim,T} <: APLocus{Dim,T} end
"""
    APSurface{Dim,T} <: APLocus{Dim,T}

A codimension-1 locus that is **not** one-dimensional — meaningless for
`Dim == 2` (where codimension-1 already means "curve", i.e.
[`APCurve`](@ref)), and only populated starting at `Dim == 3`:
`APPlane3` (flat, no enclosed volume) and `APSphere3`
(curved, encloses a volume) are its first members (3D geometry is
currently paused — see the repo's own working notes). `APSurface` is to
`APCurve` what a plane is to a line: the same "boundary-type locus with no
interior of its own" role, one dimension up. Like `APCurve`, a concrete
`APSurface` may still carry `area`/`volume`-style measures for whatever it
happens to enclose (a sphere does, a bare plane doesn't) — mirroring how
`APCircle2 <: APCurve` already has [`area`](@ref) despite being "just a
curve".
"""
abstract type APSurface{Dim,T} <: APLocus{Dim,T} end
"""
    APSet{Dim,T} <: APLocus{Dim,T}

A locus with a genuine interior/exterior — `p in s` is meaningful.
Covers both the unbounded members ([`APHalfPlane2`](@ref),
[`APAngle2`](@ref), [`APStrip2`](@ref) — regions with infinite extent) and
every bounded [`APRegion`](@ref)/[`APPolygon`](@ref). Grouping unbounded
and bounded regions under one parent reflects that both answer the same
basic question (is this point inside?) even though only the bounded ones
have a finite [`area`](@ref)/[`perimeter`](@ref).
"""
abstract type APSet{Dim,T} <: APLocus{Dim,T} end
"""
    APRegion{Dim,T} <: APSet{Dim,T}

An `APSet` with finite extent — as opposed to
[`APHalfPlane2`](@ref)/[`APAngle2`](@ref)/[`APStrip2`](@ref), which stretch
to infinity. In practice, every concrete `APRegion` is also an
[`APPolygon`](@ref) (a closed boundary made of straight or curved sides).
"""
abstract type APRegion{Dim,T} <: APSet{Dim,T} end
"""
    APPolygon{Dim,T} <: APRegion{Dim,T}

A closed region bounded by an ordered sequence of sides — implements
either [`vertices`](@ref) (straight-sided: [`APTriangle`](@ref),
[`APQuadrilateral`](@ref), [`APStraightNgon`](@ref)) or [`sides`](@ref)
directly (mixing straight [`APSegment`](@ref)s with
[`APCircularArc2`](@ref)s: [`APCircularSector2`](@ref),
[`APCircularSegment2`](@ref), [`APAnnularSector2`](@ref),
[`APInterstice2`](@ref), and the `APCurvilinear*2` family). Either way,
[`area`](@ref)/[`perimeter`](@ref)/[`centroid`](@ref)/[`is_convex`](@ref)/
[`point_in_polygon`](@ref) are defined *once*, generically, on
`APPolygon` itself via a shared Green's-theorem walk over `sides(p)` — a
straight side's contribution reduces exactly to the familiar shoelace
term, so this is one formula covering the entire polygon family, curved
or not.
"""
abstract type APPolygon{Dim,T} <: APRegion{Dim,T} end
"""
    APPolyhedron{Dim,T} <: APRegion{Dim,T}

A closed 3D solid bounded by an unordered list of planar polygon
`faces` (each an [`APPolygon`](@ref)`{3,T}`) — the `APPolyhedron`
analogue of `APPolygon`'s `sides`, exactly one dimension up:
`volume`/`surface_area`/`centroid` are defined *once*, generically, via a
divergence-theorem tetrahedral decomposition over `faces(p)`, the same
way `area`/`perimeter`/`centroid` are defined once on `APPolygon` via a
Green's-theorem walk over `sides(p)`. (3D geometry, and so every concrete
`APPolyhedron`, is currently paused.)
"""
abstract type APPolyhedron{Dim,T} <: APRegion{Dim,T} end
"""
    APTransform{T}

The parent of [`APAffineMap`](@ref) and any future transform type — a
function *between* geometric objects, rather than one itself, which is
why `APTransform` sits outside the [`APObject`](@ref) tree entirely.
"""
abstract type APTransform{T<:Real} end
Base.Broadcast.broadcastable(x::APObject) = Ref(x)
Base.Broadcast.broadcastable(x::APTransform) = Ref(x)
translate(v::AbstractVector{<:APObject}, args...; kwargs...) = translate.(v, args...; kwargs...)
rotate(v::AbstractVector{<:APObject}, args...; kwargs...) = rotate.(v, args...; kwargs...)
homothety(v::AbstractVector{<:APObject}, args...; kwargs...) = homothety.(v, args...; kwargs...)
reflection(v::AbstractVector{<:APObject}, args...; kwargs...) = reflection.(v, args...; kwargs...)
"""
    APPoint(x, y)
    APPoint(x, y, z)
    APPoint(coords::NTuple)

A point in `Dim`-dimensional space (`Dim` inferred from how many
coordinates you give it). Supports `+`, `-`, unary `-`, scalar `*`/`/`,
indexing (`p[i]`), destructuring iteration (`x, y = p`), `==`, `isapprox`,
and the standard linear-algebra functions `dot`/`norm`/`normalize`.

Arithmetic between two `APPoint`s is deliberately permissive — `p1 + p2`,
`p1 - p2` and `k * p` all return another `APPoint`, not an [`APVector`](@ref):
this mirrors how points have always been used throughout this package (as
both locations and free vectors at once), so existing formulas keep
working unchanged. `APVector` exists only for when you explicitly want a
type that reads as "this is a direction, not a location" — convert either
way with `APVector(p)`/`APPoint(v)`.
"""
struct APPoint{Dim,T<:Real} <: APObject{Dim,T}
    coords::NTuple{Dim,T}
end
APPoint(xs::Real...) = APPoint(promote(xs...))
"""
    APPoint(t::Tuple)

`APPoint((5, 10))` — same as `APPoint(5, 10)`, for when the coordinates
already come as a tuple (a mixed-type tuple like `(5, 10.0)` is promoted
the same way `APPoint(5, 10.0)` is; a same-type tuple like `(5, 10)`
would already match the plain `coords::NTuple{Dim,T}` field constructor
without this method, but this makes both cases behave identically).
"""
APPoint(t::Tuple{Vararg{Real}}) = APPoint(t...)
"""
    APVector(x, y)
    APVector(x, y, z)
    APVector(coords::NTuple)
    APVector(p::APPoint)

A direction/displacement in `Dim`-dimensional space — the same underlying
representation as [`APPoint`](@ref), kept as a distinct type purely so a
signature can say "this is a direction" (and so `norm`/`dot`/`normalize`
read naturally). Supports the same operations as `APPoint`; `APPoint(v)`
converts back the other way.
"""
struct APVector{Dim,T<:Real} <: APObject{Dim,T}
    coords::NTuple{Dim,T}
end
APVector(xs::Real...) = APVector(promote(xs...))
APVector(p::APPoint) = APVector(p.coords)
APVector(v::APVector) = v
APPoint(v::APVector) = APPoint(v.coords)
APPoint(p::APPoint) = p
const APPointOrVector{Dim,T} = Union{APPoint{Dim,T},APVector{Dim,T}}
Base.getindex(p::APPointOrVector, i::Integer) = p.coords[i]
Base.length(::APPointOrVector{Dim}) where {Dim} = Dim
Base.iterate(p::APPointOrVector, state::Int=1) = state > length(p) ? nothing : (p[state], state + 1)
Base.eltype(::Type{<:APPointOrVector{Dim,T}}) where {Dim,T} = T
Base.:(==)(a::APPoint, b::APPoint) = a.coords == b.coords
Base.:(==)(a::APVector, b::APVector) = a.coords == b.coords
Base.convert(::Type{APPoint{Dim,T}}, p::APPoint{Dim}) where {Dim,T} = APPoint{Dim,T}(T.(p.coords))
Base.convert(::Type{APVector{Dim,T}}, v::APVector{Dim}) where {Dim,T} = APVector{Dim,T}(T.(v.coords))
Base.isapprox(a::APPoint, b::APPoint; kwargs...) = all(isapprox(x, y; kwargs...) for (x, y) in zip(a.coords, b.coords))
Base.isapprox(a::APVector, b::APVector; kwargs...) = all(isapprox(x, y; kwargs...) for (x, y) in zip(a.coords, b.coords))
Base.isapprox(x::AbstractArray{<:APPointOrVector}, y::AbstractArray{<:APPointOrVector}; kwargs...) =
    length(x) == length(y) && all(isapprox(a, b; kwargs...) for (a, b) in zip(x, y))
Base.show(io::IO, p::APPoint) = print(io, "[", join(p.coords, ", "), "]")
Base.show(io::IO, v::APVector) = print(io, "⟨", join(v.coords, ", "), "⟩")
Base.:-(a::APPoint, b::APPoint) = APVector(a.coords .- b.coords)
Base.:-(a::APPoint) = APPoint((-).(a.coords))
Base.:*(k::Real, a::APPoint) = APPoint(k .* a.coords)
Base.:*(a::APPoint, k::Real) = k * a
Base.:/(a::APPoint, k::Real) = APPoint(a.coords ./ k)
Base.:+(a::APVector, b::APVector) = APVector(a.coords .+ b.coords)
Base.:-(a::APVector, b::APVector) = APVector(a.coords .- b.coords)
Base.:-(a::APVector) = APVector((-).(a.coords))
Base.:*(k::Real, a::APVector) = APVector(k .* a.coords)
Base.:*(a::APVector, k::Real) = k * a
Base.:/(a::APVector, k::Real) = APVector(a.coords ./ k)
Base.:+(p::APPoint, v::APVector) = APPoint(p.coords .+ v.coords)
Base.:+(v::APVector, p::APPoint) = p + v
Base.:-(p::APPoint, v::APVector) = APPoint(p.coords .- v.coords)
LinearAlgebra.dot(a::APPointOrVector, b::APPointOrVector) = sum(a.coords .* b.coords)
LinearAlgebra.norm(a::APPointOrVector) = sqrt(dot(a, a))
LinearAlgebra.normalize(a::APPointOrVector) = a / norm(a)
