# -------------------------------------------------------------------------ike
# EGHalfSpace3, EGSlab3, EGDihedralAngle3, EGPolyhedralAngle3 (<: EGSet{3,T}
# directly, unbounded) -- the 3D peers of EGHalfPlane2/EGStrip2/EGAngle2
# from eg_unbounded.jl. EGDihedralAngle3 is the edge+2-halfplanes angle
# (peer of EGAngle2, one dimension up); EGPolyhedralAngle3 is the
# vertex+n-rays solid angle (n=3 is the classical "triedro" -- kept as one
# general type rather than a separate fixed-3 struct, the same way
# EGCurvilinearNgon2 doesn't get a separate "Pentagon" type per n).
# -------------------------------------------------------------------------

# The component of p (or the free vector p-edge.p1) perpendicular to edge's
# own direction -- shared building block for EGDihedralAngle3.
_perp_to_edge(p::EGPoint{3}, edge::EGLine{3}) = p - projection(p, edge)

# Signed angle (radians, right-hand rule about axis) to rotate `u` onto
# `v`, both assumed already perpendicular to `axis` -- the 3D, given-axis
# analogue of `angle_between(u,v)` (which is inherently 2D: there's no
# unique "positive" rotation sense in 3D without picking an axis first).
_signed_angle_about(u, v, axis) = atan(dot(axis, cross3(u, v)), dot(u, v))

# --- EGHalfSpace3 -------------------------------------------------------------

"""
    EGHalfSpace3(boundary::EGPlane3, side::Int)
    EGHalfSpace3(boundary::EGPlane3, p::EGPoint{3})

The half-space bounded by `boundary`: either directly via `side` (`+1`
matching `boundary.normal`'s own direction, `-1` the other way), or via a
point `p` known to lie in the half-space — the 3D analogue of
[`EGHalfPlane2`](@ref).
"""
struct EGHalfSpace3{T<:Real} <: EGSet{3,T}
    boundary::EGPlane3{T}
    side::Int
end
function EGHalfSpace3(boundary::EGPlane3, p::EGPoint{3})
    s = side_of_plane(p, boundary)
    s == 0 && throw(ArgumentError("EGHalfSpace3: p lies exactly on boundary; side is ambiguous"))
    return EGHalfSpace3(boundary, s)
end

Base.:(==)(a::EGHalfSpace3, b::EGHalfSpace3) = a.boundary == b.boundary && a.side == b.side
Base.show(io::IO, hs::EGHalfSpace3) = print(io, "EGHalfSpace3(", hs.boundary, ", side=", hs.side, ")")

"""
    p in hs::EGHalfSpace3

Whether `p` lies in `hs` (its own side of `hs.boundary`, boundary included).
"""
Base.in(p::EGPoint{3}, hs::EGHalfSpace3) = side_of_plane(p, hs.boundary) * hs.side >= 0

"""
    distance(p::EGPoint{3}, hs::EGHalfSpace3; mode::Symbol=:region)

`0.0` from inside `hs` with the default `mode = :region`; with `mode =
:boundary`, always the distance to `hs.boundary`, even from inside --
same convention as [`distance(::EGPoint, ::EGHalfPlane2)`](@ref).
"""
function distance(p::EGPoint{3}, hs::EGHalfSpace3; mode::Symbol=:region)
    _check_distance_mode(mode)
    d = distance(p, hs.boundary)
    mode == :boundary && return d
    return p in hs ? zero(d) : d
end
distance(hs::EGHalfSpace3, p::EGPoint{3}; mode::Symbol=:region) = distance(p, hs; mode=mode)

rotate(hs::EGHalfSpace3, angle::Real, axis::EGLine{3}) = EGHalfSpace3(rotate(hs.boundary, angle, axis), hs.side)
translate(hs::EGHalfSpace3, v::EGVector{3}) = EGHalfSpace3(translate(hs.boundary, v), hs.side)
homothety(hs::EGHalfSpace3, k::Real, center::EGPoint{3}=EGPoint(0.0, 0.0, 0.0)) = EGHalfSpace3(homothety(hs.boundary, k, center), hs.side)
function reflection(hs::EGHalfSpace3, about)
    new_boundary = reflection(hs.boundary, about)
    interior_pt = hs.boundary.point + hs.side * hs.boundary.normal
    return EGHalfSpace3(new_boundary, side_of_plane(reflection(interior_pt, about), new_boundary))
end

# --- EGSlab3 -------------------------------------------------------------------

"""
    EGSlab3(plane1::EGPlane3, plane2::EGPlane3; atol=1e-9)

The region between two parallel planes — the 3D analogue of
[`EGStrip2`](@ref). Throws an `ArgumentError` if `plane1`/`plane2` aren't
parallel.
"""
struct EGSlab3{T<:Real} <: EGSet{3,T}
    plane1::EGPlane3{T}
    plane2::EGPlane3{T}
    function EGSlab3{T}(plane1::EGPlane3{T}, plane2::EGPlane3{T}; atol=1e-9) where {T<:Real}
        norm(cross3(plane1.normal, plane2.normal)) <= sqrt(atol) ||
            throw(ArgumentError("EGSlab3: plane1 and plane2 must be parallel"))
        return new{T}(plane1, plane2)
    end
end
function EGSlab3(plane1::EGPlane3{T1}, plane2::EGPlane3{T2}; atol=1e-9) where {T1,T2}
    T = promote_type(T1, T2)
    return EGSlab3{T}(convert(EGPlane3{T}, plane1), convert(EGPlane3{T}, plane2); atol=atol)
end

Base.:(==)(a::EGSlab3, b::EGSlab3) = a.plane1 == b.plane1 && a.plane2 == b.plane2
Base.show(io::IO, s::EGSlab3) = print(io, "EGSlab3(", s.plane1, ", ", s.plane2, ")")

"""
    slab_width(s::EGSlab3)

The perpendicular distance between `s`'s two planes — the 3D analogue of
[`strip_width`](@ref).
"""
slab_width(s::EGSlab3) = distance(s.plane1.point, s.plane2)

"""
    p in s::EGSlab3

Whether `p` lies between (or on) `s`'s two planes.
"""
function Base.in(p::EGPoint{3}, s::EGSlab3)
    d1, d2 = _signed_distance(p, s.plane1), _signed_distance(p, s.plane2)
    return d1 * d2 <= 0 || iszero(d1) || iszero(d2)
end

"""
    distance(p::EGPoint{3}, s::EGSlab3; mode::Symbol=:region)

`0.0` from inside `s` with the default `mode = :region` (the `min`
distance to either plane, otherwise); with `mode = :boundary`, always that
`min`, even from inside — same convention as
[`distance(::EGPoint, ::EGStrip2)`](@ref).
"""
function distance(p::EGPoint{3}, s::EGSlab3; mode::Symbol=:region)
    _check_distance_mode(mode)
    d = min(distance(p, s.plane1), distance(p, s.plane2))
    mode == :boundary && return d
    return p in s ? zero(d) : d
end
distance(s::EGSlab3, p::EGPoint{3}; mode::Symbol=:region) = distance(p, s; mode=mode)

rotate(s::EGSlab3, angle::Real, axis::EGLine{3}) = EGSlab3(rotate(s.plane1, angle, axis), rotate(s.plane2, angle, axis))
translate(s::EGSlab3, v::EGVector{3}) = EGSlab3(translate(s.plane1, v), translate(s.plane2, v))
homothety(s::EGSlab3, k::Real, center::EGPoint{3}=EGPoint(0.0, 0.0, 0.0)) = EGSlab3(homothety(s.plane1, k, center), homothety(s.plane2, k, center))
reflection(s::EGSlab3, about) = EGSlab3(reflection(s.plane1, about), reflection(s.plane2, about))

# --- EGDihedralAngle3 -----------------------------------------------------------

"""
    EGDihedralAngle3(edge::EGLine{3}, a::EGPoint{3}, b::EGPoint{3})

The dihedral angle at `edge`, swept from the half-plane `edge`+`a` to the
half-plane `edge`+`b` — the 3D analogue of [`EGAngle2`](@ref) (a vertex +
2 rays there; an edge *line* + 2 half-planes here). Oriented the same way:
`EGDihedralAngle3(edge, a, b)` and `EGDihedralAngle3(edge, b, a)` have the
same [`abs`](@ref) but opposite sign, via the right-hand rule about
`direction(edge)`.
"""
struct EGDihedralAngle3{T<:Real} <: EGSet{3,T}
    edge::EGLine{3,T}
    a::EGPoint{3,T}
    b::EGPoint{3,T}
end
function EGDihedralAngle3(edge::EGLine{3,T1}, a::EGPoint, b::EGPoint) where {T1}
    T = promote_type(T1, eltype(a), eltype(b))
    return EGDihedralAngle3{T}(convert(EGLine{3,T}, edge), convert(EGPoint{3,T}, a), convert(EGPoint{3,T}, b))
end

Base.:(==)(x::EGDihedralAngle3, y::EGDihedralAngle3) = x.edge == y.edge && x.a == y.a && x.b == y.b
Base.show(io::IO, d::EGDihedralAngle3) = print(io, "EGDihedralAngle3(", d.edge, ", ", d.a, ", ", d.b, ")")

_dihedral_k(d::EGDihedralAngle3) = direction(d.edge) / norm(direction(d.edge))
_dihedral_va(d::EGDihedralAngle3) = _perp_to_edge(d.a, d.edge)
_dihedral_vb(d::EGDihedralAngle3) = _perp_to_edge(d.b, d.edge)

"""
    measure(d::EGDihedralAngle3)

The signed dihedral angle (radians, `(-π, π]`), swept counterclockwise
(right-hand rule about `direction(d.edge)`) from the half-plane through
`a` to the one through `b`.
"""
measure(d::EGDihedralAngle3) = _signed_angle_about(_dihedral_va(d), _dihedral_vb(d), _dihedral_k(d))

"""
    normalized_measure(d::EGDihedralAngle3)

[`measure`](@ref)`(d)` shifted into `[0, 2π)`.
"""
normalized_measure(d::EGDihedralAngle3) = mod(measure(d), 2pi)

Base.abs(d::EGDihedralAngle3) = acos(clamp(dot(normalize(_dihedral_va(d)), normalize(_dihedral_vb(d))), -1.0, 1.0))
is_direct(d::EGDihedralAngle3) = measure(d) > 0

"""
    reverse(d::EGDihedralAngle3)

Swap `a`/`b` — flips the sign of [`measure`](@ref) but not [`abs`](@ref).
"""
Base.reverse(d::EGDihedralAngle3) = EGDihedralAngle3(d.edge, d.b, d.a)

"""
    p in d::EGDihedralAngle3

Whether `p` falls in the solid wedge swept from the half-plane through
`a` to the one through `b`.
"""
function Base.in(p::EGPoint{3}, d::EGDihedralAngle3)
    vp = _perp_to_edge(p, d.edge)
    norm(vp) <= eps(Float64) && return true # on the edge itself
    θ = mod(_signed_angle_about(_dihedral_va(d), vp, _dihedral_k(d)), 2pi)
    return θ <= mod(measure(d), 2pi) + sqrt(eps(Float64))
end

rotate(d::EGDihedralAngle3, angle::Real, axis::EGLine{3}) =
    EGDihedralAngle3(rotate(d.edge, angle, axis), rotate(d.a, angle, axis), rotate(d.b, angle, axis))
translate(d::EGDihedralAngle3, v::EGVector{3}) = EGDihedralAngle3(translate(d.edge, v), translate(d.a, v), translate(d.b, v))

"""
    homothety(d::EGDihedralAngle3, k::Real, center::EGPoint{3}=EGPoint(0.0,0.0,0.0))

Unlike a 2D `homothety` (never orientation-reversing, `k²` is always
positive) or `homothety` on any other 3D type here, a 3D homothety's
linear part has determinant `k³` — negative for `k < 0`, a genuinely
orientation-reversing map. So `a`/`b` are swapped exactly when `k < 0`
(same reasoning as [`reflection(::EGDihedralAngle3, _)`](@ref)) to keep
[`measure`](@ref)'s sign correctly tracking the transformed wedge, rather
than silently flipping only for negative ratios.
"""
function homothety(d::EGDihedralAngle3, k::Real, center::EGPoint{3}=EGPoint(0.0, 0.0, 0.0))
    e, a2, b2 = homothety(d.edge, k, center), homothety(d.a, k, center), homothety(d.b, k, center)
    return k < 0 ? EGDihedralAngle3(e, b2, a2) : EGDihedralAngle3(e, a2, b2)
end

# A reflection reverses orientation, so `a`/`b` are swapped -- exactly the
# reason `reflection(::EGAngle2, _)` swaps its own `a`/`b`, one dimension up
# (the 3D wrinkle: unlike 2D, THIS holds for point reflection too, since a
# 3D point reflection is itself orientation-reversing -- see
# `homothety(::EGPlane3, _)`'s docstring).
reflection(d::EGDihedralAngle3, about) =
    EGDihedralAngle3(reflection(d.edge, about), reflection(d.b, about), reflection(d.a, about))

# --- EGPolyhedralAngle3 (n >= 3 rays from a vertex; n = 3 is the "triedro") -----

"""
    EGPolyhedralAngle3(vertex::EGPoint{3}, rays::AbstractVector{<:EGPoint{3}})

The solid angle at `vertex` swept by `n >= 3` consecutive rays
(`vertex -> rays[i]`), each pair of neighbors bounding one planar face —
the 3D analogue of [`EGAngle2`](@ref) with more than 2 rays. `n == 3` is
the classical **triedro** (trihedral angle, e.g. the corner of a
tetrahedron); there is no separate fixed-3 type, the same way
[`EGCurvilinearNgon2`](@ref) doesn't get one type per side count.
"""
struct EGPolyhedralAngle3{T<:Real} <: EGSet{3,T}
    vertex::EGPoint{3,T}
    rays::Vector{EGPoint{3,T}}
    function EGPolyhedralAngle3{T}(vertex::EGPoint{3,T}, rays::Vector{EGPoint{3,T}}) where {T<:Real}
        length(rays) >= 3 || throw(ArgumentError("EGPolyhedralAngle3: needs at least 3 rays (got $(length(rays)))"))
        return new{T}(vertex, rays)
    end
end
function EGPolyhedralAngle3(v::EGPoint, rs::AbstractVector)
    T = promote_type(eltype(v), (eltype(r) for r in rs)...)
    return EGPolyhedralAngle3{T}(convert(EGPoint{3,T}, v), EGPoint{3,T}[convert(EGPoint{3,T}, r) for r in rs])
end

Base.:(==)(x::EGPolyhedralAngle3, y::EGPolyhedralAngle3) = x.vertex == y.vertex && x.rays == y.rays
Base.show(io::IO, pa::EGPolyhedralAngle3) = print(io, "EGPolyhedralAngle3(", pa.vertex, ", ", pa.rays, ")")

# Van Oosterom & Strackee's closed-form solid angle of the triangular cone
# spanned by unit-ish vectors u, v, w from the vertex.
function _triangle_solid_angle(u, v, w)
    nu, nv, nw = norm(u), norm(v), norm(w)
    numer = abs(dot(u, cross3(v, w)))
    denom = nu * nv * nw + dot(u, v) * nw + dot(u, w) * nv + dot(v, w) * nu
    return 2 * atan(numer, denom)
end

"""
    solid_angle(pa::EGPolyhedralAngle3)

The solid angle (steradians) `pa` subtends, via Van Oosterom & Strackee's
closed form on each of the `n-2` triangles fanned from `rays[1]` (a
triedro, `n=3`, is exactly one such triangle).
"""
function solid_angle(pa::EGPolyhedralAngle3)
    rs = [r - pa.vertex for r in pa.rays]
    return sum(_triangle_solid_angle(rs[1], rs[i], rs[i+1]) for i in 2:length(rs)-1)
end

"""
    p in pa::EGPolyhedralAngle3

Whether `p` falls in the solid cone `pa` sweeps: on the correct side of
every one of the `n` planes formed by `pa.vertex` and each consecutive
pair of rays.
"""
function Base.in(p::EGPoint{3}, pa::EGPolyhedralAngle3)
    n = length(pa.rays)
    interior = pa.vertex + sum(r - pa.vertex for r in pa.rays) / n
    for i in 1:n
        ri, rj = pa.rays[i], pa.rays[mod1(i + 1, n)]
        nrm = cross3(ri - pa.vertex, rj - pa.vertex)
        norm(nrm) <= eps(Float64) && continue
        wall = EGPlane3(pa.vertex, nrm)
        side_of_plane(interior, wall) * side_of_plane(p, wall) < 0 && return false
    end
    return true
end

rotate(pa::EGPolyhedralAngle3, angle::Real, axis::EGLine{3}) =
    EGPolyhedralAngle3(rotate(pa.vertex, angle, axis), [rotate(r, angle, axis) for r in pa.rays])
translate(pa::EGPolyhedralAngle3, v::EGVector{3}) = EGPolyhedralAngle3(translate(pa.vertex, v), [translate(r, v) for r in pa.rays])
homothety(pa::EGPolyhedralAngle3, k::Real, center::EGPoint{3}=EGPoint(0.0, 0.0, 0.0)) =
    EGPolyhedralAngle3(homothety(pa.vertex, k, center), [homothety(r, k, center) for r in pa.rays])
reflection(pa::EGPolyhedralAngle3, about) = EGPolyhedralAngle3(reflection(pa.vertex, about), [reflection(r, about) for r in pa.rays])
