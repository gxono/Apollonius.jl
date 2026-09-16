# -------------------------------------------------------------------------
# EGEllipse3, EGParabola3, EGHyperbola3 (<: EGCurve{3,T}) and their arc
# types (EGCircularArc3, EGEllipticArc3, EGParabolicArc3, EGHyperbolicArc3)
# -- planar conics embedded in 3D via an explicit supporting plane
# (normal + an in-plane reference direction `u`), plus a fuller EGCircle3
# API (Phase 1 left it a minimal stub).
#
# Key reuse: `_to_local_frame(p, origin, u::EGVector, w::EGVector)` /
# `_from_local_frame` in eg_conic.jl are ALREADY dimension-generic (plain
# dot products against explicit u/w vectors, no 2D assumption at all) --
# only the *angle*-based overloads there are 2D-only. So every Newton
# closest-point solver (`_closest_ellipse_local_param`, etc.) is reused
# UNCHANGED below: it operates purely on scalar local (lx,ly) coordinates,
# and an orthonormal embedding preserves Euclidean distance, so the exact
# same 2D numerics give the correct 3D answer for free.
# -------------------------------------------------------------------------

# w = the second in-plane basis vector, completing (u, w, normal) into a
# right-handed orthonormal frame -- computed on demand, never stored (same
# "don't duplicate what's derivable" principle as EGCircle3's `plane`).
_conic3_w(normal::EGVector{3}, u::EGVector{3}) = cross3(normal, u)

# --- EGCircle3: fill out the Phase-1 stub with the full circle API -------------

# An arbitrary (but fixed, deterministic) in-plane unit reference
# direction for a circle -- unlike ellipse/hyperbola, a circle has no
# distinguished axis, so `point_on_circle3`/etc. just need *some* in-plane
# basis, not a meaningful one.
function _circle3_u(c::EGCircle3)
    n = c.normal
    ref = abs(n[1]) < 0.9 ? EGVector(1.0, 0.0, 0.0) : EGVector(0.0, 1.0, 0.0)
    v = cross3(n, ref)
    return v / norm(v)
end

"""
    point_on_circle3(c::EGCircle3, t::Real)

A point on `c` at angular parameter `t` (radians), using an arbitrary but
fixed in-plane reference direction (a circle has no distinguished axis,
unlike an ellipse).
"""
function point_on_circle3(c::EGCircle3, t::Real)
    u = _circle3_u(c)
    w = _conic3_w(c.normal, u)
    return c.center + c.r * cos(t) * u + c.r * sin(t) * w
end

"""
    is_on_circle3(p::EGPoint{3}, c::EGCircle3; atol=1e-9)

Whether `p` lies exactly on `c` — on its supporting plane *and* at
distance `c.r` from `c.center`.
"""
function is_on_circle3(p::EGPoint{3}, c::EGCircle3; atol=1e-9)
    on_plane(p, plane(c); atol=atol) || return false
    return abs(distance(p, c.center) - c.r) <= sqrt(atol) * max(c.r, norm(c.center), 1.0)
end

# --- EGEllipse3 -----------------------------------------------------------------

"""
    EGEllipse3(center::EGPoint{3}, a::Real, b::Real, normal::EGVector{3}, u::EGVector{3})
    EGEllipse3(f1::EGPoint{3}, f2::EGPoint{3}, p::EGPoint{3})
    EGEllipse3(f1::EGPoint{3}, f2::EGPoint{3}, a::Real, normal::EGVector{3})

A planar ellipse embedded in 3D: semi-axes `a` (along `u`) and `b` (along
`cross3(normal, u)`), centered at `center`, in the plane through `center`
perpendicular to `normal`. `u` is auto-orthogonalized against `normal` and
normalized, so it only needs to be *approximately* in-plane.

The 3-point-derived bifocal form `(f1, f2, p)` needs no extra plane
argument (3 non-collinear points determine a unique plane on their own).
The axis-only bifocal form `(f1, f2, a)`, unlike its 2D counterpart, takes
an explicit `normal` — two foci alone only pin down the focal *axis*, not
which of the infinitely many planes containing it the ellipse lies in.
"""
struct EGEllipse3{T<:Real} <: EGCurve{3,T}
    center::EGPoint{3,T}
    a::T
    b::T
    normal::EGVector{3,T}
    u::EGVector{3,T}
    function EGEllipse3{T}(center::EGPoint{3,T}, a::T, b::T, normal::EGVector{3,T}, u::EGVector{3,T}) where {T<:Real}
        n = normal / norm(normal)
        up = u - dot(u, n) * n
        return new{T}(center, a, b, n, up / norm(up))
    end
end
function EGEllipse3(c::EGPoint, a::Real, b::Real, normal::EGVector{3}, u::EGVector{3})
    T = promote_type(eltype(c), typeof(a), typeof(b), eltype(normal), eltype(u))
    return EGEllipse3{T}(convert(EGPoint{3,T}, c), T(a), T(b), convert(EGVector{3,T}, normal), convert(EGVector{3,T}, u))
end
function EGEllipse3(f1::EGPoint, f2::EGPoint, a::Real, normal::EGVector{3})
    c = distance(f1, f2) / 2
    a <= c && throw(ArgumentError("EGEllipse3: a must be greater than half the distance between the foci"))
    d = f2 - f1
    return EGEllipse3(midpoint(f1, f2), a, sqrt(a^2 - c^2), normal, EGVector(d[1], d[2], d[3]))
end
function EGEllipse3(f1::EGPoint, f2::EGPoint, p::EGPoint)
    n = cross3(f2 - f1, p - f1)
    a = (distance(p, f1) + distance(p, f2)) / 2
    return EGEllipse3(f1, f2, a, n)
end

Base.:(==)(x::EGEllipse3, y::EGEllipse3) = x.center == y.center && x.a == y.a && x.b == y.b && x.normal == y.normal && x.u == y.u
Base.isapprox(x::EGEllipse3, y::EGEllipse3; kwargs...) =
    isapprox(x.center, y.center; kwargs...) && isapprox(x.a, y.a; kwargs...) && isapprox(x.b, y.b; kwargs...) &&
    isapprox(x.normal, y.normal; kwargs...) && isapprox(x.u, y.u; kwargs...)
Base.show(io::IO, e::EGEllipse3) = print(io, "EGEllipse3(center=", e.center, ", a=", e.a, ", b=", e.b, ", n=", e.normal, ", u=", e.u, ")")

"""
    plane(e::EGEllipse3)

The supporting [`EGPlane3`](@ref) of `e`.
"""
plane(e::EGEllipse3) = EGPlane3(e.center, e.normal)

_to_ellipse3_local(p::EGPoint{3}, e::EGEllipse3) = _to_local_frame(p, e.center, e.u, _conic3_w(e.normal, e.u))
_from_ellipse3_local(x, y, e::EGEllipse3) = _from_local_frame(x, y, e.center, e.u, _conic3_w(e.normal, e.u))

"""
    point_on_ellipse3(e::EGEllipse3, t::Real)
"""
point_on_ellipse3(e::EGEllipse3, t::Real) = _from_ellipse3_local(e.a * cos(t), e.b * sin(t), e)

"""
    is_on_ellipse3(p::EGPoint{3}, e::EGEllipse3; atol=1e-9)
"""
function is_on_ellipse3(p::EGPoint{3}, e::EGEllipse3; atol=1e-9)
    lx, ly = _to_ellipse3_local(p, e)
    return abs((lx / e.a)^2 + (ly / e.b)^2 - 1) <= atol
end

area(e::EGEllipse3) = pi * e.a * e.b
function perimeter(e::EGEllipse3)
    a, b = e.a, e.b
    h = ((a - b) / (a + b))^2
    return pi * (a + b) * (1 + 3h / (10 + sqrt(4 - 3h)))
end
centroid(e::EGEllipse3) = e.center

"""
    foci(e::EGEllipse3)
"""
function foci(e::EGEllipse3)
    c = sqrt(abs(e.a^2 - e.b^2))
    dir = e.a >= e.b ? e.u : _conic3_w(e.normal, e.u)
    return (e.center + c * dir, e.center - c * dir)
end

"""
    orthoptic(e::EGEllipse3)

The orthoptic (director) circle of `e`, as an [`EGCircle3`](@ref) in the
same plane -- the 3D analogue of `orthoptic(::EGEllipse2)`.
"""
orthoptic(e::EGEllipse3) = EGCircle3(e.center, sqrt(e.a^2 + e.b^2), e.normal)

"""
    distance(p::EGPoint{3}, e::EGEllipse3)

Distance from `p` to the curve of `e`, via the same Newton solve as
[`distance(::EGPoint, ::EGEllipse2)`](@ref) (reused verbatim: it operates
on scalar local coordinates, which an orthonormal embedding preserves
distances for).
"""
function distance(p::EGPoint{3}, e::EGEllipse3)
    lx, ly = _to_ellipse3_local(p, e)
    isapprox(e.a, e.b) && return abs(sqrt(lx^2 + ly^2) - e.a)
    t = _closest_ellipse_local_param(lx, ly, e.a, e.b)
    cx, cy = e.a * cos(t), e.b * sin(t)
    return sqrt((lx - cx)^2 + (ly - cy)^2)
end
distance(e::EGEllipse3, p::EGPoint{3}) = distance(p, e)

rotate(e::EGEllipse3, angle::Real, axis::EGLine{3}) =
    EGEllipse3(rotate(e.center, angle, axis), e.a, e.b, rotate(e.normal, angle, axis), rotate(e.u, angle, axis))
translate(e::EGEllipse3, v::EGVector{3}) = EGEllipse3(translate(e.center, v), e.a, e.b, e.normal, e.u)
"""
    homothety(e::EGEllipse3, k::Real, center::EGPoint{3}=EGPoint(0.0,0.0,0.0))

Scales `a`/`b` by `abs(k)`; `normal`/`u` are left as-is regardless of
`k`'s sign (an ellipse has no inherent chirality to track, unlike
[`EGHalfSpace3`](@ref)/[`EGDihedralAngle3`](@ref) -- matching the 2D
convention of never touching `angle` under `homothety` either).
"""
homothety(e::EGEllipse3, k::Real, center::EGPoint{3}=EGPoint(0.0, 0.0, 0.0)) =
    EGEllipse3(homothety(e.center, k, center), abs(k) * e.a, abs(k) * e.b, e.normal, e.u)
reflection(e::EGEllipse3, about) = EGEllipse3(reflection(e.center, about), e.a, e.b, reflection(e.normal, about), reflection(e.u, about))

# --- EGHyperbola3 ---------------------------------------------------------------

"""
    EGHyperbola3(center::EGPoint{3}, a::Real, b::Real, normal::EGVector{3}, u::EGVector{3})
    EGHyperbola3(f1::EGPoint{3}, f2::EGPoint{3}, p::EGPoint{3})
    EGHyperbola3(f1::EGPoint{3}, f2::EGPoint{3}, a::Real, normal::EGVector{3})

The 3D analogue of [`EGHyperbola2`](@ref) -- see [`EGEllipse3`](@ref) for
the shared `normal`/`u` embedding convention and why the axis-only bifocal
form needs an explicit `normal`.
"""
struct EGHyperbola3{T<:Real} <: EGCurve{3,T}
    center::EGPoint{3,T}
    a::T
    b::T
    normal::EGVector{3,T}
    u::EGVector{3,T}
    function EGHyperbola3{T}(center::EGPoint{3,T}, a::T, b::T, normal::EGVector{3,T}, u::EGVector{3,T}) where {T<:Real}
        n = normal / norm(normal)
        up = u - dot(u, n) * n
        return new{T}(center, a, b, n, up / norm(up))
    end
end
function EGHyperbola3(c::EGPoint, a::Real, b::Real, normal::EGVector{3}, u::EGVector{3})
    T = promote_type(eltype(c), typeof(a), typeof(b), eltype(normal), eltype(u))
    return EGHyperbola3{T}(convert(EGPoint{3,T}, c), T(a), T(b), convert(EGVector{3,T}, normal), convert(EGVector{3,T}, u))
end
function EGHyperbola3(f1::EGPoint, f2::EGPoint, a::Real, normal::EGVector{3})
    c = distance(f1, f2) / 2
    a >= c && throw(ArgumentError("EGHyperbola3: a must be less than half the distance between the foci"))
    d = f2 - f1
    return EGHyperbola3(midpoint(f1, f2), a, sqrt(c^2 - a^2), normal, EGVector(d[1], d[2], d[3]))
end
function EGHyperbola3(f1::EGPoint, f2::EGPoint, p::EGPoint)
    n = cross3(f2 - f1, p - f1)
    a = abs(distance(p, f1) - distance(p, f2)) / 2
    return EGHyperbola3(f1, f2, a, n)
end

Base.:(==)(x::EGHyperbola3, y::EGHyperbola3) = x.center == y.center && x.a == y.a && x.b == y.b && x.normal == y.normal && x.u == y.u
Base.isapprox(x::EGHyperbola3, y::EGHyperbola3; kwargs...) =
    isapprox(x.center, y.center; kwargs...) && isapprox(x.a, y.a; kwargs...) && isapprox(x.b, y.b; kwargs...) &&
    isapprox(x.normal, y.normal; kwargs...) && isapprox(x.u, y.u; kwargs...)
Base.show(io::IO, h::EGHyperbola3) = print(io, "EGHyperbola3(center=", h.center, ", a=", h.a, ", b=", h.b, ", n=", h.normal, ", u=", h.u, ")")

plane(h::EGHyperbola3) = EGPlane3(h.center, h.normal)

_to_hyperbola3_local(p::EGPoint{3}, h::EGHyperbola3) = _to_local_frame(p, h.center, h.u, _conic3_w(h.normal, h.u))
_from_hyperbola3_local(x, y, h::EGHyperbola3) = _from_local_frame(x, y, h.center, h.u, _conic3_w(h.normal, h.u))

"""
    point_on_hyperbola3(h::EGHyperbola3, t::Real; branch::Int=1)
"""
function point_on_hyperbola3(h::EGHyperbola3, t::Real; branch::Int=1)
    x, y = branch * h.a * cosh(t), h.b * sinh(t)
    return _from_hyperbola3_local(x, y, h)
end

"""
    is_on_hyperbola3(p::EGPoint{3}, h::EGHyperbola3; atol=1e-9)
"""
function is_on_hyperbola3(p::EGPoint{3}, h::EGHyperbola3; atol=1e-9)
    lx, ly = _to_hyperbola3_local(p, h)
    return abs((lx / h.a)^2 - (ly / h.b)^2 - 1) <= atol
end

"""
    foci(h::EGHyperbola3)
"""
function foci(h::EGHyperbola3)
    c = sqrt(h.a^2 + h.b^2)
    return (h.center + c * h.u, h.center - c * h.u)
end

"""
    asymptotes(h::EGHyperbola3)

The two asymptote lines of `h`, as a 2-tuple of `EGLine{3}`.
"""
function asymptotes(h::EGHyperbola3)
    p1 = _from_hyperbola3_local(h.a, h.b, h)
    p2 = _from_hyperbola3_local(h.a, -h.b, h)
    return (EGLine(h.center, p1), EGLine(h.center, p2))
end

"""
    distance(p::EGPoint{3}, h::EGHyperbola3)
"""
function distance(p::EGPoint{3}, h::EGHyperbola3)
    lx, ly = _to_hyperbola3_local(p, h)
    best = Inf
    for branch in (1, -1)
        t = _closest_hyperbola_local_param(lx, ly, h.a, h.b, branch)
        cx, cy = branch * h.a * cosh(t), h.b * sinh(t)
        best = min(best, sqrt((lx - cx)^2 + (ly - cy)^2))
    end
    return best
end
distance(h::EGHyperbola3, p::EGPoint{3}) = distance(p, h)

rotate(h::EGHyperbola3, angle::Real, axis::EGLine{3}) =
    EGHyperbola3(rotate(h.center, angle, axis), h.a, h.b, rotate(h.normal, angle, axis), rotate(h.u, angle, axis))
translate(h::EGHyperbola3, v::EGVector{3}) = EGHyperbola3(translate(h.center, v), h.a, h.b, h.normal, h.u)
homothety(h::EGHyperbola3, k::Real, center::EGPoint{3}=EGPoint(0.0, 0.0, 0.0)) =
    EGHyperbola3(homothety(h.center, k, center), abs(k) * h.a, abs(k) * h.b, h.normal, h.u)
reflection(h::EGHyperbola3, about) = EGHyperbola3(reflection(h.center, about), h.a, h.b, reflection(h.normal, about), reflection(h.u, about))

# --- EGParabola3 -----------------------------------------------------------------

"""
    EGParabola3(focus::EGPoint{3}, directrix::EGLine{3})

The 3D analogue of [`EGParabola2`](@ref). No extra plane argument is
needed: a focus point plus a directrix line determine a unique plane on
their own (as long as the focus isn't already on the directrix's own
infinite extension, an existing degenerate-input error case).
"""
struct EGParabola3{T<:Real} <: EGCurve{3,T}
    focus::EGPoint{3,T}
    directrix::EGLine{3,T}
end
function EGParabola3(f::EGPoint, directrix::EGLine{3})
    T = promote_type(eltype(f), eltype(directrix.p1))
    return EGParabola3{T}(convert(EGPoint{3,T}, f), convert(EGLine{3,T}, directrix))
end

Base.:(==)(x::EGParabola3, y::EGParabola3) = x.focus == y.focus && x.directrix == y.directrix
Base.isapprox(x::EGParabola3, y::EGParabola3; kwargs...) = isapprox(x.focus, y.focus; kwargs...) && isapprox(x.directrix, y.directrix; kwargs...)
Base.show(io::IO, par::EGParabola3) = print(io, "EGParabola3(focus=", par.focus, ", directrix=", par.directrix, ")")

"""
    vertex(par::EGParabola3)
"""
vertex(par::EGParabola3) = midpoint(par.focus, projection(par.focus, par.directrix))

"""
    focal_parameter(par::EGParabola3)
"""
focal_parameter(par::EGParabola3) = distance(par.focus, par.directrix)

function _parabola3_frame(par::EGParabola3)
    foot = projection(par.focus, par.directrix)
    u = (par.focus - foot) / norm(par.focus - foot)
    w = direction(par.directrix) / norm(direction(par.directrix))
    return midpoint(par.focus, foot), EGVector(u[1], u[2], u[3]), EGVector(w[1], w[2], w[3])
end

"""
    plane(par::EGParabola3)
"""
function plane(par::EGParabola3)
    _, u, w = _parabola3_frame(par)
    return EGPlane3(par.focus, cross3(u, w))
end

"""
    point_on_parabola3(par::EGParabola3, s::Real)
"""
function point_on_parabola3(par::EGParabola3, s::Real)
    V, u, w = _parabola3_frame(par)
    p = focal_parameter(par)
    return _from_local_frame(s^2 / (2p), s, V, u, w)
end

"""
    is_on_parabola3(p::EGPoint{3}, par::EGParabola3; atol=1e-9)
"""
is_on_parabola3(p::EGPoint{3}, par::EGParabola3; atol=1e-9) =
    abs(distance(p, par.focus) - distance(p, par.directrix)) <= sqrt(atol) * max(norm(p), norm(par.focus), 1.0)

"""
    orthoptic(par::EGParabola3)

Exactly `par.directrix` -- see `orthoptic(::EGParabola2)`.
"""
orthoptic(par::EGParabola3) = par.directrix

"""
    distance(p::EGPoint{3}, par::EGParabola3)
"""
function distance(p::EGPoint{3}, par::EGParabola3)
    V, u, w = _parabola3_frame(par)
    pf = focal_parameter(par)
    X0, Y0 = _to_local_frame(p, V, u, w)
    s = _closest_parabola_local_param(X0, Y0, pf)
    return distance(p, point_on_parabola3(par, s))
end
distance(par::EGParabola3, p::EGPoint{3}) = distance(p, par)

rotate(par::EGParabola3, angle::Real, axis::EGLine{3}) = EGParabola3(rotate(par.focus, angle, axis), rotate(par.directrix, angle, axis))
translate(par::EGParabola3, v::EGVector{3}) = EGParabola3(translate(par.focus, v), translate(par.directrix, v))
homothety(par::EGParabola3, k::Real, center::EGPoint{3}=EGPoint(0.0, 0.0, 0.0)) =
    EGParabola3(homothety(par.focus, k, center), homothety(par.directrix, k, center))
reflection(par::EGParabola3, about) = EGParabola3(reflection(par.focus, about), reflection(par.directrix, about))

# --- EGCircularArc3 --------------------------------------------------------------

"""
    EGCircularArc3(circle::EGCircle3, p1::EGPoint{3}, p2::EGPoint{3})

The arc of `circle` traversed from `p1` to `p2`, sweeping counterclockwise
as seen looking against `circle.normal` (right-hand rule) -- the 3D
analogue of [`EGCircularArc2`](@ref).
"""
struct EGCircularArc3{T<:Real} <: EGCurve{3,T}
    circle::EGCircle3{T}
    p1::EGPoint{3,T}
    p2::EGPoint{3,T}
end
function EGCircularArc3(circle::EGCircle3, p1::EGPoint, p2::EGPoint)
    T = promote_type(eltype(circle.center), eltype(p1), eltype(p2))
    return EGCircularArc3{T}(convert(EGCircle3{T}, circle), convert(EGPoint{3,T}, p1), convert(EGPoint{3,T}, p2))
end

Base.:(==)(x::EGCircularArc3, y::EGCircularArc3) = x.circle == y.circle && x.p1 == y.p1 && x.p2 == y.p2
Base.convert(::Type{EGCircularArc3{T}}, a::EGCircularArc3) where {T} = EGCircularArc3{T}(a.circle, a.p1, a.p2)
Base.show(io::IO, arc::EGCircularArc3) = print(io, "EGCircularArc3(", arc.circle, ", ", arc.p1, " -> ", arc.p2, ")")

"""
    reverse(arc::EGCircularArc3)

The complementary arc -- see [`reverse(::EGCircularArc2)`](@ref).
"""
Base.reverse(arc::EGCircularArc3) = EGCircularArc3(arc.circle, arc.p2, arc.p1)

_arc3_angle(arc::EGCircularArc3, p::EGPoint{3}) = begin
    u = _circle3_u(arc.circle)
    w = _conic3_w(arc.circle.normal, u)
    x, y = dot(p - arc.circle.center, u), dot(p - arc.circle.center, w)
    atan(y, x)
end

"""
    measure(arc::EGCircularArc3)
"""
measure(arc::EGCircularArc3) = mod(_arc3_angle(arc, arc.p2) - _arc3_angle(arc, arc.p1), 2π)

"""
    arc_length(arc::EGCircularArc3)
"""
arc_length(arc::EGCircularArc3) = arc.circle.r * measure(arc)

function point_on_arc(arc::EGCircularArc3, t::Real)
    u = _circle3_u(arc.circle)
    w = _conic3_w(arc.circle.normal, u)
    a = _arc3_angle(arc, arc.p1) + t * measure(arc)
    return arc.circle.center + arc.circle.r * cos(a) * u + arc.circle.r * sin(a) * w
end
midpoint(arc::EGCircularArc3) = point_on_arc(arc, 0.5)

function distance(p::EGPoint{3}, arc::EGCircularArc3)
    c = arc.circle
    on_plane(p, plane(c)) || return min(distance(p, arc.p1), distance(p, arc.p2), _cap_arc3_distance(p, arc))
    a1 = _arc3_angle(arc, arc.p1)
    ap = _arc3_angle(arc, p)
    0 <= mod(ap - a1, 2π) <= measure(arc) && return abs(distance(p, c.center) - c.r)
    return min(distance(p, arc.p1), distance(p, arc.p2))
end
distance(arc::EGCircularArc3, p::EGPoint{3}) = distance(p, arc)
# For a point NOT on the circle's own plane, the closest point on the full
# circle first projects `p` onto the plane, then proceeds exactly as
# on-plane -- separated out since the in-plane angle test only makes sense
# after that projection.
function _cap_arc3_distance(p::EGPoint{3}, arc::EGCircularArc3)
    c = arc.circle
    foot = projection(p, plane(c))
    onto_circle = c.center + c.r * (foot - c.center) / norm(foot - c.center)
    a1, ap = _arc3_angle(arc, arc.p1), _arc3_angle(arc, onto_circle)
    in_range = 0 <= mod(ap - a1, 2π) <= measure(arc)
    closest = in_range ? onto_circle : (mod(ap - a1, 2π) < π ? arc.p2 : arc.p1)
    return distance(p, closest)
end

function Base.in(p::EGPoint{3}, arc::EGCircularArc3; atol=1e-9)
    is_on_circle3(p, arc.circle; atol=atol) || return false
    return mod(_arc3_angle(arc, p) - _arc3_angle(arc, arc.p1), 2π) <= measure(arc)
end

rotate(arc::EGCircularArc3, angle::Real, axis::EGLine{3}) =
    EGCircularArc3(rotate(arc.circle, angle, axis), rotate(arc.p1, angle, axis), rotate(arc.p2, angle, axis))
translate(arc::EGCircularArc3, v::EGVector{3}) = EGCircularArc3(translate(arc.circle, v), translate(arc.p1, v), translate(arc.p2, v))
homothety(arc::EGCircularArc3, k::Real, center::EGPoint{3}=EGPoint(0.0, 0.0, 0.0)) =
    EGCircularArc3(homothety(arc.circle, k, center), homothety(arc.p1, k, center), homothety(arc.p2, k, center))
reflection(arc::EGCircularArc3, about::EGPoint{3}) =
    EGCircularArc3(reflection(arc.circle, about), reflection(arc.p1, about), reflection(arc.p2, about))
reflection(arc::EGCircularArc3, about::EGPlane3) =
    EGCircularArc3(reflection(arc.circle, about), reflection(arc.p2, about), reflection(arc.p1, about))

# --- EGEllipticArc3 --------------------------------------------------------------

"""
    EGEllipticArc3(ellipse::EGEllipse3, p1::EGPoint{3}, p2::EGPoint{3})
"""
struct EGEllipticArc3{T<:Real} <: EGCurve{3,T}
    ellipse::EGEllipse3{T}
    p1::EGPoint{3,T}
    p2::EGPoint{3,T}
end
function EGEllipticArc3(ellipse::EGEllipse3, p1::EGPoint, p2::EGPoint)
    T = promote_type(eltype(ellipse.center), eltype(p1), eltype(p2))
    return EGEllipticArc3{T}(convert(EGEllipse3{T}, ellipse), convert(EGPoint{3,T}, p1), convert(EGPoint{3,T}, p2))
end

Base.reverse(arc::EGEllipticArc3) = EGEllipticArc3(arc.ellipse, arc.p2, arc.p1)

function _ellipse3_param(e::EGEllipse3, p::EGPoint{3})
    lx, ly = _to_ellipse3_local(p, e)
    return atan(ly / e.b, lx / e.a)
end
_ellipse3_param(arc::EGEllipticArc3, p::EGPoint{3}) = _ellipse3_param(arc.ellipse, p)

measure(arc::EGEllipticArc3) = mod(_ellipse3_param(arc, arc.p2) - _ellipse3_param(arc, arc.p1), 2π)
function point_on_arc(arc::EGEllipticArc3, t::Real)
    a = _ellipse3_param(arc, arc.p1) + t * measure(arc)
    return point_on_ellipse3(arc.ellipse, a)
end
midpoint(arc::EGEllipticArc3) = point_on_arc(arc, 0.5)

function arc_length(arc::EGEllipticArc3)
    e = arc.ellipse
    θ1 = _ellipse3_param(arc, arc.p1)
    Δθ = measure(arc)
    speed(t) = abs(Δθ) * sqrt((e.a * sin(θ1 + t * Δθ))^2 + (e.b * cos(θ1 + t * Δθ))^2)
    return _simpson_integrate(speed, 0.0, 1.0)
end

function distance(p::EGPoint{3}, arc::EGEllipticArc3)
    e = arc.ellipse
    lx, ly = _to_ellipse3_local(p, e)
    t1 = _ellipse3_param(arc, arc.p1)
    d = _closest_ellipse_local_param_in_range(lx, ly, e.a, e.b, t1, measure(arc))
    return min(d, distance(p, arc.p1), distance(p, arc.p2))
end
distance(arc::EGEllipticArc3, p::EGPoint{3}) = distance(p, arc)

function Base.in(p::EGPoint{3}, arc::EGEllipticArc3; atol=1e-9)
    is_on_ellipse3(p, arc.ellipse; atol=atol) || return false
    return mod(_ellipse3_param(arc, p) - _ellipse3_param(arc, arc.p1), 2π) <= measure(arc)
end

rotate(arc::EGEllipticArc3, angle::Real, axis::EGLine{3}) =
    EGEllipticArc3(rotate(arc.ellipse, angle, axis), rotate(arc.p1, angle, axis), rotate(arc.p2, angle, axis))
translate(arc::EGEllipticArc3, v::EGVector{3}) = EGEllipticArc3(translate(arc.ellipse, v), translate(arc.p1, v), translate(arc.p2, v))
homothety(arc::EGEllipticArc3, k::Real, center::EGPoint{3}=EGPoint(0.0, 0.0, 0.0)) =
    EGEllipticArc3(homothety(arc.ellipse, k, center), homothety(arc.p1, k, center), homothety(arc.p2, k, center))
reflection(arc::EGEllipticArc3, about::EGPoint{3}) =
    EGEllipticArc3(reflection(arc.ellipse, about), reflection(arc.p1, about), reflection(arc.p2, about))
reflection(arc::EGEllipticArc3, about::EGPlane3) =
    EGEllipticArc3(reflection(arc.ellipse, about), reflection(arc.p2, about), reflection(arc.p1, about))

# --- EGParabolicArc3 --------------------------------------------------------------

"""
    EGParabolicArc3(parabola::EGParabola3, p1::EGPoint{3}, p2::EGPoint{3})

Open curve -- no complementary-arc ambiguity, so `reflection` never swaps
`p1`/`p2` (same reasoning as [`EGParabolicArc2`](@ref)).
"""
struct EGParabolicArc3{T<:Real} <: EGCurve{3,T}
    parabola::EGParabola3{T}
    p1::EGPoint{3,T}
    p2::EGPoint{3,T}
end
function EGParabolicArc3(parabola::EGParabola3, p1::EGPoint, p2::EGPoint)
    T = promote_type(eltype(parabola.focus), eltype(p1), eltype(p2))
    return EGParabolicArc3{T}(convert(EGParabola3{T}, parabola), convert(EGPoint{3,T}, p1), convert(EGPoint{3,T}, p2))
end

Base.reverse(arc::EGParabolicArc3) = EGParabolicArc3(arc.parabola, arc.p2, arc.p1)

function _parabola3_param(par::EGParabola3, p::EGPoint{3})
    V, u, w = _parabola3_frame(par)
    _, y = _to_local_frame(p, V, u, w)
    return y
end
_parabola3_param(arc::EGParabolicArc3, p::EGPoint{3}) = _parabola3_param(arc.parabola, p)

function point_on_arc(arc::EGParabolicArc3, t::Real)
    s1, s2 = _parabola3_param(arc, arc.p1), _parabola3_param(arc, arc.p2)
    return point_on_parabola3(arc.parabola, s1 + t * (s2 - s1))
end
midpoint(arc::EGParabolicArc3) = point_on_arc(arc, 0.5)

function arc_length(arc::EGParabolicArc3)
    pf = focal_parameter(arc.parabola)
    s1, s2 = _parabola3_param(arc, arc.p1), _parabola3_param(arc, arc.p2)
    speed(t) = abs(s2 - s1) * sqrt(((s1 + t * (s2 - s1)) / pf)^2 + 1)
    return _simpson_integrate(speed, 0.0, 1.0)
end

function distance(p::EGPoint{3}, arc::EGParabolicArc3)
    par = arc.parabola
    V, u, w = _parabola3_frame(par)
    X0, Y0 = _to_local_frame(p, V, u, w)
    s1, s2 = _parabola3_param(arc, arc.p1), _parabola3_param(arc, arc.p2)
    smin, smax = minmax(s1, s2)
    d = _closest_parabola_local_param_in_range(X0, Y0, focal_parameter(par), smin, smax)
    return min(d, distance(p, arc.p1), distance(p, arc.p2))
end
distance(arc::EGParabolicArc3, p::EGPoint{3}) = distance(p, arc)

function Base.in(p::EGPoint{3}, arc::EGParabolicArc3; atol=1e-9)
    is_on_parabola3(p, arc.parabola; atol=atol) || return false
    smin, smax = minmax(_parabola3_param(arc, arc.p1), _parabola3_param(arc, arc.p2))
    return smin <= _parabola3_param(arc, p) <= smax
end

rotate(arc::EGParabolicArc3, angle::Real, axis::EGLine{3}) =
    EGParabolicArc3(rotate(arc.parabola, angle, axis), rotate(arc.p1, angle, axis), rotate(arc.p2, angle, axis))
translate(arc::EGParabolicArc3, v::EGVector{3}) = EGParabolicArc3(translate(arc.parabola, v), translate(arc.p1, v), translate(arc.p2, v))
homothety(arc::EGParabolicArc3, k::Real, center::EGPoint{3}=EGPoint(0.0, 0.0, 0.0)) =
    EGParabolicArc3(homothety(arc.parabola, k, center), homothety(arc.p1, k, center), homothety(arc.p2, k, center))
reflection(arc::EGParabolicArc3, about) = EGParabolicArc3(reflection(arc.parabola, about), reflection(arc.p1, about), reflection(arc.p2, about))

# --- EGHyperbolicArc3 --------------------------------------------------------------

"""
    EGHyperbolicArc3(hyperbola::EGHyperbola3, p1::EGPoint{3}, p2::EGPoint{3})

Assumed to lie on the same branch. Open curve -- `reflection` never swaps
`p1`/`p2` (same reasoning as [`EGHyperbolicArc2`](@ref)).
"""
struct EGHyperbolicArc3{T<:Real} <: EGCurve{3,T}
    hyperbola::EGHyperbola3{T}
    p1::EGPoint{3,T}
    p2::EGPoint{3,T}
end
function EGHyperbolicArc3(hyperbola::EGHyperbola3, p1::EGPoint, p2::EGPoint)
    T = promote_type(eltype(hyperbola.center), eltype(p1), eltype(p2))
    return EGHyperbolicArc3{T}(convert(EGHyperbola3{T}, hyperbola), convert(EGPoint{3,T}, p1), convert(EGPoint{3,T}, p2))
end

Base.reverse(arc::EGHyperbolicArc3) = EGHyperbolicArc3(arc.hyperbola, arc.p2, arc.p1)

function _hyperbola3_param(h::EGHyperbola3, p::EGPoint{3})
    lx, ly = _to_hyperbola3_local(p, h)
    return asinh(ly / h.b), (lx >= 0 ? 1 : -1)
end
_hyperbola3_param(arc::EGHyperbolicArc3, p::EGPoint{3}) = _hyperbola3_param(arc.hyperbola, p)

function point_on_arc(arc::EGHyperbolicArc3, t::Real)
    t1, branch = _hyperbola3_param(arc, arc.p1)
    t2, _ = _hyperbola3_param(arc, arc.p2)
    return point_on_hyperbola3(arc.hyperbola, t1 + t * (t2 - t1); branch=branch)
end
midpoint(arc::EGHyperbolicArc3) = point_on_arc(arc, 0.5)

function arc_length(arc::EGHyperbolicArc3)
    h = arc.hyperbola
    t1, _ = _hyperbola3_param(arc, arc.p1)
    t2, _ = _hyperbola3_param(arc, arc.p2)
    speed(t) = abs(t2 - t1) * sqrt((h.a * sinh(t1 + t * (t2 - t1)))^2 + (h.b * cosh(t1 + t * (t2 - t1)))^2)
    return _simpson_integrate(speed, 0.0, 1.0)
end

function distance(p::EGPoint{3}, arc::EGHyperbolicArc3)
    h = arc.hyperbola
    lx, ly = _to_hyperbola3_local(p, h)
    t1, branch = _hyperbola3_param(arc, arc.p1)
    t2, _ = _hyperbola3_param(arc, arc.p2)
    tmin, tmax = minmax(t1, t2)
    d = _closest_hyperbola_local_param_in_range(lx, ly, h.a, h.b, branch, tmin, tmax)
    return min(d, distance(p, arc.p1), distance(p, arc.p2))
end
distance(arc::EGHyperbolicArc3, p::EGPoint{3}) = distance(p, arc)

function Base.in(p::EGPoint{3}, arc::EGHyperbolicArc3; atol=1e-9)
    is_on_hyperbola3(p, arc.hyperbola; atol=atol) || return false
    t1, branch = _hyperbola3_param(arc, arc.p1)
    t2, _ = _hyperbola3_param(arc, arc.p2)
    t, b = _hyperbola3_param(arc, p)
    b == branch || return false
    tmin, tmax = minmax(t1, t2)
    return tmin <= t <= tmax
end

rotate(arc::EGHyperbolicArc3, angle::Real, axis::EGLine{3}) =
    EGHyperbolicArc3(rotate(arc.hyperbola, angle, axis), rotate(arc.p1, angle, axis), rotate(arc.p2, angle, axis))
translate(arc::EGHyperbolicArc3, v::EGVector{3}) = EGHyperbolicArc3(translate(arc.hyperbola, v), translate(arc.p1, v), translate(arc.p2, v))
homothety(arc::EGHyperbolicArc3, k::Real, center::EGPoint{3}=EGPoint(0.0, 0.0, 0.0)) =
    EGHyperbolicArc3(homothety(arc.hyperbola, k, center), homothety(arc.p1, k, center), homothety(arc.p2, k, center))
reflection(arc::EGHyperbolicArc3, about) = EGHyperbolicArc3(reflection(arc.hyperbola, about), reflection(arc.p1, about), reflection(arc.p2, about))
