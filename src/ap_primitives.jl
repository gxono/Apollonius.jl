"""
    rotate(p::APPoint{2}, angle, center=APPoint(0.0, 0.0))

Rotate `p` by `angle` radians (counterclockwise) around `center`.
"""
function rotate(p::APPoint{2}, angle::Real, center::APPoint{2}=APPoint(0.0, 0.0))
    v = p - center
    c, s = cos(angle), sin(angle)
    return center + APVector(c * v[1] - s * v[2], s * v[1] + c * v[2])
end
"""
    homothety(p::APPoint, k, center=APPoint(0.0, 0.0))

Scale `p` by ratio `k` about `center`.
"""
homothety(p::APPoint, k::Real, center::APPoint=APPoint(0.0, 0.0)) = center + k * (p - center)
"""
    reflection(p::APPoint, about::APPoint)

Reflect `p` through the point `about` (point symmetry).
"""
reflection(p::APPoint, about::APPoint) = about + (about - p)
"""
    translate(p::APPoint, v::APVector)

Translate `p` by `v`. The fourth member of the `rotate`/`homothety`/
`reflection`/`translate` quartet implemented across the whole package;
unlike the other three, it takes no `center` (a translation has none).
"""
translate(p::APPoint, v::APVector) = p + v
"""
    midpoint(p1::APPoint, p2::APPoint)
"""
midpoint(p1::APPoint, p2::APPoint) = p1 + (p2 - p1) / 2
"""
    distance(p1::APPoint, p2::APPoint)
"""
distance(p1::APPoint, p2::APPoint) = norm(p2 - p1)
"""
    orthogonal(v::APVector)

`v` rotated by +90 degrees (counterclockwise). 2D only.
"""
orthogonal(v::APVector{2}) = APVector(-v[2], v[1])
orthogonal(p::APPoint{2}) = APVector(-p[2], p[1])
"""
    APSegment(p1::APPoint, p2::APPoint)

The finite segment `[p1, p2]`. `s[1]`/`s[2]` access its two endpoints.
"""
struct APSegment{Dim,T<:Real} <: APCurve{Dim,T}
    p1::APPoint{Dim,T}
    p2::APPoint{Dim,T}
end
function APSegment(p1::APPoint{Dim}, p2::APPoint{Dim}) where {Dim}
    T = promote_type(eltype(p1), eltype(p2))
    return APSegment(convert(APPoint{Dim,T}, p1), convert(APPoint{Dim,T}, p2))
end
"""
    APLine(p1::APPoint, p2::APPoint)

The infinite straight line passing through `p1` and `p2`. `l[1]`/`l[2]`
access the two defining points.
"""
struct APLine{Dim,T<:Real} <: APCurve{Dim,T}
    p1::APPoint{Dim,T}
    p2::APPoint{Dim,T}
end
function APLine(p1::APPoint{Dim}, p2::APPoint{Dim}) where {Dim}
    T = promote_type(eltype(p1), eltype(p2))
    return APLine(convert(APPoint{Dim,T}, p1), convert(APPoint{Dim,T}, p2))
end
APLine(s::APSegment) = APLine(s.p1, s.p2)
"""
    APRay(origin::APPoint, through::APPoint)

The half-line starting at `origin` and passing through `through`.
`r[1]`/`r[2]` access `origin`/`through`.
"""
struct APRay{Dim,T<:Real} <: APCurve{Dim,T}
    origin::APPoint{Dim,T}
    through::APPoint{Dim,T}
end
function APRay(origin::APPoint{Dim}, through::APPoint{Dim}) where {Dim}
    T = promote_type(eltype(origin), eltype(through))
    return APRay(convert(APPoint{Dim,T}, origin), convert(APPoint{Dim,T}, through))
end
APLine(r::APRay) = APLine(r.origin, r.through)
Base.getindex(s::APSegment, i::Integer) = i == 1 ? s.p1 : s.p2
Base.length(::APSegment) = 2
Base.iterate(s::APSegment, i::Int=1) = i > 2 ? nothing : (s[i], i + 1)
Base.eltype(::Type{<:APSegment{Dim,T}}) where {Dim,T} = APPoint{Dim,T}
Base.getindex(l::APLine, i::Integer) = i == 1 ? l.p1 : l.p2
Base.length(::APLine) = 2
Base.iterate(l::APLine, i::Int=1) = i > 2 ? nothing : (l[i], i + 1)
Base.eltype(::Type{<:APLine{Dim,T}}) where {Dim,T} = APPoint{Dim,T}
Base.getindex(r::APRay, i::Integer) = i == 1 ? r.origin : r.through
Base.length(::APRay) = 2
Base.iterate(r::APRay, i::Int=1) = i > 2 ? nothing : (r[i], i + 1)
Base.eltype(::Type{<:APRay{Dim,T}}) where {Dim,T} = APPoint{Dim,T}
Base.:(==)(a::APSegment, b::APSegment) = a.p1 == b.p1 && a.p2 == b.p2
Base.:(==)(a::APLine, b::APLine) = a.p1 == b.p1 && a.p2 == b.p2
Base.:(==)(a::APRay, b::APRay) = a.origin == b.origin && a.through == b.through
Base.convert(::Type{APSegment{Dim,T}}, s::APSegment{Dim}) where {Dim,T} = APSegment{Dim,T}(s.p1, s.p2)
Base.convert(::Type{APLine{Dim,T}}, l::APLine{Dim}) where {Dim,T} = APLine{Dim,T}(l.p1, l.p2)
Base.convert(::Type{APRay{Dim,T}}, r::APRay{Dim}) where {Dim,T} = APRay{Dim,T}(r.origin, r.through)
Base.isapprox(a::APSegment, b::APSegment; kwargs...) = isapprox(a.p1, b.p1; kwargs...) && isapprox(a.p2, b.p2; kwargs...)
function Base.isapprox(a::APLine{2}, b::APLine{2}; atol=1e-9, kwargs...)
    is_parallel(a, b; atol=atol) &&
        on_line(a.p1, b; atol=atol)
end
function Base.isapprox(a::APRay, b::APRay; atol=1e-9, kwargs...)
    isapprox(a.origin, b.origin; atol=atol, kwargs...) || return false
    d1, d2 = direction(a), direction(b)
    abs(cross2(d1, d2)) <= atol * norm(d1) * norm(d2) && dot(d1, d2) > 0
end
Base.show(io::IO, s::APSegment) = print(io, "APSegment(", s.p1, " -> ", s.p2, ")")
"""
    reverse(s::APSegment)

`s`, traversed from `s.p2` to `s.p1`.
"""
Base.reverse(s::APSegment) = APSegment(s.p2, s.p1)
Base.show(io::IO, l::APLine) = print(io, "APLine(", l.p1, " -> ", l.p2, ")")
Base.show(io::IO, r::APRay) = print(io, "APRay(", r.origin, " -> ", r.through, ")")
"""
    direction(obj)

The direction of a `APLine`, `APRay` or `APSegment`, as an [`APVector`](@ref).
"""
direction(l::APLine) = l.p2 - l.p1
direction(r::APRay) = r.through - r.origin
direction(s::APSegment) = s.p2 - s.p1
"""
    rotate(v::APVector{2}, angle::Real)

Rotate the direction `v` by `angle` radians (counterclockwise).
"""
function rotate(v::APVector{2}, angle::Real)
    c, s = cos(angle), sin(angle)
    return APVector(c * v[1] - s * v[2], s * v[1] + c * v[2])
end
"""
    homothety(v::APVector, k::Real, center::APPoint=APPoint(0.0, 0.0))

`k * v`: for a free vector, `center` has nothing to act on (there's no
position), so it's accepted purely for signature symmetry with every
other `homothety` method (points, curves, [`APEquipollentVector`](@ref)).
Having this defined for a bare `APVector` is what lets
[`@to_luxor_picture`](@ref) scale one to the picture's own scale factor
even though it has no [`APBoundingBox`](@ref) to shift into position:
see `_place_in_picture`'s own comment for the reasoning.
"""
homothety(v::APVector{Dim,T}, k::Real, center::APPoint{Dim}=APPoint(ntuple(_ -> zero(T), Dim))) where {Dim,T} = k * v
"""
    reflection(v::APVector, about::APPoint)

Point-reflect the direction `v`: simply `-v`, since a free vector has no
position for `about` to act on.
"""
reflection(v::APVector, about::APPoint) = -v
"""
    reflection(v::APVector{2}, about::APLine)

Reflect the direction `v` across `about`'s own direction (axial
symmetry); `about`'s position is irrelevant, only its direction matters.
"""
function reflection(v::APVector{2}, about::APLine)
    d = direction(about)
    return 2 * (dot(v, d) / dot(d, d)) * d - v
end
"""
    rotate(v::APVector{3}, angle::Real, axis::APLine{3})

Rotate the direction `v` by `angle` radians about `axis`'s own
*direction* (only `direction(axis)` matters: a free vector has no
position, so where `axis` sits in space is irrelevant). Same Rodrigues
formula as `rotate(::APPoint{3}, ::Real, ::APLine{3})`, minus the
anchor-point offset.
"""
function rotate(v::APVector{3}, angle::Real, axis::APLine{3})
    k = direction(axis) / norm(direction(axis))
    v_par = dot(v, k) * k
    v_perp = v - v_par
    c, s = cos(angle), sin(angle)
    return v_par + c * v_perp + s * cross3(k, v_perp)
end
distance(s::APSegment) = distance(s.p1, s.p2)
midpoint(s::APSegment) = midpoint(s.p1, s.p2)
"""
    projection(p::APPoint, l::APLine; angle::Real=pi/2)

Where a line through `p`, at `angle` radians from `l`'s own direction
(counterclockwise; the default `pi/2` is the ordinary perpendicular/
orthogonal projection), meets `l`: the oblique projection of `p` onto
`l` for any other `angle`. `angle` must be strictly between `0` and `π`:
at either end, the projecting line becomes parallel to `l` itself, so
there's no longer a single intersection point.

| Keyword | Default | Meaning |
|:--------|:--------|:--------|
| `angle` | `pi/2` | angle of the projecting line with `l`, in radians, strictly between `0` and `π`; the default is the perpendicular |
"""
function projection(p::APPoint, l::APLine; angle::Real=pi / 2)
    d = direction(l)
    angle == pi / 2 && return l.p1 + (dot(p - l.p1, d) / dot(d, d)) * d
    0 < angle < pi || throw(ArgumentError("projection: angle must be strictly between 0 and π (got $angle)"))
    u = rotate(d, angle)
    t = cross2(u, p - l.p1) / cross2(u, d)
    return l.p1 + t * d
end
"""
    projection(l::APLine; angle::Real=pi/2)

`p -> projection(p, l; angle=angle)`: for composing with `|>`/`map`/
`filter`, e.g. `map(projection(l), points)` to project a whole collection
onto `l` at once.
"""
projection(l::APLine; angle::Real=pi / 2) = p -> projection(p, l; angle=angle)
distance(p::APPoint{2}, l::APLine{2}) = abs(cross2(direction(l), p - l.p1)) / norm(direction(l))
distance(l::APLine{2}, p::APPoint{2}) = distance(p, l)
"""
    distance(p::APPoint{3}, l::APLine{3})

Perpendicular distance from `p` to the infinite line `l`, via the 3D
cross product (`cross2`'s 2D formula above doesn't generalize: it only
reads 2 of `p`'s 3 coordinates, which is silently wrong rather than
merely inapplicable, so this is its own dispatched method rather than a
fallback).
"""
distance(p::APPoint{3}, l::APLine{3}) = norm(cross3(direction(l), p - l.p1)) / norm(direction(l))
distance(l::APLine{3}, p::APPoint{3}) = distance(p, l)
"""
    distance(p::APPoint, s::APSegment)

Distance from `p` to the closest point of the *finite* segment `s` (unlike
[`distance(::APPoint, ::APLine)`](@ref), which measures to the infinite
line through `s`'s two points).
"""
function distance(p::APPoint, s::APSegment)
    d = s.p2 - s.p1
    dd = dot(d, d)
    dd <= 0 && return distance(p, s.p1)
    t = clamp(dot(p - s.p1, d) / dd, 0.0, 1.0)
    return distance(p, s.p1 + t * d)
end
distance(s::APSegment, p::APPoint) = distance(p, s)
"""
    distance(p::APPoint, r::APRay)

Distance from `p` to the closest point of the *half-line* `r` (clamped at
`r.origin`, unbounded past `r.through`).
"""
function distance(p::APPoint, r::APRay)
    d = r.through - r.origin
    dd = dot(d, d)
    dd <= 0 && return distance(p, r.origin)
    t = max(dot(p - r.origin, d) / dd, 0.0)
    return distance(p, r.origin + t * d)
end
distance(r::APRay, p::APPoint) = distance(p, r)
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
    distance(l1::APLine, l2::APLine; atol=1e-9)

`0` if `l1` and `l2` cross; otherwise (they're parallel) the constant
perpendicular gap between them.
"""
function distance(l1::APLine, l2::APLine; atol=1e-9)
    _clipped_lines_cross(l1.p1, direction(l1), -Inf, Inf, l2.p1, direction(l2), -Inf, Inf; atol=atol) && return 0.0
    return distance(l1.p1, l2)
end
"""
    distance(l::APLine, r::APRay; atol=1e-9)
"""
function distance(l::APLine, r::APRay; atol=1e-9)
    _clipped_lines_cross(l.p1, direction(l), -Inf, Inf, r.origin, direction(r), 0.0, Inf; atol=atol) && return 0.0
    return distance(r.origin, l)
end
distance(r::APRay, l::APLine; atol=1e-9) = distance(l, r; atol=atol)
"""
    distance(l::APLine, s::APSegment; atol=1e-9)
"""
function distance(l::APLine, s::APSegment; atol=1e-9)
    _clipped_lines_cross(l.p1, direction(l), -Inf, Inf, s.p1, direction(s), 0.0, 1.0; atol=atol) && return 0.0
    return min(distance(s.p1, l), distance(s.p2, l))
end
distance(s::APSegment, l::APLine; atol=1e-9) = distance(l, s; atol=atol)
"""
    distance(r1::APRay, r2::APRay; atol=1e-9)
"""
function distance(r1::APRay, r2::APRay; atol=1e-9)
    _clipped_lines_cross(r1.origin, direction(r1), 0.0, Inf, r2.origin, direction(r2), 0.0, Inf; atol=atol) && return 0.0
    return min(distance(r1.origin, r2), distance(r2.origin, r1))
end
"""
    distance(r::APRay, s::APSegment; atol=1e-9)
"""
function distance(r::APRay, s::APSegment; atol=1e-9)
    _clipped_lines_cross(r.origin, direction(r), 0.0, Inf, s.p1, direction(s), 0.0, 1.0; atol=atol) && return 0.0
    return min(distance(r.origin, s), distance(s.p1, r), distance(s.p2, r))
end
distance(s::APSegment, r::APRay; atol=1e-9) = distance(r, s; atol=atol)
"""
    distance(s1::APSegment, s2::APSegment; atol=1e-9)
"""
function distance(s1::APSegment, s2::APSegment; atol=1e-9)
    _clipped_lines_cross(s1.p1, direction(s1), 0.0, 1.0, s2.p1, direction(s2), 0.0, 1.0; atol=atol) && return 0.0
    return min(distance(s1.p1, s2), distance(s1.p2, s2), distance(s2.p1, s1), distance(s2.p2, s1))
end
"""
    reflection(p::APPoint{2}, l::APLine{2})

Reflect `p` across the line `l` (axial symmetry). **2D only, deliberately**:
in 3D, "reflecting through the foot of the perpendicular onto a line" is
actually a 180° rotation *about* that line (orientation-*preserving*,
`rotate(p, pi, axis)` once 3D `rotate` is loaded), not a mirror
reflection (orientation-*reversing*), a line's orthogonal complement in
3D is a whole plane, not a single direction, so there is no unique mirror
to reflect across. The true 3D mirror would be `reflection(::APPoint{3},
::APPlane3)` (3D geometry is currently paused).
"""
reflection(p::APPoint{2}, l::APLine{2}) = (foot = projection(p, l); foot + (foot - p))
reflection(s::APSegment, about) = APSegment(reflection(s.p1, about), reflection(s.p2, about))
reflection(l::APLine, about) = APLine(reflection(l.p1, about), reflection(l.p2, about))
reflection(r::APRay, about) = APRay(reflection(r.origin, about), reflection(r.through, about))
rotate(s::APSegment{2}, angle::Real, center::APPoint{2}=APPoint(0.0, 0.0)) =
    APSegment(rotate(s.p1, angle, center), rotate(s.p2, angle, center))
rotate(l::APLine{2}, angle::Real, center::APPoint{2}=APPoint(0.0, 0.0)) =
    APLine(rotate(l.p1, angle, center), rotate(l.p2, angle, center))
rotate(r::APRay{2}, angle::Real, center::APPoint{2}=APPoint(0.0, 0.0)) =
    APRay(rotate(r.origin, angle, center), rotate(r.through, angle, center))
"""
    rotate(p::APPoint{3}, angle::Real, axis::APLine{3})

Rotate `p` by `angle` radians (right-hand rule around `direction(axis)`)
about `axis`: the 3D analogue of `rotate(p::APPoint{2}, angle, center)`,
via the closed-form Rodrigues rotation formula (no quaternions/matrix
exponential needed): decompose `p - axis.p1` into its component along the
axis (unchanged) and perpendicular to it (rotated within the plane
spanned by itself and `k × v_perp`).
"""
function rotate(p::APPoint{3}, angle::Real, axis::APLine{3})
    k = direction(axis) / norm(direction(axis))
    v = p - axis.p1
    v_par = dot(v, k) * k
    v_perp = v - v_par
    c, s = cos(angle), sin(angle)
    return axis.p1 + v_par + c * v_perp + s * cross3(k, v_perp)
end
"""
    rotate(s::APSegment{3}, angle::Real, axis::APLine{3})
    rotate(l::APLine{3}, angle::Real, axis::APLine{3})
    rotate(r::APRay{3}, angle::Real, axis::APLine{3})

The 3D analogue of the `center`-based `rotate` above, about an `axis`
instead of a `center` (see [`rotate(::APPoint{3}, ::Real, ::APLine{3})`](@ref)).
"""
rotate(s::APSegment{3}, angle::Real, axis::APLine{3}) =
    APSegment(rotate(s.p1, angle, axis), rotate(s.p2, angle, axis))
rotate(l::APLine{3}, angle::Real, axis::APLine{3}) =
    APLine(rotate(l.p1, angle, axis), rotate(l.p2, angle, axis))
rotate(r::APRay{3}, angle::Real, axis::APLine{3}) =
    APRay(rotate(r.origin, angle, axis), rotate(r.through, angle, axis))
homothety(s::APSegment, k::Real, center::APPoint=APPoint(0.0, 0.0)) =
    APSegment(homothety(s.p1, k, center), homothety(s.p2, k, center))
homothety(l::APLine, k::Real, center::APPoint=APPoint(0.0, 0.0)) =
    APLine(homothety(l.p1, k, center), homothety(l.p2, k, center))
homothety(r::APRay, k::Real, center::APPoint=APPoint(0.0, 0.0)) =
    APRay(homothety(r.origin, k, center), homothety(r.through, k, center))
translate(s::APSegment, v::APVector) = APSegment(translate(s.p1, v), translate(s.p2, v))
translate(l::APLine, v::APVector) = APLine(translate(l.p1, v), translate(l.p2, v))
translate(r::APRay, v::APVector) = APRay(translate(r.origin, v), translate(r.through, v))
"""
    APBoundingBox(min::APPoint, max::APPoint)

An axis-aligned bounding box. Deliberately not part of the `APRegion`
hierarchy and has no `rotate`/`reflection` methods: an arbitrary rotation
or reflection wouldn't generally produce another axis-aligned box.
Translation (`+`/`-`) and uniform scaling about the origin (`*`) are the
only transforms that always keep it axis-aligned, so those are what's
supported.
"""
struct APBoundingBox{Dim,T<:Real} <: APObject{Dim,T}
    min::APPoint{Dim,T}
    max::APPoint{Dim,T}
end
function APBoundingBox(min::APPoint{Dim}, max::APPoint{Dim}) where {Dim}
    T = promote_type(eltype(min), eltype(max))
    return APBoundingBox(convert(APPoint{Dim,T}, min), convert(APPoint{Dim,T}, max))
end
APBoundingBox(bb::APBoundingBox) = bb
function homothety(bb::APBoundingBox, k::Real, center::APPoint=APPoint(0.0, 0.0))
    p1 = homothety(bb.min, k, center)
    p2 = homothety(bb.max, k, center)
    if k < 0
        p1, p2 = p2, p1
    end
    return APBoundingBox(p1, p2)
end
function APBoundingBox(points::AbstractVector{<:APPoint{Dim}}) where {Dim}
    isempty(points) && throw(ArgumentError("APBoundingBox requires at least one point"))
    lo = APPoint(ntuple(i -> minimum(p[i] for p in points), Dim))
    hi = APPoint(ntuple(i -> maximum(p[i] for p in points), Dim))
    return APBoundingBox(lo, hi)
end
APBoundingBox(points::AbstractArray{<:APPoint}) = APBoundingBox(vec(points))
APBoundingBox(s::APSegment) = APBoundingBox([s.p1, s.p2])
"""
    APBoundingBox(shapes::Union{Tuple,NamedTuple})

The [`bbox_union`](@ref) of a fixed-size group of shapes: e.g. the
`(A=..., B=..., C=...)` returned by [`excenters`](@ref)/[`excircles`](@ref)
or the plain 3-tuple returned by [`euler_points`](@ref): so these work
directly wherever a single shape would (like inside
[`@to_luxor_picture`](@ref)) without first calling `collect`.
"""
function APBoundingBox(shapes::Union{Tuple,NamedTuple})
    isempty(shapes) && throw(ArgumentError("APBoundingBox requires at least one shape"))
    return reduce(bbox_union, APBoundingBox.(values(shapes)))
end
"""
    APBoundingBox(p::APPoint)

The degenerate box `APBoundingBox(p, p)`: zero-size, but still a real
position, so `p` grows a [`bbox_union`](@ref) exactly like any other
shape would.
"""
APBoundingBox(p::APPoint) = APBoundingBox(p, p)
"""
    APBoundingBox()

The *empty* bounding box: the neutral element for [`bbox_union`](@ref):
`bbox_union(APBoundingBox(), bb) == bb` for any `bb`. This is what
`APBoundingBox` returns for values that have no position of their own to
contribute to a picture's extent: a plain number, an [`APVector`](@ref)
(a direction, not a location: unlike [`APPoint`](@ref), which *does* get
its own degenerate box above), or an unbounded curve/region
([`APLine`](@ref), [`APRay`](@ref), `APAngle2`, `APHalfPlane2`,
`APStrip2`, which have no finite extent to report). It exists so generic
code, [`@boundingbox`](@ref), [`@to_luxor_picture`](@ref), can call
`APBoundingBox` on every value named in a block without special-casing the
ones that aren't meant to be drawn or sized.
"""
APBoundingBox() = APBoundingBox(APPoint(Inf, Inf), APPoint(-Inf, -Inf))
APBoundingBox(::APVector) = APBoundingBox()
APBoundingBox(::Real) = APBoundingBox()
APBoundingBox(::APLine) = APBoundingBox()
APBoundingBox(::APRay) = APBoundingBox()
"""
    APBoundingBox(v::AbstractVector{<:APObject})

The [`bbox_union`](@ref) of every element's own box: the empty box (see
[`APBoundingBox()`](@ref) above) for an empty `v`, so this composes
exactly like a single value would, rather than erroring on "no points"
the way [`APBoundingBox(::AbstractVector{<:APPoint})`](@ref) does. This is
what lets a plain `Vector` of shapes, what [`intersection`](@ref)/
[`tangent_points`](@ref) return, since they can give 0, 1 or 2 points
depending on the geometry, work as a single named item inside a
[`@boundingbox`](@ref)/[`@to_luxor_picture`](@ref) block, without
unwrapping it by hand first.
"""
APBoundingBox(v::AbstractVector{<:APObject}) = reduce(bbox_union, APBoundingBox.(v); init=APBoundingBox())
"""
    isempty(bb::APBoundingBox)

Whether `bb` is the empty box (see [`APBoundingBox()`](@ref)).
"""
Base.isempty(bb::APBoundingBox) = bb.min[1] > bb.max[1]
Base.:(==)(a::APBoundingBox, b::APBoundingBox) = a.min == b.min && a.max == b.max
Base.isapprox(a::APBoundingBox, b::APBoundingBox; kwargs...) =
    isapprox(a.min, b.min; kwargs...) && isapprox(a.max, b.max; kwargs...)
Base.:+(bb::APBoundingBox, v::APVector) = APBoundingBox(bb.min + v, bb.max + v)
Base.:-(bb::APBoundingBox, v::APVector) = APBoundingBox(bb.min - v, bb.max - v)
translate(bb::APBoundingBox, v::APVector) = APBoundingBox(bb.min + v, bb.max + v)
function Base.:*(bb::APBoundingBox{Dim}, k::Real) where {Dim}
    p1, p2 = bb.min * k, bb.max * k
    lo = APPoint(ntuple(i -> min(p1[i], p2[i]), Dim))
    hi = APPoint(ntuple(i -> max(p1[i], p2[i]), Dim))
    return APBoundingBox(lo, hi)
end
Base.show(io::IO, bb::APBoundingBox) = print(io, "APBoundingBox(", bb.min, " .. ", bb.max, ")")
"""
    p in bb::APBoundingBox
"""
Base.in(p::APPoint{Dim}, bb::APBoundingBox{Dim}) where {Dim} = all(i -> bb.min[i] <= p[i] <= bb.max[i], 1:Dim)
function _check_distance_mode(mode::Symbol)
    mode in (:region, :boundary) ||
        throw(ArgumentError("distance: mode must be :region or :boundary, got $(repr(mode))"))
end
"""
    distance(p::APPoint, bb::APBoundingBox; mode::Symbol=:region)

`mode=:region` (default): `0` when `p` is inside or on `bb`, otherwise the
usual point-to-axis-aligned-box distance. `mode=:boundary`: always the
distance to the nearest edge, even from inside.

| Keyword | Default | Meaning |
|:--------|:--------|:--------|
| `mode` | `:region` | for regions and sets: `:region` gives `0` for a point inside or on it, `:boundary` the distance to the boundary even from inside |
"""
function distance(p::APPoint{2}, bb::APBoundingBox{2}; mode::Symbol=:region)
    _check_distance_mode(mode)
    if p in bb
        mode == :region && return 0.0
        return min(p[1] - bb.min[1], bb.max[1] - p[1], p[2] - bb.min[2], bb.max[2] - p[2])
    end
    dx = max(bb.min[1] - p[1], 0.0, p[1] - bb.max[1])
    dy = max(bb.min[2] - p[2], 0.0, p[2] - bb.max[2])
    return sqrt(dx^2 + dy^2)
end
distance(bb::APBoundingBox{2}, p::APPoint{2}; mode::Symbol=:region) = distance(p, bb; mode=mode)
"""
    bbox_width(bb::APBoundingBox)
"""
bbox_width(bb::APBoundingBox) = bb.max[1] - bb.min[1]
"""
    bbox_height(bb::APBoundingBox)
"""
bbox_height(bb::APBoundingBox) = bb.max[2] - bb.min[2]
"""
    bbox_center(bb::APBoundingBox)
"""
bbox_center(bb::APBoundingBox) = midpoint(bb.min, bb.max)
"""
    bbox_diagonal(bb::APBoundingBox)

The distance between `bb.min` and `bb.max`.
"""
bbox_diagonal(bb::APBoundingBox) = distance(bb.min, bb.max)
"""
    bbox_aspect_ratio(bb::APBoundingBox)

`bbox_width(bb) / bbox_height(bb)`.
"""
bbox_aspect_ratio(bb::APBoundingBox) = bbox_width(bb) / bbox_height(bb)
"""
    bboxes_intersect(a::APBoundingBox, b::APBoundingBox)

Whether `a` and `b` overlap (touching counts as intersecting).
"""
bboxes_intersect(a::APBoundingBox{2}, b::APBoundingBox{2}) =
    !(a.max[1] < b.min[1] || b.max[1] < a.min[1] || a.max[2] < b.min[2] || b.max[2] < a.min[2])
"""
    bbox_intersection(a::APBoundingBox, b::APBoundingBox)

The overlapping box of `a` and `b`, or `nothing` if they don't intersect.
"""
function bbox_intersection(a::APBoundingBox{2}, b::APBoundingBox{2})
    bboxes_intersect(a, b) || return nothing
    lo = APPoint(max(a.min[1], b.min[1]), max(a.min[2], b.min[2]))
    hi = APPoint(min(a.max[1], b.max[1]), min(a.max[2], b.max[2]))
    return APBoundingBox(lo, hi)
end
"""
    bbox_union(a::APBoundingBox, b::APBoundingBox)

The smallest box containing both `a` and `b`. Unlike
[`bbox_intersection`](@ref), this always exists: `a`/`b` don't need to
overlap. The empty box (see [`APBoundingBox()`](@ref)) is the identity
element: `bbox_union` with it returns the other box unchanged.
"""
function bbox_union(a::APBoundingBox{2}, b::APBoundingBox{2})
    isempty(a) && return b
    isempty(b) && return a
    lo = APPoint(min(a.min[1], b.min[1]), min(a.min[2], b.min[2]))
    hi = APPoint(max(a.max[1], b.max[1]), max(a.max[2], b.max[2]))
    return APBoundingBox(lo, hi)
end
function _block_stmt_names(stmt)
    stmt isa Symbol && return (stmt === :_ ? Symbol[] : [stmt], false)
    if stmt isa Expr && stmt.head === :(=)
        lhs = stmt.args[1]
        lhs isa Symbol && return (lhs === :_ ? Symbol[] : [lhs], true)
        if lhs isa Expr && lhs.head === :tuple && all(a -> a isa Symbol, lhs.args)
            return (filter(!=(:_), Vector{Symbol}(lhs.args)), true)
        end
    end
    return (Symbol[], false)
end
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
        c = APCircle2(...)
        s = APSegment(...)
        t                     # a shape already defined earlier
    end
    @boundingbox c             # a single shape/expression also works

The [`bbox_union`](@ref) of every shape named in the block: via
[`APBoundingBox`](@ref) applied to each, then `reduce`d with `bbox_union`
-- as a single expression. Each top-level line in the block is either:

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

Lines run in order, top to bottom, exactly as written: this is not a new
scope (no `let`): a bare name refers to whatever `name` already means at
that point, and an assignment defines `name` in the enclosing scope, so
mixing "build a new shape here" and "also include this shape from
earlier" freely on different lines works as expected.

A single expression instead of a `begin ... end` block (`@boundingbox c`,
or even `@boundingbox c = APCircle2(...)`) works the same way, treated as
a one-line block: `APBoundingBox(c)` directly is simpler for that case,
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
        reduce(bbox_union, APBoundingBox.($shapes))
    end)
    return esc(body)
end
function _picture_layout(bw::Real, bh::Real, width, height, scale, margin::Real)
    fit_width, fit_height = width !== nothing && scale === nothing, height !== nothing && scale === nothing
    ((fit_width && !fit_height && bw == 0) || (fit_height && !fit_width && bh == 0) || (fit_width && fit_height && bw == 0 && bh == 0)) &&
        throw(ArgumentError("@to_luxor_picture: the content has no extent in the direction to fit (a single point, for example), so it cannot be scaled to width/height"))
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
function _scale_and_flip(shape, s::Real, flip::Bool)
    scaled = homothety(shape, s, APPoint(0.0, 0.0))
    flip || return scaled
    return reflection(scaled, APLine(APPoint(0.0, 0.0), APPoint(1.0, 0.0)))
end
function _place_in_picture(shape, bb::APBoundingBox, s::Real, flip::Bool)
    center = APVector((bb.min[1] + bb.max[1]) / 2, (bb.min[2] + bb.max[2]) / 2)
    if !applicable(translate, shape, center)
        applicable(homothety, shape, s, APPoint(0.0, 0.0)) || return shape
        return _scale_and_flip(shape, s, flip)
    end
    return _scale_and_flip(translate(shape, -center), s, flip)
end
const _PICTURE_KWNAMES = (:width, :height, :scale, :margin, :flip)
function _parse_picture_kwargs(macroname, exprs)
    given = Dict{Symbol,Any}()
    for e in exprs
        (e isa Expr && e.head === :(=) && e.args[1] isa Symbol && e.args[1] in _PICTURE_KWNAMES) ||
            error("$macroname: unrecognized argument `$e`: expected one of $_PICTURE_KWNAMES, or the shapes block as the last argument")
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
    slots = Union{Symbol,Nothing}[]
    body = Expr(:block, :($shapes = Any[]), :($sizing_shapes = Any[]))
    for stmt in block.args
        if stmt isa LineNumberNode
            push!(body.args, stmt)
            continue
        end
        stmt, unbounded_here = _strip_unbounded(stmt)
        names, run_first = _block_stmt_names(stmt)
        if isempty(names)
            push!(body.args, :(throw(ArgumentError($macroname * ": an unnamed expression is not allowed (" * $(string(stmt)) * "): assign it to a name"))))
            continue
        end
        run_first && push!(body.args, stmt)
        for name in names
            push!(body.args, :(push!($shapes, $name)))
            unbounded_here || push!(body.args, :(push!($sizing_shapes, $name)))
            push!(slots, name)
        end
    end
    picture_layout = GlobalRef(@__MODULE__, :_picture_layout)
    place_in_picture = GlobalRef(@__MODULE__, :_place_in_picture)
    bb = gensym(:bb)
    s = gensym(:s)
    W = gensym(:W)
    H = gensym(:H)
    fct = gensym(:picture_fct)
    drawbb = gensym(:drawbb)
    push!(body.args, quote
        isempty($shapes) && throw(ArgumentError($macroname * ": the block has no shapes"))
        $bb = reduce(bbox_union, APBoundingBox.($sizing_shapes); init=APBoundingBox())
        isempty($bb) && throw(ArgumentError($macroname * ": none of the shapes in the block have a finite bounding box (only numbers/vectors/unbounded shapes, or everything marked @unbounded?)"))
        $s, $W, $H = $picture_layout(bbox_width($bb), bbox_height($bb), $width, $height, $scale, $margin)
        $fct = shape -> $place_in_picture(shape, $bb, $s, $flip)
        $drawbb = APBoundingBox(APPoint(-($W / 2 - $margin), -($H / 2 - $margin)), APPoint($W / 2 - $margin, $H / 2 - $margin))
    end)
    results = gensym(:picture_results)
    push!(body.args, :($results = Any[]))
    for (i, slot) in enumerate(slots)
        transformed = :($place_in_picture($shapes[$i], $bb, $s, $flip))
        if mutating
            push!(body.args, :($slot = $transformed), :(push!($results, $slot)))
        else
            push!(body.args, :(push!($results, $transformed)))
        end
    end
    size_expr = :((width=$W, height=$H, fct=$fct, bb=$drawbb))
    if mutating
        push!(body.args, size_expr)
    else
        order = unique(slots)   # a name assigned twice keeps its last value, at its first position
        last_index = Dict(name => i for (i, name) in enumerate(slots))
        values = [:($results[$(last_index[name])]) for name in order]
        push!(body.args, :(($size_expr, NamedTuple{$(Tuple(order))}(($(values...),)))))
    end
    return esc(body)
end
"""
    @unbounded expr

Inside a [`@to_luxor_picture`](@ref)/[`@to_luxor_picture!`](@ref) block,
marks `expr` as excluded from that picture's fit-to-canvas *sizing*, its
own [`APBoundingBox`](@ref) is left out of the union that determines the
canvas size and scale factor, while still binding/transforming it
normally, exactly like every other line in the block. Wrap either the
whole line (`@unbounded aux = APCircle2(...)`) or just the right-hand
side (`aux = @unbounded APCircle2(...)`); both read the same way.

Outside a picture block, `@unbounded expr` is simply `expr`: a plain,
harmless passthrough, so it's always safe to write regardless of context.

Useful for an auxiliary construction shape that has a real, large extent
but isn't meant to set the picture's own scale: e.g. a big locus circle
used only to build an intersection point:

```julia
lxm = @to_luxor_picture! width=500 height=240 begin
    A = APPoint(1.0, 1.0)
    locus = @unbounded APCircle2(APPoint(0.0, 0.0), 1000.0)   # huge, but shouldn't zoom the picture out
    B = intersection(locus, APLine(A, APPoint(2.0, 2.0)))[1]
end
```

If *every* shape in the block ends up marked `@unbounded` (or the block
otherwise has nothing with a finite bounding box), the same
`ArgumentError` [`@to_luxor_picture`](@ref) already throws for an empty
bounding box applies: there's nothing left to size the canvas by.
"""
macro unbounded(expr)
    return esc(expr)
end
"""
    @to_luxor_picture begin
        c = APCircle2(...)
        s = APSegment(...)
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
canvas size: translate/scale them so their combined [`APBoundingBox`](@ref)
fits centered on the *origin*, always preserving aspect ratio (the scale
factor is always the same in `x` and `y`: a circle always stays a
circle). Returns two `NamedTuple`s, called `lxm` (the "Luxor meta") and `lxo`
(the "Luxor objects") in the examples: `lxm = (width, height, fct, bb)` has the
exact canvas size to pass to `Drawing` (`lxm.width`, `lxm.height`, or
positionally `w, h = ...`), `fct`, the exact same translate/scale/flip
function applied to every shape in the block, so it can be applied
*outside* the block too, to something that isn't itself part of the
picture (e.g. a label position computed after the fact) and still land in
the same transformed coordinate space, and `bb`, the [`APBoundingBox`](@ref)
of the drawable area itself (the canvas, centered on the origin, with
`margin` subtracted from every side): handy for e.g. `path(lxm.bb;
action=:clip)`, independent of what the block's own shapes happen to
cover. `lxo` is the second `NamedTuple`, with one field per name in the
block, holding the translated/scaled copy: `lxo.c`, `lxo.s`, or all at
once with `(; c, s) = lxo`. Nothing has to be listed twice, so a shape
built inside the block is returned without writing its name again. The
originals (`c`/`s`/`t` themselves) are untouched: see
[`@to_luxor_picture!`](@ref) for the mutating form. It also destructures by
position, in the order of the block, as a plain tuple would. A name assigned
more than once keeps its last value, in the position of its first appearance
(the earlier values still count for the size of the canvas).

Centering on `(0, 0)` matches Luxor's own `origin()` convention (device
`(0, 0)` moved to the center of the canvas), so the result is ready to
draw right after `origin()`: which `@png`/`@svg`/`@pdf` already call for
you. The shapes are also reflected across the x-axis (`flip=true` by
default): this package's own geometry follows the standard math
convention (y up, counterclockwise angles positive), but Luxor, like
most 2D graphics APIs, draws with y increasing *downward*, so without
this correction everything would render as a vertical mirror image of how
it reads on paper. Pass `flip=false` to get the raw, un-mirrored
coordinates instead (e.g. if you're already deliberately working in
screen/y-down coordinates).

```julia
lxm, lxo = @to_luxor_picture width=400 begin
    c = APCircle2(APPoint(3.0, -1.0), 5.0)
    s = APSegment(APPoint(-2.0, 4.0), APPoint(6.0, -3.0))
end
@png begin
    path(lxo.c; action=:stroke)
    path(lxo.s; action=:stroke)
    label("center", :N, lxm.fct(c.center))   # a point that was never one of the block's shapes
end lxm.width lxm.height
```

Building the `Drawing` by hand instead needs its own `origin()` call
first, since `Drawing` itself doesn't move `(0, 0)`:

```julia
Drawing(lxm.width, lxm.height, "out.png")
origin()
path(lxo.c; action=:stroke)
path(lxo.s; action=:stroke)
finish()
```

Scaling options (mutually exclusive: `scale` cannot be combined with
`width`/`height`):

  - neither given: scale factor `1.0` (the shapes' own coordinate units
    become output units directly, no resizing), the returned canvas size
    is exactly the content size (plus `margin`);
  - `scale`: a literal, uniform multiplier, the returned canvas size is
    *derived* from the scaled content (plus `margin`), same as above;
  - `width` alone (or `height` alone): scaled so that side comes out
    exactly `width` (resp. `height`) minus `margin`, the other side
    following to preserve the aspect ratio, there's never leftover space
    to center away in this case;
  - `width` *and* `height` together: a "contain" fit, scaled by whichever
    of the two is more restrictive, so the content fits inside *both*
    without distortion. The returned canvas is exactly `(width, height)`
    regardless; if the content's aspect ratio doesn't match, it's centered,
    leaving extra blank space on one axis beyond `margin`.

`margin` (default `0.0`) is the minimum blank space guaranteed around the
content on every side, in output units. `flip` (default `true`) is
independent of all of the above: see the note above.

Each line in the block is a name: an assignment `name = expr` (or a
destructuring one, `p, q = expr`, which gives `p` and `q` as separate
names) binds it in the enclosing scope as usual, and the name of a shape
defined earlier can also be written on its own line. Any other bare
expression is an `ArgumentError`: it would have no name to return it under,
so assign it first.

Wrap a line in [`@unbounded`](@ref) (`aux = @unbounded APCircle2(...)`, or
`@unbounded aux = APCircle2(...)`) to still bind/transform it normally
*without* its own `APBoundingBox` counting toward the canvas's sizing:
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
Returns just `(width=w, height=h, fct=fct, bb=bb)`, a `NamedTuple` (see
[`@to_luxor_picture`](@ref) for what `fct`/`bb` give you beyond `width`/
`height`), the shapes are already accessible under their own names. A
bare, unnamed expression has nothing to rebind, so this form rejects it
(same as [`@translate!`](@ref) and the rest of that family).
"""
macro to_luxor_picture!(args...)
    isempty(args) && error("@to_luxor_picture!: missing the shapes block")
    width, height, scale, margin, flip = _parse_picture_kwargs("@to_luxor_picture!", args[1:end-1])
    return _picture_body(true, args[end], width, height, scale, margin, flip)
end
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
                push!(body.args, :(throw(ArgumentError("cannot mutate an unnamed expression: assign it to a variable first"))))
            else
                push!(body.args, :(push!($results, $(make_call(stmt)))))
            end
            n_items += 1
            continue
        end
        run_first && push!(body.args, stmt)
        for name in names
            if mutating
                push!(body.args, :($name = $(make_call(name))), :(push!($results, $name)))
            else
                push!(body.args, :(push!($results, $(make_call(name)))))
            end
            n_items += 1
        end
    end
    push!(body.args, n_items == 1 ? :($results[1]) : :(($results...,)))
    return esc(body)
end
"""
    @translate v begin
        c = APCircle2(...)
        s = APSegment(...)
        t                     # a shape already defined earlier
    end
    @translate v c             # a single shape/expression also works

[`translate`](@ref) every shape named in the block by `v`, returning them
as a tuple in order (`C, S, T = @translate v begin ... end`): `c`/`s`/`t`
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
variable) to its own translated value. `APCircle2`/`APSegment`/... are all
immutable structs, so nothing is changed in place: the object itself
never mutates, only the *variable* is repointed at a new one (the same
trick `Setfield.jl`'s `@set!` uses for immutable structs generally). A
bare *unnamed* expression (nothing to rebind) is an `ArgumentError` in
this form.

When embedding a call to `@translate`/`@rotate`/`@homothety`/`@reflection`
directly inside another expression: as an argument to a function, say
-- wrap it in its own parentheses: `f((@rotate angle p), other_arg)`, not
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

The mutating counterpart of [`@translate`](@ref): see its docstring for
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
a tuple: see [`@translate`](@ref) for the full rundown of how the block
is read (assignments vs. bare references) and what it returns.

    @rotate! angle begin ... end
    @rotate! angle center begin ... end

The mutating form, see [`@translate!`](@ref).
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

The mutating counterpart of [`@rotate`](@ref): see [`@translate!`](@ref)
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
returning them as a tuple: see [`@translate`](@ref) for the full rundown
of how the block is read and what it returns.

    @homothety! k begin ... end
    @homothety! k center begin ... end

The mutating form, see [`@translate!`](@ref).
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

The mutating counterpart of [`@homothety`](@ref): see
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
line, returning them as a tuple: see [`@translate`](@ref) for the full
rundown of how the block is read and what it returns.

    @reflection! about begin ... end

The mutating form, see [`@translate!`](@ref).
"""
macro reflection(about, block)
    _shape_transform_body(false, x -> :(reflection($x, $about)), block)
end
"""
    @reflection! about begin ... end
    @reflection! about c

The mutating counterpart of [`@reflection`](@ref): see
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
`invert` itself): see [`@translate`](@ref) for the full rundown of how
the block is read and what it returns. `invert` can change a shape's own
type (an `APLine` inverts to an `APCircle2` and vice versa): no
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

The mutating counterpart of [`@invert`](@ref): see [`@translate!`](@ref)
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

[`invert_neg`](@ref) every shape named in the block: the negative-ratio
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

The mutating counterpart of [`@invert_neg`](@ref): see
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

Apply the [`APAffineMap`](@ref) `m` to every shape named in the block:
see [`@translate`](@ref) for the full rundown of how the block is read
and what it returns.
"""
macro affinemap(m, block)
    _shape_transform_body(false, x -> :($m($x)), block)
end
"""
    @affinemap! m begin ... end

The mutating counterpart of [`@affinemap`](@ref): see
[`@translate!`](@ref) for what "mutating" means for immutable shapes.
"""
macro affinemap!(m, block)
    _shape_transform_body(true, x -> :($m($x)), block)
end
