# -------------------------------------------------------------------------
# EGCircularSector3, EGCircularSegment3, EGAnnularSector3 (<: EGPolygon{3,T})
# -- planar curved regions embedded in 3D via their own circle's plane,
# the 3D analogues of EGCircularSector2/EGCircularSegment2/EGAnnularSector2.
#
# Implementation trick: since each of these is guaranteed planar (it lives
# entirely in one EGCircularArc3's own circle's plane), `area`/`perimeter`/
# `centroid` are computed by projecting into a 2D frame local to that
# plane, delegating to the already-verified 2D EGCircularSector2/
# EGCircularSegment2/EGAnnularSector2 machinery, and lifting any point
# result back to 3D -- exact, not an approximation, since an orthonormal
# frame change preserves distances/angles/areas.
#
# The fully general EGCurvilinearTriangle3/Quadrilateral3/Ngon3 (mixed
# straight+any-conic-arc sides, arbitrary orientation, not necessarily
# planar in one circle's frame) are NOT here -- left for a later phase.
# -------------------------------------------------------------------------

# Maps a 3D point into the 2D frame local to circle `c` (origin at
# c.center, basis (_circle3_u(c), _conic3_w(c.normal, u))) and back.
_circle3_to2d(c::EGCircle3, p::EGPoint{3}) = begin
    u = _circle3_u(c)
    w = _conic3_w(c.normal, u)
    EGPoint(dot(p - c.center, u), dot(p - c.center, w))
end
_circle3_from2d(c::EGCircle3, p2::EGPoint{2}) = begin
    u = _circle3_u(c)
    w = _conic3_w(c.normal, u)
    c.center + p2[1] * u + p2[2] * w
end

# --- EGCircularSector3 -----------------------------------------------------

"""
    EGCircularSector3(arc::EGCircularArc3)
    EGCircularSector3(circle::EGCircle3, p1::EGPoint{3}, p2::EGPoint{3})

The "pie slice" swept by `arc` -- the 3D analogue of
[`EGCircularSector2`](@ref).
"""
struct EGCircularSector3{T<:Real} <: EGPolygon{3,T}
    arc::EGCircularArc3{T}
end
EGCircularSector3(circle::EGCircle3, p1, p2) = EGCircularSector3(EGCircularArc3(circle, p1, p2))

Base.:(==)(x::EGCircularSector3, y::EGCircularSector3) = x.arc == y.arc
Base.show(io::IO, s::EGCircularSector3) = print(io, "EGCircularSector3(", s.arc, ")")

_sector3_2d(s::EGCircularSector3) = begin
    c = s.arc.circle
    arc2 = EGCircularArc2(EGCircle2(EGPoint(0.0, 0.0), c.r), _circle3_to2d(c, s.arc.p1), _circle3_to2d(c, s.arc.p2))
    EGCircularSector2(arc2)
end

area(s::EGCircularSector3) = area(_sector3_2d(s))
perimeter(s::EGCircularSector3) = perimeter(_sector3_2d(s))
centroid(s::EGCircularSector3) = _circle3_from2d(s.arc.circle, centroid(_sector3_2d(s)))

function Base.in(p::EGPoint{3}, s::EGCircularSector3)
    on_plane(p, plane(s.arc.circle)) || return false
    return _circle3_to2d(s.arc.circle, p) in _sector3_2d(s)
end

rotate(s::EGCircularSector3, angle::Real, axis::EGLine{3}) = EGCircularSector3(rotate(s.arc, angle, axis))
translate(s::EGCircularSector3, v::EGVector{3}) = EGCircularSector3(translate(s.arc, v))
homothety(s::EGCircularSector3, k::Real, center::EGPoint{3}=EGPoint(0.0, 0.0, 0.0)) = EGCircularSector3(homothety(s.arc, k, center))
reflection(s::EGCircularSector3, about) = EGCircularSector3(reflection(s.arc, about))

# --- EGCircularSegment3 -----------------------------------------------------

"""
    EGCircularSegment3(arc::EGCircularArc3)
    EGCircularSegment3(circle::EGCircle3, p1::EGPoint{3}, p2::EGPoint{3})

The "cap" bounded by `arc` and its chord -- the 3D analogue of
[`EGCircularSegment2`](@ref).
"""
struct EGCircularSegment3{T<:Real} <: EGPolygon{3,T}
    arc::EGCircularArc3{T}
end
EGCircularSegment3(circle::EGCircle3, p1, p2) = EGCircularSegment3(EGCircularArc3(circle, p1, p2))

Base.:(==)(x::EGCircularSegment3, y::EGCircularSegment3) = x.arc == y.arc
Base.show(io::IO, s::EGCircularSegment3) = print(io, "EGCircularSegment3(", s.arc, ")")

_segment3_2d(s::EGCircularSegment3) = begin
    c = s.arc.circle
    arc2 = EGCircularArc2(EGCircle2(EGPoint(0.0, 0.0), c.r), _circle3_to2d(c, s.arc.p1), _circle3_to2d(c, s.arc.p2))
    EGCircularSegment2(arc2)
end

area(s::EGCircularSegment3) = area(_segment3_2d(s))
perimeter(s::EGCircularSegment3) = perimeter(_segment3_2d(s))
centroid(s::EGCircularSegment3) = _circle3_from2d(s.arc.circle, centroid(_segment3_2d(s)))

function Base.in(p::EGPoint{3}, s::EGCircularSegment3)
    on_plane(p, plane(s.arc.circle)) || return false
    return _circle3_to2d(s.arc.circle, p) in _segment3_2d(s)
end

rotate(s::EGCircularSegment3, angle::Real, axis::EGLine{3}) = EGCircularSegment3(rotate(s.arc, angle, axis))
translate(s::EGCircularSegment3, v::EGVector{3}) = EGCircularSegment3(translate(s.arc, v))
homothety(s::EGCircularSegment3, k::Real, center::EGPoint{3}=EGPoint(0.0, 0.0, 0.0)) = EGCircularSegment3(homothety(s.arc, k, center))
reflection(s::EGCircularSegment3, about) = EGCircularSegment3(reflection(s.arc, about))

# --- EGAnnularSector3 -----------------------------------------------------

"""
    EGAnnularSector3(outer::EGCircularArc3, r_inner::Real)

The "ring slice" between `outer` and the corresponding arc of the
concentric circle of radius `r_inner` -- the 3D analogue of
[`EGAnnularSector2`](@ref).
"""
struct EGAnnularSector3{T<:Real} <: EGPolygon{3,T}
    outer::EGCircularArc3{T}
    r_inner::T
    function EGAnnularSector3{T}(outer::EGCircularArc3{T}, r_inner::T) where {T<:Real}
        r_inner < outer.circle.r || throw(ArgumentError("EGAnnularSector3: r_inner must be less than the outer radius"))
        return new{T}(outer, r_inner)
    end
end
function EGAnnularSector3(outer::EGCircularArc3{T1}, r_inner::T2) where {T1,T2}
    T = promote_type(T1, T2)
    return EGAnnularSector3{T}(convert(EGCircularArc3{T}, outer), T(r_inner))
end

Base.:(==)(x::EGAnnularSector3, y::EGAnnularSector3) = x.outer == y.outer && x.r_inner == y.r_inner
Base.show(io::IO, s::EGAnnularSector3) = print(io, "EGAnnularSector3(", s.outer, ", r_inner=", s.r_inner, ")")

_annular3_2d(s::EGAnnularSector3) = begin
    c = s.outer.circle
    arc2 = EGCircularArc2(EGCircle2(EGPoint(0.0, 0.0), c.r), _circle3_to2d(c, s.outer.p1), _circle3_to2d(c, s.outer.p2))
    EGAnnularSector2(arc2, s.r_inner)
end

area(s::EGAnnularSector3) = area(_annular3_2d(s))
perimeter(s::EGAnnularSector3) = perimeter(_annular3_2d(s))
centroid(s::EGAnnularSector3) = _circle3_from2d(s.outer.circle, centroid(_annular3_2d(s)))

rotate(s::EGAnnularSector3, angle::Real, axis::EGLine{3}) = EGAnnularSector3(rotate(s.outer, angle, axis), s.r_inner)
translate(s::EGAnnularSector3, v::EGVector{3}) = EGAnnularSector3(translate(s.outer, v), s.r_inner)
homothety(s::EGAnnularSector3, k::Real, center::EGPoint{3}=EGPoint(0.0, 0.0, 0.0)) = EGAnnularSector3(homothety(s.outer, k, center), abs(k) * s.r_inner)
reflection(s::EGAnnularSector3, about) = EGAnnularSector3(reflection(s.outer, about), s.r_inner)
