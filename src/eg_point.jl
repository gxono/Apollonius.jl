# -------------------------------------------------------------------------
# EGPoint / EGVector, and the abstract skeleton of the whole EG-prefixed
# type hierarchy.
#
# Supporting the arithmetic/indexing interface the rest of the package relies 
# on: `p[i]` indexing, `+`/`-`/unary `-`, scalar `*`/`/`, `dot`/`norm`/`normalize`,
# and destructuring iteration (`x, y = p`).
#
# EGPoint and EGVector are kept as distinct types purely for clarity in
# signatures (a direction vs. a location), not for type-safety: arithmetic
# stays deliberately permissive — EGPoint +/- EGPoint, k*EGPoint, etc. all
# still return EGPoint. No CGAL-style strict affine-space rules (yet 🤔).
# -------------------------------------------------------------------------

"""
    EGObject{Dim,T}

The root of every type this package defines: anything that lives in
`Dim`-dimensional space with coordinates of element type `T`. Every
concrete EG-prefixed type — points, vectors, curves, regions, bounding
boxes — is an `EGObject`. [`EGTransform`](@ref) (affine maps and friends)
is deliberately *not* part of this tree: a transform isn't itself a
geometric object, it's a function between them.
"""
abstract type EGObject{Dim,T<:Real} end

"""
    EGLocus{Dim,T} <: EGObject{Dim,T}

Anything definable as the set of points satisfying some geometric
condition — the parent of both [`EGCurve`](@ref) (1-dimensional loci:
lines, conics, arcs) and [`EGSet`](@ref) (regions with interior area:
half-planes, angles, polygons). `EGPoint`/`EGVector` and
[`EGBoundingBox`](@ref) sit outside this branch — a single point isn't
usefully a "locus", and a bounding box is an axis-aligned convenience
object rather than a rotation/reflection-covariant one (see its own
docstring for why).
"""
abstract type EGLocus{Dim,T} <: EGObject{Dim,T} end

"""
    EGCurve{Dim,T} <: EGLocus{Dim,T}

A one-dimensional locus: [`EGLine`](@ref), [`EGRay`](@ref),
[`EGSegment`](@ref), the conics ([`EGCircle2`](@ref), [`EGEllipse2`](@ref),
[`EGParabola2`](@ref), [`EGHyperbola2`](@ref), grouped under
[`EGConic2`](@ref)), and the conic arcs ([`EGCircularArc2`](@ref) and
friends, grouped under `EGConicArc2`). Has no interior — it bounds a
region rather than being one.
"""
abstract type EGCurve{Dim,T} <: EGLocus{Dim,T} end

"""
    EGSurface{Dim,T} <: EGLocus{Dim,T}

A codimension-1 locus that is **not** one-dimensional — meaningless for
`Dim == 2` (where codimension-1 already means "curve", i.e.
[`EGCurve`](@ref)), and only populated starting at `Dim == 3`:
`EGPlane3` (flat, no enclosed volume) and `EGSphere3`
(curved, encloses a volume) are its first members (3D geometry is
currently paused — see the repo's own working notes). `EGSurface` is to
`EGCurve` what a plane is to a line: the same "boundary-type locus with no
interior of its own" role, one dimension up. Like `EGCurve`, a concrete
`EGSurface` may still carry `area`/`volume`-style measures for whatever it
happens to enclose (a sphere does, a bare plane doesn't) — mirroring how
`EGCircle2 <: EGCurve` already has [`area`](@ref) despite being "just a
curve".
"""
abstract type EGSurface{Dim,T} <: EGLocus{Dim,T} end

"""
    EGSet{Dim,T} <: EGLocus{Dim,T}

A locus with a genuine interior/exterior — `p in s` is meaningful.
Covers both the unbounded members ([`EGHalfPlane2`](@ref),
[`EGAngle2`](@ref), [`EGStrip2`](@ref) — regions with infinite extent) and
every bounded [`EGRegion`](@ref)/[`EGPolygon`](@ref). Grouping unbounded
and bounded regions under one parent reflects that both answer the same
basic question (is this point inside?) even though only the bounded ones
have a finite [`area`](@ref)/[`perimeter`](@ref).
"""
abstract type EGSet{Dim,T} <: EGLocus{Dim,T} end

"""
    EGRegion{Dim,T} <: EGSet{Dim,T}

An `EGSet` with finite extent — as opposed to
[`EGHalfPlane2`](@ref)/[`EGAngle2`](@ref)/[`EGStrip2`](@ref), which stretch
to infinity. In practice, every concrete `EGRegion` is also an
[`EGPolygon`](@ref) (a closed boundary made of straight or curved sides).
"""
abstract type EGRegion{Dim,T} <: EGSet{Dim,T} end

"""
    EGPolygon{Dim,T} <: EGRegion{Dim,T}

A closed region bounded by an ordered sequence of sides — implements
either [`vertices`](@ref) (straight-sided: [`EGTriangle`](@ref),
[`EGQuadrilateral`](@ref), [`EGStraightNgon`](@ref)) or [`sides`](@ref)
directly (mixing straight [`EGSegment`](@ref)s with
[`EGCircularArc2`](@ref)s: [`EGCircularSector2`](@ref),
[`EGCircularSegment2`](@ref), [`EGAnnularSector2`](@ref),
[`EGInterstice2`](@ref), and the `EGCurvilinear*2` family). Either way,
[`area`](@ref)/[`perimeter`](@ref)/[`centroid`](@ref)/[`is_convex`](@ref)/
[`point_in_polygon`](@ref) are defined *once*, generically, on
`EGPolygon` itself via a shared Green's-theorem walk over `sides(p)` — a
straight side's contribution reduces exactly to the familiar shoelace
term, so this is one formula covering the entire polygon family, curved
or not.
"""
abstract type EGPolygon{Dim,T} <: EGRegion{Dim,T} end

"""
    EGPolyhedron{Dim,T} <: EGRegion{Dim,T}

A closed 3D solid bounded by an unordered list of planar polygon
`faces` (each an [`EGPolygon`](@ref)`{3,T}`) — the `EGPolyhedron`
analogue of `EGPolygon`'s `sides`, exactly one dimension up:
`volume`/`surface_area`/`centroid` are defined *once*, generically, via a
divergence-theorem tetrahedral decomposition over `faces(p)`, the same
way `area`/`perimeter`/`centroid` are defined once on `EGPolygon` via a
Green's-theorem walk over `sides(p)`. (3D geometry, and so every concrete
`EGPolyhedron`, is currently paused.)
"""
abstract type EGPolyhedron{Dim,T} <: EGRegion{Dim,T} end

"""
    EGTransform{T}

The parent of [`EGAffineMap`](@ref) and any future transform type — a
function *between* geometric objects, rather than one itself, which is
why `EGTransform` sits outside the [`EGObject`](@ref) tree entirely.
"""
abstract type EGTransform{T<:Real} end

#Evita broadcasting sobre cada campo del struct
Base.Broadcast.broadcastable(x::EGObject) = Ref(x)
Base.Broadcast.broadcastable(x::EGTransform) = Ref(x)

#Necesario para @translate o @to_luxor_picture
translate(v::AbstractVector{<:EGObject}, args...; kwargs...) = translate.(v, args...; kwargs...)
rotate(v::AbstractVector{<:EGObject}, args...; kwargs...) = rotate.(v, args...; kwargs...)
homothety(v::AbstractVector{<:EGObject}, args...; kwargs...) = homothety.(v, args...; kwargs...)
reflection(v::AbstractVector{<:EGObject}, args...; kwargs...) = reflection.(v, args...; kwargs...)

"""
    EGPoint(x, y)
    EGPoint(x, y, z)
    EGPoint(coords::NTuple)

A point in `Dim`-dimensional space (`Dim` inferred from how many
coordinates you give it). Supports `+`, `-`, unary `-`, scalar `*`/`/`,
indexing (`p[i]`), destructuring iteration (`x, y = p`), `==`, `isapprox`,
and the standard linear-algebra functions `dot`/`norm`/`normalize`.

Arithmetic between two `EGPoint`s is deliberately permissive — `p1 + p2`,
`p1 - p2` and `k * p` all return another `EGPoint`, not an [`EGVector`](@ref):
this mirrors how points have always been used throughout this package (as
both locations and free vectors at once), so existing formulas keep
working unchanged. `EGVector` exists only for when you explicitly want a
type that reads as "this is a direction, not a location" — convert either
way with `EGVector(p)`/`EGPoint(v)`.
"""
struct EGPoint{Dim,T<:Real} <: EGObject{Dim,T}
    coords::NTuple{Dim,T}
end

EGPoint(xs::Real...) = EGPoint(promote(xs...))

"""
    EGPoint(t::Tuple)

`EGPoint((5, 10))` — same as `EGPoint(5, 10)`, for when the coordinates
already come as a tuple (a mixed-type tuple like `(5, 10.0)` is promoted
the same way `EGPoint(5, 10.0)` is; a same-type tuple like `(5, 10)`
would already match the plain `coords::NTuple{Dim,T}` field constructor
without this method, but this makes both cases behave identically).
"""
EGPoint(t::Tuple{Vararg{Real}}) = EGPoint(t...)


"""
    EGVector(x, y)
    EGVector(x, y, z)
    EGVector(coords::NTuple)
    EGVector(p::EGPoint)

A direction/displacement in `Dim`-dimensional space — the same underlying
representation as [`EGPoint`](@ref), kept as a distinct type purely so a
signature can say "this is a direction" (and so `norm`/`dot`/`normalize`
read naturally). Supports the same operations as `EGPoint`; `EGPoint(v)`
converts back the other way.
"""
struct EGVector{Dim,T<:Real} <: EGObject{Dim,T}
    coords::NTuple{Dim,T}
end

EGVector(xs::Real...) = EGVector(promote(xs...))
EGVector(p::EGPoint) = EGVector(p.coords)
EGVector(v::EGVector) = v
EGPoint(v::EGVector) = EGPoint(v.coords)
EGPoint(p::EGPoint) = p

const EGPointOrVector{Dim,T} = Union{EGPoint{Dim,T},EGVector{Dim,T}}

Base.getindex(p::EGPointOrVector, i::Integer) = p.coords[i]
Base.length(::EGPointOrVector{Dim}) where {Dim} = Dim
Base.iterate(p::EGPointOrVector, state::Int=1) = state > length(p) ? nothing : (p[state], state + 1)
Base.eltype(::Type{<:EGPointOrVector{Dim,T}}) where {Dim,T} = T

Base.:(==)(a::EGPoint, b::EGPoint) = a.coords == b.coords
Base.:(==)(a::EGVector, b::EGVector) = a.coords == b.coords

# Every parametric struct's auto-generated inner constructor (e.g., the
# `EGCircle2{T}(center, r)` that `EGCircle2(center, r) = EGCircle2{promote_type(...)}(...)`
# calls) converts each argument to its declared field type via `convert` —
# but `convert` has no idea how to turn an `EGPoint{Dim,S}` into an
# `EGPoint{Dim,T}` unless told, so *every* constructor built on that
# `promote_type`-then-let-Julia-convert pattern (EGCircle2, EGTriangle,
# EGQuadrilateral, EGSegment/EGLine/EGRay, EGAngle2, ...) fails the moment
# two arguments don't already share an element type — e.g. an EGPoint built
# from `Int` literals paired with a `Float64` radius. These two methods are
# the actual fix, in the one place it belongs.
Base.convert(::Type{EGPoint{Dim,T}}, p::EGPoint{Dim}) where {Dim,T} = EGPoint{Dim,T}(T.(p.coords))
Base.convert(::Type{EGVector{Dim,T}}, v::EGVector{Dim}) where {Dim,T} = EGVector{Dim,T}(T.(v.coords))
Base.isapprox(a::EGPoint, b::EGPoint; kwargs...) = all(isapprox(x, y; kwargs...) for (x, y) in zip(a.coords, b.coords))
Base.isapprox(a::EGVector, b::EGVector; kwargs...) = all(isapprox(x, y; kwargs...) for (x, y) in zip(a.coords, b.coords))

# `EGPoint`/`EGVector` are plain structs, not `AbstractArray`s (deliberate:
# see the module-level design notes on the type hierarchy), so
# `Vector{EGPoint} ≈ Vector{EGPoint}` would otherwise fall through to
# LinearAlgebra's generic `isapprox(::AbstractArray, ::AbstractArray)` —
# which computes a common eltype by reducing with `promote_type` seeded at
# `Bool`, and `promote_type(Bool, EGPoint{...})` is `Any` (no promotion
# rule relates them), breaking the tolerance calculation entirely. A
# same-element-type array of EGPoint/EGVector needs no promotion at all,
# so short-circuit straight to an elementwise comparison instead.
Base.isapprox(x::AbstractArray{<:EGPointOrVector}, y::AbstractArray{<:EGPointOrVector}; kwargs...) =
    length(x) == length(y) && all(isapprox(a, b; kwargs...) for (a, b) in zip(x, y))

Base.show(io::IO, p::EGPoint) = print(io, "[", join(p.coords, ", "), "]")
Base.show(io::IO, v::EGVector) = print(io, "⟨", join(v.coords, ", "), "⟩")

Base.:-(a::EGPoint, b::EGPoint) = EGVector(a.coords .- b.coords)
Base.:-(a::EGPoint) = EGPoint((-).(a.coords))
Base.:*(k::Real, a::EGPoint) = EGPoint(k .* a.coords)
Base.:*(a::EGPoint, k::Real) = k * a
Base.:/(a::EGPoint, k::Real) = EGPoint(a.coords ./ k)

Base.:+(a::EGVector, b::EGVector) = EGVector(a.coords .+ b.coords)
Base.:-(a::EGVector, b::EGVector) = EGVector(a.coords .- b.coords)
Base.:-(a::EGVector) = EGVector((-).(a.coords))
Base.:*(k::Real, a::EGVector) = EGVector(k .* a.coords)
Base.:*(a::EGVector, k::Real) = k * a
Base.:/(a::EGVector, k::Real) = EGVector(a.coords ./ k)

# Cross-type: EGPoint stays the "location" result type, matching how
# `direction(l) = l.p2 - l.p1` followed by `l.p1 + t*direction(l)` already
# reads today.
Base.:+(p::EGPoint, v::EGVector) = EGPoint(p.coords .+ v.coords)
Base.:+(v::EGVector, p::EGPoint) = p + v
Base.:-(p::EGPoint, v::EGVector) = EGPoint(p.coords .- v.coords)

LinearAlgebra.dot(a::EGPointOrVector, b::EGPointOrVector) = sum(a.coords .* b.coords)
LinearAlgebra.norm(a::EGPointOrVector) = sqrt(dot(a, a))
LinearAlgebra.normalize(a::EGPointOrVector) = a / norm(a)
