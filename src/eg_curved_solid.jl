# -------------------------------------------------------------------------
# EGCylinder3, EGCone3 -- right circular solids with a curved lateral
# surface, so NOT EGPolyhedron (a poliedro, by definition, has only flat
# faces -- see eg_polyhedron.jl's header note). Direct EGRegion{3,T}
# subtypes instead, each with its own textbook closed-form
# volume/surface_area/centroid -- there's no benefit to routing 2 types
# with such simple formulas through a generic "faces" mechanism.
#
# Both are deliberately minimal (2 points + a radius each, per an
# explicit design request): p1/p2 (or apex/base_center) and r fully
# determine a RIGHT circular cylinder/cone (axis perpendicular to the
# caps); nothing else is stored, everything else (height, axis direction,
# the cap(s) as EGCircle3) is derived on demand.
# -------------------------------------------------------------------------

# --- EGCylinder3 ----------------------------------------------------------------

"""
    EGCylinder3(p1::EGPoint{3}, p2::EGPoint{3}, r::Real)

The right circular cylinder with cap centers `p1`/`p2` and radius `r`
(the axis is `[p1,p2]`; the caps are perpendicular to it).
"""
struct EGCylinder3{T<:Real} <: EGRegion{3,T}
    p1::EGPoint{3,T}
    p2::EGPoint{3,T}
    r::T
end
function EGCylinder3(p1::EGPointLike, p2::EGPointLike, r::Real)
    p1, p2 = _topoint(p1), _topoint(p2)
    T = promote_type(eltype(p1), eltype(p2), typeof(r))
    return EGCylinder3{T}(convert(EGPoint{3,T}, p1), convert(EGPoint{3,T}, p2), T(r))
end

Base.:(==)(a::EGCylinder3, b::EGCylinder3) = a.p1 == b.p1 && a.p2 == b.p2 && a.r == b.r
Base.isapprox(a::EGCylinder3, b::EGCylinder3; kwargs...) =
    isapprox(a.p1, b.p1; kwargs...) && isapprox(a.p2, b.p2; kwargs...) && isapprox(a.r, b.r; kwargs...)
Base.show(io::IO, cyl::EGCylinder3) = print(io, "EGCylinder3(", cyl.p1, ", ", cyl.p2, ", ", cyl.r, ")")

"""
    height(cyl::EGCylinder3)
"""
height(cyl::EGCylinder3) = distance(cyl.p1, cyl.p2)

"""
    caps(cyl::EGCylinder3)

The two [`EGCircle3`](@ref) caps of `cyl`, as a 2-tuple — computed on
demand rather than stored (see the file header).
"""
function caps(cyl::EGCylinder3)
    n = EGVector((cyl.p2 - cyl.p1)[1], (cyl.p2 - cyl.p1)[2], (cyl.p2 - cyl.p1)[3])
    return EGCircle3(cyl.p1, cyl.r, n), EGCircle3(cyl.p2, cyl.r, n)
end

volume(cyl::EGCylinder3) = pi * cyl.r^2 * height(cyl)
surface_area(cyl::EGCylinder3) = 2 * pi * cyl.r^2 + 2 * pi * cyl.r * height(cyl)
centroid(cyl::EGCylinder3) = midpoint(cyl.p1, cyl.p2)

"""
    p in cyl::EGCylinder3

Whether `p` lies in the solid `cyl` (inside or on its surface).
"""
function Base.in(p::EGPoint{3}, cyl::EGCylinder3)
    axis = EGLine(cyl.p1, cyl.p2)
    f = projection(p, axis)
    d = direction(axis)
    t = dot(f - cyl.p1, d) / dot(d, d)
    (t < -sqrt(eps(Float64)) || t > 1 + sqrt(eps(Float64))) && return false
    return distance(p, axis) <= cyl.r
end

"""
    distance(p::EGPoint{3}, cyl::EGCylinder3; mode::Symbol=:region)

Distance from `p` to the solid `cyl`, with the same `mode = :region`/
`:boundary` convention as [`distance(::EGPoint,::EGSphere3)`](@ref).
Computed via `cyl`'s own axial *meridian profile* in (axial, radial)
coordinates, since a right cylinder is a surface of revolution: the 3D
distance to its surface equals the plain 2D distance from `p`'s own
`(t, r)` coordinates to the profile's **3** real boundary segments (both
caps plus the lateral surface). Note this is only 3 sides, not a closed
rectangle `[0,height] x [0,r]` — the 4th, `r = 0`, is just `cyl`'s own
axis, not a physical surface, so it must NOT be treated as a boundary
(that would wrongly report points near the axis as "close to the
boundary").
"""
function distance(p::EGPoint{3}, cyl::EGCylinder3; mode::Symbol=:region)
    _check_distance_mode(mode)
    axis = EGLine(cyl.p1, cyl.p2)
    d = direction(axis)
    t = dot(p - cyl.p1, d) / dot(d, d) * norm(d)
    r = distance(p, axis)
    h = height(cyl)
    q = EGPoint(t, r)
    bottom = EGSegment(EGPoint(0.0, 0.0), EGPoint(0.0, cyl.r))
    lateral = EGSegment(EGPoint(0.0, cyl.r), EGPoint(h, cyl.r))
    top = EGSegment(EGPoint(h, cyl.r), EGPoint(h, 0.0))
    bd = min(distance(q, bottom), distance(q, lateral), distance(q, top))
    mode == :boundary && return bd
    inside = 0 <= t <= h && r <= cyl.r
    return inside ? zero(bd) : bd
end
distance(cyl::EGCylinder3, p::EGPoint{3}; mode::Symbol=:region) = distance(p, cyl; mode=mode)

rotate(cyl::EGCylinder3, angle::Real, axis::EGLine{3}) = EGCylinder3(rotate(cyl.p1, angle, axis), rotate(cyl.p2, angle, axis), cyl.r)
translate(cyl::EGCylinder3, v::EGVector{3}) = EGCylinder3(translate(cyl.p1, v), translate(cyl.p2, v), cyl.r)
homothety(cyl::EGCylinder3, k::Real, center::EGPoint{3}=EGPoint(0.0, 0.0, 0.0)) =
    EGCylinder3(homothety(cyl.p1, k, center), homothety(cyl.p2, k, center), abs(k) * cyl.r)
reflection(cyl::EGCylinder3, about) = EGCylinder3(reflection(cyl.p1, about), reflection(cyl.p2, about), cyl.r)

# --- EGCone3 --------------------------------------------------------------------

"""
    EGCone3(apex::EGPoint{3}, base_center::EGPoint{3}, r::Real)

The right circular cone with the given `apex`, base center
`base_center`, and base radius `r` (the axis is `[apex,base_center]`; the
base is perpendicular to it).
"""
struct EGCone3{T<:Real} <: EGRegion{3,T}
    apex::EGPoint{3,T}
    base_center::EGPoint{3,T}
    r::T
end
function EGCone3(apex::EGPointLike, base_center::EGPointLike, r::Real)
    apex, base_center = _topoint(apex), _topoint(base_center)
    T = promote_type(eltype(apex), eltype(base_center), typeof(r))
    return EGCone3{T}(convert(EGPoint{3,T}, apex), convert(EGPoint{3,T}, base_center), T(r))
end

Base.:(==)(a::EGCone3, b::EGCone3) = a.apex == b.apex && a.base_center == b.base_center && a.r == b.r
Base.isapprox(a::EGCone3, b::EGCone3; kwargs...) =
    isapprox(a.apex, b.apex; kwargs...) && isapprox(a.base_center, b.base_center; kwargs...) && isapprox(a.r, b.r; kwargs...)
Base.show(io::IO, c::EGCone3) = print(io, "EGCone3(", c.apex, ", ", c.base_center, ", ", c.r, ")")

"""
    height(c::EGCone3)
"""
height(c::EGCone3) = distance(c.apex, c.base_center)

"""
    slant_height(c::EGCone3)
"""
slant_height(c::EGCone3) = sqrt(height(c)^2 + c.r^2)

"""
    base(c::EGCone3)

The base [`EGCircle3`](@ref) of `c` — computed on demand rather than
stored.
"""
function base(c::EGCone3)
    n = EGVector((c.apex - c.base_center)[1], (c.apex - c.base_center)[2], (c.apex - c.base_center)[3])
    return EGCircle3(c.base_center, c.r, n)
end

volume(c::EGCone3) = pi * c.r^2 * height(c) / 3
surface_area(c::EGCone3) = pi * c.r^2 + pi * c.r * slant_height(c)

"""
    centroid(c::EGCone3)

A quarter of the way from the base to the apex — the same fraction as
[`centroid(::EGPyramid3)`](@ref) over a regular base, since a cone is
exactly the `n -> ∞` limit of a pyramid over a regular `n`-gon.
"""
centroid(c::EGCone3) = c.base_center + (c.apex - c.base_center) / 4

"""
    p in c::EGCone3

Whether `p` lies in the solid `c` (inside or on its surface).
"""
function Base.in(p::EGPoint{3}, c::EGCone3)
    axis = EGLine(c.base_center, c.apex)
    d = direction(axis)
    t = dot(p - c.base_center, d) / dot(d, d)
    (t < -sqrt(eps(Float64)) || t > 1 + sqrt(eps(Float64))) && return false
    return distance(p, axis) <= c.r * (1 - t)
end

"""
    distance(p::EGPoint{3}, c::EGCone3; mode::Symbol=:region)

Distance from `p` to the solid `c`, with the same `mode = :region`/
`:boundary` convention as [`distance(::EGPoint,::EGSphere3)`](@ref) --
via the same *meridian profile* idea as
[`distance(::EGPoint,::EGCylinder3)`](@ref): `p`'s own `(t, r)` (axial,
radial) coordinates against the profile's **2** real boundary segments
(the base disk, `(0,0)` to `(0,r)`, and the slant side, `(0,r)` to
`(height,0)`) — again explicitly not a 3rd, `r = 0` segment, which is
just `c`'s own axis.
"""
function distance(p::EGPoint{3}, c::EGCone3; mode::Symbol=:region)
    _check_distance_mode(mode)
    axis = EGLine(c.base_center, c.apex)
    d = direction(axis)
    t = dot(p - c.base_center, d) / dot(d, d) * norm(d)
    r = distance(p, axis)
    h = height(c)
    q = EGPoint(t, r)
    base_seg = EGSegment(EGPoint(0.0, 0.0), EGPoint(0.0, c.r))
    slant = EGSegment(EGPoint(0.0, c.r), EGPoint(h, 0.0))
    bd = min(distance(q, base_seg), distance(q, slant))
    mode == :boundary && return bd
    inside = 0 <= t <= h && r <= c.r * (1 - t / h)
    return inside ? zero(bd) : bd
end
distance(c::EGCone3, p::EGPoint{3}; mode::Symbol=:region) = distance(p, c; mode=mode)

rotate(c::EGCone3, angle::Real, axis::EGLine{3}) = EGCone3(rotate(c.apex, angle, axis), rotate(c.base_center, angle, axis), c.r)
translate(c::EGCone3, v::EGVector{3}) = EGCone3(translate(c.apex, v), translate(c.base_center, v), c.r)
homothety(c::EGCone3, k::Real, center::EGPoint{3}=EGPoint(0.0, 0.0, 0.0)) =
    EGCone3(homothety(c.apex, k, center), homothety(c.base_center, k, center), abs(k) * c.r)
reflection(c::EGCone3, about) = EGCone3(reflection(c.apex, about), reflection(c.base_center, about), c.r)
