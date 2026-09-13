# -------------------------------------------------------------------------
# EGEquipollentVector (<: EGCurve{Dim,T}): a free EGVector applied at a
# specific EGPoint -- the classical "vector equipolente" (a representative
# of a free vector, tied to a point of application). Unlike a bare
# EGVector (deliberately positionless, so EGBoundingBox(::EGVector) is
# empty and it's exempt from @to_luxor_picture's fit-to-canvas transform
# entirely -- see its own docstring), this type HAS a position, so it
# gets a real EGBoundingBox and transforms fully and correctly (including
# being scaled by homothety) like every other EGCurve.
# -------------------------------------------------------------------------

"""
    EGEquipollentVector(vector::EGVector, point::EGPoint)

`vector`, applied at `point` -- i.e. the directed segment from `point` to
`point + vector`. Unlike a bare [`EGVector`](@ref) (which has no position
and is therefore exempt from `@to_luxor_picture`'s fit-to-canvas transform
entirely), this type has a real [`EGBoundingBox`](@ref) and transforms
fully like any other `EGCurve` — in particular, `homothety` correctly
scales its length along with everything else in a picture, which a bare
`EGVector` cannot. `vector` comes first to match
[`path(::EGVector, ::EGPoint)`](@ref)'s own `(vector, from)` order, and so
the single-argument form below reads as "this vector, optionally at a
point" rather than the other way around.
"""
struct EGEquipollentVector{Dim,T<:Real} <: EGCurve{Dim,T}
    vector::EGVector{Dim,T}
    point::EGPoint{Dim,T}
end
function EGEquipollentVector(vector::EGVector, point::EGPointLike)
    p = _topoint(point)
    T = promote_type(eltype(p), eltype(vector))
    return EGEquipollentVector{length(p),T}(convert(EGVector{length(p),T}, vector), convert(EGPoint{length(p),T}, p))
end

"""
    EGEquipollentVector(vector::EGVector)

`vector`, applied at the origin.
"""
EGEquipollentVector(vector::EGVector{Dim,T}) where {Dim,T} = EGEquipollentVector(vector, EGPoint(ntuple(_ -> zero(T), Dim)))

Base.:(==)(x::EGEquipollentVector, y::EGEquipollentVector) = x.vector == y.vector && x.point == y.point
Base.isapprox(x::EGEquipollentVector, y::EGEquipollentVector; kwargs...) =
    isapprox(x.vector, y.vector; kwargs...) && isapprox(x.point, y.point; kwargs...)
Base.show(io::IO, ev::EGEquipollentVector) = print(io, "EGEquipollentVector(", ev.vector, ", ", ev.point, ")")

"""
    tip(ev::EGEquipollentVector)

`ev.point + ev.vector` — computed on demand rather than stored, to avoid
duplicating information already fully determined by `point`/`vector`.
"""
tip(ev::EGEquipollentVector) = ev.point + ev.vector

direction(ev::EGEquipollentVector) = ev.vector

"""
    norm(ev::EGEquipollentVector)
    normalize(ev::EGEquipollentVector)
    dot(ev::EGEquipollentVector, other)

The standard linear-algebra functions, acting on `ev.vector` (the
magnitude/direction it actually carries) while leaving `ev.point`
untouched by `normalize` — the same "point of application stays fixed"
convention every other operation on this type follows. `dot` accepts
either another `EGEquipollentVector` or a bare `EGVector` on either side,
always comparing directions only (a dot product has no notion of "point
of application" to account for).
"""
LinearAlgebra.norm(ev::EGEquipollentVector) = norm(ev.vector)
LinearAlgebra.normalize(ev::EGEquipollentVector) = EGEquipollentVector(normalize(ev.vector), ev.point)
LinearAlgebra.dot(ev::EGEquipollentVector, w::EGVector) = dot(ev.vector, w)
LinearAlgebra.dot(w::EGVector, ev::EGEquipollentVector) = dot(w, ev.vector)
LinearAlgebra.dot(x::EGEquipollentVector, y::EGEquipollentVector) = dot(x.vector, y.vector)

EGBoundingBox(ev::EGEquipollentVector) = EGBoundingBox([ev.point, tip(ev)])

"""
    ev::EGEquipollentVector + w::EGVector

Adds the free vector `w` to `ev`'s own vector, **keeping the same point of
application** — the parallelogram-law sum of two vectors applied at the
same point, expressed here as "one equipollent vector plus a free one"
since that's the operation actually needed (summing two
`EGEquipollentVector`s at potentially *different* points has no single
canonical geometric meaning without first choosing which point to
translate them to, so it's deliberately not defined).
"""
Base.:+(ev::EGEquipollentVector, w::EGVector) = EGEquipollentVector(ev.vector + w, ev.point)
Base.:+(w::EGVector, ev::EGEquipollentVector) = ev + w
Base.:-(ev::EGEquipollentVector, w::EGVector) = EGEquipollentVector(ev.vector - w, ev.point)

translate(ev::EGEquipollentVector, w::EGVector) = EGEquipollentVector(ev.vector, translate(ev.point, w))

rotate(ev::EGEquipollentVector{2}, angle::Real, center::EGPoint{2}=EGPoint(0.0, 0.0)) =
    EGEquipollentVector(rotate(ev.vector, angle), rotate(ev.point, angle, center))
rotate(ev::EGEquipollentVector{3}, angle::Real, axis::EGLine{3}) =
    EGEquipollentVector(rotate(ev.vector, angle, axis), rotate(ev.point, angle, axis))

"""
    homothety(ev::EGEquipollentVector, k::Real, center::EGPoint=EGPoint(0.0,0.0))

Scales `ev.point` about `center` as usual, and `ev.vector` by the literal
`k` (not `abs(k)`) — a negative `k` correctly flips the vector's direction
too, matching how the whole configuration point-reflects through `center`.
This is exactly the scaling a bare `EGVector` can never get inside
`@to_luxor_picture` (see this type's own docstring for why).
"""
homothety(ev::EGEquipollentVector{2}, k::Real, center::EGPoint{2}=EGPoint(0.0, 0.0)) =
    EGEquipollentVector(k * ev.vector, homothety(ev.point, k, center))
homothety(ev::EGEquipollentVector{3}, k::Real, center::EGPoint{3}=EGPoint(0.0, 0.0, 0.0)) =
    EGEquipollentVector(k * ev.vector, homothety(ev.point, k, center))

reflection(ev::EGEquipollentVector, about) = EGEquipollentVector(reflection(ev.vector, about), reflection(ev.point, about))
