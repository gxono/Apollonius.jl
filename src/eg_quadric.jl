# -------------------------------------------------------------------------
# EGEllipsoid3, EGParaboloid3, EGHyperboloid3 (1 or 2 sheets),
# EGHyperbolicParaboloid3 (<: EGSurface{3,T}) -- the genuinely-3D-only
# quadric surfaces. Unlike every other conic/curve type in this package,
# these have NO 2D analogue to port from (a saddle surface is a
# phenomenon that only exists once you have 3 dimensions to bend into),
# so this file is new design rather than a generalization of existing
# code. Deliberately minimal API: constructors, membership, a
# parametrization, and the transform quartet -- no `intersection`/
# `distance` (a genuinely large undertaking per quadric pair, left for a
# later pass), and `surface_area` only where a closed form exists
# (nowhere here except the sphere, already covered by `EGSphere3`) or a
# well-known, explicitly-labeled *approximation* exists (the ellipsoid).
# -------------------------------------------------------------------------

# --- EGEllipsoid3 -----------------------------------------------------------

"""
    EGEllipsoid3(center::EGPoint{3}, a::Real, b::Real, c::Real, u::EGVector{3}, v::EGVector{3})

An ellipsoid centered at `center` with semi-axes `a` (along `u`), `b`
(along `v`), `c` (along `cross3(u,v)`) -- the 3D generalization of
[`EGEllipse2`](@ref)/[`EGEllipse3`](@ref) one dimension up. `v` is
auto-orthogonalized against `u` (both normalized), the same convention as
[`EGEllipse3`](@ref)'s `u`.
"""
struct EGEllipsoid3{T<:Real} <: EGSurface{3,T}
    center::EGPoint{3,T}
    a::T
    b::T
    c::T
    u::EGVector{3,T}
    v::EGVector{3,T}
    function EGEllipsoid3{T}(center::EGPoint{3,T}, a::T, b::T, c::T, u::EGVector{3,T}, v::EGVector{3,T}) where {T<:Real}
        un = u / norm(u)
        vp = v - dot(v, un) * un
        return new{T}(center, a, b, c, un, vp / norm(vp))
    end
end
function EGEllipsoid3(center::EGPointLike, a::Real, b::Real, c::Real, u::EGVector{3}, v::EGVector{3})
    ctr = _topoint(center)
    T = promote_type(eltype(ctr), typeof(a), typeof(b), typeof(c), eltype(u), eltype(v))
    return EGEllipsoid3{T}(convert(EGPoint{3,T}, ctr), T(a), T(b), T(c), convert(EGVector{3,T}, u), convert(EGVector{3,T}, v))
end

Base.:(==)(x::EGEllipsoid3, y::EGEllipsoid3) =
    x.center == y.center && x.a == y.a && x.b == y.b && x.c == y.c && x.u == y.u && x.v == y.v
Base.show(io::IO, e::EGEllipsoid3) = print(io, "EGEllipsoid3(center=", e.center, ", a=", e.a, ", b=", e.b, ", c=", e.c, ")")

_ellipsoid3_frame(e::EGEllipsoid3) = (e.u, e.v, cross3(e.u, e.v))

"""
    point_on_ellipsoid3(e::EGEllipsoid3, θ::Real, φ::Real)

The point at spherical parameters `θ` (polar, from the `w = cross3(u,v)`
axis) and `φ` (azimuthal, in the `u`-`v` plane).
"""
function point_on_ellipsoid3(e::EGEllipsoid3, θ::Real, φ::Real)
    u, v, w = _ellipsoid3_frame(e)
    return e.center + e.a * sin(θ) * cos(φ) * u + e.b * sin(θ) * sin(φ) * v + e.c * cos(θ) * w
end

"""
    is_on_ellipsoid3(p::EGPoint{3}, e::EGEllipsoid3; atol=1e-9)
"""
function is_on_ellipsoid3(p::EGPoint{3}, e::EGEllipsoid3; atol=1e-9)
    u, v, w = _ellipsoid3_frame(e)
    d = p - e.center
    lx, ly, lz = dot(d, u), dot(d, v), dot(d, w)
    return abs((lx / e.a)^2 + (ly / e.b)^2 + (lz / e.c)^2 - 1) <= atol
end

"""
    volume(e::EGEllipsoid3)

The volume enclosed by `e`, `(4/3)πabc` -- exact.
"""
volume(e::EGEllipsoid3) = (4 / 3) * pi * e.a * e.b * e.c

"""
    surface_area(e::EGEllipsoid3)

**Approximate** surface area of `e`, via Thomsen's formula
`4π·((aᵖbᵖ + aᵖcᵖ + bᵖcᵖ)/3)^(1/p)` with `p ≈ 1.6075` — unlike every other
`surface_area`/`area`/`perimeter` in this package, a general ellipsoid's
true surface area has no elementary closed form at all (it's a genuine
elliptic integral), and Thomsen's approximation is only guaranteed
accurate to within about 1.06% relative error, not exact.
"""
function surface_area(e::EGEllipsoid3)
    p = 1.6075
    return 4 * pi * ((e.a^p * e.b^p + e.a^p * e.c^p + e.b^p * e.c^p) / 3)^(1 / p)
end

centroid(e::EGEllipsoid3) = e.center

rotate(e::EGEllipsoid3, angle::Real, axis::EGLine{3}) =
    EGEllipsoid3(rotate(e.center, angle, axis), e.a, e.b, e.c, rotate(e.u, angle, axis), rotate(e.v, angle, axis))
translate(e::EGEllipsoid3, v::EGVector{3}) = EGEllipsoid3(translate(e.center, v), e.a, e.b, e.c, e.u, e.v)
homothety(e::EGEllipsoid3, k::Real, center::EGPoint{3}=EGPoint(0.0, 0.0, 0.0)) =
    EGEllipsoid3(homothety(e.center, k, center), abs(k) * e.a, abs(k) * e.b, abs(k) * e.c, e.u, e.v)
reflection(e::EGEllipsoid3, about) = EGEllipsoid3(reflection(e.center, about), e.a, e.b, e.c, reflection(e.u, about), reflection(e.v, about))

# --- EGParaboloid3 (elliptic paraboloid) --------------------------------------

"""
    EGParaboloid3(vertex::EGPoint{3}, a::Real, b::Real, axis::EGVector{3}, u::EGVector{3})

The elliptic paraboloid `z = (x/a)² + (y/b)²` in the local frame at
`vertex` with `axis` (`z`) as the opening direction and `u` (`x`)
perpendicular to it -- the 3D-only surface swept by "stacking" scaled
copies of an [`EGParabola2`](@ref)-like profile around `axis` (an
elliptic, not circular, cross-section in general, since `a` and `b` can
differ).
"""
struct EGParaboloid3{T<:Real} <: EGSurface{3,T}
    vertex::EGPoint{3,T}
    a::T
    b::T
    axis::EGVector{3,T}
    u::EGVector{3,T}
    function EGParaboloid3{T}(vertex::EGPoint{3,T}, a::T, b::T, axis::EGVector{3,T}, u::EGVector{3,T}) where {T<:Real}
        axn = axis / norm(axis)
        up = u - dot(u, axn) * axn
        return new{T}(vertex, a, b, axn, up / norm(up))
    end
end
function EGParaboloid3(vertex::EGPointLike, a::Real, b::Real, axis::EGVector{3}, u::EGVector{3})
    v = _topoint(vertex)
    T = promote_type(eltype(v), typeof(a), typeof(b), eltype(axis), eltype(u))
    return EGParaboloid3{T}(convert(EGPoint{3,T}, v), T(a), T(b), convert(EGVector{3,T}, axis), convert(EGVector{3,T}, u))
end

Base.:(==)(x::EGParaboloid3, y::EGParaboloid3) = x.vertex == y.vertex && x.a == y.a && x.b == y.b && x.axis == y.axis && x.u == y.u
Base.show(io::IO, p::EGParaboloid3) = print(io, "EGParaboloid3(vertex=", p.vertex, ", a=", p.a, ", b=", p.b, ")")

_paraboloid3_frame(p::EGParaboloid3) = (p.u, cross3(p.axis, p.u), p.axis)

"""
    point_on_paraboloid3(par::EGParaboloid3, r::Real, φ::Real)

The point at radial-like parameter `r` and azimuthal angle `φ`
(`x = a·r·cosφ`, `y = b·r·sinφ`, `z = r²`).
"""
function point_on_paraboloid3(par::EGParaboloid3, r::Real, φ::Real)
    u, w, axis = _paraboloid3_frame(par)
    return par.vertex + par.a * r * cos(φ) * u + par.b * r * sin(φ) * w + r^2 * axis
end

"""
    is_on_paraboloid3(p::EGPoint{3}, par::EGParaboloid3; atol=1e-9)
"""
function is_on_paraboloid3(p::EGPoint{3}, par::EGParaboloid3; atol=1e-9)
    u, w, axis = _paraboloid3_frame(par)
    d = p - par.vertex
    lx, ly, lz = dot(d, u), dot(d, w), dot(d, axis)
    return abs(lz - ((lx / par.a)^2 + (ly / par.b)^2)) <= atol
end

rotate(p::EGParaboloid3, angle::Real, axis::EGLine{3}) =
    EGParaboloid3(rotate(p.vertex, angle, axis), p.a, p.b, rotate(p.axis, angle, axis), rotate(p.u, angle, axis))
translate(p::EGParaboloid3, v::EGVector{3}) = EGParaboloid3(translate(p.vertex, v), p.a, p.b, p.axis, p.u)
homothety(p::EGParaboloid3, k::Real, center::EGPoint{3}=EGPoint(0.0, 0.0, 0.0)) =
    EGParaboloid3(homothety(p.vertex, k, center), abs(k) * p.a, abs(k) * p.b, p.axis, p.u)
reflection(p::EGParaboloid3, about) = EGParaboloid3(reflection(p.vertex, about), p.a, p.b, reflection(p.axis, about), reflection(p.u, about))

# --- EGHyperboloid3 (1 or 2 sheets) --------------------------------------------

"""
    EGHyperboloid3(center::EGPoint{3}, a::Real, b::Real, c::Real, u::EGVector{3}, v::EGVector{3}; sheets::Int=1)

`(x/a)² + (y/b)² - (z/c)² = 1` (`sheets=1`, one connected surface) or
`= -1` (`sheets=2`, two disjoint sheets), in the local frame at `center`
with `u`/`v` the `x`/`y` directions and `cross3(u,v)` the `z` (axis)
direction. `sheets=1` is a single connected "waist" surface; `sheets=2`
is two separate, unconnected surfaces facing away from each other along
the axis -- genuinely different topology, not just a sign flip, which is
why [`point_on_hyperboloid3`](@ref) needs a `branch` argument only for
the latter.
"""
struct EGHyperboloid3{T<:Real} <: EGSurface{3,T}
    center::EGPoint{3,T}
    a::T
    b::T
    c::T
    u::EGVector{3,T}
    v::EGVector{3,T}
    sheets::Int
    function EGHyperboloid3{T}(center::EGPoint{3,T}, a::T, b::T, c::T, u::EGVector{3,T}, v::EGVector{3,T}, sheets::Int) where {T<:Real}
        sheets in (1, 2) || throw(ArgumentError("EGHyperboloid3: sheets must be 1 or 2 (got $sheets)"))
        un = u / norm(u)
        vp = v - dot(v, un) * un
        return new{T}(center, a, b, c, un, vp / norm(vp), sheets)
    end
end
function EGHyperboloid3(center::EGPointLike, a::Real, b::Real, c::Real, u::EGVector{3}, v::EGVector{3}; sheets::Int=1)
    ctr = _topoint(center)
    T = promote_type(eltype(ctr), typeof(a), typeof(b), typeof(c), eltype(u), eltype(v))
    return EGHyperboloid3{T}(convert(EGPoint{3,T}, ctr), T(a), T(b), T(c), convert(EGVector{3,T}, u), convert(EGVector{3,T}, v), sheets)
end

Base.:(==)(x::EGHyperboloid3, y::EGHyperboloid3) =
    x.center == y.center && x.a == y.a && x.b == y.b && x.c == y.c && x.u == y.u && x.v == y.v && x.sheets == y.sheets
Base.show(io::IO, h::EGHyperboloid3) = print(io, "EGHyperboloid3(center=", h.center, ", a=", h.a, ", b=", h.b, ", c=", h.c, ", sheets=", h.sheets, ")")

_hyperboloid3_frame(h::EGHyperboloid3) = (h.u, h.v, cross3(h.u, h.v))

"""
    point_on_hyperboloid3(h::EGHyperboloid3, t::Real, φ::Real; branch::Int=1)

For `h.sheets == 1`: `x = a·cosh(t)·cosφ`, `y = b·cosh(t)·sinφ`,
`z = c·sinh(t)` (one connected surface, `branch` ignored). For
`h.sheets == 2`: `x = a·sinh(t)·cosφ`, `y = b·sinh(t)·sinφ`,
`z = branch·c·cosh(t)` (picks one of the two sheets via `branch = ±1`,
the same convention as [`point_on_hyperbola`](@ref)'s own `branch`).
"""
function point_on_hyperboloid3(h::EGHyperboloid3, t::Real, φ::Real; branch::Int=1)
    u, v, w = _hyperboloid3_frame(h)
    if h.sheets == 1
        return h.center + h.a * cosh(t) * cos(φ) * u + h.b * cosh(t) * sin(φ) * v + h.c * sinh(t) * w
    else
        return h.center + h.a * sinh(t) * cos(φ) * u + h.b * sinh(t) * sin(φ) * v + branch * h.c * cosh(t) * w
    end
end

"""
    is_on_hyperboloid3(p::EGPoint{3}, h::EGHyperboloid3; atol=1e-9)
"""
function is_on_hyperboloid3(p::EGPoint{3}, h::EGHyperboloid3; atol=1e-9)
    u, v, w = _hyperboloid3_frame(h)
    d = p - h.center
    lx, ly, lz = dot(d, u), dot(d, v), dot(d, w)
    target = h.sheets == 1 ? 1.0 : -1.0
    return abs((lx / h.a)^2 + (ly / h.b)^2 - (lz / h.c)^2 - target) <= atol
end

rotate(h::EGHyperboloid3, angle::Real, axis::EGLine{3}) =
    EGHyperboloid3(rotate(h.center, angle, axis), h.a, h.b, h.c, rotate(h.u, angle, axis), rotate(h.v, angle, axis); sheets=h.sheets)
translate(h::EGHyperboloid3, v::EGVector{3}) = EGHyperboloid3(translate(h.center, v), h.a, h.b, h.c, h.u, h.v; sheets=h.sheets)
homothety(h::EGHyperboloid3, k::Real, center::EGPoint{3}=EGPoint(0.0, 0.0, 0.0)) =
    EGHyperboloid3(homothety(h.center, k, center), abs(k) * h.a, abs(k) * h.b, abs(k) * h.c, h.u, h.v; sheets=h.sheets)
reflection(h::EGHyperboloid3, about) =
    EGHyperboloid3(reflection(h.center, about), h.a, h.b, h.c, reflection(h.u, about), reflection(h.v, about); sheets=h.sheets)

# --- EGHyperbolicParaboloid3 (the saddle) --------------------------------------

"""
    EGHyperbolicParaboloid3(vertex::EGPoint{3}, a::Real, b::Real, axis::EGVector{3}, u::EGVector{3})

The saddle surface `z = (x/a)² - (y/b)²` in the local frame at `vertex`
with `axis` (`z`) and `u` (`x`) perpendicular to it -- the purest example
of a "genuinely 3D-only" quadric: unlike every other conic/quadric in
this package, no 2D curve, stacked or swept, produces this shape (it's
doubly-ruled by two *different* families of straight lines, a fact with
no 2D analogue at all).
"""
struct EGHyperbolicParaboloid3{T<:Real} <: EGSurface{3,T}
    vertex::EGPoint{3,T}
    a::T
    b::T
    axis::EGVector{3,T}
    u::EGVector{3,T}
    function EGHyperbolicParaboloid3{T}(vertex::EGPoint{3,T}, a::T, b::T, axis::EGVector{3,T}, u::EGVector{3,T}) where {T<:Real}
        axn = axis / norm(axis)
        up = u - dot(u, axn) * axn
        return new{T}(vertex, a, b, axn, up / norm(up))
    end
end
function EGHyperbolicParaboloid3(vertex::EGPointLike, a::Real, b::Real, axis::EGVector{3}, u::EGVector{3})
    v = _topoint(vertex)
    T = promote_type(eltype(v), typeof(a), typeof(b), eltype(axis), eltype(u))
    return EGHyperbolicParaboloid3{T}(convert(EGPoint{3,T}, v), T(a), T(b), convert(EGVector{3,T}, axis), convert(EGVector{3,T}, u))
end

Base.:(==)(x::EGHyperbolicParaboloid3, y::EGHyperbolicParaboloid3) =
    x.vertex == y.vertex && x.a == y.a && x.b == y.b && x.axis == y.axis && x.u == y.u
Base.show(io::IO, p::EGHyperbolicParaboloid3) = print(io, "EGHyperbolicParaboloid3(vertex=", p.vertex, ", a=", p.a, ", b=", p.b, ")")

_hypar3_frame(p::EGHyperbolicParaboloid3) = (p.u, cross3(p.axis, p.u), p.axis)

"""
    point_on_hyperbolic_paraboloid3(p::EGHyperbolicParaboloid3, x::Real, y::Real)

The point at local coordinates `x`/`y`: `p.vertex + a·x·u + b·y·w +
(x² - y²)·axis`.
"""
function point_on_hyperbolic_paraboloid3(p::EGHyperbolicParaboloid3, x::Real, y::Real)
    u, w, axis = _hypar3_frame(p)
    return p.vertex + p.a * x * u + p.b * y * w + (x^2 - y^2) * axis
end

"""
    is_on_hyperbolic_paraboloid3(p::EGPoint{3}, hp::EGHyperbolicParaboloid3; atol=1e-9)
"""
function is_on_hyperbolic_paraboloid3(p::EGPoint{3}, hp::EGHyperbolicParaboloid3; atol=1e-9)
    u, w, axis = _hypar3_frame(hp)
    d = p - hp.vertex
    lx, ly, lz = dot(d, u), dot(d, w), dot(d, axis)
    return abs(lz - ((lx / hp.a)^2 - (ly / hp.b)^2)) <= atol
end

rotate(p::EGHyperbolicParaboloid3, angle::Real, axis::EGLine{3}) =
    EGHyperbolicParaboloid3(rotate(p.vertex, angle, axis), p.a, p.b, rotate(p.axis, angle, axis), rotate(p.u, angle, axis))
translate(p::EGHyperbolicParaboloid3, v::EGVector{3}) = EGHyperbolicParaboloid3(translate(p.vertex, v), p.a, p.b, p.axis, p.u)
homothety(p::EGHyperbolicParaboloid3, k::Real, center::EGPoint{3}=EGPoint(0.0, 0.0, 0.0)) =
    EGHyperbolicParaboloid3(homothety(p.vertex, k, center), abs(k) * p.a, abs(k) * p.b, p.axis, p.u)
reflection(p::EGHyperbolicParaboloid3, about) =
    EGHyperbolicParaboloid3(reflection(p.vertex, about), p.a, p.b, reflection(p.axis, about), reflection(p.u, about))
