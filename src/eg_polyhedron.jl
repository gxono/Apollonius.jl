# -------------------------------------------------------------------------
# EGPolyhedron (<: EGRegion{Dim,T}), the flat-faced-solid sibling of
# EGPolygon: a closed 3D solid bounded by planar polygon `faces`, exactly
# one dimension up from EGPolygon's `sides`. Concrete types:
# EGTetrahedron3, EGPyramid3, EGPrism3, EGParallelepiped3 (+ the box3/cube3
# named constructors), EGGeneralPolyhedron3.
#
# EGCylinder3/EGCone3 are deliberately NOT here (see eg_curved_solid.jl):
# a curved lateral surface makes "polyhedron" a genuine misnomer for them,
# and their volume/surface_area/centroid have such simple closed forms
# that routing them through the generic `faces` machinery below would add
# complexity for no benefit.
# -------------------------------------------------------------------------

"""
    faces(p::EGPolyhedron)

The planar polygon faces of `p`, each an [`EGPolygon`](@ref)`{3,T}` given
with consistent **outward** orientation (every concrete constructor below
guarantees this on its own, regardless of the order its own defining
points were given in) -- the `EGPolyhedron` analogue of
[`sides`](@ref)`(::EGPolygon)`.
"""
function faces end

# Build a planar face from `verts` (given in either winding order),
# auto-reversed if needed so its own outward normal (Newell's method: the
# sum of consecutive cross products) points away from `interior_pt` -- any
# point already known to lie inside the solid. Used by every concrete
# EGPolyhedron constructor below so `faces` always comes out consistently
# outward-oriented no matter which order the user's own points were given
# in -- the polyhedron analogue of `EGTetrahedron3`... no separate
# "walk"/stitching step (unlike `_polygon_walk` in eg_polygon.jl) is
# needed here, since each face is built directly from known-good vertices
# rather than reassembled from an arbitrary side soup.
function _outward_face(verts::AbstractVector, interior_pt::EGPoint{3})
    n = length(verts)
    fnormal = sum(cross3(verts[i], verts[mod1(i + 1, n)]) for i in 1:n)
    c = sum(verts) / n
    ordered = dot(fnormal, interior_pt - c) > 0 ? reverse(verts) : verts
    n == 3 && return EGTriangle(ordered[1], ordered[2], ordered[3])
    n == 4 && return EGQuadrilateral(ordered[1], ordered[2], ordered[3], ordered[4])
    return EGStraightNgon(ordered)
end

# Signed volume and first-moment contribution of one planar face, via
# fan-triangulation from its own first vertex: each triangle (v1,vi,vi+1)
# forms a tetrahedron with the origin, whose signed volume and centroid
# are both closed-form. Summed over every face (with NO reversed-side
# bookkeeping needed, unlike `_polygon_walk` -- see `faces`'s own
# docstring for why: every face is already consistently outward-oriented
# by construction), this is the divergence-theorem analogue of
# `_side_greens_term`/`_polygon_walk`, one dimension up.
function _face_volume_moment(f)
    vs = vertices(f)
    v1 = vs[1]
    T = eltype(v1)
    vol, mx, my, mz = zero(T), zero(T), zero(T), zero(T)
    for i in 2:length(vs)-1
        vi, vi1 = vs[i], vs[i+1]
        sv = dot(cross3(v1, vi), vi1) / 6
        vol += sv
        mx += sv * (v1[1] + vi[1] + vi1[1]) / 4
        my += sv * (v1[2] + vi[2] + vi1[2]) / 4
        mz += sv * (v1[3] + vi[3] + vi1[3]) / 4
    end
    return vol, mx, my, mz
end

"""
    volume(p::EGPolyhedron)

Volume of `p`, via a signed tetrahedral decomposition from the origin
(fan-triangulating each of [`faces`](@ref)`(p)`) -- the divergence-theorem
analogue of `area(::EGPolygon)`'s Green's-theorem walk.
"""
volume(p::EGPolyhedron) = abs(sum(f -> _face_volume_moment(f)[1], faces(p)))

"""
    centroid(p::EGPolyhedron)

Volume-weighted centroid of `p`, from the same tetrahedral decomposition
[`volume`](@ref) uses.
"""
function centroid(p::EGPolyhedron)
    vol, mx, my, mz = 0.0, 0.0, 0.0, 0.0
    for f in faces(p)
        v, x, y, z = _face_volume_moment(f)
        vol += v
        mx += x
        my += y
        mz += z
    end
    return EGPoint(mx / vol, my / vol, mz / vol)
end

"""
    surface_area(p::EGPolyhedron)

Sum of the areas of `p`'s [`faces`](@ref).
"""
surface_area(p::EGPolyhedron) = sum(area, faces(p))

# --- EGTetrahedron3 -----------------------------------------------------------

"""
    EGTetrahedron3(a::EGPoint{3}, b::EGPoint{3}, c::EGPoint{3}, d::EGPoint{3})

The 3-simplex through `a`, `b`, `c`, `d` (in *any* order -- unlike a
2D `EGTriangle`, where vertex order only affects `is_convex`-style
predicates, a 3D solid's faces need a definite outward sense, which
[`faces`](@ref) works out from the 4 points directly rather than trusting
their input order) -- the direct analogue of [`EGTriangle`](@ref).
"""
struct EGTetrahedron3{T<:Real} <: EGPolyhedron{3,T}
    a::EGPoint{3,T}
    b::EGPoint{3,T}
    c::EGPoint{3,T}
    d::EGPoint{3,T}
end
function EGTetrahedron3(a::EGPointLike, b::EGPointLike, c::EGPointLike, d::EGPointLike)
    a, b, c, d = _topoint(a), _topoint(b), _topoint(c), _topoint(d)
    T = promote_type(eltype(a), eltype(b), eltype(c), eltype(d))
    return EGTetrahedron3{T}(convert(EGPoint{3,T}, a), convert(EGPoint{3,T}, b), convert(EGPoint{3,T}, c), convert(EGPoint{3,T}, d))
end

vertices(t::EGTetrahedron3) = (t.a, t.b, t.c, t.d)
Base.getindex(t::EGTetrahedron3, i::Integer) = vertices(t)[i]
Base.length(::EGTetrahedron3) = 4
Base.iterate(t::EGTetrahedron3, i::Int=1) = i > 4 ? nothing : (t[i], i + 1)
Base.:(==)(x::EGTetrahedron3, y::EGTetrahedron3) = x.a == y.a && x.b == y.b && x.c == y.c && x.d == y.d
Base.show(io::IO, t::EGTetrahedron3) = print(io, "EGTetrahedron3(", t.a, ", ", t.b, ", ", t.c, ", ", t.d, ")")

function faces(t::EGTetrahedron3)
    interior = (t.a + t.b + t.c + t.d) / 4
    return (_outward_face([t.b, t.c, t.d], interior), _outward_face([t.a, t.c, t.d], interior),
        _outward_face([t.a, t.b, t.d], interior), _outward_face([t.a, t.b, t.c], interior))
end

rotate(t::EGTetrahedron3, angle::Real, axis::EGLine{3}) =
    EGTetrahedron3(rotate(t.a, angle, axis), rotate(t.b, angle, axis), rotate(t.c, angle, axis), rotate(t.d, angle, axis))
translate(t::EGTetrahedron3, v::EGVector{3}) = EGTetrahedron3(translate(t.a, v), translate(t.b, v), translate(t.c, v), translate(t.d, v))
homothety(t::EGTetrahedron3, k::Real, center::EGPoint{3}=EGPoint(0.0, 0.0, 0.0)) =
    EGTetrahedron3(homothety(t.a, k, center), homothety(t.b, k, center), homothety(t.c, k, center), homothety(t.d, k, center))
reflection(t::EGTetrahedron3, about) =
    EGTetrahedron3(reflection(t.a, about), reflection(t.b, about), reflection(t.c, about), reflection(t.d, about))

# --- EGParallelepiped3 ---------------------------------------------------------

"""
    EGParallelepiped3(origin::EGPoint{3}, u::EGVector{3}, v::EGVector{3}, w::EGVector{3})

The parallelepiped with one vertex at `origin` and edges `u`, `v`, `w`
(not necessarily perpendicular) -- the direct analogue of
[`EGQuadrilateral`](@ref). See [`box3`](@ref)/[`cube3`](@ref) for the
common axis-aligned-rectangular-box and cube special cases.
"""
struct EGParallelepiped3{T<:Real} <: EGPolyhedron{3,T}
    origin::EGPoint{3,T}
    u::EGVector{3,T}
    v::EGVector{3,T}
    w::EGVector{3,T}
end
function EGParallelepiped3(origin::EGPointLike, u::EGVector{3}, v::EGVector{3}, w::EGVector{3})
    o = _topoint(origin)
    T = promote_type(eltype(o), eltype(u), eltype(v), eltype(w))
    return EGParallelepiped3{T}(convert(EGPoint{3,T}, o), convert(EGVector{3,T}, u), convert(EGVector{3,T}, v), convert(EGVector{3,T}, w))
end

Base.:(==)(x::EGParallelepiped3, y::EGParallelepiped3) = x.origin == y.origin && x.u == y.u && x.v == y.v && x.w == y.w
Base.show(io::IO, pp::EGParallelepiped3) = print(io, "EGParallelepiped3(", pp.origin, ", ", pp.u, ", ", pp.v, ", ", pp.w, ")")

"""
    vertices(pp::EGParallelepiped3)

The 8 vertices of `pp`, derived from `origin`/`u`/`v`/`w` (not stored).
"""
vertices(pp::EGParallelepiped3) = (pp.origin, pp.origin + pp.u, pp.origin + pp.u + pp.v, pp.origin + pp.v,
    pp.origin + pp.w, pp.origin + pp.u + pp.w, pp.origin + pp.u + pp.v + pp.w, pp.origin + pp.v + pp.w)

function faces(pp::EGParallelepiped3)
    p1, p2, p3, p4, p5, p6, p7, p8 = vertices(pp)
    interior = pp.origin + (pp.u + pp.v + pp.w) / 2
    return (_outward_face([p1, p2, p3, p4], interior), _outward_face([p5, p6, p7, p8], interior),
        _outward_face([p1, p2, p6, p5], interior), _outward_face([p4, p3, p7, p8], interior),
        _outward_face([p1, p4, p8, p5], interior), _outward_face([p2, p3, p7, p6], interior))
end

rotate(pp::EGParallelepiped3, angle::Real, axis::EGLine{3}) =
    EGParallelepiped3(rotate(pp.origin, angle, axis), rotate(pp.u, angle, axis), rotate(pp.v, angle, axis), rotate(pp.w, angle, axis))
translate(pp::EGParallelepiped3, v::EGVector{3}) = EGParallelepiped3(translate(pp.origin, v), pp.u, pp.v, pp.w)
homothety(pp::EGParallelepiped3, k::Real, center::EGPoint{3}=EGPoint(0.0, 0.0, 0.0)) =
    EGParallelepiped3(homothety(pp.origin, k, center), k * pp.u, k * pp.v, k * pp.w)
reflection(pp::EGParallelepiped3, about::EGPoint{3}) = EGParallelepiped3(reflection(pp.origin, about), -pp.u, -pp.v, -pp.w)
reflection(pp::EGParallelepiped3, about::EGPlane3) =
    EGParallelepiped3(reflection(pp.origin, about), reflection(pp.u, about), reflection(pp.v, about), reflection(pp.w, about))

"""
    box3(origin::EGPoint{3}, dx::Real, dy::Real, dz::Real)

The axis-aligned rectangular box ("ortoedro") with one corner at `origin`
and the given side lengths -- a named constructor for the common special
case of [`EGParallelepiped3`](@ref) with 3 mutually perpendicular edges,
the same way [`rectangle_on_segment`](@ref) is a named special case of
[`EGQuadrilateral`](@ref).
"""
box3(origin::EGPointLike, dx::Real, dy::Real, dz::Real) =
    EGParallelepiped3(origin, EGVector(dx, 0.0, 0.0), EGVector(0.0, dy, 0.0), EGVector(0.0, 0.0, dz))

"""
    cube3(origin::EGPoint{3}, side::Real)

The axis-aligned cube with one corner at `origin` and the given `side`
length -- the further special case of [`box3`](@ref) with equal sides.
"""
cube3(origin::EGPointLike, side::Real) = box3(origin, side, side, side)

# --- EGPyramid3 -----------------------------------------------------------------

"""
    EGPyramid3(apex::EGPoint{3}, base::EGStraightNgon{3})

The pyramid with vertex `apex` over the (planar) polygon `base` -- the
general-base analogue of [`EGTetrahedron3`](@ref) (a tetrahedron is
exactly a pyramid over a triangular base). `base`'s own vertex order
doesn't need to be pre-oriented; [`faces`](@ref) works it out.
"""
struct EGPyramid3{T<:Real} <: EGPolyhedron{3,T}
    apex::EGPoint{3,T}
    base::EGStraightNgon{3,T}
end
function EGPyramid3(apex::EGPointLike, base::EGStraightNgon{3})
    a = _topoint(apex)
    T = promote_type(eltype(a), eltype(base.vertices[1]))
    return EGPyramid3{T}(convert(EGPoint{3,T}, a), EGStraightNgon(EGPoint{3,T}[convert(EGPoint{3,T}, v) for v in base.vertices]))
end

Base.:(==)(x::EGPyramid3, y::EGPyramid3) = x.apex == y.apex && x.base == y.base
Base.show(io::IO, p::EGPyramid3) = print(io, "EGPyramid3(", p.apex, ", ", p.base, ")")

function faces(p::EGPyramid3)
    bv = collect(vertices(p.base))
    n = length(bv)
    interior = (sum(bv) / n + p.apex) / 2
    lateral = [_outward_face([p.apex, bv[i], bv[mod1(i + 1, n)]], interior) for i in 1:n]
    return (_outward_face(bv, interior), lateral...)
end

rotate(p::EGPyramid3, angle::Real, axis::EGLine{3}) = EGPyramid3(rotate(p.apex, angle, axis), rotate(p.base, angle, axis))
translate(p::EGPyramid3, v::EGVector{3}) = EGPyramid3(translate(p.apex, v), translate(p.base, v))
homothety(p::EGPyramid3, k::Real, center::EGPoint{3}=EGPoint(0.0, 0.0, 0.0)) =
    EGPyramid3(homothety(p.apex, k, center), homothety(p.base, k, center))
reflection(p::EGPyramid3, about) = EGPyramid3(reflection(p.apex, about), reflection(p.base, about))

# --- EGPrism3 -------------------------------------------------------------------

"""
    EGPrism3(base::EGStraightNgon{3}, v::EGVector{3})

The prism with base `base` and top face `translate(base, v)` -- lateral
faces are the parallelograms connecting corresponding edges. A *right*
prism over a [`regular_polygon`](@ref) base with `v` perpendicular to it
is the common textbook case; oblique prisms (any `v`) work the same way.
"""
struct EGPrism3{T<:Real} <: EGPolyhedron{3,T}
    base::EGStraightNgon{3,T}
    v::EGVector{3,T}
end
function EGPrism3(base::EGStraightNgon{3}, v::EGVector{3})
    T = promote_type(eltype(base.vertices[1]), eltype(v))
    return EGPrism3{T}(EGStraightNgon(EGPoint{3,T}[convert(EGPoint{3,T}, p) for p in base.vertices]), convert(EGVector{3,T}, v))
end

Base.:(==)(x::EGPrism3, y::EGPrism3) = x.base == y.base && x.v == y.v
Base.show(io::IO, p::EGPrism3) = print(io, "EGPrism3(", p.base, ", ", p.v, ")")

function faces(p::EGPrism3)
    bv = collect(vertices(p.base))
    n = length(bv)
    tv = [b + p.v for b in bv]
    interior = (sum(bv) + sum(tv)) / (2n)
    lateral = [_outward_face([bv[i], bv[mod1(i + 1, n)], tv[mod1(i + 1, n)], tv[i]], interior) for i in 1:n]
    return (_outward_face(bv, interior), _outward_face(tv, interior), lateral...)
end

rotate(p::EGPrism3, angle::Real, axis::EGLine{3}) = EGPrism3(rotate(p.base, angle, axis), rotate(p.v, angle, axis))
translate(p::EGPrism3, v::EGVector{3}) = EGPrism3(translate(p.base, v), p.v)
homothety(p::EGPrism3, k::Real, center::EGPoint{3}=EGPoint(0.0, 0.0, 0.0)) = EGPrism3(homothety(p.base, k, center), k * p.v)
reflection(p::EGPrism3, about::EGPoint{3}) = EGPrism3(reflection(p.base, about), -p.v)
reflection(p::EGPrism3, about::EGPlane3) = EGPrism3(reflection(p.base, about), reflection(p.v, about))

# --- EGGeneralPolyhedron3 -------------------------------------------------------

"""
    EGGeneralPolyhedron3(faces::AbstractVector{<:EGPolygon{3}})

A closed solid bounded by an arbitrary list of planar polygon faces,
given with consistent **outward** orientation (not validated -- same
"assumed correct" convention as [`EGStraightNgon`](@ref)'s "assumed
simple") -- the fully general analogue of [`EGStraightNgon`](@ref).
"""
struct EGGeneralPolyhedron3{T<:Real} <: EGPolyhedron{3,T}
    faces::Vector{<:EGPolygon{3,T}}
end
EGGeneralPolyhedron3(fs::AbstractVector{<:EGPolygon{3,T}}) where {T} = EGGeneralPolyhedron3{T}(collect(fs))

faces(pg::EGGeneralPolyhedron3) = pg.faces
Base.:(==)(x::EGGeneralPolyhedron3, y::EGGeneralPolyhedron3) = x.faces == y.faces
Base.show(io::IO, pg::EGGeneralPolyhedron3) = print(io, "EGGeneralPolyhedron3(", pg.faces, ")")

rotate(pg::EGGeneralPolyhedron3, angle::Real, axis::EGLine{3}) = EGGeneralPolyhedron3([rotate(f, angle, axis) for f in pg.faces])
translate(pg::EGGeneralPolyhedron3, v::EGVector{3}) = EGGeneralPolyhedron3([translate(f, v) for f in pg.faces])
homothety(pg::EGGeneralPolyhedron3, k::Real, center::EGPoint{3}=EGPoint(0.0, 0.0, 0.0)) =
    EGGeneralPolyhedron3([homothety(f, k, center) for f in pg.faces])
reflection(pg::EGGeneralPolyhedron3, about) = EGGeneralPolyhedron3([reflection(f, about) for f in pg.faces])
