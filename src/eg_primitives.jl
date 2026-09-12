# -------------------------------------------------------------------------
# EGSegment/EGLine/EGRay (<: EGCurve) and EGBoundingBox, built on
# EGPoint/EGVector.
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
    translate(p::EGPoint, v::EGVector)

Translate `p` by `v`. The fourth member of the `rotate`/`homothety`/
`reflection`/`translate` quartet implemented across the whole package;
unlike the other three, it takes no `center` (a translation has none).
"""
translate(p::EGPoint, v::EGVector) = p + v

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
function EGSegment(p1::EGPointLike, p2::EGPointLike)
    p1, p2 = _topoint(p1), _topoint(p2)
    return EGSegment{length(p1),promote_type(eltype(p1), eltype(p2))}(p1, p2)
end

"""
    EGLine(p1::EGPoint, p2::EGPoint)

The infinite straight line passing through `p1` and `p2`.
"""
struct EGLine{Dim,T<:Real} <: EGCurve{Dim,T}
    p1::EGPoint{Dim,T}
    p2::EGPoint{Dim,T}
end
function EGLine(p1::EGPointLike, p2::EGPointLike)
    p1, p2 = _topoint(p1), _topoint(p2)
    return EGLine{length(p1),promote_type(eltype(p1), eltype(p2))}(p1, p2)
end
EGLine(s::EGSegment) = EGLine(s.p1, s.p2)

"""
    EGRay(origin::EGPoint, through::EGPoint)

The half-line starting at `origin` and passing through `through`.
"""
struct EGRay{Dim,T<:Real} <: EGCurve{Dim,T}
    origin::EGPoint{Dim,T}
    through::EGPoint{Dim,T}
end
function EGRay(o::EGPointLike, t::EGPointLike)
    o, t = _topoint(o), _topoint(t)
    return EGRay{length(o),promote_type(eltype(o), eltype(t))}(o, t)
end

Base.getindex(s::EGSegment, i::Integer) = i == 1 ? s.p1 : s.p2
Base.length(::EGSegment) = 2
Base.iterate(s::EGSegment, i::Int=1) = i > 2 ? nothing : (s[i], i + 1)

Base.:(==)(a::EGSegment, b::EGSegment) = a.p1 == b.p1 && a.p2 == b.p2
Base.:(==)(a::EGLine, b::EGLine) = a.p1 == b.p1 && a.p2 == b.p2
Base.:(==)(a::EGRay, b::EGRay) = a.origin == b.origin && a.through == b.through

# Lets these convert like EGPoint/EGVector do (see the comment there) when
# nested as a field inside another struct with a different element type —
# e.g. EGStrip2 holding two EGLines, or EGParabola2 holding an EGLine
# directrix. Delegating to the type-parameterized inner constructor is
# enough: it already converts each field itself (that's what needed the
# EGPoint/EGVector fix in the first place).
Base.convert(::Type{EGSegment{Dim,T}}, s::EGSegment{Dim}) where {Dim,T} = EGSegment{Dim,T}(s.p1, s.p2)
Base.convert(::Type{EGLine{Dim,T}}, l::EGLine{Dim}) where {Dim,T} = EGLine{Dim,T}(l.p1, l.p2)
Base.convert(::Type{EGRay{Dim,T}}, r::EGRay{Dim}) where {Dim,T} = EGRay{Dim,T}(r.origin, r.through)
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

# --- EGVector transforms --------------------------------------------------
#
# A free vector has no position, only direction and magnitude, so it gets
# just the transforms that are actually meaningful for that: `rotate`
# (turns the direction) and `reflection` (mirrors the direction, about a
# point or a line — either way position-independent, since there's no
# anchor to reflect). No `center` argument, unlike `rotate`/`homothety`
# on `EGPoint`. `homothety(v, k)` is just `k * v` (already supported via
# `*`) and `translate` would be the identity (translating a positionless
# vector changes nothing) — neither adds anything, so neither is defined.

"""
    rotate(v::EGVector{2}, angle::Real)

Rotate the direction `v` by `angle` radians (counterclockwise).
"""
function rotate(v::EGVector{2}, angle::Real)
    c, s = cos(angle), sin(angle)
    return EGVector(c * v[1] - s * v[2], s * v[1] + c * v[2])
end

"""
    reflection(v::EGVector, about::EGPoint)

Point-reflect the direction `v` — simply `-v`, since a free vector has no
position for `about` to act on.
"""
reflection(v::EGVector, about::EGPoint) = -v

"""
    reflection(v::EGVector{2}, about::EGLine)

Reflect the direction `v` across `about`'s own direction (axial
symmetry); `about`'s position is irrelevant, only its direction matters.
"""
function reflection(v::EGVector{2}, about::EGLine)
    d = direction(about)
    return 2 * (dot(v, d) / dot(d, d)) * d - v
end

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
    distance(p::EGPoint, s::EGSegment)

Distance from `p` to the closest point of the *finite* segment `s` (unlike
[`distance(::EGPoint, ::EGLine)`](@ref), which measures to the infinite
line through `s`'s two points).
"""
function distance(p::EGPoint, s::EGSegment)
    d = s.p2 - s.p1
    dd = dot(d, d)
    dd <= 0 && return distance(p, s.p1)
    t = clamp(dot(p - s.p1, d) / dd, 0.0, 1.0)
    return distance(p, s.p1 + t * d)
end
distance(s::EGSegment, p::EGPoint) = distance(p, s)

"""
    distance(p::EGPoint, r::EGRay)

Distance from `p` to the closest point of the *half-line* `r` (clamped at
`r.origin`, unbounded past `r.through`).
"""
function distance(p::EGPoint, r::EGRay)
    d = r.through - r.origin
    dd = dot(d, d)
    dd <= 0 && return distance(p, r.origin)
    t = max(dot(p - r.origin, d) / dd, 0.0)
    return distance(p, r.origin + t * d)
end
distance(r::EGRay, p::EGPoint) = distance(p, r)

# Whether the infinite lines through (origin1,dir1) and (origin2,dir2) cross
# at parameters (t1,t2) landing inside [t1min,t1max] and [t2min,t2max] —
# shared by every EGLine/EGRay/EGSegment pairwise `distance` below, since
# for any two of these "clipped line" curves, either they genuinely cross
# within both curves' own valid ranges (distance 0), or — because each is
# an affine (straight, unclamped-slope) parametrization — the minimum
# distance is always achieved at one of the finite endpoints among the two
# curves (a Line contributes none, a Ray one, a Segment two).
function _clipped_lines_cross(origin1, dir1, t1min, t1max, origin2, dir2, t2min, t2max; atol=1e-9)
    denom = cross2(dir1, dir2)
    abs(denom) <= atol * norm(dir1) * norm(dir2) && return false
    diff = origin2 - origin1
    t1 = cross2(diff, dir2) / denom
    t2 = cross2(diff, dir1) / denom
    tol1 = sqrt(atol) * max(norm(dir1), 1.0)
    tol2 = sqrt(atol) * max(norm(dir2), 1.0)
    return (t1min - tol1 <= t1 <= t1max + tol1) && (t2min - tol2 <= t2 <= t2max + tol2)
end

"""
    distance(l1::EGLine, l2::EGLine; atol=1e-9)

`0` if `l1` and `l2` cross; otherwise (they're parallel) the constant
perpendicular gap between them.
"""
function distance(l1::EGLine, l2::EGLine; atol=1e-9)
    _clipped_lines_cross(l1.p1, direction(l1), -Inf, Inf, l2.p1, direction(l2), -Inf, Inf; atol=atol) && return 0.0
    return distance(l1.p1, l2)
end

"""
    distance(l::EGLine, r::EGRay; atol=1e-9)
"""
function distance(l::EGLine, r::EGRay; atol=1e-9)
    _clipped_lines_cross(l.p1, direction(l), -Inf, Inf, r.origin, direction(r), 0.0, Inf; atol=atol) && return 0.0
    return distance(r.origin, l)
end
distance(r::EGRay, l::EGLine; atol=1e-9) = distance(l, r; atol=atol)

"""
    distance(l::EGLine, s::EGSegment; atol=1e-9)
"""
function distance(l::EGLine, s::EGSegment; atol=1e-9)
    _clipped_lines_cross(l.p1, direction(l), -Inf, Inf, s.p1, direction(s), 0.0, 1.0; atol=atol) && return 0.0
    return min(distance(s.p1, l), distance(s.p2, l))
end
distance(s::EGSegment, l::EGLine; atol=1e-9) = distance(l, s; atol=atol)

"""
    distance(r1::EGRay, r2::EGRay; atol=1e-9)
"""
function distance(r1::EGRay, r2::EGRay; atol=1e-9)
    _clipped_lines_cross(r1.origin, direction(r1), 0.0, Inf, r2.origin, direction(r2), 0.0, Inf; atol=atol) && return 0.0
    return min(distance(r1.origin, r2), distance(r2.origin, r1))
end

"""
    distance(r::EGRay, s::EGSegment; atol=1e-9)
"""
function distance(r::EGRay, s::EGSegment; atol=1e-9)
    _clipped_lines_cross(r.origin, direction(r), 0.0, Inf, s.p1, direction(s), 0.0, 1.0; atol=atol) && return 0.0
    return min(distance(r.origin, s), distance(s.p1, r), distance(s.p2, r))
end
distance(s::EGSegment, r::EGRay; atol=1e-9) = distance(r, s; atol=atol)

"""
    distance(s1::EGSegment, s2::EGSegment; atol=1e-9)
"""
function distance(s1::EGSegment, s2::EGSegment; atol=1e-9)
    _clipped_lines_cross(s1.p1, direction(s1), 0.0, 1.0, s2.p1, direction(s2), 0.0, 1.0; atol=atol) && return 0.0
    return min(distance(s1.p1, s2), distance(s1.p2, s2), distance(s2.p1, s1), distance(s2.p2, s1))
end

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

translate(s::EGSegment, v::EGVector) = EGSegment(translate(s.p1, v), translate(s.p2, v))
translate(l::EGLine, v::EGVector) = EGLine(translate(l.p1, v), translate(l.p2, v))
translate(r::EGRay, v::EGVector) = EGRay(translate(r.origin, v), translate(r.through, v))

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
function EGBoundingBox(min::EGPointLike, max::EGPointLike)
    min, max = _topoint(min), _topoint(max)
    return EGBoundingBox{length(min),promote_type(eltype(min), eltype(max))}(min, max)
end

function EGBoundingBox(points::AbstractVector{<:EGPoint{Dim}}) where {Dim}
    isempty(points) && throw(ArgumentError("EGBoundingBox requires at least one point"))
    lo = EGPoint(ntuple(i -> minimum(p[i] for p in points), Dim))
    hi = EGPoint(ntuple(i -> maximum(p[i] for p in points), Dim))
    return EGBoundingBox(lo, hi)
end
EGBoundingBox(points::AbstractVector{<:Tuple}) = EGBoundingBox([_topoint(p) for p in points])

EGBoundingBox(s::EGSegment) = EGBoundingBox([s.p1, s.p2])

Base.:(==)(a::EGBoundingBox, b::EGBoundingBox) = a.min == b.min && a.max == b.max
Base.isapprox(a::EGBoundingBox, b::EGBoundingBox; kwargs...) =
    isapprox(a.min, b.min; kwargs...) && isapprox(a.max, b.max; kwargs...)
Base.:+(bb::EGBoundingBox, p::EGPoint) = EGBoundingBox(bb.min + p, bb.max + p)
Base.:-(bb::EGBoundingBox, p::EGPoint) = EGBoundingBox(bb.min - p, bb.max - p)
translate(bb::EGBoundingBox, v::EGVector) = EGBoundingBox(bb.min + v, bb.max + v)
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

# Shared by every `distance(p, region; mode)` method (EGBoundingBox here;
# EGPolygon in eg_polygon.jl; EGHalfPlane2/EGStrip2/EGAngle2 in
# eg_unbounded.jl): `mode = :region` (default) is the standard "distance to
# a closed set" convention (0 exactly when p belongs to it); `mode =
# :boundary` always measures to the boundary itself, even from inside.
function _check_distance_mode(mode::Symbol)
    mode in (:region, :boundary) ||
        throw(ArgumentError("distance: mode must be :region or :boundary, got $(repr(mode))"))
end

"""
    distance(p::EGPoint, bb::EGBoundingBox; mode::Symbol=:region)

`mode=:region` (default): `0` when `p` is inside or on `bb`, otherwise the
usual point-to-axis-aligned-box distance. `mode=:boundary`: always the
distance to the nearest edge, even from inside.
"""
function distance(p::EGPoint{2}, bb::EGBoundingBox{2}; mode::Symbol=:region)
    _check_distance_mode(mode)
    if p in bb
        mode == :region && return 0.0
        return min(p[1] - bb.min[1], bb.max[1] - p[1], p[2] - bb.min[2], bb.max[2] - p[2])
    end
    dx = max(bb.min[1] - p[1], 0.0, p[1] - bb.max[1])
    dy = max(bb.min[2] - p[2], 0.0, p[2] - bb.max[2])
    return sqrt(dx^2 + dy^2)
end
distance(bb::EGBoundingBox{2}, p::EGPoint{2}; mode::Symbol=:region) = distance(p, bb; mode=mode)

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

"""
    bbox_union(a::EGBoundingBox, b::EGBoundingBox)

The smallest box containing both `a` and `b`. Unlike
[`bbox_intersection`](@ref), this always exists — `a`/`b` don't need to
overlap.
"""
function bbox_union(a::EGBoundingBox{2}, b::EGBoundingBox{2})
    lo = EGPoint(min(a.min[1], b.min[1]), min(a.min[2], b.min[2]))
    hi = EGPoint(max(a.max[1], b.max[1]), max(a.max[2], b.max[2]))
    return EGBoundingBox(lo, hi)
end

"""
    @boundingbox begin
        c = EGCircle2(...)
        s = EGSegment(...)
        t                     # a shape already defined earlier
    end
    @boundingbox c             # a single shape/expression also works

The [`bbox_union`](@ref) of every shape named in the block — via
[`EGBoundingBox`](@ref) applied to each, then `reduce`d with `bbox_union`
— as a single expression. Each top-level line in the block is either:

  - an assignment `name = expr`: `expr` is evaluated and bound to `name`
    exactly as if the `@boundingbox` weren't there (so `name` stays usable
    on later lines, or after the macro, exactly like ordinary code), *and*
    its value is folded into the union; or
  - a bare expression (most often just the name of a shape defined
    earlier, outside the block or on an earlier line inside it): its
    value is folded into the union, nothing is assigned.

Lines run in order, top to bottom, exactly as written — this is not a new
scope (no `let`): a bare name refers to whatever `name` already means at
that point, and an assignment defines `name` in the enclosing scope, so
mixing "build a new shape here" and "also include this shape from
earlier" freely on different lines works as expected.

A single expression instead of a `begin ... end` block (`@boundingbox c`,
or even `@boundingbox c = EGCircle2(...)`) works the same way, treated as
a one-line block — `EGBoundingBox(c)` directly is simpler for that case,
but this stays consistent rather than requiring `begin`/`end` only
sometimes.
"""
macro boundingbox(block)
    block isa Expr && block.head === :block || (block = Expr(:block, block))

    shapes = gensym(:boundingbox_shapes)
    body = Expr(:block, :($shapes = Any[]))
    for stmt in block.args
        if stmt isa LineNumberNode
            push!(body.args, stmt)
        elseif stmt isa Expr && stmt.head === :(=) && stmt.args[1] isa Symbol
            push!(body.args, stmt, :(push!($shapes, $(stmt.args[1]))))
        else
            push!(body.args, :(push!($shapes, $stmt)))
        end
    end
    push!(body.args, quote
        isempty($shapes) && throw(ArgumentError("@boundingbox: the block has no shapes"))
        reduce(bbox_union, EGBoundingBox.($shapes))
    end)
    return esc(body)
end

# --- @to_luxor_picture / @to_luxor_picture! ---------------------------------
#
# Turns a set of shapes into a ready-to-draw "picture": translate/scale them
# so their combined EGBoundingBox lands inside a known, exact canvas size,
# always preserving aspect ratio (scaling is always uniform in x and y).
# Despite the name, this is plain geometry with no Luxor dependency at all
# -- it only computes where things should go; `path(...)` (the Luxor
# extension) is what actually draws them. Kept alongside
# @boundingbox/@translate!/etc. for the same reason those live here rather
# than in the extension.

# The uniform scale factor `s` and final canvas size `(W, H)` for a content
# bounding box of size `(bw, bh)`:
#   - `scale` given: canvas hugs the scaled content exactly (plus margin on
#     every side) -- W/H are *derived*, not requested.
#   - only `width` (or only `height`) given: scaled so that side comes out
#     exactly `width` (resp. `height`) minus the margin; the other side
#     follows to preserve the aspect ratio, so there's never leftover space
#     to center away.
#   - both `width` and `height` given: a "contain" fit -- scaled by
#     whichever of the two is more restrictive, so the content fits inside
#     *both* (never distorted, never cropped); W/H are exactly the
#     requested values, and any leftover space on the less-restrictive axis
#     is later split evenly on both sides (see `_place_in_picture`).
#   - neither given: scale factor `1.0`.
function _picture_layout(bw::Real, bh::Real, width, height, scale, margin::Real)
    if scale !== nothing
        s = Float64(scale)
        W = bw * s + 2margin
        H = bh * s + 2margin
    elseif width !== nothing && height !== nothing
        W, H = Float64(width), Float64(height)
        s = min((W - 2margin) / bw, (H - 2margin) / bh)
    elseif width !== nothing
        W = Float64(width)
        s = (W - 2margin) / bw
        H = bh * s + 2margin
    elseif height !== nothing
        H = Float64(height)
        s = (H - 2margin) / bh
        W = bw * s + 2margin
    else
        s = 1.0
        W = bw + 2margin
        H = bh + 2margin
    end
    return s, W, H
end

# Shift `shape` so `bb.min` lands on the origin, scale uniformly by `s`
# about the origin (so e.g. a circle always stays a circle), then shift
# again to center the scaled content within the final `(W, H)` canvas --
# equivalent to insetting by `margin` on every side when the content
# already fills `(W, H)` exactly, and splitting any extra leftover space
# evenly otherwise (the "contain fit" case, see `_picture_layout`).
function _place_in_picture(shape, bb::EGBoundingBox, s::Real, W::Real, H::Real)
    shifted = translate(shape, EGVector(-bb.min[1], -bb.min[2]))
    scaled = homothety(shifted, s, EGPoint(0.0, 0.0))
    offset = EGVector((W - bbox_width(bb) * s) / 2, (H - bbox_height(bb) * s) / 2)
    return translate(scaled, offset)
end

const _PICTURE_KWNAMES = (:width, :height, :scale, :margin)

# Reads the trailing `key = value` arguments a macro call was given before
# its final (block) argument -- e.g. `@to_luxor_picture width=400 begin ... end`
# -- and returns the 4 option expressions in a fixed order, still
# unevaluated (they're spliced into the generated code and evaluated in the
# caller's scope, same as the block itself).
function _parse_picture_kwargs(macroname, exprs)
    given = Dict{Symbol,Any}()
    for e in exprs
        (e isa Expr && e.head === :(=) && e.args[1] isa Symbol && e.args[1] in _PICTURE_KWNAMES) ||
            error("$macroname: unrecognized argument `$e` -- expected one of $_PICTURE_KWNAMES, or the shapes block as the last argument")
        given[e.args[1]] = e.args[2]
    end
    if haskey(given, :scale) && (haskey(given, :width) || haskey(given, :height))
        error("$macroname: `scale` cannot be combined with `width`/`height`")
    end
    getval(k, default) = get(given, k, default)
    return (getval(:width, nothing), getval(:height, nothing), getval(:scale, nothing), getval(:margin, 0.0))
end

function _picture_body(mutating::Bool, block, width, height, scale, margin)
    block isa Expr && block.head === :block || (block = Expr(:block, block))

    shapes = gensym(:picture_shapes)
    slots = Union{Symbol,Nothing}[]   # nothing = anonymous result slot; Symbol = rebind target (mutating only)
    body = Expr(:block, :($shapes = Any[]))
    for stmt in block.args
        if stmt isa LineNumberNode
            push!(body.args, stmt)
        elseif stmt isa Symbol
            push!(body.args, :(push!($shapes, $stmt)))
            push!(slots, mutating ? stmt : nothing)
        elseif stmt isa Expr && stmt.head === :(=) && stmt.args[1] isa Symbol
            push!(body.args, stmt, :(push!($shapes, $(stmt.args[1]))))
            push!(slots, mutating ? stmt.args[1] : nothing)
        elseif mutating
            push!(body.args, :(throw(ArgumentError("@to_luxor_picture!: cannot mutate an unnamed expression — assign it to a variable first"))))
        else
            push!(body.args, :(push!($shapes, $stmt)))
            push!(slots, nothing)
        end
    end

    picture_layout = GlobalRef(@__MODULE__, :_picture_layout)
    place_in_picture = GlobalRef(@__MODULE__, :_place_in_picture)

    bb = gensym(:bb)
    s = gensym(:s)
    W = gensym(:W)
    H = gensym(:H)
    push!(body.args, quote
        isempty($shapes) && throw(ArgumentError("@to_luxor_picture: the block has no shapes"))
        $bb = reduce(bbox_union, EGBoundingBox.($shapes))
        $s, $W, $H = $picture_layout(bbox_width($bb), bbox_height($bb), $width, $height, $scale, $margin)
    end)

    results = gensym(:picture_results)
    push!(body.args, :($results = Any[]))
    for (i, slot) in enumerate(slots)
        transformed = :($place_in_picture($shapes[$i], $bb, $s, $W, $H))
        if slot === nothing
            push!(body.args, :(push!($results, $transformed)))
        else
            push!(body.args, :($slot = $transformed), :(push!($results, $slot)))
        end
    end

    size_expr = :(($W, $H))
    if mutating
        push!(body.args, size_expr)
    else
        shapes_expr = length(slots) == 1 ? :($results[1]) : :(($results...,))
        push!(body.args, :(($size_expr, $shapes_expr)))
    end
    return esc(body)
end

"""
    @to_luxor_picture begin
        c = EGCircle2(...)
        s = EGSegment(...)
        t                     # a shape already defined earlier
    end
    @to_luxor_picture c        # a single shape/expression also works
    @to_luxor_picture width=400 begin ... end
    @to_luxor_picture height=300 begin ... end
    @to_luxor_picture width=400 height=300 begin ... end
    @to_luxor_picture scale=2.0 begin ... end
    @to_luxor_picture width=400 margin=10 begin ... end

Prepares every shape named in the block for drawing at a known, exact
canvas size: translate/scale them so their combined [`EGBoundingBox`](@ref)
fits centered inside that canvas, always preserving aspect ratio (the
scale factor is always the same in `x` and `y` — a circle always stays a
circle). Returns `((width, height), shapes)` — `width`/`height` is the
exact canvas size to pass to `Drawing`, and `shapes` are the
translated/scaled copies (`c`/`s`/`t` themselves are untouched — see
[`@to_luxor_picture!`](@ref) for the mutating form), in the same order as
the block, as a tuple (or bare, for a single shape). Since no `origin()`
call is needed afterward — the content is already positioned for the
returned canvas — draw directly in the default top-left-anchored device
space:

```julia
(w, h), (c2, s2) = @to_luxor_picture width=400 begin
    c = EGCircle2(EGPoint(3.0, -1.0), 5.0)
    s = EGSegment(EGPoint(-2.0, 4.0), EGPoint(6.0, -3.0))
end
Drawing(w, h, "out.png")
path(c2; action=:stroke)
path(s2; action=:stroke)
finish()
```

Scaling options (mutually exclusive: `scale` cannot be combined with
`width`/`height`):

  - neither given: scale factor `1.0` (the shapes' own coordinate units
    become output units directly, no resizing) — the returned canvas size
    is exactly the content size (plus `margin`);
  - `scale`: a literal, uniform multiplier — the returned canvas size is
    *derived* from the scaled content (plus `margin`), same as above;
  - `width` alone (or `height` alone): scaled so that side comes out
    exactly `width` (resp. `height`) minus `margin`, the other side
    following to preserve the aspect ratio — there's never leftover space
    to center away in this case;
  - `width` *and* `height` together: a "contain" fit — scaled by whichever
    of the two is more restrictive, so the content fits inside *both*
    without distortion. The returned canvas is exactly `(width, height)`
    regardless; if the content's aspect ratio doesn't match, it's centered,
    leaving extra blank space on one axis beyond `margin`.

`margin` (default `0.0`) is the minimum blank space guaranteed around the
content on every side, in output units.

Each line in the block is read exactly like [`@boundingbox`](@ref)'s (an
assignment binds `name` in the enclosing scope as usual, or a bare
expression contributes without binding anything); a bare, unnamed
expression works here too since nothing needs to be rebound.
"""
macro to_luxor_picture(args...)
    isempty(args) && error("@to_luxor_picture: missing the shapes block")
    width, height, scale, margin = _parse_picture_kwargs("@to_luxor_picture", args[1:end-1])
    return _picture_body(false, args[end], width, height, scale, margin)
end

"""
    @to_luxor_picture! begin ... end
    @to_luxor_picture! width=400 begin ... end

The mutating counterpart of [`@to_luxor_picture`](@ref): rebinds each
*named* shape (an assignment, or a bare reference to a shape defined
earlier) to its own translated/scaled image, instead of returning copies.
Returns just `(width, height)` — the shapes are already accessible under
their own names. A bare, unnamed expression has nothing to rebind, so this
form rejects it (same as [`@translate!`](@ref) and the rest of that
family).
"""
macro to_luxor_picture!(args...)
    isempty(args) && error("@to_luxor_picture!: missing the shapes block")
    width, height, scale, margin = _parse_picture_kwargs("@to_luxor_picture!", args[1:end-1])
    return _picture_body(true, args[end], width, height, scale, margin)
end

# Shared codegen for the @translate/@rotate/@homothety/@reflection family
# (and their `!` counterparts) below: walk a `begin...end` block (or a
# single expression, treated as a one-line block) the same way
# `@boundingbox` does, but instead of folding everything into one value,
# apply `make_call` (a closure building `transform_fn(x, args...)` for a
# given value-expression `x`) to each named item and collect the results
# into a returned tuple.
#
# `mutating`: for an assignment `name = expr` or a bare `name`, whether to
# also rebind `name` to its own transformed value — the closest Julia gets
# to "mutating" an immutable shape in place (the object itself never
# changes; the *variable* is repointed at a new one, same trick
# `Setfield.jl`'s `@set!` uses). An unnamed bare expression (no variable to
# rebind) is fine for the non-mutating form but an error for the mutating
# one — there's nothing for `!` to rebind.
function _shape_transform_body(mutating::Bool, make_call, block)
    block isa Expr && block.head === :block || (block = Expr(:block, block))

    results = gensym(:transformed)
    body = Expr(:block, :($results = Any[]))
    n_items = 0
    for stmt in block.args
        if stmt isa LineNumberNode
            push!(body.args, stmt)
        elseif stmt isa Symbol || (stmt isa Expr && stmt.head === :(=) && stmt.args[1] isa Symbol)
            name = stmt isa Symbol ? stmt : stmt.args[1]
            stmt isa Symbol || push!(body.args, stmt) # run the assignment itself first
            if mutating
                push!(body.args, :($name = $(make_call(name))), :(push!($results, $name)))
            else
                push!(body.args, :(push!($results, $(make_call(name)))))
            end
            n_items += 1
        elseif mutating
            push!(body.args, :(throw(ArgumentError("cannot mutate an unnamed expression — assign it to a variable first"))))
            n_items += 1
        else
            push!(body.args, :(push!($results, $(make_call(stmt)))))
            n_items += 1
        end
    end
    # a single item returns its bare value, not a 1-tuple — same ergonomics
    # as `@boundingbox`'s "a single shape/expression also works"
    push!(body.args, n_items == 1 ? :($results[1]) : :(($results...,)))
    return esc(body)
end

"""
    @translate v begin
        c = EGCircle2(...)
        s = EGSegment(...)
        t                     # a shape already defined earlier
    end
    @translate v c             # a single shape/expression also works

[`translate`](@ref) every shape named in the block by `v`, returning them
as a tuple in order (`C, S, T = @translate v begin ... end`) — `c`/`s`/`t`
themselves are untouched, exactly like calling `translate` by hand and
keeping the result under a new name. Each top-level line is either an
assignment `name = expr` (runs as ordinary code, and its value is
translated into the result tuple) or a bare expression (most often the
name of a shape defined earlier); see [`@boundingbox`](@ref) for the full
rundown of that part, which works identically here.

    @translate! v begin ... end

The mutating form: instead of leaving `c`/`s`/`t` alone and returning
copies, it rebinds each *named* one (an assignment or a bare existing
variable) to its own translated value. `EGCircle2`/`EGSegment`/... are all
immutable structs, so nothing is changed in place — the object itself
never mutates, only the *variable* is repointed at a new one (the same
trick `Setfield.jl`'s `@set!` uses for immutable structs generally). A
bare *unnamed* expression (nothing to rebind) is an `ArgumentError` in
this form.

When embedding a call to `@translate`/`@rotate`/`@homothety`/`@reflection`
directly inside another expression — as an argument to a function, say
— wrap it in its own parentheses: `f((@rotate angle p), other_arg)`, not
`f(@rotate angle p, other_arg)`. Without them, Julia's bare `@macro arg1
arg2 ...` call syntax swallows the surrounding comma-separated arguments
into an unwanted tuple; this is a general Julia parsing rule for any
multi-argument macro call, not specific to these. A bare statement
(`x = @rotate angle p`) never has this problem.
"""
macro translate(v, block)
    _shape_transform_body(false, x -> :(translate($x, $v)), block)
end

"""
    @translate! v begin ... end
    @translate! v c

The mutating counterpart of [`@translate`](@ref) — see its docstring for
the full rundown (what "mutating" means for immutable shapes, and the
`ArgumentError` on a bare unnamed expression).
"""
macro translate!(v, block)
    _shape_transform_body(true, x -> :(translate($x, $v)), block)
end

"""
    @rotate angle begin ... end
    @rotate angle center begin ... end
    @rotate angle c             # a single shape/expression also works

[`rotate`](@ref) every shape named in the block by `angle` (about `center`,
defaulting to the origin exactly like `rotate` itself), returning them as
a tuple — see [`@translate`](@ref) for the full rundown of how the block
is read (assignments vs. bare references) and what it returns.

    @rotate! angle begin ... end
    @rotate! angle center begin ... end

The mutating form — see [`@translate!`](@ref).
"""
macro rotate(angle, block)
    _shape_transform_body(false, x -> :(rotate($x, $angle)), block)
end
macro rotate(angle, center, block)
    _shape_transform_body(false, x -> :(rotate($x, $angle, $center)), block)
end

"""
    @rotate! angle begin ... end
    @rotate! angle center begin ... end
    @rotate! angle c

The mutating counterpart of [`@rotate`](@ref) — see [`@translate!`](@ref)
for what "mutating" means for immutable shapes.
"""
macro rotate!(angle, block)
    _shape_transform_body(true, x -> :(rotate($x, $angle)), block)
end
macro rotate!(angle, center, block)
    _shape_transform_body(true, x -> :(rotate($x, $angle, $center)), block)
end

"""
    @homothety k begin ... end
    @homothety k center begin ... end
    @homothety k c              # a single shape/expression also works

[`homothety`](@ref) every shape named in the block by ratio `k` (about
`center`, defaulting to the origin exactly like `homothety` itself),
returning them as a tuple — see [`@translate`](@ref) for the full rundown
of how the block is read and what it returns.

    @homothety! k begin ... end
    @homothety! k center begin ... end

The mutating form — see [`@translate!`](@ref).
"""
macro homothety(k, block)
    _shape_transform_body(false, x -> :(homothety($x, $k)), block)
end
macro homothety(k, center, block)
    _shape_transform_body(false, x -> :(homothety($x, $k, $center)), block)
end

"""
    @homothety! k begin ... end
    @homothety! k center begin ... end
    @homothety! k c

The mutating counterpart of [`@homothety`](@ref) — see
[`@translate!`](@ref) for what "mutating" means for immutable shapes.
"""
macro homothety!(k, block)
    _shape_transform_body(true, x -> :(homothety($x, $k)), block)
end
macro homothety!(k, center, block)
    _shape_transform_body(true, x -> :(homothety($x, $k, $center)), block)
end

"""
    @reflection about begin ... end
    @reflection about c         # a single shape/expression also works

[`reflection`](@ref) every shape named in the block `about` a point or a
line, returning them as a tuple — see [`@translate`](@ref) for the full
rundown of how the block is read and what it returns.

    @reflection! about begin ... end

The mutating form — see [`@translate!`](@ref).
"""
macro reflection(about, block)
    _shape_transform_body(false, x -> :(reflection($x, $about)), block)
end

"""
    @reflection! about begin ... end
    @reflection! about c

The mutating counterpart of [`@reflection`](@ref) — see
[`@translate!`](@ref) for what "mutating" means for immutable shapes.
"""
macro reflection!(about, block)
    _shape_transform_body(true, x -> :(reflection($x, $about)), block)
end

"""
    @invert center begin ... end
    @invert center k begin ... end
    @invert center c              # a single shape/expression also works

[`invert`](@ref) every shape named in the block with respect to the
circle centered at `center` (radius `k`, defaulting to `1.0` exactly like
`invert` itself) — see [`@translate`](@ref) for the full rundown of how
the block is read and what it returns. `invert` can change a shape's own
type (an `EGLine` inverts to an `EGCircle2` and vice versa) — no
different here.
"""
macro invert(center, block)
    _shape_transform_body(false, x -> :(invert($x, $center)), block)
end
macro invert(center, k, block)
    _shape_transform_body(false, x -> :(invert($x, $center; k=$k)), block)
end

"""
    @invert! center begin ... end
    @invert! center k begin ... end

The mutating counterpart of [`@invert`](@ref) — see [`@translate!`](@ref)
for what "mutating" means for immutable shapes.
"""
macro invert!(center, block)
    _shape_transform_body(true, x -> :(invert($x, $center)), block)
end
macro invert!(center, k, block)
    _shape_transform_body(true, x -> :(invert($x, $center; k=$k)), block)
end

"""
    @invert_neg center begin ... end
    @invert_neg center k begin ... end
    @invert_neg center c

[`invert_neg`](@ref) every shape named in the block — the negative-ratio
counterpart of [`@invert`](@ref); see [`@translate`](@ref) for the full
rundown of how the block is read and what it returns.
"""
macro invert_neg(center, block)
    _shape_transform_body(false, x -> :(invert_neg($x, $center)), block)
end
macro invert_neg(center, k, block)
    _shape_transform_body(false, x -> :(invert_neg($x, $center; k=$k)), block)
end

"""
    @invert_neg! center begin ... end
    @invert_neg! center k begin ... end

The mutating counterpart of [`@invert_neg`](@ref) — see
[`@translate!`](@ref) for what "mutating" means for immutable shapes.
"""
macro invert_neg!(center, block)
    _shape_transform_body(true, x -> :(invert_neg($x, $center)), block)
end
macro invert_neg!(center, k, block)
    _shape_transform_body(true, x -> :(invert_neg($x, $center; k=$k)), block)
end

"""
    @affinemap m begin ... end
    @affinemap m c                # a single shape/expression also works

Apply the [`EGAffineMap`](@ref) `m` to every shape named in the block —
see [`@translate`](@ref) for the full rundown of how the block is read
and what it returns.
"""
macro affinemap(m, block)
    _shape_transform_body(false, x -> :($m($x)), block)
end

"""
    @affinemap! m begin ... end

The mutating counterpart of [`@affinemap`](@ref) — see
[`@translate!`](@ref) for what "mutating" means for immutable shapes.
"""
macro affinemap!(m, block)
    _shape_transform_body(true, x -> :($m($x)), block)
end
