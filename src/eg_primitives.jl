# -------------------------------------------------------------------------
# EGSegment/EGLine/EGRay (<: EGCurve) and EGBoundingBox, built on
# EGPoint/EGVector.
# -------------------------------------------------------------------------

# --- Point-level transforms (needed before Segment/Line/Ray can define
# their own pointwise versions) ---------------------------------------

"""
    rotate(p::EGPoint{2}, angle, center=EGPoint(0.0, 0.0))

Rotate `p` by `angle` radians (counterclockwise) around `center`.
"""
function rotate(p::EGPoint{2}, angle::Real, center::EGPoint{2}=EGPoint(0.0, 0.0))
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

The infinite straight line passing through `p1` and `p2`. `l[1]`/`l[2]`
access the two defining points.
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
`r[1]`/`r[2]` access `origin`/`through`.
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
Base.eltype(::Type{<:EGSegment{Dim,T}}) where {Dim,T} = EGPoint{Dim,T}

# Same `[i]`/iteration/destructuring protocol as EGSegment above (`p1, p2 =
# l`, `l[1]`, `for p in l`, `collect(Iterators.flatten(lines))` to flatten
# a collection of lines into their defining points, ...). Safe to add
# despite EGLine/EGRay being used throughout as single "shape" values --
# `Broadcast.broadcastable(x::EGObject) = Ref(x)` (eg_point.jl) already
# keeps them from being mistaken for a collection under broadcasting.
# `eltype` (not just `iterate`/`length`) is what lets `collect`/
# `Iterators.flatten` infer `Vector{EGPoint{Dim,T}}` instead of falling
# back to `Vector{Any}`.
Base.getindex(l::EGLine, i::Integer) = i == 1 ? l.p1 : l.p2
Base.length(::EGLine) = 2
Base.iterate(l::EGLine, i::Int=1) = i > 2 ? nothing : (l[i], i + 1)
Base.eltype(::Type{<:EGLine{Dim,T}}) where {Dim,T} = EGPoint{Dim,T}

Base.getindex(r::EGRay, i::Integer) = i == 1 ? r.origin : r.through
Base.length(::EGRay) = 2
Base.iterate(r::EGRay, i::Int=1) = i > 2 ? nothing : (r[i], i + 1)
Base.eltype(::Type{<:EGRay{Dim,T}}) where {Dim,T} = EGPoint{Dim,T}

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
    homothety(v::EGVector, k::Real, center::EGPoint=EGPoint(0.0, 0.0))

`k * v` — for a free vector, `center` has nothing to act on (there's no
position), so it's accepted purely for signature symmetry with every
other `homothety` method (points, curves, [`EGEquipollentVector`](@ref)).
Having this defined for a bare `EGVector` is what lets
[`@to_luxor_picture`](@ref) scale one to the picture's own scale factor
even though it has no [`EGBoundingBox`](@ref) to shift into position —
see `_place_in_picture`'s own comment for the reasoning.
"""
homothety(v::EGVector{Dim,T}, k::Real, center::EGPoint{Dim}=EGPoint(ntuple(_ -> zero(T), Dim))) where {Dim,T} = k * v

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

"""
    rotate(v::EGVector{3}, angle::Real, axis::EGLine{3})

Rotate the direction `v` by `angle` radians about `axis`'s own
*direction* (only `direction(axis)` matters -- a free vector has no
position, so where `axis` sits in space is irrelevant). Same Rodrigues
formula as `rotate(::EGPoint{3}, ::Real, ::EGLine{3})`, minus the
anchor-point offset.
"""
function rotate(v::EGVector{3}, angle::Real, axis::EGLine{3})
    k = direction(axis) / norm(direction(axis))
    v_par = dot(v, k) * k
    v_perp = v - v_par
    c, s = cos(angle), sin(angle)
    return v_par + c * v_perp + s * cross3(k, v_perp)
end

# `slope_angle` is already defined, untyped, in primitives.jl
# (`atan(direction(obj)[2], direction(obj)[1])`) — works here for free
# since it just calls `direction`, already overloaded above.

distance(s::EGSegment) = distance(s.p1, s.p2)
midpoint(s::EGSegment) = midpoint(s.p1, s.p2)

"""
    projection(p::EGPoint, l::EGLine; angle::Real=pi/2)

Where a line through `p`, at `angle` radians from `l`'s own direction
(counterclockwise; the default `pi/2` is the ordinary perpendicular/
orthogonal projection), meets `l` — the oblique projection of `p` onto
`l` for any other `angle`. `angle` must be strictly between `0` and `π`:
at either end, the projecting line becomes parallel to `l` itself, so
there's no longer a single intersection point.
"""
function projection(p::EGPoint, l::EGLine; angle::Real=pi / 2)
    d = direction(l)
    angle == pi / 2 && return l.p1 + (dot(p - l.p1, d) / dot(d, d)) * d
    0 < angle < pi || throw(ArgumentError("projection: angle must be strictly between 0 and π (got $angle)"))
    u = rotate(d, angle)
    t = cross2(u, p - l.p1) / cross2(u, d)
    return l.p1 + t * d
end

"""
    projection(l::EGLine; angle::Real=pi/2)

`p -> projection(p, l; angle=angle)` — for composing with `|>`/`map`/
`filter`, e.g. `map(projection(l), points)` to project a whole collection
onto `l` at once.
"""
projection(l::EGLine; angle::Real=pi / 2) = p -> projection(p, l; angle=angle)

distance(p::EGPoint{2}, l::EGLine{2}) = abs(cross2(direction(l), p - l.p1)) / norm(direction(l))
distance(l::EGLine{2}, p::EGPoint{2}) = distance(p, l)

"""
    distance(p::EGPoint{3}, l::EGLine{3})

Perpendicular distance from `p` to the infinite line `l`, via the 3D
cross product (`cross2`'s 2D formula above doesn't generalize -- it only
reads 2 of `p`'s 3 coordinates, which is silently wrong rather than
merely inapplicable, so this is its own dispatched method rather than a
fallback).
"""
distance(p::EGPoint{3}, l::EGLine{3}) = norm(cross3(direction(l), p - l.p1)) / norm(direction(l))
distance(l::EGLine{3}, p::EGPoint{3}) = distance(p, l)

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
    reflection(p::EGPoint{2}, l::EGLine{2})

Reflect `p` across the line `l` (axial symmetry). **2D only, deliberately**:
in 3D, "reflecting through the foot of the perpendicular onto a line" is
actually a 180° rotation *about* that line (orientation-*preserving* --
`rotate(p, pi, axis)` once 3D `rotate` is loaded), not a mirror
reflection (orientation-*reversing*) -- a line's orthogonal complement in
3D is a whole plane, not a single direction, so there is no unique mirror
to reflect across. The true 3D mirror is
[`reflection(::EGPoint{3}, ::EGPlane3)`](@ref).
"""
reflection(p::EGPoint{2}, l::EGLine{2}) = 2 * projection(p, l) - p

reflection(s::EGSegment, about) = EGSegment(reflection(s.p1, about), reflection(s.p2, about))
reflection(l::EGLine, about) = EGLine(reflection(l.p1, about), reflection(l.p2, about))
reflection(r::EGRay, about) = EGRay(reflection(r.origin, about), reflection(r.through, about))

rotate(s::EGSegment{2}, angle::Real, center::EGPoint{2}=EGPoint(0.0, 0.0)) =
    EGSegment(rotate(s.p1, angle, center), rotate(s.p2, angle, center))
rotate(l::EGLine{2}, angle::Real, center::EGPoint{2}=EGPoint(0.0, 0.0)) =
    EGLine(rotate(l.p1, angle, center), rotate(l.p2, angle, center))
rotate(r::EGRay{2}, angle::Real, center::EGPoint{2}=EGPoint(0.0, 0.0)) =
    EGRay(rotate(r.origin, angle, center), rotate(r.through, angle, center))

"""
    rotate(p::EGPoint{3}, angle::Real, axis::EGLine{3})

Rotate `p` by `angle` radians (right-hand rule around `direction(axis)`)
about `axis` — the 3D analogue of `rotate(p::EGPoint{2}, angle, center)`,
via the closed-form Rodrigues rotation formula (no quaternions/matrix
exponential needed): decompose `p - axis.p1` into its component along the
axis (unchanged) and perpendicular to it (rotated within the plane
spanned by itself and `k × v_perp`).
"""
function rotate(p::EGPoint{3}, angle::Real, axis::EGLine{3})
    k = direction(axis) / norm(direction(axis))
    v = p - axis.p1
    v_par = dot(v, k) * k
    v_perp = v - v_par
    c, s = cos(angle), sin(angle)
    return axis.p1 + v_par + c * v_perp + s * cross3(k, v_perp)
end

"""
    rotate(s::EGSegment{3}, angle::Real, axis::EGLine{3})
    rotate(l::EGLine{3}, angle::Real, axis::EGLine{3})
    rotate(r::EGRay{3}, angle::Real, axis::EGLine{3})

The 3D analogue of the `center`-based `rotate` above, about an `axis`
instead of a `center` (see [`rotate(::EGPoint{3}, ::Real, ::EGLine{3})`](@ref)).
"""
rotate(s::EGSegment{3}, angle::Real, axis::EGLine{3}) =
    EGSegment(rotate(s.p1, angle, axis), rotate(s.p2, angle, axis))
rotate(l::EGLine{3}, angle::Real, axis::EGLine{3}) =
    EGLine(rotate(l.p1, angle, axis), rotate(l.p2, angle, axis))
rotate(r::EGRay{3}, angle::Real, axis::EGLine{3}) =
    EGRay(rotate(r.origin, angle, axis), rotate(r.through, angle, axis))

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

"""
    EGBoundingBox(p::EGPoint)

The degenerate box `EGBoundingBox(p, p)` — zero-size, but still a real
position, so `p` grows a [`bbox_union`](@ref) exactly like any other
shape would.
"""
EGBoundingBox(p::EGPoint) = EGBoundingBox(p, p)

"""
    EGBoundingBox()

The *empty* bounding box: the neutral element for [`bbox_union`](@ref) —
`bbox_union(EGBoundingBox(), bb) == bb` for any `bb`. This is what
`EGBoundingBox` returns for values that have no position of their own to
contribute to a picture's extent: a plain number, an [`EGVector`](@ref)
(a direction, not a location — unlike [`EGPoint`](@ref), which *does* get
its own degenerate box above), or an unbounded curve/region
([`EGLine`](@ref), [`EGRay`](@ref), `EGAngle2`, `EGHalfPlane2`,
`EGStrip2`, which have no finite extent to report). It exists so generic
code — [`@boundingbox`](@ref), [`@to_luxor_picture`](@ref) — can call
`EGBoundingBox` on every value named in a block without special-casing the
ones that aren't meant to be drawn or sized.
"""
EGBoundingBox() = EGBoundingBox(EGPoint(Inf, Inf), EGPoint(-Inf, -Inf))

EGBoundingBox(::EGVector) = EGBoundingBox()
EGBoundingBox(::Real) = EGBoundingBox()
EGBoundingBox(::EGLine) = EGBoundingBox()
EGBoundingBox(::EGRay) = EGBoundingBox()

"""
    EGBoundingBox(v::AbstractVector{<:EGObject})

The [`bbox_union`](@ref) of every element's own box — the empty box (see
[`EGBoundingBox()`](@ref) above) for an empty `v`, so this composes
exactly like a single value would, rather than erroring on "no points"
the way [`EGBoundingBox(::AbstractVector{<:EGPoint})`](@ref) does. This is
what lets a plain `Vector` of shapes — what [`intersection`](@ref)/
[`tangent_points`](@ref) return, since they can give 0, 1 or 2 points
depending on the geometry — work as a single named item inside a
[`@boundingbox`](@ref)/[`@to_luxor_picture`](@ref) block, without
unwrapping it by hand first.
"""
EGBoundingBox(v::AbstractVector{<:EGObject}) = reduce(bbox_union, EGBoundingBox.(v); init=EGBoundingBox())

"""
    isempty(bb::EGBoundingBox)

Whether `bb` is the empty box (see [`EGBoundingBox()`](@ref)).
"""
Base.isempty(bb::EGBoundingBox) = bb.min[1] > bb.max[1]

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
overlap. The empty box (see [`EGBoundingBox()`](@ref)) is the identity
element: `bbox_union` with it returns the other box unchanged.
"""
function bbox_union(a::EGBoundingBox{2}, b::EGBoundingBox{2})
    isempty(a) && return b
    isempty(b) && return a
    lo = EGPoint(min(a.min[1], b.min[1]), min(a.min[2], b.min[2]))
    hi = EGPoint(max(a.max[1], b.max[1]), max(a.max[2], b.max[2]))
    return EGBoundingBox(lo, hi)
end

# Classifies one top-level statement from a "shapes block" the way every
# macro in this family reads one -- shared by @boundingbox,
# _shape_transform_body (@translate/@rotate/@homothety/@reflection/
# @invert/@invert_neg/@affinemap) and _picture_body (@to_luxor_picture).
# A bare name, `name = expr`, or a destructuring `name1, name2, ... =
# expr` (a plain tuple of symbols on the left, e.g. what
# `external_tangent_lines`/`tangent_points`/`intersection` naturally
# return) all introduce one or more names to fold into the result/rebind;
# anything else -- a bare expression, or an assignment whose left side
# isn't a plain symbol or tuple-of-symbols (a splat, a nested pattern) --
# is an unnamed expression, same as before this handled destructuring.
# Returns `(names, run_first)`: `names` is the list of symbols introduced
# (empty for an unnamed expression); `run_first` is whether the statement
# itself needs to run before those names exist (true for any assignment,
# false for a bare existing name).
function _block_stmt_names(stmt)
    stmt isa Symbol && return ([stmt], false)
    if stmt isa Expr && stmt.head === :(=)
        lhs = stmt.args[1]
        lhs isa Symbol && return ([lhs], true)
        if lhs isa Expr && lhs.head === :tuple && all(a -> a isa Symbol, lhs.args)
            return (Vector{Symbol}(lhs.args), true)
        end
    end
    return (Symbol[], false)
end

# Used only by _picture_body: recognizes a statement wrapped in @unbounded
# -- either the whole statement (`@unbounded aux = EGCircle2(...)`) or just
# its right-hand side (`aux = @unbounded EGCircle2(...)`) -- and strips the
# wrapper off, returning the plain statement underneath plus whether it was
# marked. `_block_stmt_names` never needs to know @unbounded exists: by the
# time it sees the statement, the wrapper is already gone.
function _strip_unbounded(stmt)
    if stmt isa Expr && stmt.head === :macrocall && stmt.args[1] === Symbol("@unbounded")
        return (stmt.args[end], true)
    end
    if stmt isa Expr && stmt.head === :(=) && stmt.args[2] isa Expr &&
       stmt.args[2].head === :macrocall && stmt.args[2].args[1] === Symbol("@unbounded")
        return (Expr(:(=), stmt.args[1], stmt.args[2].args[end]), true)
    end
    return (stmt, false)
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
    its value is folded into the union;
  - a destructuring assignment `name1, name2, ... = expr` (e.g.
    `l1, l2 = external_tangent_lines(c1, c2)`): runs the same way, and
    *each* of `name1`/`name2`/... is folded into the union individually,
    exactly as if each had its own `name = ...` line; or
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
            continue
        end
        names, run_first = _block_stmt_names(stmt)
        if isempty(names)
            push!(body.args, :(push!($shapes, $stmt)))
        else
            run_first && push!(body.args, stmt)
            for name in names
                push!(body.args, :(push!($shapes, $name)))
            end
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

# Shift `shape` so `bb`'s own center lands on the origin, then scale
# uniformly by `s` about the origin (so e.g. a circle always stays a
# circle). This matches Luxor's `origin()` convention -- (0,0) at the
# canvas center -- so the result is ready to draw right after `origin()`
# (which `@png`/`@svg`/`@pdf` already call for you). Centering on (0,0)
# also handles the "contain fit" leftover-space centering for free: since
# the canvas itself is centered on (0,0) too (`_picture_layout` always
# splits `margin`/leftover space evenly), no separate centering offset is
# needed here.
#
# `flip`: reflect across the x-axis (negate y) after shifting/scaling.
# This package's own geometry uses the standard math convention (y up,
# counterclockwise angles positive), but Luxor -- like most 2D graphics
# APIs -- draws with y increasing *downward*. Left uncorrected, that
# mismatch renders everything as a vertical mirror image of how it reads
# on paper (what's "above" the origin ends up drawn below it). `flip`
# defaults to `true` so the common case (draw once, look right) needs no
# extra thought; pass `flip=false` to see the raw, un-mirrored
# coordinates instead (e.g. if you're deliberately working in screen/y-down
# coordinates already).
#
# A `shape` with no position of its own -- a plain number, an EGVector --
# can't be shifted (`translate` has no method for either: there's nothing
# to move; for a number especially, it isn't even the kind of value it
# knows how to transform). These typically reach here as construction
# helpers named earlier in the block (e.g. `radio = 5` before
# `EGCircle2(centro, radio)`), not shapes meant to be drawn/sized
# themselves -- except a bare EGVector, which very much IS meant to be
# drawn, just without a position of its own to place. Scale and flip are
# both *linear* (unlike shift, they don't need a position to act relative
# to), so a shape that can't be shifted can still be scaled/flipped if it
# supports `homothety` -- this is exactly what lets a free direction
# come out at the picture's own scale, matching whatever anchor point
# it's drawn from (itself placed normally, since it's an EGPoint) --
# see EGVector's own `homothety` method. Anything that supports neither
# (a plain number) is left completely untouched.
#
# This is deliberately NOT the same test as "does this have a finite
# EGBoundingBox" -- an unbounded shape (EGLine, EGRay, EGAngle2,
# EGHalfPlane2, EGStrip2) has no finite extent to contribute to the
# picture's *size*, but it very much has a position, and does support
# translate/homothety like anything else, so it still needs to move
# along with everything else in the picture. Checking `applicable`
# directly (rather than `EGBoundingBox`'s emptiness) gets both right: a
# type that supports the transform is always transformed, regardless of
# whether it has a finite bbox; one that doesn't is left alone only if
# its bbox is *also* empty (confirming it was never meant to be
# positioned) -- if a shape claims a real bbox but doesn't support
# translate, that's a bug in its own definition and should still surface
# as a MethodError, not be silently swallowed here.
function _scale_and_flip(shape, s::Real, flip::Bool)
    scaled = homothety(shape, s, EGPoint(0.0, 0.0))
    flip || return scaled
    return reflection(scaled, EGLine(EGPoint(0.0, 0.0), EGPoint(1.0, 0.0)))
end

function _place_in_picture(shape, bb::EGBoundingBox, s::Real, flip::Bool)
    center = EGVector((bb.min[1] + bb.max[1]) / 2, (bb.min[2] + bb.max[2]) / 2)
    if !applicable(translate, shape, center)
        applicable(homothety, shape, s, EGPoint(0.0, 0.0)) || return shape
        return _scale_and_flip(shape, s, flip)
    end
    return _scale_and_flip(translate(shape, -center), s, flip)
end

const _PICTURE_KWNAMES = (:width, :height, :scale, :margin, :flip)

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
    return (getval(:width, nothing), getval(:height, nothing), getval(:scale, nothing), getval(:margin, 0.0), getval(:flip, true))
end

function _picture_body(mutating::Bool, block, width, height, scale, margin, flip)
    block isa Expr && block.head === :block || (block = Expr(:block, block))
    macroname = mutating ? "@to_luxor_picture!" : "@to_luxor_picture"

    shapes = gensym(:picture_shapes)
    sizing_shapes = gensym(:picture_sizing_shapes)
    slots = Union{Symbol,Nothing}[]   # nothing = anonymous result slot; Symbol = rebind target (mutating only)
    body = Expr(:block, :($shapes = Any[]), :($sizing_shapes = Any[]))
    for stmt in block.args
        if stmt isa LineNumberNode
            push!(body.args, stmt)
            continue
        end
        stmt, unbounded_here = _strip_unbounded(stmt)
        names, run_first = _block_stmt_names(stmt)
        if isempty(names)
            if mutating
                push!(body.args, :(throw(ArgumentError($macroname * ": cannot mutate an unnamed expression — assign it to a variable first"))))
            else
                push!(body.args, :(push!($shapes, $stmt)))
                unbounded_here || push!(body.args, :(push!($sizing_shapes, $shapes[end])))
                push!(slots, nothing)
            end
            continue
        end
        run_first && push!(body.args, stmt)
        for name in names
            push!(body.args, :(push!($shapes, $name)))
            unbounded_here || push!(body.args, :(push!($sizing_shapes, $name)))
            push!(slots, mutating ? name : nothing)
        end
    end

    picture_layout = GlobalRef(@__MODULE__, :_picture_layout)
    place_in_picture = GlobalRef(@__MODULE__, :_place_in_picture)

    bb = gensym(:bb)
    s = gensym(:s)
    W = gensym(:W)
    H = gensym(:H)
    push!(body.args, quote
        isempty($shapes) && throw(ArgumentError($macroname * ": the block has no shapes"))
        $bb = reduce(bbox_union, EGBoundingBox.($sizing_shapes); init=EGBoundingBox())
        isempty($bb) && throw(ArgumentError($macroname * ": none of the shapes in the block have a finite bounding box (only numbers/vectors/unbounded shapes, or everything marked @unbounded?)"))
        $s, $W, $H = $picture_layout(bbox_width($bb), bbox_height($bb), $width, $height, $scale, $margin)
    end)

    results = gensym(:picture_results)
    push!(body.args, :($results = Any[]))
    for (i, slot) in enumerate(slots)
        transformed = :($place_in_picture($shapes[$i], $bb, $s, $flip))
        if slot === nothing
            push!(body.args, :(push!($results, $transformed)))
        else
            push!(body.args, :($slot = $transformed), :(push!($results, $slot)))
        end
    end

    size_expr = :((width=$W, height=$H))
    if mutating
        push!(body.args, size_expr)
    else
        shapes_expr = length(slots) == 1 ? :($results[1]) : :(($results...,))
        push!(body.args, :(($size_expr, $shapes_expr)))
    end
    return esc(body)
end

"""
    @unbounded expr

Inside a [`@to_luxor_picture`](@ref)/[`@to_luxor_picture!`](@ref) block,
marks `expr` as excluded from that picture's fit-to-canvas *sizing* — its
own [`EGBoundingBox`](@ref) is left out of the union that determines the
canvas size and scale factor — while still binding/transforming it
normally, exactly like every other line in the block. Wrap either the
whole line (`@unbounded aux = EGCircle2(...)`) or just the right-hand
side (`aux = @unbounded EGCircle2(...)`); both read the same way.

Outside a picture block, `@unbounded expr` is simply `expr` — a plain,
harmless passthrough, so it's always safe to write regardless of context.

Useful for an auxiliary construction shape that has a real, large extent
but isn't meant to set the picture's own scale — e.g. a big locus circle
used only to build an intersection point:

```julia
sz = @to_luxor_picture! width=500 height=240 begin
    A = EGPoint(1.0, 1.0)
    locus = @unbounded EGCircle2(EGPoint(0.0, 0.0), 1000.0)   # huge, but shouldn't zoom the picture out
    B = intersection(locus, EGLine(A, EGPoint(2.0, 2.0)))[1]
end
```

If *every* shape in the block ends up marked `@unbounded` (or the block
otherwise has nothing with a finite bounding box), the same
`ArgumentError` [`@to_luxor_picture`](@ref) already throws for an empty
bounding box applies — there's nothing left to size the canvas by.
"""
macro unbounded(expr)
    return esc(expr)
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
    @to_luxor_picture flip=false width=400 begin ... end

Prepares every shape named in the block for drawing at a known, exact
canvas size: translate/scale them so their combined [`EGBoundingBox`](@ref)
fits centered on the *origin*, always preserving aspect ratio (the scale
factor is always the same in `x` and `y` — a circle always stays a
circle). Returns `((width=w, height=h), shapes)` — a `NamedTuple` with the
exact canvas size to pass to `Drawing` (`w, h = ...` still works
positionally, same as a plain tuple, alongside `sz.width`/`sz.height`),
and `shapes` are the translated/scaled copies (`c`/`s`/`t` themselves are
untouched — see [`@to_luxor_picture!`](@ref) for the mutating form), in
the same order as the block, as a tuple (or bare, for a single shape).

Centering on `(0, 0)` matches Luxor's own `origin()` convention (device
`(0, 0)` moved to the center of the canvas), so the result is ready to
draw right after `origin()` — which `@png`/`@svg`/`@pdf` already call for
you. The shapes are also reflected across the x-axis (`flip=true` by
default): this package's own geometry follows the standard math
convention (y up, counterclockwise angles positive), but Luxor -- like
most 2D graphics APIs -- draws with y increasing *downward*, so without
this correction everything would render as a vertical mirror image of how
it reads on paper. Pass `flip=false` to get the raw, un-mirrored
coordinates instead (e.g. if you're already deliberately working in
screen/y-down coordinates).

```julia
(w, h), (c2, s2) = @to_luxor_picture width=400 begin
    c = EGCircle2(EGPoint(3.0, -1.0), 5.0)
    s = EGSegment(EGPoint(-2.0, 4.0), EGPoint(6.0, -3.0))
end
@png begin
    path(c2; action=:stroke)
    path(s2; action=:stroke)
end w h
```

Building the `Drawing` by hand instead needs its own `origin()` call
first, since `Drawing` itself doesn't move `(0, 0)`:

```julia
Drawing(w, h, "out.png")
origin()
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
content on every side, in output units. `flip` (default `true`) is
independent of all of the above -- see the note above.

Each line in the block is read exactly like [`@boundingbox`](@ref)'s (an
assignment binds `name` in the enclosing scope as usual, or a bare
expression contributes without binding anything); a bare, unnamed
expression works here too since nothing needs to be rebound.

Wrap a line in [`@unbounded`](@ref) (`aux = @unbounded EGCircle2(...)`, or
`@unbounded aux = EGCircle2(...)`) to still bind/transform it normally
*without* its own `EGBoundingBox` counting toward the canvas's sizing —
e.g. a large auxiliary construction circle used only to build an
intersection point, that you don't want forcing the picture to zoom out
to fit.
"""
macro to_luxor_picture(args...)
    isempty(args) && error("@to_luxor_picture: missing the shapes block")
    width, height, scale, margin, flip = _parse_picture_kwargs("@to_luxor_picture", args[1:end-1])
    return _picture_body(false, args[end], width, height, scale, margin, flip)
end

"""
    @to_luxor_picture! begin ... end
    @to_luxor_picture! width=400 begin ... end

The mutating counterpart of [`@to_luxor_picture`](@ref): rebinds each
*named* shape (an assignment, or a bare reference to a shape defined
earlier) to its own translated/scaled image, instead of returning copies.
Returns just `(width=w, height=h)` — a `NamedTuple` (see
[`@to_luxor_picture`](@ref) for what that gives you beyond a plain tuple)
— the shapes are already accessible under their own names. A bare,
unnamed expression has nothing to rebind, so this form rejects it (same
as [`@translate!`](@ref) and the rest of that family).
"""
macro to_luxor_picture!(args...)
    isempty(args) && error("@to_luxor_picture!: missing the shapes block")
    width, height, scale, margin, flip = _parse_picture_kwargs("@to_luxor_picture!", args[1:end-1])
    return _picture_body(true, args[end], width, height, scale, margin, flip)
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
            continue
        end
        names, run_first = _block_stmt_names(stmt)
        if isempty(names)
            if mutating
                push!(body.args, :(throw(ArgumentError("cannot mutate an unnamed expression — assign it to a variable first"))))
            else
                push!(body.args, :(push!($results, $(make_call(stmt)))))
            end
            n_items += 1
            continue
        end
        run_first && push!(body.args, stmt) # run the assignment itself first
        for name in names
            if mutating
                push!(body.args, :($name = $(make_call(name))), :(push!($results, $name)))
            else
                push!(body.args, :(push!($results, $(make_call(name)))))
            end
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
keeping the result under a new name. Each top-level line is an assignment
`name = expr` (runs as ordinary code, and its value is translated into the
result tuple), a destructuring assignment `name1, name2, ... = expr`
(each name translated individually), or a bare expression (most often the
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
