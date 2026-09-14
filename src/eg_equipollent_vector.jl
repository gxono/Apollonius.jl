# -------------------------------------------------------------------------
# EGEquipollentVector (<: EGCurve{Dim,T}): a free EGVector applied at a
# specific EGPoint -- the classical "vector equipolente" (a representative
# of a free vector, tied to a point of application). A bare EGVector is
# deliberately positionless, so EGBoundingBox(::EGVector) is empty and it
# never contributes to @to_luxor_picture's fit-to-canvas *sizing*, and it
# can't be shifted into position either (nowhere to shift it *to*) -- but
# it CAN be scaled/flipped to the picture's own scale (see its own
# `homothety` method and `_place_in_picture`'s comment), which composes
# correctly with a separately-placed anchor EGPoint. EGEquipollentVector
# is still the more robust choice for anything meant to be drawn/reasoned
# about as one piece: it has a real EGBoundingBox of its own (so it
# contributes to the picture's sizing even if it's the only thing in the
# block), and transforms fully as a single object via translate/rotate/
# homothety/reflection, without needing a second, separately-tracked
# anchor point alongside it.
# -------------------------------------------------------------------------

"""
    EGEquipollentVector(vector::EGVector, point::EGPoint)

`vector`, applied at `point` -- i.e. the directed segment from `point` to
`point + vector`. A bare [`EGVector`](@ref) has no position of its own, so
it never contributes to [`@to_luxor_picture`](@ref)'s fit-to-canvas
*sizing* and can't be shifted into place the way a positioned shape can
— this type can, since it has a real [`EGBoundingBox`](@ref) and
transforms fully as one piece via `translate`/`rotate`/`homothety`/
`reflection`, without needing a second point tracked alongside it.
`vector` comes first to match [`path(::EGVector, ::EGPoint)`](@ref)'s own
`(vector, from)` order, and so the single-argument form below reads as
"this vector, optionally at a point" rather than the other way around.
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
    EGVector(ev::EGEquipollentVector)

The bare, positionless [`EGVector`](@ref) `ev` carries (`ev.vector`,
discarding `ev.point`) — the same "convert back to the simpler type"
convention as [`EGVector(::EGPoint)`](@ref).
"""
EGVector(ev::EGEquipollentVector) = ev.vector

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

"""
    p::EGPoint + ev::EGEquipollentVector

Same as `p + ev.vector` — `ev`'s own point of application is ignored here,
exactly like `p + v::EGVector` never looks at where `v` "is" (it isn't
anywhere). Use [`translate`](@ref)`(p, ev)` instead if what's wanted is to
move `p`; this method exists only so point arithmetic doesn't have to
unwrap `ev` by hand first.
"""
Base.:+(p::EGPoint, ev::EGEquipollentVector) = p + ev.vector
Base.:+(ev::EGEquipollentVector, p::EGPoint) = p + ev

translate(ev::EGEquipollentVector, w::EGVector) = EGEquipollentVector(ev.vector, translate(ev.point, w))

"""
    translate(obj::EGObject, ev::EGEquipollentVector)

Translate `obj` by `ev`'s own displacement (`ev.vector`), ignoring
`ev.point` — translation only cares about direction and magnitude, not
where `ev` happens to be anchored. Lets any of the package's existing
`translate(obj, ::EGVector)` methods be driven by an `EGEquipollentVector`
directly, without unwrapping it by hand first.
"""
translate(obj::EGObject, ev::EGEquipollentVector) = translate(obj, ev.vector)

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
