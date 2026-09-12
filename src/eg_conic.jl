# -------------------------------------------------------------------------
# Phase 4 of the EG-prefixed type hierarchy rewrite (see
# .claude/plans/structured-wibbling-wigderson.md): EGCircle2, EGEllipse2,
# EGParabola2, EGHyperbola2 (<: EGConic2), and EGCircularArc2,
# EGEllipticArc2, EGParabolicArc2, EGHyperbolicArc2 (<: EGConicArc2).
# Coexists with the existing Point2-based Circle/Ellipse/Parabola/
# Hyperbola/CircularArc for now.
#
# Deliberately out of scope here (deferred alongside the rest of
# intersections.jl/tangency.jl/apollonius.jl/radical_axis.jl/inversion.jl,
# which need `intersection`/quadratic-solving/tangency machinery not yet
# ported): `intersection(::EGLine, _)`, `polar_line`, `tangent_points`,
# `tangent_lines`, and everything Circle-specific about tangency/Apollonius
# problems/inversion/radical axes.
# -------------------------------------------------------------------------

"""
    EGConic2{T} <: EGCurve{2,T}

The parent of the four 2D conic types: [`EGCircle2`](@ref),
[`EGEllipse2`](@ref), [`EGParabola2`](@ref), [`EGHyperbola2`](@ref).
`EGCircle2` is a *sibling* here, not a subtype of `EGEllipse2` — despite
being the degenerate `a == b` case mathematically, it's a genuinely
different (simpler, one-parameter) struct rather than an `EGEllipse2`
with equal axes.
"""
abstract type EGConic2{T} <: EGCurve{2,T} end

"""
    EGConicArc2{T} <: EGCurve{2,T}

The parent of the four conic-arc types, each a bounded piece of the
matching [`EGConic2`](@ref): [`EGCircularArc2`](@ref), `EGEllipticArc2`,
`EGParabolicArc2`, `EGHyperbolicArc2`. For the two closed conics (circle,
ellipse) two points leave a "which way around" ambiguity, so
`reflection` about an `EGLine` swaps the arc's endpoints to stay a true
mirror image rather than jumping to the complementary arc; the two open
curves (parabola, a single hyperbola branch) have no such ambiguity, so
their `reflection` never swaps.
"""
abstract type EGConicArc2{T} <: EGCurve{2,T} end

_to_local_frame(p::EGPoint, origin::EGPoint, u::EGVector, w::EGVector) = (dot(p - origin, u), dot(p - origin, w))
function _to_local_frame(p::EGPoint, origin::EGPoint, angle::Real)
    c, s = cos(angle), sin(angle)
    return _to_local_frame(p, origin, EGVector(c, s), EGVector(-s, c))
end
_from_local_frame(x::Real, y::Real, origin::EGPoint, u::EGVector, w::EGVector) = origin + x * u + y * w
function _from_local_frame(x::Real, y::Real, origin::EGPoint, angle::Real)
    c, s = cos(angle), sin(angle)
    return _from_local_frame(x, y, origin, EGVector(c, s), EGVector(-s, c))
end

# --- EGCircle2 --------------------------------------------------------------

"""
    EGCircle2(center, r)
"""
struct EGCircle2{T<:Real} <: EGConic2{T}
    center::EGPoint{2,T}
    r::T
end
EGCircle2(center::EGPoint{2,T1}, r::T2) where {T1,T2} = EGCircle2{promote_type(T1, T2)}(center, promote_type(T1, T2)(r))

Base.:(==)(a::EGCircle2, b::EGCircle2) = a.center == b.center && a.r == b.r
Base.isapprox(a::EGCircle2, b::EGCircle2; kwargs...) = isapprox(a.center, b.center; kwargs...) && isapprox(a.r, b.r; kwargs...)
Base.show(io::IO, c::EGCircle2) = print(io, "EGCircle2(", c.center, ", ", c.r, ")")
Base.in(p::EGPoint, c::EGCircle2) = distance(p, c.center) <= c.r
area(c::EGCircle2) = pi * c.r^2
perimeter(c::EGCircle2) = 2 * pi * c.r

rotate(c::EGCircle2, angle::Real, center::EGPoint=EGPoint(0.0, 0.0)) = EGCircle2(rotate(c.center, angle, center), c.r)
homothety(c::EGCircle2, k::Real, center::EGPoint=EGPoint(0.0, 0.0)) = EGCircle2(homothety(c.center, k, center), abs(k) * c.r)
reflection(c::EGCircle2, about) = EGCircle2(reflection(c.center, about), c.r)

EGBoundingBox(c::EGCircle2) = EGBoundingBox(c.center - EGPoint(c.r, c.r), c.center + EGPoint(c.r, c.r))

# --- EGEllipse2 --------------------------------------------------------------

"""
    EGEllipse2(center, a, b, angle=0.0)
    EGEllipse2(f1::EGPoint, f2::EGPoint, a::Real)
    EGEllipse2(f1::EGPoint, f2::EGPoint, p::EGPoint)
"""
struct EGEllipse2{T<:Real} <: EGConic2{T}
    center::EGPoint{2,T}
    a::T
    b::T
    angle::T
end
function EGEllipse2(center::EGPoint{2}, a::Real, b::Real, angle::Real=0.0)
    T = promote_type(eltype(center), typeof(float(a)), typeof(float(b)), typeof(float(angle)))
    return EGEllipse2{T}(EGPoint{2,T}(center.coords), T(a), T(b), T(angle))
end
function EGEllipse2(f1::EGPoint{2}, f2::EGPoint{2}, a::Real)
    c = distance(f1, f2) / 2
    a <= c && throw(ArgumentError("EGEllipse2: a must be greater than half the distance between the foci"))
    d = f2 - f1
    return EGEllipse2(midpoint(f1, f2), a, sqrt(a^2 - c^2), atan(d[2], d[1]))
end
EGEllipse2(f1::EGPoint{2}, f2::EGPoint{2}, p::EGPoint{2}) = EGEllipse2(f1, f2, (distance(p, f1) + distance(p, f2)) / 2)

Base.:(==)(x::EGEllipse2, y::EGEllipse2) = x.center == y.center && x.a == y.a && x.b == y.b && x.angle == y.angle
Base.isapprox(x::EGEllipse2, y::EGEllipse2; kwargs...) =
    isapprox(x.center, y.center; kwargs...) && isapprox(x.a, y.a; kwargs...) &&
    isapprox(x.b, y.b; kwargs...) && isapprox(x.angle, y.angle; kwargs...)
Base.show(io::IO, e::EGEllipse2) = print(io, "EGEllipse2(center=", e.center, ", a=", e.a, ", b=", e.b, ", angle=", e.angle, ")")

_to_ellipse_local(p::EGPoint, e::EGEllipse2) = _to_local_frame(p, e.center, e.angle)
_from_ellipse_local(x, y, e::EGEllipse2) = _from_local_frame(x, y, e.center, e.angle)

Base.in(p::EGPoint, e::EGEllipse2) = begin
    lx, ly = _to_ellipse_local(p, e)
    (lx / e.a)^2 + (ly / e.b)^2 <= 1
end

"""
    point_on_ellipse(e::EGEllipse2, t::Real)
"""
point_on_ellipse(e::EGEllipse2, t::Real) = _from_ellipse_local(e.a * cos(t), e.b * sin(t), e)

"""
    is_on_ellipse(p::EGPoint, e::EGEllipse2; atol=1e-9)
"""
function is_on_ellipse(p::EGPoint, e::EGEllipse2; atol=1e-9)
    lx, ly = _to_ellipse_local(p, e)
    return abs((lx / e.a)^2 + (ly / e.b)^2 - 1) <= atol
end

area(e::EGEllipse2) = pi * e.a * e.b
function perimeter(e::EGEllipse2)
    a, b = e.a, e.b
    h = ((a - b) / (a + b))^2
    return pi * (a + b) * (1 + 3h / (10 + sqrt(4 - 3h)))
end

"""
    orthoptic(e::EGEllipse2)

The orthoptic (director) circle of `e`: the locus of points from which the
two tangent lines to `e` are perpendicular. Always a real circle, of
radius `sqrt(a^2 + b^2)` centered at `e.center`.
"""
orthoptic(e::EGEllipse2) = EGCircle2(e.center, sqrt(e.a^2 + e.b^2))

"""
    foci(e::EGEllipse2)

The two foci of `e`, as a 2-tuple.
"""
function foci(e::EGEllipse2)
    c = sqrt(abs(e.a^2 - e.b^2))
    dir = e.a >= e.b ? EGVector(cos(e.angle), sin(e.angle)) : EGVector(-sin(e.angle), cos(e.angle))
    return (e.center + c * dir, e.center - c * dir)
end

rotate(e::EGEllipse2, angle::Real, center::EGPoint=EGPoint(0.0, 0.0)) =
    EGEllipse2(rotate(e.center, angle, center), e.a, e.b, e.angle + angle)
homothety(e::EGEllipse2, k::Real, center::EGPoint=EGPoint(0.0, 0.0)) =
    EGEllipse2(homothety(e.center, k, center), abs(k) * e.a, abs(k) * e.b, e.angle)
reflection(e::EGEllipse2, about::EGPoint) = EGEllipse2(reflection(e.center, about), e.a, e.b, e.angle)
function reflection(e::EGEllipse2, about::EGLine)
    φ = atan(direction(about)[2], direction(about)[1])
    return EGEllipse2(reflection(e.center, about), e.a, e.b, 2 * φ - e.angle)
end

# --- EGHyperbola2 ------------------------------------------------------------

"""
    EGHyperbola2(center, a, b, angle=0.0)
    EGHyperbola2(f1::EGPoint, f2::EGPoint, a::Real)
    EGHyperbola2(f1::EGPoint, f2::EGPoint, p::EGPoint)
"""
struct EGHyperbola2{T<:Real} <: EGConic2{T}
    center::EGPoint{2,T}
    a::T
    b::T
    angle::T
end
function EGHyperbola2(center::EGPoint{2}, a::Real, b::Real, angle::Real=0.0)
    T = promote_type(eltype(center), typeof(float(a)), typeof(float(b)), typeof(float(angle)))
    return EGHyperbola2{T}(EGPoint{2,T}(center.coords), T(a), T(b), T(angle))
end
function EGHyperbola2(f1::EGPoint{2}, f2::EGPoint{2}, a::Real)
    c = distance(f1, f2) / 2
    a >= c && throw(ArgumentError("EGHyperbola2: a must be less than half the distance between the foci"))
    d = f2 - f1
    return EGHyperbola2(midpoint(f1, f2), a, sqrt(c^2 - a^2), atan(d[2], d[1]))
end
EGHyperbola2(f1::EGPoint{2}, f2::EGPoint{2}, p::EGPoint{2}) = EGHyperbola2(f1, f2, abs(distance(p, f1) - distance(p, f2)) / 2)

Base.:(==)(x::EGHyperbola2, y::EGHyperbola2) = x.center == y.center && x.a == y.a && x.b == y.b && x.angle == y.angle
Base.isapprox(x::EGHyperbola2, y::EGHyperbola2; kwargs...) =
    isapprox(x.center, y.center; kwargs...) && isapprox(x.a, y.a; kwargs...) &&
    isapprox(x.b, y.b; kwargs...) && isapprox(x.angle, y.angle; kwargs...)
Base.show(io::IO, h::EGHyperbola2) = print(io, "EGHyperbola2(center=", h.center, ", a=", h.a, ", b=", h.b, ", angle=", h.angle, ")")

_to_hyperbola_local(p::EGPoint, h::EGHyperbola2) = _to_local_frame(p, h.center, h.angle)
_from_hyperbola_local(x, y, h::EGHyperbola2) = _from_local_frame(x, y, h.center, h.angle)

Base.in(p::EGPoint, h::EGHyperbola2) = begin
    lx, ly = _to_hyperbola_local(p, h)
    (lx / h.a)^2 - (ly / h.b)^2 >= 1
end

"""
    point_on_hyperbola(h::EGHyperbola2, t::Real; branch::Int=1)
"""
function point_on_hyperbola(h::EGHyperbola2, t::Real; branch::Int=1)
    x, y = branch * h.a * cosh(t), h.b * sinh(t)
    return _from_hyperbola_local(x, y, h)
end

"""
    is_on_hyperbola(p::EGPoint, h::EGHyperbola2; atol=1e-9)
"""
function is_on_hyperbola(p::EGPoint, h::EGHyperbola2; atol=1e-9)
    lx, ly = _to_hyperbola_local(p, h)
    return abs((lx / h.a)^2 - (ly / h.b)^2 - 1) <= atol
end

"""
    foci(h::EGHyperbola2)

The two foci of `h`, as a 2-tuple.
"""
function foci(h::EGHyperbola2)
    c = sqrt(h.a^2 + h.b^2)
    dir = EGVector(cos(h.angle), sin(h.angle))
    return (h.center + c * dir, h.center - c * dir)
end

"""
    orthoptic(h::EGHyperbola2)

The orthoptic (director) circle of `h`: the locus of points from which the
two tangent lines to `h` are perpendicular. Only real when `a > b` (radius
`sqrt(a^2 - b^2)`, centered at `h.center`); throws an `ArgumentError`
otherwise, since then no real such circle exists.
"""
function orthoptic(h::EGHyperbola2)
    h.a <= h.b && throw(ArgumentError("orthoptic: no real orthoptic circle exists when a <= b"))
    return EGCircle2(h.center, sqrt(h.a^2 - h.b^2))
end

"""
    asymptotes(h::EGHyperbola2)

The two asymptote lines of `h`, as a 2-tuple.
"""
function asymptotes(h::EGHyperbola2)
    p1 = _from_hyperbola_local(h.a, h.b, h)
    p2 = _from_hyperbola_local(h.a, -h.b, h)
    return (EGLine(h.center, p1), EGLine(h.center, p2))
end

rotate(h::EGHyperbola2, angle::Real, center::EGPoint=EGPoint(0.0, 0.0)) =
    EGHyperbola2(rotate(h.center, angle, center), h.a, h.b, h.angle + angle)
homothety(h::EGHyperbola2, k::Real, center::EGPoint=EGPoint(0.0, 0.0)) =
    EGHyperbola2(homothety(h.center, k, center), abs(k) * h.a, abs(k) * h.b, h.angle)
reflection(h::EGHyperbola2, about::EGPoint) = EGHyperbola2(reflection(h.center, about), h.a, h.b, h.angle)
function reflection(h::EGHyperbola2, about::EGLine)
    φ = atan(direction(about)[2], direction(about)[1])
    return EGHyperbola2(reflection(h.center, about), h.a, h.b, 2 * φ - h.angle)
end

# --- EGParabola2 -------------------------------------------------------------

"""
    EGParabola2(focus::EGPoint, directrix::EGLine)
"""
struct EGParabola2{T<:Real} <: EGConic2{T}
    focus::EGPoint{2,T}
    directrix::EGLine{2,T}
end
function EGParabola2(focus::EGPoint{2,T1}, directrix::EGLine{2,T2}) where {T1,T2}
    T = promote_type(T1, T2)
    return EGParabola2{T}(EGPoint{2,T}(focus.coords), EGLine{2,T}(directrix.p1, directrix.p2))
end

Base.:(==)(x::EGParabola2, y::EGParabola2) = x.focus == y.focus && x.directrix == y.directrix
Base.isapprox(x::EGParabola2, y::EGParabola2; kwargs...) =
    isapprox(x.focus, y.focus; kwargs...) && isapprox(x.directrix, y.directrix; kwargs...)
Base.show(io::IO, par::EGParabola2) = print(io, "EGParabola2(focus=", par.focus, ", directrix=", par.directrix, ")")

Base.in(p::EGPoint, par::EGParabola2) = distance(p, par.focus) <= distance(p, par.directrix)

"""
    vertex(par::EGParabola2)

The vertex of `par`: the midpoint between its focus and the foot of the
perpendicular from the focus to the directrix.
"""
vertex(par::EGParabola2) = midpoint(par.focus, projection(par.focus, par.directrix))

"""
    focal_parameter(par::EGParabola2)

The distance between the focus and the directrix of `par` (often denoted `p`).
"""
focal_parameter(par::EGParabola2) = distance(par.focus, par.directrix)

"""
    orthoptic(par::EGParabola2)

The orthoptic curve of `par`: the locus of points from which the two
tangent lines to `par` are perpendicular. For a parabola this is,
somewhat surprisingly, exactly its own directrix.
"""
orthoptic(par::EGParabola2) = par.directrix

function _parabola_frame(par::EGParabola2)
    foot = projection(par.focus, par.directrix)
    u = (par.focus - foot) / norm(par.focus - foot)
    return midpoint(par.focus, foot), EGVector(u), orthogonal(EGVector(u))
end

"""
    point_on_parabola(par::EGParabola2, s::Real)
"""
function point_on_parabola(par::EGParabola2, s::Real)
    V, u, w = _parabola_frame(par)
    p = focal_parameter(par)
    return _from_local_frame(s^2 / (2p), s, V, u, w)
end

"""
    is_on_parabola(p::EGPoint, par::EGParabola2; atol=1e-9)
"""
is_on_parabola(p::EGPoint, par::EGParabola2; atol=1e-9) =
    abs(distance(p, par.focus) - distance(p, par.directrix)) <=
    sqrt(atol) * max(norm(p), norm(par.focus), 1.0)

rotate(par::EGParabola2, angle::Real, center::EGPoint=EGPoint(0.0, 0.0)) =
    EGParabola2(rotate(par.focus, angle, center), rotate(par.directrix, angle, center))
reflection(par::EGParabola2, about) = EGParabola2(reflection(par.focus, about), reflection(par.directrix, about))
homothety(par::EGParabola2, k::Real, center::EGPoint=EGPoint(0.0, 0.0)) =
    EGParabola2(homothety(par.focus, k, center), homothety(par.directrix, k, center))

# --- EGCircularArc2 -----------------------------------------------------------

"""
    EGCircularArc2(circle::EGCircle2, p1::EGPoint, p2::EGPoint)

The arc of `circle` traversed counterclockwise from `p1` to `p2`.
"""
struct EGCircularArc2{T<:Real} <: EGConicArc2{T}
    circle::EGCircle2{T}
    p1::EGPoint{2,T}
    p2::EGPoint{2,T}
end
function EGCircularArc2(circle::EGCircle2{T1}, p1::EGPoint{2,T2}, p2::EGPoint{2,T3}) where {T1,T2,T3}
    T = promote_type(T1, T2, T3)
    return EGCircularArc2{T}(EGCircle2{T}(EGPoint{2,T}(circle.center.coords), T(circle.r)), EGPoint{2,T}(p1.coords), EGPoint{2,T}(p2.coords))
end

Base.:(==)(x::EGCircularArc2, y::EGCircularArc2) = x.circle == y.circle && x.p1 == y.p1 && x.p2 == y.p2
Base.isapprox(x::EGCircularArc2, y::EGCircularArc2; kwargs...) =
    isapprox(x.circle, y.circle; kwargs...) && isapprox(x.p1, y.p1; kwargs...) && isapprox(x.p2, y.p2; kwargs...)
Base.show(io::IO, arc::EGCircularArc2) = print(io, "EGCircularArc2(", arc.circle, ", ", arc.p1, " -> ", arc.p2, ")")

_arc_angle(arc::EGCircularArc2, p::EGPoint) = atan(p[2] - arc.circle.center[2], p[1] - arc.circle.center[1])

"""
    measure(arc::EGCircularArc2)
"""
measure(arc::EGCircularArc2) = mod(_arc_angle(arc, arc.p2) - _arc_angle(arc, arc.p1), 2π)

"""
    arc_length(arc::EGCircularArc2)

The length of `arc`: `circle.r * measure(arc)`.
"""
arc_length(arc::EGCircularArc2) = arc.circle.r * measure(arc)

"""
    point_on_arc(arc, t::Real)

The point on `arc` at parameter `t` (`t = 0` gives `arc.p1`, `t = 1`
gives `arc.p2`) — defined for [`EGCircularArc2`](@ref), `EGEllipticArc2`,
`EGParabolicArc2` and `EGHyperbolicArc2`.
"""
function point_on_arc(arc::EGCircularArc2, t::Real)
    a = _arc_angle(arc, arc.p1) + t * measure(arc)
    return arc.circle.center + arc.circle.r * EGPoint(cos(a), sin(a))
end
midpoint(arc::EGCircularArc2) = point_on_arc(arc, 0.5)

rotate(arc::EGCircularArc2, angle::Real, center::EGPoint=EGPoint(0.0, 0.0)) =
    EGCircularArc2(rotate(arc.circle, angle, center), rotate(arc.p1, angle, center), rotate(arc.p2, angle, center))
homothety(arc::EGCircularArc2, k::Real, center::EGPoint=EGPoint(0.0, 0.0)) =
    EGCircularArc2(homothety(arc.circle, k, center), homothety(arc.p1, k, center), homothety(arc.p2, k, center))
reflection(arc::EGCircularArc2, about::EGPoint) =
    EGCircularArc2(reflection(arc.circle, about), reflection(arc.p1, about), reflection(arc.p2, about))
reflection(arc::EGCircularArc2, about::EGLine) =
    EGCircularArc2(reflection(arc.circle, about), reflection(arc.p2, about), reflection(arc.p1, about))

# --- EGEllipticArc2 -----------------------------------------------------------

"""
    EGEllipticArc2(ellipse::EGEllipse2, p1::EGPoint, p2::EGPoint)

The arc of `ellipse` traversed counterclockwise (in the ellipse's own
parametrization) from `p1` to `p2` — the ellipse analogue of
[`EGCircularArc2`](@ref), same swept/complementary-arc convention.
"""
struct EGEllipticArc2{T<:Real} <: EGConicArc2{T}
    ellipse::EGEllipse2{T}
    p1::EGPoint{2,T}
    p2::EGPoint{2,T}
end

function _ellipse_param(e::EGEllipse2, p::EGPoint)
    lx, ly = _to_ellipse_local(p, e)
    return atan(ly / e.b, lx / e.a)
end
_ellipse_param(arc::EGEllipticArc2, p::EGPoint) = _ellipse_param(arc.ellipse, p)

"""
    measure(arc::EGEllipticArc2)

The swept parameter range from `p1` to `p2`, counterclockwise, in
`[0, 2π)` (the ellipse's own angular parameter, not true arc angle).
"""
measure(arc::EGEllipticArc2) = mod(_ellipse_param(arc, arc.p2) - _ellipse_param(arc, arc.p1), 2π)

function point_on_arc(arc::EGEllipticArc2, t::Real)
    a = _ellipse_param(arc, arc.p1) + t * measure(arc)
    return point_on_ellipse(arc.ellipse, a)
end
midpoint(arc::EGEllipticArc2) = point_on_arc(arc, 0.5)

rotate(arc::EGEllipticArc2, angle::Real, center::EGPoint=EGPoint(0.0, 0.0)) =
    EGEllipticArc2(rotate(arc.ellipse, angle, center), rotate(arc.p1, angle, center), rotate(arc.p2, angle, center))
homothety(arc::EGEllipticArc2, k::Real, center::EGPoint=EGPoint(0.0, 0.0)) =
    EGEllipticArc2(homothety(arc.ellipse, k, center), homothety(arc.p1, k, center), homothety(arc.p2, k, center))
reflection(arc::EGEllipticArc2, about::EGPoint) =
    EGEllipticArc2(reflection(arc.ellipse, about), reflection(arc.p1, about), reflection(arc.p2, about))
reflection(arc::EGEllipticArc2, about::EGLine) =
    EGEllipticArc2(reflection(arc.ellipse, about), reflection(arc.p2, about), reflection(arc.p1, about))

# --- EGParabolicArc2 ----------------------------------------------------------

"""
    EGParabolicArc2(parabola::EGParabola2, p1::EGPoint, p2::EGPoint)

The arc of `parabola` between `p1` and `p2`. Unlike a circle/ellipse (a
closed curve, where two points leave the "which way around" arc
ambiguous), a parabola is open — two points on it always determine a
single, unambiguous arc, with no complementary alternative — so, unlike
[`EGCircularArc2`](@ref)/[`EGEllipticArc2`](@ref), `reflection` never
needs to swap `p1`/`p2`.
"""
struct EGParabolicArc2{T<:Real} <: EGConicArc2{T}
    parabola::EGParabola2{T}
    p1::EGPoint{2,T}
    p2::EGPoint{2,T}
end

function _parabola_param(par::EGParabola2, p::EGPoint)
    V, u, w = _parabola_frame(par)
    _, y = _to_local_frame(p, V, u, w)
    return y
end
_parabola_param(arc::EGParabolicArc2, p::EGPoint) = _parabola_param(arc.parabola, p)

function point_on_arc(arc::EGParabolicArc2, t::Real)
    s1, s2 = _parabola_param(arc, arc.p1), _parabola_param(arc, arc.p2)
    return point_on_parabola(arc.parabola, s1 + t * (s2 - s1))
end
midpoint(arc::EGParabolicArc2) = point_on_arc(arc, 0.5)

rotate(arc::EGParabolicArc2, angle::Real, center::EGPoint=EGPoint(0.0, 0.0)) =
    EGParabolicArc2(rotate(arc.parabola, angle, center), rotate(arc.p1, angle, center), rotate(arc.p2, angle, center))
homothety(arc::EGParabolicArc2, k::Real, center::EGPoint=EGPoint(0.0, 0.0)) =
    EGParabolicArc2(homothety(arc.parabola, k, center), homothety(arc.p1, k, center), homothety(arc.p2, k, center))
reflection(arc::EGParabolicArc2, about) =
    EGParabolicArc2(reflection(arc.parabola, about), reflection(arc.p1, about), reflection(arc.p2, about))

# --- EGHyperbolicArc2 ---------------------------------------------------------

"""
    EGHyperbolicArc2(hyperbola::EGHyperbola2, p1::EGPoint, p2::EGPoint)

The arc of `hyperbola` between `p1` and `p2`, assumed to lie on the same
branch. Like [`EGParabolicArc2`](@ref) (and unlike the closed conics), a
single branch of a hyperbola is open, so `reflection` never needs to swap
`p1`/`p2`.
"""
struct EGHyperbolicArc2{T<:Real} <: EGConicArc2{T}
    hyperbola::EGHyperbola2{T}
    p1::EGPoint{2,T}
    p2::EGPoint{2,T}
end

function _hyperbola_param(h::EGHyperbola2, p::EGPoint)
    lx, ly = _to_hyperbola_local(p, h)
    return asinh(ly / h.b), (lx >= 0 ? 1 : -1)
end
_hyperbola_param(arc::EGHyperbolicArc2, p::EGPoint) = _hyperbola_param(arc.hyperbola, p)

function point_on_arc(arc::EGHyperbolicArc2, t::Real)
    t1, branch = _hyperbola_param(arc, arc.p1)
    t2, _ = _hyperbola_param(arc, arc.p2)
    return point_on_hyperbola(arc.hyperbola, t1 + t * (t2 - t1); branch=branch)
end
midpoint(arc::EGHyperbolicArc2) = point_on_arc(arc, 0.5)

rotate(arc::EGHyperbolicArc2, angle::Real, center::EGPoint=EGPoint(0.0, 0.0)) =
    EGHyperbolicArc2(rotate(arc.hyperbola, angle, center), rotate(arc.p1, angle, center), rotate(arc.p2, angle, center))
homothety(arc::EGHyperbolicArc2, k::Real, center::EGPoint=EGPoint(0.0, 0.0)) =
    EGHyperbolicArc2(homothety(arc.hyperbola, k, center), homothety(arc.p1, k, center), homothety(arc.p2, k, center))
reflection(arc::EGHyperbolicArc2, about) =
    EGHyperbolicArc2(reflection(arc.hyperbola, about), reflection(arc.p1, about), reflection(arc.p2, about))
