# -------------------------------------------------------------------------
# EGPlane3, EGSphere3 (<: EGSurface{3,T}) and a minimal EGCircle3 stub, plus
# every pairwise distance/projection/intersection between EGPoint{3}/
# EGLine{3}/EGPlane3/EGSphere3. Phase 1 of the 3D geometry rollout: see the
# design plan for the full phased roadmap (polyhedra, dihedral angles, full
# 3D conics/arcs and quadric surfaces all come later).
#
# EGCircle3 here is deliberately minimal (center/r/plane only, no arc or
# tangent-line API) -- it exists solely so intersection(::EGPlane3,
# ::EGSphere3)/intersection(::EGSphere3, ::EGSphere3) have a real circle
# type to return instead of an ad-hoc tuple. Full 3D-conic functionality
# (point_on_circle3, tangent lines, EGEllipse3/EGParabola3/EGHyperbola3 and
# their arcs) is its own later phase.
# -------------------------------------------------------------------------

# --- EGPlane3 ---------------------------------------------------------------

"""
    EGPlane3(point::EGPoint{3}, normal::EGVector{3})
    EGPlane3(p1::EGPoint{3}, p2::EGPoint{3}, p3::EGPoint{3}; atol=1e-9)

The infinite plane through `point`, perpendicular to `normal` — the 3D
analogue of [`EGLine`](@ref) (a codimension-1, no-interior-of-its-own
locus; see [`EGSurface`](@ref)). `normal` is normalized on construction, so
`pl.normal` is always a unit vector.

The 3-point form builds the plane through `p1`, `p2`, `p3` (throws an
`ArgumentError` if they're collinear, since then no unique plane passes
through all three) via `normal = cross3(p2-p1, p3-p1)`.
"""
struct EGPlane3{T<:Real} <: EGSurface{3,T}
    point::EGPoint{3,T}
    normal::EGVector{3,T}
    # Defined here, rather than left to the auto-generated default, so that
    # EVERY construction path normalizes `normal` -- Julia would otherwise
    # also auto-generate an outer `EGPlane3(point::EGPoint{3,T},
    # normal::EGVector{3,T}) where T` that's exactly as specific as the
    # normalizing outer constructor below whenever `point`/`normal` already
    # share a T, silently bypassing normalization (the same
    # default-outer-constructor trap `EGAnnularSector2` documents).
    function EGPlane3{T}(point::EGPoint{3,T}, normal::EGVector{3,T}) where {T<:Real}
        return new{T}(point, normal / norm(normal))
    end
end
function EGPlane3(point::EGPointLike, normal::EGVector{3})
    p = _topoint(point)
    T = promote_type(eltype(p), eltype(normal))
    return EGPlane3{T}(convert(EGPoint{3,T}, p), convert(EGVector{3,T}, normal))
end
function EGPlane3(p1::EGPointLike, p2::EGPointLike, p3::EGPointLike; atol=1e-9)
    p1, p2, p3 = _topoint(p1), _topoint(p2), _topoint(p3)
    u, v = p2 - p1, p3 - p1
    n = cross3(u, v)
    norm(n) <= atol * max(norm(u) * norm(v), 1.0) &&
        throw(ArgumentError("EGPlane3: p1, p2, p3 must not be collinear (no unique plane through them)"))
    return EGPlane3(p1, n)
end

Base.:(==)(a::EGPlane3, b::EGPlane3) = a.point == b.point && a.normal == b.normal
Base.convert(::Type{EGPlane3{T}}, pl::EGPlane3) where {T} =
    EGPlane3{T}(convert(EGPoint{3,T}, pl.point), convert(EGVector{3,T}, pl.normal))
Base.isapprox(a::EGPlane3, b::EGPlane3; kwargs...) =
    isapprox(a.point, b.point; kwargs...) && isapprox(a.normal, b.normal; kwargs...)
Base.show(io::IO, pl::EGPlane3) = print(io, "EGPlane3(", pl.point, ", n=", pl.normal, ")")

_signed_distance(p::EGPoint{3}, pl::EGPlane3) = dot(p - pl.point, pl.normal)

"""
    distance(p::EGPoint{3}, pl::EGPlane3)

Perpendicular distance from `p` to `pl`.
"""
distance(p::EGPoint{3}, pl::EGPlane3) = abs(_signed_distance(p, pl))
distance(pl::EGPlane3, p::EGPoint{3}) = distance(p, pl)

"""
    side_of_plane(p::EGPoint{3}, pl::EGPlane3)

`+1` if `p` is on the side `pl.normal` points towards, `-1` if on the
other side, `0` if `p` is on `pl` — the 3D analogue of
[`side_of_line`](@ref).
"""
function side_of_plane(p::EGPoint{3}, pl::EGPlane3)
    d = _signed_distance(p, pl)
    return d > 0 ? 1 : (d < 0 ? -1 : 0)
end

"""
    on_plane(p::EGPoint{3}, pl::EGPlane3; atol=1e-9)

Whether `p` lies exactly on `pl` — the 3D analogue of [`on_line`](@ref).
"""
on_plane(p::EGPoint{3}, pl::EGPlane3; atol=1e-9) =
    distance(p, pl) <= sqrt(atol) * max(norm(p), norm(pl.point), 1.0)

"""
    projection(p::EGPoint{3}, pl::EGPlane3)

The foot of the perpendicular from `p` onto `pl`.
"""
projection(p::EGPoint{3}, pl::EGPlane3) = p - _signed_distance(p, pl) * pl.normal
projection(pl::EGPlane3) = p -> projection(p, pl)

"""
    reflection(p::EGPoint{3}, about::EGPlane3)

Mirror `p` across the plane `about` — the true 3D mirror reflection (see
the package docs for why there is deliberately no
`reflection(::EGPoint{3}, ::EGLine{3})`: reflecting across a line isn't a
well-defined rigid motion once the line's orthogonal complement is a whole
plane rather than a single direction).
"""
reflection(p::EGPoint{3}, about::EGPlane3) = p - 2 * _signed_distance(p, about) * about.normal

"""
    reflection(v::EGVector{3}, about::EGPlane3)

Mirror the direction `v` across `about`'s orientation (only `about.normal`
matters, not its `point` -- a free vector has no position for that to
act on) -- the 3D sibling of `reflection(::EGVector{2}, ::EGLine)`.
"""
reflection(v::EGVector{3}, about::EGPlane3) = v - 2 * dot(v, about.normal) * about.normal

"""
    rotate(pl::EGPlane3, angle::Real, axis::EGLine{3})
    translate(pl::EGPlane3, v::EGVector{3})
    homothety(pl::EGPlane3, k::Real, center::EGPoint{3}=EGPoint(0.0,0.0,0.0))
    reflection(pl::EGPlane3, about)

`rotate`/`translate`/`homothety`/`reflection` for `EGPlane3`, each acting
on `point`/`normal` pointwise. **Unlike every 2D `homothety`** (where a
negative `k` never reverses orientation — `k²` is always positive), a 3D
homothety's linear part has determinant `k³`, which *is* negative for
`k < 0` — a genuinely orientation-reversing map in 3D. So `normal` picks
up a `sign(k)` flip here (harmless for the bare plane *as a set*, which
doesn't care which way `normal` points, but load-bearing for anything
built on top that treats `normal` as meaningful, like
[`EGHalfSpace3`](@ref)/[`EGDihedralAngle3`](@ref)).
"""
rotate(pl::EGPlane3, angle::Real, axis::EGLine{3}) = EGPlane3(rotate(pl.point, angle, axis), rotate(pl.normal, angle, axis))
translate(pl::EGPlane3, v::EGVector{3}) = EGPlane3(translate(pl.point, v), pl.normal)
homothety(pl::EGPlane3, k::Real, center::EGPoint{3}=EGPoint(0.0, 0.0, 0.0)) = EGPlane3(homothety(pl.point, k, center), sign(k) * pl.normal)
reflection(pl::EGPlane3, about::EGPoint{3}) = EGPlane3(reflection(pl.point, about), -pl.normal)
reflection(pl::EGPlane3, about::EGPlane3) = EGPlane3(reflection(pl.point, about), reflection(pl.normal, about))

# --- EGSphere3 ---------------------------------------------------------------

"""
    EGSphere3(center::EGPoint{3}, r::Real)
"""
struct EGSphere3{T<:Real} <: EGSurface{3,T}
    center::EGPoint{3,T}
    r::T
end
function EGSphere3(center::EGPointLike, r::Real)
    c = _topoint(center)
    T = promote_type(eltype(c), typeof(r))
    return EGSphere3{T}(convert(EGPoint{3,T}, c), T(r))
end

Base.:(==)(a::EGSphere3, b::EGSphere3) = a.center == b.center && a.r == b.r
Base.convert(::Type{EGSphere3{T}}, s::EGSphere3) where {T} = EGSphere3{T}(convert(EGPoint{3,T}, s.center), T(s.r))
Base.isapprox(a::EGSphere3, b::EGSphere3; kwargs...) = isapprox(a.center, b.center; kwargs...) && isapprox(a.r, b.r; kwargs...)
Base.show(io::IO, s::EGSphere3) = print(io, "EGSphere3(", s.center, ", ", s.r, ")")

"""
    volume(sph::EGSphere3)

The volume of the ball `sph` encloses, `(4/3)*π*r³` — the 3D analogue of
[`area`](@ref)`(::EGCircle2)`.
"""
volume(sph::EGSphere3) = (4 / 3) * pi * sph.r^3

"""
    surface_area(sph::EGSphere3)

The surface area of `sph` itself, `4πr²` — the 3D analogue of
[`perimeter`](@ref)`(::EGCircle2)`.
"""
surface_area(sph::EGSphere3) = 4 * pi * sph.r^2

centroid(sph::EGSphere3) = sph.center

"""
    on_sphere(p::EGPoint{3}, sph::EGSphere3; atol=1e-9)

Whether `p` lies exactly on `sph`.
"""
on_sphere(p::EGPoint{3}, sph::EGSphere3; atol=1e-9) =
    abs(distance(p, sph.center) - sph.r) <= sqrt(atol) * max(sph.r, norm(sph.center), 1.0)

"""
    distance(p::EGPoint{3}, sph::EGSphere3; mode::Symbol=:region)

Distance from `p` to the ball `sph` encloses. With `mode = :region` (the
default), `0.0` when `p` is inside or on `sph`, otherwise the distance to
the nearest point on the surface. With `mode = :boundary`, always the
distance to the surface itself, even from inside — same convention as
[`distance(::EGPoint, ::EGPolygon)`](@ref).
"""
function distance(p::EGPoint{3}, sph::EGSphere3; mode::Symbol=:region)
    _check_distance_mode(mode)
    d = abs(distance(p, sph.center) - sph.r)
    mode == :boundary && return d
    return distance(p, sph.center) <= sph.r ? zero(d) : d
end
distance(sph::EGSphere3, p::EGPoint{3}; mode::Symbol=:region) = distance(p, sph; mode=mode)

"""
    rotate(sph::EGSphere3, angle::Real, axis::EGLine{3})
    translate(sph::EGSphere3, v::EGVector{3})
    homothety(sph::EGSphere3, k::Real, center::EGPoint{3}=EGPoint(0.0,0.0,0.0))
    reflection(sph::EGSphere3, about)

A sphere's radius has no orientation to preserve, so all four just move
`center` and (for `homothety`) scale `r` by `abs(k)`.
"""
rotate(sph::EGSphere3, angle::Real, axis::EGLine{3}) = EGSphere3(rotate(sph.center, angle, axis), sph.r)
translate(sph::EGSphere3, v::EGVector{3}) = EGSphere3(translate(sph.center, v), sph.r)
homothety(sph::EGSphere3, k::Real, center::EGPoint{3}=EGPoint(0.0, 0.0, 0.0)) = EGSphere3(homothety(sph.center, k, center), abs(k) * sph.r)
reflection(sph::EGSphere3, about::Union{EGPoint{3},EGPlane3}) = EGSphere3(reflection(sph.center, about), sph.r)

# --- EGCircle3 (minimal stub -- see file header) -----------------------------

"""
    EGCircle3(center::EGPoint{3}, r::Real, normal::EGVector{3})

A circle of radius `r` centered at `center`, lying in the plane through
`center` perpendicular to `normal` (`normal` is normalized on
construction). Stores `center`/`r`/`normal` only — **not** a full
[`EGPlane3`](@ref) — since a plane's own `point` field would just
duplicate `center`; use [`plane`](@ref)`(c)` to build the supporting
`EGPlane3` on demand. Deliberately minimal otherwise too — see the
file-level note on why the fuller 3D-conic API is a later phase.
"""
struct EGCircle3{T<:Real} <: EGCurve{3,T}
    center::EGPoint{3,T}
    r::T
    normal::EGVector{3,T}
    # Same reasoning as EGPlane3's inner constructor: defined here so every
    # construction path normalizes `normal`, rather than relying on the
    # auto-generated default (which would silently skip it whenever
    # center/r/normal already share a T).
    function EGCircle3{T}(center::EGPoint{3,T}, r::T, normal::EGVector{3,T}) where {T<:Real}
        return new{T}(center, r, normal / norm(normal))
    end
end
function EGCircle3(center::EGPointLike, r::Real, normal::EGVector{3})
    c = _topoint(center)
    T = promote_type(eltype(c), typeof(r), eltype(normal))
    return EGCircle3{T}(convert(EGPoint{3,T}, c), T(r), convert(EGVector{3,T}, normal))
end

Base.:(==)(a::EGCircle3, b::EGCircle3) = a.center == b.center && a.r == b.r && a.normal == b.normal
Base.isapprox(a::EGCircle3, b::EGCircle3; kwargs...) =
    isapprox(a.center, b.center; kwargs...) && isapprox(a.r, b.r; kwargs...) && isapprox(a.normal, b.normal; kwargs...)
Base.show(io::IO, c::EGCircle3) = print(io, "EGCircle3(", c.center, ", ", c.r, ", n=", c.normal, ")")

"""
    plane(c::EGCircle3)

The supporting [`EGPlane3`](@ref) of `c` (through `c.center`,
perpendicular to `c.normal`) — computed on demand rather than stored, to
avoid duplicating `c.center` in a nested `EGPlane3.point` field.
"""
plane(c::EGCircle3) = EGPlane3(c.center, c.normal)

area(c::EGCircle3) = pi * c.r^2
perimeter(c::EGCircle3) = 2 * pi * c.r
centroid(c::EGCircle3) = c.center

"""
    rotate(c::EGCircle3, angle::Real, axis::EGLine{3})
    translate(c::EGCircle3, v::EGVector{3})
    homothety(c::EGCircle3, k::Real, center::EGPoint{3}=EGPoint(0.0,0.0,0.0))
    reflection(c::EGCircle3, about)

`center`/`normal` transform pointwise (same convention as `EGPlane3`,
including the `sign(k)` flip of `normal` under `homothety` — see its
docstring for why a negative `k` is orientation-reversing in 3D);
`homothety` scales `r` by `abs(k)`.
"""
rotate(c::EGCircle3, angle::Real, axis::EGLine{3}) = EGCircle3(rotate(c.center, angle, axis), c.r, rotate(c.normal, angle, axis))
translate(c::EGCircle3, v::EGVector{3}) = EGCircle3(translate(c.center, v), c.r, c.normal)
homothety(c::EGCircle3, k::Real, center::EGPoint{3}=EGPoint(0.0, 0.0, 0.0)) = EGCircle3(homothety(c.center, k, center), abs(k) * c.r, sign(k) * c.normal)
reflection(c::EGCircle3, about::EGPoint{3}) = EGCircle3(reflection(c.center, about), c.r, -c.normal)
reflection(c::EGCircle3, about::EGPlane3) = EGCircle3(reflection(c.center, about), c.r, reflection(c.normal, about))

# --- Line <-> Plane -----------------------------------------------------------

"""
    intersection(l::EGLine{3}, pl::EGPlane3; atol=1e-9)

Where `l` crosses `pl`. Returns a `Vector{EGPoint{3,Float64}}` with 0 or 1
points (0 when `l` is parallel to -- and not contained in -- `pl`). Throws
an `ArgumentError` if `l` lies entirely in `pl` (infinitely many
intersection points, not representable as a finite `Vector`).
"""
function intersection(l::EGLine{3}, pl::EGPlane3; atol=1e-9)
    d = direction(l)
    denom = dot(d, pl.normal)
    tol = sqrt(atol) * max(norm(d), 1.0)
    if abs(denom) <= tol
        on_plane(l.p1, pl; atol=atol) &&
            throw(ArgumentError("intersection: l lies entirely in pl (infinitely many points)"))
        return EGPoint{3,Float64}[]
    end
    t = _signed_distance(l.p1, pl) / -denom
    q = l.p1 + t * d
    return [EGPoint(q[1], q[2], q[3])]
end
intersection(pl::EGPlane3, l::EGLine{3}; atol=1e-9) = intersection(l, pl; atol=atol)

# --- Plane <-> Plane -----------------------------------------------------------

"""
    intersection(pl1::EGPlane3, pl2::EGPlane3; atol=1e-9)

Where `pl1` and `pl2` cross: an `EGLine{3,Float64}` in general, or
`nothing` if they're parallel (including coincident -- like
[`intersection(::EGLine,::EGLine)`](@ref), a whole shared plane isn't a
single answer, so it isn't special-cased). Unlike every `intersection`
method between two 2D shapes, this is the first one in the package that
*doesn't* return a `Vector{EGPoint}` -- two planes generically meet in an
infinite line, not a finite set of points.
"""
function intersection(pl1::EGPlane3, pl2::EGPlane3; atol=1e-9)
    n1, n2 = pl1.normal, pl2.normal
    dirvec = cross3(n1, n2)
    norm(dirvec) <= sqrt(atol) && return nothing

    d1, d2 = dot(n1, pl1.point), dot(n2, pl2.point)
    c = dot(n1, n2)
    denom = 1 - c^2
    p0 = ((d1 - d2 * c) * n1 + (d2 - d1 * c) * n2) / denom
    p0 = EGPoint(p0[1], p0[2], p0[3])
    return EGLine(p0, p0 + dirvec)
end

"""
    distance(pl1::EGPlane3, pl2::EGPlane3)

`0.0` if `pl1`/`pl2` intersect (or coincide), otherwise the perpendicular
distance between the two parallel planes.
"""
function distance(pl1::EGPlane3, pl2::EGPlane3)
    intersection(pl1, pl2) !== nothing && return 0.0
    return distance(pl2.point, pl1)
end

"""
    distance(l::EGLine{3}, pl::EGPlane3)

`0.0` if `l` crosses (or lies in) `pl`, otherwise the perpendicular
distance from `l` (constant along its whole length) to `pl`.
"""
function distance(l::EGLine{3}, pl::EGPlane3)
    tol = sqrt(eps(Float64)) * max(norm(direction(l)), 1.0)
    abs(dot(direction(l), pl.normal)) > tol && return 0.0
    return distance(l.p1, pl)
end
distance(pl::EGPlane3, l::EGLine{3}) = distance(l, pl)

# --- Line <-> Line (3D: parallel / intersecting / skew) ------------------------

"""
    intersection(l1::EGLine{3}, l2::EGLine{3}; atol=1e-9)

Where `l1` and `l2` cross. Returns a `Vector{EGPoint{3,Float64}}` with 0 or
1 points: empty when they're parallel *or* skew (see
[`line_line_position`](@ref) to tell those apart from a genuine crossing),
a single point when they're coplanar and not parallel.
"""
function intersection(l1::EGLine{3}, l2::EGLine{3}; atol=1e-9)
    pos = line_line_position(l1, l2; atol=atol)
    pos in (:parallel, :skew, :coincident) && return EGPoint{3,Float64}[]
    d1, d2 = direction(l1), direction(l2)
    n = cross3(d1, d2)
    t = dot(cross3(l2.p1 - l1.p1, d2), n) / dot(n, n)
    q = l1.p1 + t * d1
    return [EGPoint(q[1], q[2], q[3])]
end

"""
    distance(l1::EGLine{3}, l2::EGLine{3})

Distance between `l1` and `l2`: `0.0` if they intersect, the constant
perpendicular gap if parallel, or the (also constant) shortest distance
between the two skew lines otherwise.
"""
function distance(l1::EGLine{3}, l2::EGLine{3}; atol=1e-9)
    d1, d2 = direction(l1), direction(l2)
    n = cross3(d1, d2)
    tol = sqrt(atol) * max(norm(d1) * norm(d2), 1.0)
    norm(n) <= tol && return distance(l2.p1, l1)
    return abs(dot(l2.p1 - l1.p1, n)) / norm(n)
end

# --- Plane <-> Sphere, Sphere <-> Sphere, Line <-> Sphere ----------------------

"""
    intersection(pl::EGPlane3, sph::EGSphere3; atol=1e-9)

Where `pl` cuts `sph`: `nothing` (disjoint), a single `EGPoint{3,Float64}`
(tangent), or an [`EGCircle3`](@ref) (the general case).
"""
function intersection(pl::EGPlane3, sph::EGSphere3; atol=1e-9)
    d = _signed_distance(sph.center, pl)
    tol = sqrt(atol) * max(sph.r, norm(sph.center), 1.0)
    abs(d) > sph.r + tol && return nothing
    foot = sph.center - d * pl.normal
    abs(abs(d) - sph.r) <= tol && return EGPoint(foot[1], foot[2], foot[3])
    r2 = sqrt(max(sph.r^2 - d^2, 0.0))
    return EGCircle3(foot, r2, pl.normal)
end
intersection(sph::EGSphere3, pl::EGPlane3; atol=1e-9) = intersection(pl, sph; atol=atol)

"""
    intersection(sph1::EGSphere3, sph2::EGSphere3; atol=1e-9)

Where `sph1` and `sph2` meet: `nothing` (disjoint, or concentric with no
solution), a single `EGPoint{3,Float64}` (tangent), or an
[`EGCircle3`](@ref) (the general case) -- **not** a `Vector{EGPoint}` like
[`intersection(::EGCircle2,::EGCircle2)`](@ref): two spheres generically
meet in a whole circle, never just 1 or 2 points.
"""
function intersection(sph1::EGSphere3, sph2::EGSphere3; atol=1e-9)
    r1, r2 = sph1.r, sph2.r
    d = distance(sph1.center, sph2.center)
    tol = sqrt(atol) * max(r1, r2, 1.0)

    d <= atol * max(r1, r2, 1.0) && return nothing
    (d > r1 + r2 + tol || d < abs(r1 - r2) - tol) && return nothing

    u = (sph2.center - sph1.center) / d
    a = (r1^2 - r2^2 + d^2) / (2d)
    m = sph1.center + a * u
    h = sqrt(max(r1^2 - a^2, 0.0))

    h <= tol && return EGPoint(m[1], m[2], m[3])
    return EGCircle3(m, h, EGVector(u[1], u[2], u[3]))
end

"""
    intersection(l::EGLine{3}, sph::EGSphere3; atol=1e-9)

Intersection points of `l` and `sph`. Returns a `Vector{EGPoint{3,Float64}}`
with 0, 1 or 2 points -- the 3D analogue of
[`intersection(::EGLine,::EGCircle2)`](@ref).
"""
function intersection(l::EGLine{3}, sph::EGSphere3; atol=1e-9)
    f = projection(sph.center, l)
    d = distance(sph.center, f)
    r = sph.r
    tol = sqrt(atol) * max(r, norm(sph.center), 1.0)

    d > r + tol && return EGPoint{3,Float64}[]

    u = direction(l) / norm(direction(l))
    abs(d - r) <= tol && return [EGPoint(f[1], f[2], f[3])]

    h = sqrt(max(r^2 - d^2, 0.0))
    p1, p2 = f - h * u, f + h * u
    return [EGPoint(p1[1], p1[2], p1[3]), EGPoint(p2[1], p2[2], p2[3])]
end
intersection(sph::EGSphere3, l::EGLine{3}; atol=1e-9) = intersection(l, sph; atol=atol)

# --- EGSegment{3}/EGRay{3} <-> EGPlane3 ----------------------------------------

"""
    distance(s::EGSegment{3}, pl::EGPlane3)

`0.0` if `s` crosses (or touches) `pl`, otherwise the smaller of its two
endpoint distances (valid since a plane's signed distance is linear along
any straight path, so its magnitude is monotonic between two same-signed
endpoints).
"""
function distance(s::EGSegment{3}, pl::EGPlane3)
    d1, d2 = _signed_distance(s.p1, pl), _signed_distance(s.p2, pl)
    (d1 >= 0) != (d2 >= 0) && return 0.0
    return min(abs(d1), abs(d2))
end
distance(pl::EGPlane3, s::EGSegment{3}) = distance(s, pl)

"""
    distance(r::EGRay{3}, pl::EGPlane3)

`0.0` if `r` crosses `pl` somewhere along its forward direction,
otherwise the distance from `r.origin` (the closest point on `r` when it
never reaches `pl`, since the signed distance is then monotonic along the
whole ray).
"""
function distance(r::EGRay{3}, pl::EGPlane3)
    d0 = _signed_distance(r.origin, pl)
    dv = dot(direction(r), pl.normal)
    tol = sqrt(eps(Float64))
    abs(dv) <= tol && return abs(d0)
    return -d0 / dv >= -tol ? 0.0 : abs(d0)
end
distance(pl::EGPlane3, r::EGRay{3}) = distance(r, pl)

"""
    intersection(s::EGSegment{3}, pl::EGPlane3; atol=1e-9)

Where `s` crosses `pl` (0 or 1 points, filtered from
[`intersection(::EGLine{3},::EGPlane3)`](@ref) to `s`'s own finite range).
"""
function intersection(s::EGSegment{3}, pl::EGPlane3; atol=1e-9)
    pts = intersection(EGLine(s.p1, s.p2), pl; atol=atol)
    isempty(pts) && return pts
    d = s.p2 - s.p1
    t = dot(pts[1] - s.p1, d) / dot(d, d)
    return (-sqrt(atol) <= t <= 1 + sqrt(atol)) ? pts : EGPoint{3,Float64}[]
end
intersection(pl::EGPlane3, s::EGSegment{3}; atol=1e-9) = intersection(s, pl; atol=atol)

"""
    intersection(r::EGRay{3}, pl::EGPlane3; atol=1e-9)

Where `r` crosses `pl` (0 or 1 points, filtered from
[`intersection(::EGLine{3},::EGPlane3)`](@ref) to `r`'s own forward
direction).
"""
function intersection(r::EGRay{3}, pl::EGPlane3; atol=1e-9)
    pts = intersection(EGLine(r.origin, r.through), pl; atol=atol)
    isempty(pts) && return pts
    d = r.through - r.origin
    t = dot(pts[1] - r.origin, d) / dot(d, d)
    return t >= -sqrt(atol) ? pts : EGPoint{3,Float64}[]
end
intersection(pl::EGPlane3, r::EGRay{3}; atol=1e-9) = intersection(r, pl; atol=atol)

# --- EGSegment{3}/EGRay{3} <-> EGSphere3 ---------------------------------------

"""
    intersection(s::EGSegment{3}, sph::EGSphere3; atol=1e-9)

Intersection points of `s` and `sph`, filtered from
[`intersection(::EGLine{3},::EGSphere3)`](@ref) to `s`'s own finite range
-- 0, 1 or 2 points.
"""
function intersection(s::EGSegment{3}, sph::EGSphere3; atol=1e-9)
    pts = intersection(EGLine(s.p1, s.p2), sph; atol=atol)
    isempty(pts) && return pts
    d = s.p2 - s.p1
    dd = dot(d, d)
    tol = sqrt(atol)
    return filter(p -> -tol <= dot(p - s.p1, d) / dd <= 1 + tol, pts)
end
intersection(sph::EGSphere3, s::EGSegment{3}; atol=1e-9) = intersection(s, sph; atol=atol)

"""
    intersection(r::EGRay{3}, sph::EGSphere3; atol=1e-9)

Intersection points of `r` and `sph`, filtered from
[`intersection(::EGLine{3},::EGSphere3)`](@ref) to `r`'s own forward
direction -- 0, 1 or 2 points.
"""
function intersection(r::EGRay{3}, sph::EGSphere3; atol=1e-9)
    pts = intersection(EGLine(r.origin, r.through), sph; atol=atol)
    isempty(pts) && return pts
    d = r.through - r.origin
    dd = dot(d, d)
    tol = sqrt(atol)
    return filter(p -> dot(p - r.origin, d) / dd >= -tol, pts)
end
intersection(sph::EGSphere3, r::EGRay{3}; atol=1e-9) = intersection(r, sph; atol=atol)

"""
    distance(s::EGSegment{3}, sph::EGSphere3; mode::Symbol=:region)

Distance from `s` to the ball `sph` encloses, with the same
`mode = :region`/`:boundary` convention as
[`distance(::EGPoint,::EGSphere3)`](@ref): `0.0` whenever `s` touches or
crosses `sph`'s surface (checked directly via
[`intersection(::EGSegment{3},::EGSphere3)`](@ref) first, since a segment
can pass all the way through a sphere and back out, unlike an unbounded
line where "closest point to the center" always finds it); otherwise the
mode-appropriate distance from `s`'s own closest point to `sph.center`.
"""
function distance(s::EGSegment{3}, sph::EGSphere3; mode::Symbol=:region)
    _check_distance_mode(mode)
    !isempty(intersection(s, sph)) && return 0.0
    # No intersection means the WHOLE segment is on one side of the sphere's
    # surface -- but which side changes which endpoint is relevant: entirely
    # outside, the *closest*-to-center point is also closest to the surface
    # (distance-to-surface is a monotonic function of distance-to-center
    # there); entirely inside, it's the OPPOSITE -- distance-to-surface is
    # SMALLEST at whichever point is *farthest* from the center, and since
    # distance-to-center is convex along a straight segment, that farthest
    # point is always one of the two endpoints.
    inside = distance(s.p1, sph.center) < sph.r
    if inside
        bd = sph.r - max(distance(s.p1, sph.center), distance(s.p2, sph.center))
    else
        d = s.p2 - s.p1
        t = clamp(dot(sph.center - s.p1, d) / dot(d, d), 0.0, 1.0)
        bd = distance(s.p1 + t * d, sph.center) - sph.r
    end
    mode == :boundary && return bd
    return inside ? zero(bd) : bd
end
distance(sph::EGSphere3, s::EGSegment{3}; mode::Symbol=:region) = distance(s, sph; mode=mode)

"""
    distance(r::EGRay{3}, sph::EGSphere3; mode::Symbol=:region)

The `EGRay{3}` analogue of [`distance(::EGSegment{3},::EGSphere3)`](@ref).
"""
function distance(r::EGRay{3}, sph::EGSphere3; mode::Symbol=:region)
    _check_distance_mode(mode)
    !isempty(intersection(r, sph)) && return 0.0
    d = r.through - r.origin
    t = max(dot(sph.center - r.origin, d) / dot(d, d), 0.0)
    return distance(r.origin + t * d, sph; mode=mode)
end
distance(sph::EGSphere3, r::EGRay{3}; mode::Symbol=:region) = distance(r, sph; mode=mode)
