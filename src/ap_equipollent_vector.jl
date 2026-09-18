"""
    APEquipollentVector(vector::APVector, point::APPoint)

`vector`, applied at `point` -- i.e. the directed segment from `point` to
`point + vector`. A bare [`APVector`](@ref) has no position of its own, so
it never contributes to [`@to_luxor_picture`](@ref)'s fit-to-canvas
*sizing* and can't be shifted into place the way a positioned shape can
-- this type can, since it has a real [`APBoundingBox`](@ref) and
transforms fully as one piece via `translate`/`rotate`/`homothety`/
`reflection`, without needing a second point tracked alongside it.
`vector` comes first to match [`path(::APVector, ::APPoint)`](@ref)'s own
`(vector, from)` order, and so the single-argument form below reads as
"this vector, optionally at a point" rather than the other way around.
"""
struct APEquipollentVector{Dim,T<:Real} <: APCurve{Dim,T}
    vector::APVector{Dim,T}
    point::APPoint{Dim,T}
end
function APEquipollentVector(vector::APVector, p::APPoint)
    T = promote_type(eltype(p), eltype(vector))
    return APEquipollentVector{length(p),T}(convert(APVector{length(p),T}, vector), convert(APPoint{length(p),T}, p))
end
"""
    APEquipollentVector(vector::APVector)

`vector`, applied at the origin.
"""
APEquipollentVector(vector::APVector{Dim,T}) where {Dim,T} = APEquipollentVector(vector, APPoint(ntuple(_ -> zero(T), Dim)))
Base.:(==)(x::APEquipollentVector, y::APEquipollentVector) = x.vector == y.vector && x.point == y.point
Base.isapprox(x::APEquipollentVector, y::APEquipollentVector; kwargs...) =
    isapprox(x.vector, y.vector; kwargs...) && isapprox(x.point, y.point; kwargs...)
Base.show(io::IO, ev::APEquipollentVector) = print(io, "APEquipollentVector(", ev.vector, ", ", ev.point, ")")
"""
    tip(ev::APEquipollentVector)

`ev.point + ev.vector` -- computed on demand rather than stored, to avoid
duplicating information already fully determined by `point`/`vector`.
"""
tip(ev::APEquipollentVector) = ev.point + ev.vector
direction(ev::APEquipollentVector) = ev.vector
"""
    APVector(ev::APEquipollentVector)

The bare, positionless [`APVector`](@ref) `ev` carries (`ev.vector`,
discarding `ev.point`) -- the same "convert back to the simpler type"
convention as [`APVector(::APPoint)`](@ref).
"""
APVector(ev::APEquipollentVector) = ev.vector
"""
    norm(ev::APEquipollentVector)
    normalize(ev::APEquipollentVector)
    dot(ev::APEquipollentVector, other)

The standard linear-algebra functions, acting on `ev.vector` (the
magnitude/direction it actually carries) while leaving `ev.point`
untouched by `normalize` -- the same "point of application stays fixed"
convention every other operation on this type follows. `dot` accepts
either another `APEquipollentVector` or a bare `APVector` on either side,
always comparing directions only (a dot product has no notion of "point
of application" to account for).
"""
LinearAlgebra.norm(ev::APEquipollentVector) = norm(ev.vector)
LinearAlgebra.normalize(ev::APEquipollentVector) = APEquipollentVector(normalize(ev.vector), ev.point)
LinearAlgebra.dot(ev::APEquipollentVector, w::APVector) = dot(ev.vector, w)
LinearAlgebra.dot(w::APVector, ev::APEquipollentVector) = dot(w, ev.vector)
LinearAlgebra.dot(x::APEquipollentVector, y::APEquipollentVector) = dot(x.vector, y.vector)
APBoundingBox(ev::APEquipollentVector) = APBoundingBox([ev.point, tip(ev)])
"""
    ev::APEquipollentVector + w::APVector

Adds the free vector `w` to `ev`'s own vector, **keeping the same point of
application** -- the parallelogram-law sum of two vectors applied at the
same point, expressed here as "one equipollent vector plus a free one"
since that's the operation actually needed (summing two
`APEquipollentVector`s at potentially *different* points has no single
canonical geometric meaning without first choosing which point to
translate them to, so it's deliberately not defined).
"""
Base.:+(ev::APEquipollentVector, w::APVector) = APEquipollentVector(ev.vector + w, ev.point)
Base.:+(w::APVector, ev::APEquipollentVector) = ev + w
Base.:-(ev::APEquipollentVector, w::APVector) = APEquipollentVector(ev.vector - w, ev.point)
"""
    p::APPoint + ev::APEquipollentVector

Same as `p + ev.vector` -- `ev`'s own point of application is ignored here,
exactly like `p + v::APVector` never looks at where `v` "is" (it isn't
anywhere). Use [`translate`](@ref)`(p, ev)` instead if what's wanted is to
move `p`; this method exists only so point arithmetic doesn't have to
unwrap `ev` by hand first.
"""
Base.:+(p::APPoint, ev::APEquipollentVector) = p + ev.vector
Base.:+(ev::APEquipollentVector, p::APPoint) = p + ev
translate(ev::APEquipollentVector, w::APVector) = APEquipollentVector(ev.vector, translate(ev.point, w))
"""
    translate(obj::APObject, ev::APEquipollentVector)

Translate `obj` by `ev`'s own displacement (`ev.vector`), ignoring
`ev.point` -- translation only cares about direction and magnitude, not
where `ev` happens to be anchored. Lets any of the package's existing
`translate(obj, ::APVector)` methods be driven by an `APEquipollentVector`
directly, without unwrapping it by hand first.
"""
translate(obj::APObject, ev::APEquipollentVector) = translate(obj, ev.vector)
rotate(ev::APEquipollentVector{2}, angle::Real, center::APPoint{2}=APPoint(0.0, 0.0)) =
    APEquipollentVector(rotate(ev.vector, angle), rotate(ev.point, angle, center))
rotate(ev::APEquipollentVector{3}, angle::Real, axis::APLine{3}) =
    APEquipollentVector(rotate(ev.vector, angle, axis), rotate(ev.point, angle, axis))
"""
    homothety(ev::APEquipollentVector, k::Real, center::APPoint=APPoint(0.0,0.0))

Scales `ev.point` about `center` as usual, and `ev.vector` by the literal
`k` (not `abs(k)`) -- a negative `k` correctly flips the vector's direction
too, matching how the whole configuration point-reflects through `center`.
This is exactly the scaling a bare `APVector` can never get inside
`@to_luxor_picture` (see this type's own docstring for why).
"""
homothety(ev::APEquipollentVector{2}, k::Real, center::APPoint{2}=APPoint(0.0, 0.0)) =
    APEquipollentVector(k * ev.vector, homothety(ev.point, k, center))
homothety(ev::APEquipollentVector{3}, k::Real, center::APPoint{3}=APPoint(0.0, 0.0, 0.0)) =
    APEquipollentVector(k * ev.vector, homothety(ev.point, k, center))
reflection(ev::APEquipollentVector, about) = APEquipollentVector(reflection(ev.vector, about), reflection(ev.point, about))
