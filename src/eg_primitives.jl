# -------------------------------------------------------------------------
# Phase 2 of the EG-prefixed type hierarchy rewrite (see
# .claude/plans/structured-wibbling-wigderson.md): EGSegment/EGLine/EGRay
# (<: EGCurve) and EGBoundingBox, built on EGPoint/EGVector. Coexists
# alongside the existing Point2-based Segment/Line/Ray/BoundingBox for
# now — nothing else in the package is migrated onto these yet.
# -------------------------------------------------------------------------

# --- Point-level transforms (needed before Segment/Line/Ray can define
# their own pointwise versions) ---------------------------------------

"""
    rotate(p::EGPoint, angle, center=EGPoint(0.0, 0.0))

Rotate `p` by `angle` radians (counterclockwise) around `center`.
"""
function rotate(p::EGPoint, angle::Real, center::EGPoint=EGPoint(0.0, 0.0))
    v = p - center
    c, s = cos(angle), sin(angle)
    return center + EGPoint(c * v[1] - s * v[2], s * v[1] + c * v[2])
end

"""
    homothety(p::EGPoint, k, center=EGPoint(0.0, 0.0))

Scale `p` by ratio `k` about `center`.
"""
homothety(p::EGPoint, k::Real, center::EGPoint=EGPoint(0.0, 0.0)) = center + k * (p - center)

"""
    reflection(p::EGPoint, about::EGPoint)

Reflect `p` through the point `about` (point symmetry).
"""
reflection(p::EGPoint, about::EGPoint) = 2 * about - p

"""
    midpoint(p1::EGPoint, p2::EGPoint)
"""
midpoint(p1::EGPoint, p2::EGPoint) = (p1 + p2) / 2

"""
    distance(p1::EGPoint, p2::EGPoint)
"""
distance(p1::EGPoint, p2::EGPoint) = norm(p2 - p1)

"""
    orthogonal(v::EGVector)

`v` rotated by +90 degrees (counterclockwise). 2D only.
"""
orthogonal(v::EGVector{2}) = EGVector(-v[2], v[1])

# Also needed on EGPoint: since EGPoint arithmetic stays permissive
# (Point - Point -> Point, not Vector, per the session's explicit design
# choice), a "direction" computed as a difference of two points is itself
# an EGPoint, and several ported formulas (e.g. `intersection(::EGCircle2,
# ::EGCircle2)`) call `orthogonal` on exactly that.
orthogonal(p::EGPoint{2}) = EGVector(-p[2], p[1])

# `cross2` is already defined, untyped, in primitives.jl (`a[1]*b[2] -
# a[2]*b[1]`) — it works on EGPoint/EGVector for free via indexing, no
# new method needed here.

# --- EGSegment, EGLine, EGRay ------------------------------------------

"""
    EGSegment(p1::EGPoint, p2::EGPoint)

The finite segment `[p1, p2]`. `s[1]`/`s[2]` access its two endpoints.
"""
struct EGSegment{Dim,T<:Real} <: EGCurve{Dim,T}
    p1::EGPoint{Dim,T}
    p2::EGPoint{Dim,T}
end
EGSegment(p1::EGPoint{Dim,T1}, p2::EGPoint{Dim,T2}) where {Dim,T1,T2} =
    EGSegment{Dim,promote_type(T1, T2)}(p1, p2)

"""
    EGLine(p1::EGPoint, p2::EGPoint)

The infinite straight line passing through `p1` and `p2`.
"""
struct EGLine{Dim,T<:Real} <: EGCurve{Dim,T}
    p1::EGPoint{Dim,T}
    p2::EGPoint{Dim,T}
end
EGLine(p1::EGPoint{Dim,T1}, p2::EGPoint{Dim,T2}) where {Dim,T1,T2} =
    EGLine{Dim,promote_type(T1, T2)}(p1, p2)
EGLine(s::EGSegment) = EGLine(s.p1, s.p2)

"""
    EGRay(origin::EGPoint, through::EGPoint)

The half-line starting at `origin` and passing through `through`.
"""
struct EGRay{Dim,T<:Real} <: EGCurve{Dim,T}
    origin::EGPoint{Dim,T}
    through::EGPoint{Dim,T}
end
EGRay(o::EGPoint{Dim,T1}, t::EGPoint{Dim,T2}) where {Dim,T1,T2} =
    EGRay{Dim,promote_type(T1, T2)}(o, t)

Base.getindex(s::EGSegment, i::Integer) = i == 1 ? s.p1 : s.p2
Base.length(::EGSegment) = 2
Base.iterate(s::EGSegment, i::Int=1) = i > 2 ? nothing : (s[i], i + 1)

Base.:(==)(a::EGSegment, b::EGSegment) = a.p1 == b.p1 && a.p2 == b.p2
Base.:(==)(a::EGLine, b::EGLine) = a.p1 == b.p1 && a.p2 == b.p2
Base.:(==)(a::EGRay, b::EGRay) = a.origin == b.origin && a.through == b.through
Base.isapprox(a::EGSegment, b::EGSegment; kwargs...) = isapprox(a.p1, b.p1; kwargs...) && isapprox(a.p2, b.p2; kwargs...)
Base.isapprox(a::EGLine, b::EGLine; kwargs...) = isapprox(a.p1, b.p1; kwargs...) && isapprox(a.p2, b.p2; kwargs...)
Base.isapprox(a::EGRay, b::EGRay; kwargs...) = isapprox(a.origin, b.origin; kwargs...) && isapprox(a.through, b.through; kwargs...)
Base.show(io::IO, s::EGSegment) = print(io, "EGSegment(", s.p1, " -> ", s.p2, ")")
Base.show(io::IO, l::EGLine) = print(io, "EGLine(", l.p1, " -> ", l.p2, ")")
Base.show(io::IO, r::EGRay) = print(io, "EGRay(", r.origin, " -> ", r.through, ")")

"""
    direction(obj)

The direction of a `EGLine`, `EGRay` or `EGSegment`, as an [`EGVector`](@ref).
"""
direction(l::EGLine) = EGVector(l.p2 - l.p1)
direction(r::EGRay) = EGVector(r.through - r.origin)
direction(s::EGSegment) = EGVector(s.p2 - s.p1)

# `slope_angle` is already defined, untyped, in primitives.jl
# (`atan(direction(obj)[2], direction(obj)[1])`) — works here for free
# since it just calls `direction`, already overloaded above.

distance(s::EGSegment) = distance(s.p1, s.p2)
midpoint(s::EGSegment) = midpoint(s.p1, s.p2)

"""
    projection(p::EGPoint, l::EGLine)
"""
function projection(p::EGPoint, l::EGLine)
    d = direction(l)
    t = dot(p - l.p1, d) / dot(d, d)
    return l.p1 + t * d
end

distance(p::EGPoint, l::EGLine) = abs(cross2(direction(l), p - l.p1)) / norm(direction(l))
distance(l::EGLine, p::EGPoint) = distance(p, l)

"""
    reflection(p::EGPoint, l::EGLine)

Reflect `p` across the line `l` (axial symmetry).
"""
reflection(p::EGPoint, l::EGLine) = 2 * projection(p, l) - p

reflection(s::EGSegment, about) = EGSegment(reflection(s.p1, about), reflection(s.p2, about))
reflection(l::EGLine, about) = EGLine(reflection(l.p1, about), reflection(l.p2, about))
reflection(r::EGRay, about) = EGRay(reflection(r.origin, about), reflection(r.through, about))

rotate(s::EGSegment, angle::Real, center::EGPoint=EGPoint(0.0, 0.0)) =
    EGSegment(rotate(s.p1, angle, center), rotate(s.p2, angle, center))
rotate(l::EGLine, angle::Real, center::EGPoint=EGPoint(0.0, 0.0)) =
    EGLine(rotate(l.p1, angle, center), rotate(l.p2, angle, center))
rotate(r::EGRay, angle::Real, center::EGPoint=EGPoint(0.0, 0.0)) =
    EGRay(rotate(r.origin, angle, center), rotate(r.through, angle, center))

homothety(s::EGSegment, k::Real, center::EGPoint=EGPoint(0.0, 0.0)) =
    EGSegment(homothety(s.p1, k, center), homothety(s.p2, k, center))
homothety(l::EGLine, k::Real, center::EGPoint=EGPoint(0.0, 0.0)) =
    EGLine(homothety(l.p1, k, center), homothety(l.p2, k, center))
homothety(r::EGRay, k::Real, center::EGPoint=EGPoint(0.0, 0.0)) =
    EGRay(homothety(r.origin, k, center), homothety(r.through, k, center))

# --- EGBoundingBox --------------------------------------------------------

"""
    EGBoundingBox(min::EGPoint, max::EGPoint)

An axis-aligned bounding box. Deliberately not part of the `EGRegion`
hierarchy and has no `rotate`/`reflection` methods: an arbitrary rotation
or reflection wouldn't generally produce another axis-aligned box.
Translation (`+`/`-`) and uniform scaling about the origin (`*`) are the
only transforms that always keep it axis-aligned, so those are what's
supported.
"""
struct EGBoundingBox{Dim,T<:Real} <: EGObject{Dim,T}
    min::EGPoint{Dim,T}
    max::EGPoint{Dim,T}
end

function EGBoundingBox(points::AbstractVector{<:EGPoint{Dim}}) where {Dim}
    isempty(points) && throw(ArgumentError("EGBoundingBox requires at least one point"))
    lo = EGPoint(ntuple(i -> minimum(p[i] for p in points), Dim))
    hi = EGPoint(ntuple(i -> maximum(p[i] for p in points), Dim))
    return EGBoundingBox(lo, hi)
end

EGBoundingBox(s::EGSegment) = EGBoundingBox([s.p1, s.p2])

Base.:(==)(a::EGBoundingBox, b::EGBoundingBox) = a.min == b.min && a.max == b.max
Base.isapprox(a::EGBoundingBox, b::EGBoundingBox; kwargs...) =
    isapprox(a.min, b.min; kwargs...) && isapprox(a.max, b.max; kwargs...)
Base.:+(bb::EGBoundingBox, p::EGPoint) = EGBoundingBox(bb.min + p, bb.max + p)
Base.:-(bb::EGBoundingBox, p::EGPoint) = EGBoundingBox(bb.min - p, bb.max - p)
function Base.:*(bb::EGBoundingBox{Dim}, k::Real) where {Dim}
    p1, p2 = bb.min * k, bb.max * k
    lo = EGPoint(ntuple(i -> min(p1[i], p2[i]), Dim))
    hi = EGPoint(ntuple(i -> max(p1[i], p2[i]), Dim))
    return EGBoundingBox(lo, hi)
end
Base.show(io::IO, bb::EGBoundingBox) = print(io, "EGBoundingBox(", bb.min, " .. ", bb.max, ")")

"""
    p in bb::EGBoundingBox
"""
Base.in(p::EGPoint{Dim}, bb::EGBoundingBox{Dim}) where {Dim} = all(i -> bb.min[i] <= p[i] <= bb.max[i], 1:Dim)

"""
    bbox_width(bb::EGBoundingBox)
"""
bbox_width(bb::EGBoundingBox) = bb.max[1] - bb.min[1]

"""
    bbox_height(bb::EGBoundingBox)
"""
bbox_height(bb::EGBoundingBox) = bb.max[2] - bb.min[2]

"""
    bbox_center(bb::EGBoundingBox)
"""
bbox_center(bb::EGBoundingBox) = midpoint(bb.min, bb.max)

"""
    bbox_diagonal(bb::EGBoundingBox)

The distance between `bb.min` and `bb.max`.
"""
bbox_diagonal(bb::EGBoundingBox) = distance(bb.min, bb.max)

"""
    bbox_aspect_ratio(bb::EGBoundingBox)

`bbox_width(bb) / bbox_height(bb)`.
"""
bbox_aspect_ratio(bb::EGBoundingBox) = bbox_width(bb) / bbox_height(bb)

"""
    bboxes_intersect(a::EGBoundingBox, b::EGBoundingBox)

Whether `a` and `b` overlap (touching counts as intersecting).
"""
bboxes_intersect(a::EGBoundingBox{2}, b::EGBoundingBox{2}) =
    !(a.max[1] < b.min[1] || b.max[1] < a.min[1] || a.max[2] < b.min[2] || b.max[2] < a.min[2])

"""
    bbox_intersection(a::EGBoundingBox, b::EGBoundingBox)

The overlapping box of `a` and `b`, or `nothing` if they don't intersect.
"""
function bbox_intersection(a::EGBoundingBox{2}, b::EGBoundingBox{2})
    bboxes_intersect(a, b) || return nothing
    lo = EGPoint(max(a.min[1], b.min[1]), max(a.min[2], b.min[2]))
    hi = EGPoint(min(a.max[1], b.max[1]), min(a.max[2], b.max[2]))
    return EGBoundingBox(lo, hi)
end
