# -------------------------------------------------------------------------
# EGCircle2, EGEllipse2, EGParabola2, EGHyperbola2 (<: EGConic2), and
# EGCircularArc2, EGEllipticArc2, EGParabolicArc2, EGHyperbolicArc2
# (<: EGConicArc2).
#
# `intersection(::EGLine, _)`, `polar_line`, `tangent_points`,
# `tangent_lines`, and everything Circle-specific about tangency/Apollonius
# problems/inversion/radical axes live in the later-included
# eg_intersections.jl/eg_tangency.jl/eg_apollonius.jl/eg_radical_axis.jl/
# eg_inversion.jl instead, since those need machinery (quadratic-solving,
# tangency helpers) defined there.
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

# Composite Simpson's rule, used for `arc_length` on the three conic-arc
# types with no elementary closed form for arc length (unlike
# `EGCircularArc2`): the integrand (parametrization speed) is smooth and
# non-singular on a bounded arc, so a fixed, moderately fine rule already
# converges to machine precision — no adaptivity needed.
function _simpson_integrate(f, t0::Real, t1::Real; n::Int=128)
    n = isodd(n) ? n + 1 : n
    h = (t1 - t0) / n
    total = f(t0) + f(t1)
    for i in 1:n-1
        total += f(t0 + i * h) * (isodd(i) ? 4 : 2)
    end
    return total * h / 3
end

# --- EGCircle2 --------------------------------------------------------------

"""
    EGCircle2(center, r)
"""
struct EGCircle2{T<:Real} <: EGConic2{T}
    center::EGPoint{2,T}
    r::T
end
EGCircle2(center::EGPoint{2,T1}, r::T2) where {T1,T2<:Real} = EGCircle2{promote_type(T1, T2)}(center, promote_type(T1, T2)(r))
EGCircle2(center::Tuple, r::Real) = EGCircle2(_topoint(center), r)

"""
    EGCircle2(center::EGPoint, through::EGPoint)

The circle centered at `center` passing through `through` — same as
`EGCircle2(center, distance(center, through))`, for when a point on the
circle is more natural to give than the radius itself.
"""
EGCircle2(center::EGPointLike, through::EGPointLike) =
    EGCircle2(_topoint(center), distance(_topoint(center), _topoint(through)))

"""
    EGCircle2(p1::EGPoint, p2::EGPoint, p3::EGPoint; atol=1e-9)

The circle through three points — their circumcircle, computed directly
(same formula [`circumcenter`](@ref) uses on an [`EGTriangle`](@ref),
without needing to build one first). Throws an `ArgumentError` if `p1`,
`p2`, `p3` are (or are too close to) collinear, since then no finite
circle passes through all three.
"""
function EGCircle2(p1::EGPointLike, p2::EGPointLike, p3::EGPointLike; atol=1e-9)
    p1, p2, p3 = _topoint(p1), _topoint(p2), _topoint(p3)
    is_collinear(p1, p2, p3; atol=atol) &&
        throw(ArgumentError("EGCircle2: p1, p2, p3 must not be collinear (no finite circle through them)"))
    x1, y1 = p1[1], p1[2]
    x2, y2 = p2[1], p2[2]
    x3, y3 = p3[1], p3[2]
    d = 2 * (x1 * (y2 - y3) + x2 * (y3 - y1) + x3 * (y1 - y2))
    s1, s2, s3 = x1^2 + y1^2, x2^2 + y2^2, x3^2 + y3^2
    ux = (s1 * (y2 - y3) + s2 * (y3 - y1) + s3 * (y1 - y2)) / d
    uy = (s1 * (x3 - x2) + s2 * (x1 - x3) + s3 * (x2 - x1)) / d
    center = EGPoint(ux, uy)
    return EGCircle2(center, distance(center, p1))
end

Base.:(==)(a::EGCircle2, b::EGCircle2) = a.center == b.center && a.r == b.r
Base.convert(::Type{EGCircle2{T}}, c::EGCircle2) where {T} = EGCircle2{T}(c.center, T(c.r))
Base.isapprox(a::EGCircle2, b::EGCircle2; kwargs...) = isapprox(a.center, b.center; kwargs...) && isapprox(a.r, b.r; kwargs...)
Base.show(io::IO, c::EGCircle2) = print(io, "EGCircle2(", c.center, ", ", c.r, ")")
Base.in(p::EGPoint, c::EGCircle2) = distance(p, c.center) <= c.r
area(c::EGCircle2) = pi * c.r^2
perimeter(c::EGCircle2) = 2 * pi * c.r

rotate(c::EGCircle2, angle::Real, center::EGPoint=EGPoint(0.0, 0.0)) = EGCircle2(rotate(c.center, angle, center), c.r)
homothety(c::EGCircle2, k::Real, center::EGPoint=EGPoint(0.0, 0.0)) = EGCircle2(homothety(c.center, k, center), abs(k) * c.r)
reflection(c::EGCircle2, about) = EGCircle2(reflection(c.center, about), c.r)
translate(c::EGCircle2, v::EGVector) = EGCircle2(translate(c.center, v), c.r)

"""
    distance(p::EGPoint, c::EGCircle2)

Distance from `p` to the *curve* of `c` (like every other `EGCurve` — not
to the filled disk `Base.in` tests membership of).
"""
distance(p::EGPoint, c::EGCircle2) = abs(distance(p, c.center) - c.r)
distance(c::EGCircle2, p::EGPoint) = distance(p, c)

"""
    distance(c::EGCircle2, l::EGLine)

`0` if `l` crosses or is tangent to `c`; otherwise the gap between them.
"""
distance(c::EGCircle2, l::EGLine) = max(distance(c.center, l) - c.r, 0.0)
distance(l::EGLine, c::EGCircle2) = distance(c, l)

"""
    distance(c1::EGCircle2, c2::EGCircle2)

The distance between the two *curves*: `0` whenever they touch or cross
(tangent, secant, or one properly inside the other without touching is
the only case this is nonzero for *and* nested — see below), otherwise
the gap — either the external gap (`d - r1 - r2`, when disjoint) or the
gap between a smaller circle and the inside of a bigger one that encloses
it (`|r1-r2| - d`, when nested without touching).
"""
function distance(c1::EGCircle2, c2::EGCircle2)
    d = distance(c1.center, c2.center)
    return max(d - c1.r - c2.r, abs(c1.r - c2.r) - d, 0.0)
end

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
EGEllipse2(center::Tuple, a::Real, b::Real, angle::Real=0.0) = EGEllipse2(_topoint(center), a, b, angle)
function EGEllipse2(f1::EGPointLike, f2::EGPointLike, a::Real)
    f1, f2 = _topoint(f1), _topoint(f2)
    c = distance(f1, f2) / 2
    a <= c && throw(ArgumentError("EGEllipse2: a must be greater than half the distance between the foci"))
    d = f2 - f1
    return EGEllipse2(midpoint(f1, f2), a, sqrt(a^2 - c^2), atan(d[2], d[1]))
end
function EGEllipse2(f1::EGPointLike, f2::EGPointLike, p::EGPointLike)
    f1, f2, p = _topoint(f1), _topoint(f2), _topoint(p)
    return EGEllipse2(f1, f2, (distance(p, f1) + distance(p, f2)) / 2)
end

Base.:(==)(x::EGEllipse2, y::EGEllipse2) = x.center == y.center && x.a == y.a && x.b == y.b && x.angle == y.angle
Base.convert(::Type{EGEllipse2{T}}, e::EGEllipse2) where {T} = EGEllipse2{T}(e.center, T(e.a), T(e.b), T(e.angle))
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

"""
    EGBoundingBox(e::EGEllipse2)

The axis-aligned bounding box of `e`: exact, via the standard closed form
for a rotated ellipse's extent, `half-width = √(a²cos²φ + b²sin²φ)`,
`half-height = √(a²sin²φ + b²cos²φ)`.
"""
function EGBoundingBox(e::EGEllipse2)
    c, s = cos(e.angle), sin(e.angle)
    dx = sqrt((e.a * c)^2 + (e.b * s)^2)
    dy = sqrt((e.a * s)^2 + (e.b * c)^2)
    return EGBoundingBox(e.center - EGPoint(dx, dy), e.center + EGPoint(dx, dy))
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
translate(e::EGEllipse2, v::EGVector) = EGEllipse2(translate(e.center, v), e.a, e.b, e.angle)

# A single Newton run, from starting angle t0, towards a critical point of
# D(t)^2 = (a*cos(t)-lx)^2 + (b*sin(t)-ly)^2 — i.e. a root of
# g(t) = sin(t)cos(t)(b^2-a^2) + a*lx*sin(t) - b*ly*cos(t), the
# stationarity condition (no closed form exists for the closest point on
# an ellipse, unlike every other conic formula in this package).
function _newton_ellipse_t(t0::Real, lx::Real, ly::Real, a::Real, b::Real; atol=1e-12, maxiter=100)
    t = t0
    for _ in 1:maxiter
        st, ct = sincos(t)
        g = st * ct * (b^2 - a^2) + a * lx * st - b * ly * ct
        gp = (b^2 - a^2) * cos(2t) + a * lx * ct + b * ly * st
        abs(gp) <= atol && break
        Δ = g / gp
        t -= Δ
        abs(Δ) <= atol && break
    end
    return t
end

# The parameter t (in point_on_ellipse's own convention) of the closest
# point on the FULL ellipse to a point given in the ellipse's local
# (lx, ly) coordinates. g (see `_newton_ellipse_t`) has up to 4 roots (the
# ellipse's 4 axis-aligned critical points, for a point near the center)
# and Newton from a single start can converge to the wrong one (a local
# max, or the farther of two local minima) — so this tries several
# evenly-spread starting angles and keeps whichever converged root gives
# the smallest actual distance, rather than trusting the first one found.
function _closest_ellipse_local_param(lx::Real, ly::Real, a::Real, b::Real; atol=1e-12, maxiter=100)
    best_t, best_d2 = 0.0, Inf
    for t0 in (atan(ly / b, lx / a), 0.0, pi / 4, pi / 2, 3pi / 4, pi, 5pi / 4, 3pi / 2, 7pi / 4)
        t = _newton_ellipse_t(t0, lx, ly, a, b; atol=atol, maxiter=maxiter)
        cx, cy = a * cos(t), b * sin(t)
        d2 = (lx - cx)^2 + (ly - cy)^2
        if d2 < best_d2
            best_d2 = d2
            best_t = t
        end
    end
    return best_t
end

# The smallest distance from (lx,ly) to the point of the FULL ellipse
# whose own parameter lands within [t1, t1+m] (m = the arc's own
# `measure`), or `Inf` if no critical point does — used by
# `distance(::EGPoint, ::EGEllipticArc2)`. Restricting an unconstrained
# closest-point search to an arc isn't just "check whether the global
# minimum happens to land in range": the *restricted* problem can have its
# own local minimum, elsewhere in the range, that the global search never
# needed to find — so this seeds Newton with starting angles spread across
# the arc's own range instead of fixed absolute angles.
function _closest_ellipse_local_param_in_range(lx::Real, ly::Real, a::Real, b::Real, t1::Real, m::Real; atol=1e-12, maxiter=100)
    best_d2 = Inf
    nstarts = max(8, ceil(Int, m / (pi / 6)))
    for k in 0:nstarts
        t0 = t1 + m * k / nstarts
        t = _newton_ellipse_t(t0, lx, ly, a, b; atol=atol, maxiter=maxiter)
        Δ = mod(t - t1, 2π)
        (Δ <= m + 1e-7 || Δ >= 2π - 1e-7) || continue
        cx, cy = a * cos(t), b * sin(t)
        best_d2 = min(best_d2, (lx - cx)^2 + (ly - cy)^2)
    end
    return sqrt(best_d2)
end

"""
    distance(p::EGPoint, e::EGEllipse2)

Distance from `p` to the curve of `e`. Unlike every other conic distance
in this package, there's no closed form for this — it's found by Newton's
method on the ellipse's own parametrization (essentially exact in
practice, converging to machine precision in a handful of iterations for
any non-degenerate ellipse).
"""
function distance(p::EGPoint, e::EGEllipse2)
    lx, ly = _to_ellipse_local(p, e)
    isapprox(e.a, e.b) && return abs(sqrt(lx^2 + ly^2) - e.a)
    t = _closest_ellipse_local_param(lx, ly, e.a, e.b)
    cx, cy = e.a * cos(t), e.b * sin(t)
    return sqrt((lx - cx)^2 + (ly - cy)^2)
end
distance(e::EGEllipse2, p::EGPoint) = distance(p, e)

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
EGHyperbola2(center::Tuple, a::Real, b::Real, angle::Real=0.0) = EGHyperbola2(_topoint(center), a, b, angle)
function EGHyperbola2(f1::EGPointLike, f2::EGPointLike, a::Real)
    f1, f2 = _topoint(f1), _topoint(f2)
    c = distance(f1, f2) / 2
    a >= c && throw(ArgumentError("EGHyperbola2: a must be less than half the distance between the foci"))
    d = f2 - f1
    return EGHyperbola2(midpoint(f1, f2), a, sqrt(c^2 - a^2), atan(d[2], d[1]))
end
function EGHyperbola2(f1::EGPointLike, f2::EGPointLike, p::EGPointLike)
    f1, f2, p = _topoint(f1), _topoint(f2), _topoint(p)
    return EGHyperbola2(f1, f2, abs(distance(p, f1) - distance(p, f2)) / 2)
end

Base.:(==)(x::EGHyperbola2, y::EGHyperbola2) = x.center == y.center && x.a == y.a && x.b == y.b && x.angle == y.angle
Base.convert(::Type{EGHyperbola2{T}}, h::EGHyperbola2) where {T} = EGHyperbola2{T}(h.center, T(h.a), T(h.b), T(h.angle))
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
translate(h::EGHyperbola2, v::EGVector) = EGHyperbola2(translate(h.center, v), h.a, h.b, h.angle)

# A single Newton run, from starting parameter t0, towards a critical
# point of D(t)^2 = (branch*a*cosh(t)-lx)^2 + (b*sinh(t)-ly)^2 on the
# given branch — i.e. a root of g(t) = sinh(t)cosh(t)(a^2+b^2) -
# branch*a*lx*sinh(t) - b*ly*cosh(t), the stationarity condition (no
# closed form exists for the closest point on a hyperbola).
function _newton_hyperbola_t(t0::Real, lx::Real, ly::Real, a::Real, b::Real, branch::Int; atol=1e-12, maxiter=100)
    t = t0
    for _ in 1:maxiter
        st, ct = sinh(t), cosh(t)
        g = st * ct * (a^2 + b^2) - branch * a * lx * st - b * ly * ct
        gp = (a^2 + b^2) * cosh(2t) - branch * a * lx * ct - b * ly * st
        abs(gp) <= atol && break
        Δ = g / gp
        t -= Δ
        abs(Δ) <= atol && break
    end
    return t
end

# The parameter t (in point_on_hyperbola's own convention, on the given
# branch) of the closest point on that one branch to a point given in the
# hyperbola's local (lx, ly) coordinates. Same idea as
# `_closest_ellipse_local_param`: several starting points are tried (a
# single Newton start isn't always in the right basin of attraction),
# keeping whichever converged root gives the smallest actual distance.
function _closest_hyperbola_local_param(lx::Real, ly::Real, a::Real, b::Real, branch::Int; atol=1e-12, maxiter=100)
    best_t, best_d2 = 0.0, Inf
    for t0 in (asinh(ly / b), 0.0, 1.0, -1.0, 2.0, -2.0, 4.0, -4.0)
        t = _newton_hyperbola_t(t0, lx, ly, a, b, branch; atol=atol, maxiter=maxiter)
        cx, cy = branch * a * cosh(t), b * sinh(t)
        d2 = (lx - cx)^2 + (ly - cy)^2
        if d2 < best_d2
            best_d2 = d2
            best_t = t
        end
    end
    return best_t
end

# The smallest distance from (lx,ly) to the point of the given branch
# whose own parameter lands within [min(t1,t2), max(t1,t2)], or `Inf` if
# no critical point does — used by
# `distance(::EGPoint, ::EGHyperbolicArc2)`, for the same reason
# `_closest_ellipse_local_param_in_range` exists: the range-restricted
# problem can have its own local minimum that the global search never
# needed to find, so Newton is seeded with starts spread across the arc's
# own range instead of fixed absolute values.
function _closest_hyperbola_local_param_in_range(lx::Real, ly::Real, a::Real, b::Real, branch::Int, tmin::Real, tmax::Real; atol=1e-12, maxiter=100, nstarts=12)
    best_d2 = Inf
    for k in 0:nstarts
        t0 = tmin + (tmax - tmin) * k / nstarts
        t = _newton_hyperbola_t(t0, lx, ly, a, b, branch; atol=atol, maxiter=maxiter)
        (tmin - 1e-7 <= t <= tmax + 1e-7) || continue
        cx, cy = branch * a * cosh(t), b * sinh(t)
        best_d2 = min(best_d2, (lx - cx)^2 + (ly - cy)^2)
    end
    return sqrt(best_d2)
end

"""
    distance(p::EGPoint, h::EGHyperbola2)

Distance from `p` to the curve of `h` (either branch — whichever is
closer). Like [`distance(::EGPoint, ::EGEllipse2)`](@ref), found via
Newton's method rather than a closed form.
"""
function distance(p::EGPoint, h::EGHyperbola2)
    lx, ly = _to_hyperbola_local(p, h)
    best = Inf
    for branch in (1, -1)
        t = _closest_hyperbola_local_param(lx, ly, h.a, h.b, branch)
        cx, cy = branch * h.a * cosh(t), h.b * sinh(t)
        best = min(best, sqrt((lx - cx)^2 + (ly - cy)^2))
    end
    return best
end
distance(h::EGHyperbola2, p::EGPoint) = distance(p, h)

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
EGParabola2(focus::Tuple, directrix::EGLine) = EGParabola2(_topoint(focus), directrix)

Base.:(==)(x::EGParabola2, y::EGParabola2) = x.focus == y.focus && x.directrix == y.directrix
Base.convert(::Type{EGParabola2{T}}, p::EGParabola2) where {T} = EGParabola2{T}(p.focus, p.directrix)
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
translate(par::EGParabola2, v::EGVector) = EGParabola2(translate(par.focus, v), translate(par.directrix, v))

# A single Newton run, from starting local-y value y0, towards a root of
# f(y) = y^3/pf^2 + y*(2 - 2*X0/pf) - 2*Y0 = 0 — the stationarity
# condition of the squared-distance function from (X0,Y0) to the point
# (y^2/(2pf), y) of the parabola y^2 = 2*pf*x (no closed form exists for
# the closest point on a parabola either, despite f being "only" a cubic).
function _newton_parabola_y(y0::Real, X0::Real, Y0::Real, pf::Real; atol=1e-12, maxiter=100)
    y = y0
    for _ in 1:maxiter
        f = y^3 / pf^2 + y * (2 - 2X0 / pf) - 2Y0
        fp = 3y^2 / pf^2 + (2 - 2X0 / pf)
        abs(fp) <= atol && break
        Δ = f / fp
        y -= Δ
        abs(Δ) <= atol && break
    end
    return y
end

# The parameter s (in point_on_parabola's own convention: the local
# y-coordinate) of the closest point on the full parabola to a point given
# in the parabola's local (X0, Y0) coordinates. A cubic can have up to 3
# real roots, so — same reasoning as the ellipse/hyperbola cases —
# several starting points are tried, keeping whichever converged root
# gives the smallest actual distance rather than trusting the first one
# found.
function _closest_parabola_local_param(X0::Real, Y0::Real, pf::Real; atol=1e-12, maxiter=100)
    best_y, best_d2 = 0.0, Inf
    scale = max(abs(X0), abs(Y0), pf, 1.0)
    for y0 in (Y0, 0.0, scale, -scale, 2scale, -2scale)
        y = _newton_parabola_y(y0, X0, Y0, pf; atol=atol, maxiter=maxiter)
        x = y^2 / (2pf)
        d2 = (x - X0)^2 + (y - Y0)^2
        if d2 < best_d2
            best_d2 = d2
            best_y = y
        end
    end
    return best_y
end

# The smallest distance from (X0,Y0) to the point of the parabola whose
# own parameter (local y) lands within [min(s1,s2), max(s1,s2)], or `Inf`
# if no critical point does — used by
# `distance(::EGPoint, ::EGParabolicArc2)`, for the same reason
# `_closest_ellipse_local_param_in_range` exists.
function _closest_parabola_local_param_in_range(X0::Real, Y0::Real, pf::Real, smin::Real, smax::Real; atol=1e-12, maxiter=100, nstarts=12)
    best_d2 = Inf
    for k in 0:nstarts
        y0 = smin + (smax - smin) * k / nstarts
        y = _newton_parabola_y(y0, X0, Y0, pf; atol=atol, maxiter=maxiter)
        (smin - 1e-7 <= y <= smax + 1e-7) || continue
        x = y^2 / (2pf)
        best_d2 = min(best_d2, (x - X0)^2 + (y - Y0)^2)
    end
    return sqrt(best_d2)
end

"""
    distance(p::EGPoint, par::EGParabola2)

Distance from `p` to the curve of `par`. Like the ellipse/hyperbola
cases, found via Newton's method rather than a closed form.
"""
function distance(p::EGPoint, par::EGParabola2)
    V, u, w = _parabola_frame(par)
    pf = focal_parameter(par)
    X0, Y0 = _to_local_frame(p, V, u, w)
    s = _closest_parabola_local_param(X0, Y0, pf)
    return distance(p, point_on_parabola(par, s))
end
distance(par::EGParabola2, p::EGPoint) = distance(p, par)

# --- EGCircularArc2 -----------------------------------------------------------

# p, snapped onto circle (same angle from circle.center, radius circle.r).
function _project_onto_circle2(circle::EGCircle2, p::EGPoint)
    v = p - circle.center
    d2 = dot(v, v)
    d2 <= 0 && throw(ArgumentError("EGCircularArc2: p1/p2 must not coincide with the circle's own center"))
    return circle.center + (circle.r / sqrt(d2)) * v
end

"""
    EGCircularArc2(circle::EGCircle2, p1::EGPoint, p2::EGPoint)

The arc of `circle` traversed counterclockwise from `p1` to `p2`. `p1`/
`p2` need not lie exactly on `circle` -- only their *angle* from
`circle.center` matters, so the constructor projects each onto `circle`
(same angle, radius `circle.r`) before storing it. This keeps `arc.p1`/
`arc.p2` always genuinely on the circle, matching what
[`point_on_arc`](@ref)/[`midpoint`](@ref) already compute from the angle
alone -- without it, anything built directly from the raw `arc.p1`/
`arc.p2` (e.g. [`EGCircularSector2`](@ref)'s own radii,
`EGSegment(circle.center, arc.p1)`) would end at the wrong point whenever
the caller passed an off-circle `p1`/`p2`, visibly disagreeing with the
arc curve itself.
"""
struct EGCircularArc2{T<:Real} <: EGConicArc2{T}
    circle::EGCircle2{T}
    p1::EGPoint{2,T}
    p2::EGPoint{2,T}
    # An explicit inner constructor, projecting onto the circle here, is
    # required for the projection to actually apply universally -- without
    # one, Julia's own auto-generated default inner constructor for this
    # exact-type signature would still exist alongside it and, being more
    # specific than the promoting outer constructor below, would win (and
    # skip the projection) for any call already passing matching EGPoint{2,T}
    # arguments -- silently the common case, not a rare corner one.
    function EGCircularArc2{T}(circle::EGCircle2, p1::EGPoint{2}, p2::EGPoint{2}) where {T<:Real}
        return new{T}(circle, _project_onto_circle2(circle, p1), _project_onto_circle2(circle, p2))
    end
end
function EGCircularArc2(circle::EGCircle2, p1::EGPointLike, p2::EGPointLike)
    p1, p2 = _topoint(p1), _topoint(p2)
    T = promote_type(eltype(circle.center), eltype(p1), eltype(p2))
    return EGCircularArc2{T}(EGCircle2{T}(EGPoint{2,T}(circle.center.coords), T(circle.r)), EGPoint{2,T}(p1.coords), EGPoint{2,T}(p2.coords))
end

Base.:(==)(x::EGCircularArc2, y::EGCircularArc2) = x.circle == y.circle && x.p1 == y.p1 && x.p2 == y.p2
Base.convert(::Type{EGCircularArc2{T}}, a::EGCircularArc2) where {T} = EGCircularArc2{T}(a.circle, a.p1, a.p2)
Base.isapprox(x::EGCircularArc2, y::EGCircularArc2; kwargs...) =
    isapprox(x.circle, y.circle; kwargs...) && isapprox(x.p1, y.p1; kwargs...) && isapprox(x.p2, y.p2; kwargs...)
Base.show(io::IO, arc::EGCircularArc2) = print(io, "EGCircularArc2(", arc.circle, ", ", arc.p1, " -> ", arc.p2, ")")

"""
    reverse(arc::EGCircularArc2)

The *complementary* arc: same circle, `p1`/`p2` swapped, so it sweeps the
rest of the way around (`measure` goes from `θ` to `2π - θ`, 0 stays 0).
See [`reverse(::EGAngle2)`](@ref) for why this exists — the same
already-mirrored-coordinates gotcha applies here.
"""
Base.reverse(arc::EGCircularArc2) = EGCircularArc2(arc.circle, arc.p2, arc.p1)

_arc_angle(arc::EGCircularArc2, p::EGPoint) = atan(p[2] - arc.circle.center[2], p[1] - arc.circle.center[1])

# Shared by `EGBoundingBox` for EGCircularArc2/EGEllipticArc2: whether angle
# `θ` falls within the arc's own sweep `[θ1, θ1+Δθ]` (mod 2π).
_angle_in_arc_range(θ::Real, θ1::Real, Δθ::Real) = mod(θ - θ1, 2π) <= Δθ

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

"""
    EGBoundingBox(arc::EGCircularArc2)

The axis-aligned bounding box of `arc` itself (not the full circle):
exact, from `arc.p1`/`arc.p2` plus whichever of the circle's own
axis-extreme points (angle `0`, `π/2`, `π`, `3π/2`) fall within `arc`'s
own angular sweep.
"""
function EGBoundingBox(arc::EGCircularArc2)
    c = arc.circle
    θ1, Δθ = _arc_angle(arc, arc.p1), measure(arc)
    xs, ys = [arc.p1[1], arc.p2[1]], [arc.p1[2], arc.p2[2]]
    _angle_in_arc_range(0.0, θ1, Δθ) && push!(xs, c.center[1] + c.r)
    _angle_in_arc_range(π, θ1, Δθ) && push!(xs, c.center[1] - c.r)
    _angle_in_arc_range(π / 2, θ1, Δθ) && push!(ys, c.center[2] + c.r)
    _angle_in_arc_range(3π / 2, θ1, Δθ) && push!(ys, c.center[2] - c.r)
    return EGBoundingBox(EGPoint(minimum(xs), minimum(ys)), EGPoint(maximum(xs), maximum(ys)))
end

"""
    distance(p::EGPoint, arc::EGCircularArc2)

Distance from `p` to `arc` itself — not the full circle: if `p`'s
angular projection falls within the arc's own sweep, this is the same as
[`distance(::EGPoint, ::EGCircle2)`](@ref); otherwise it's the closer of
the two endpoints.
"""
function distance(p::EGPoint, arc::EGCircularArc2)
    c = arc.circle
    a1 = _arc_angle(arc, arc.p1)
    ap = atan(p[2] - c.center[2], p[1] - c.center[1])
    0 <= mod(ap - a1, 2π) <= measure(arc) && return abs(distance(p, c.center) - c.r)
    return min(distance(p, arc.p1), distance(p, arc.p2))
end
distance(arc::EGCircularArc2, p::EGPoint) = distance(p, arc)

"""
    _ray_crossings(p::EGPoint, arc::EGCircularArc2)

How many times the rightward horizontal ray from `p` crosses `arc`
itself (not the full circle) — `0`, `1` or `2`. See
[`_ray_crossings(::EGPoint, ::EGSegment)`](@ref) for why this exists:
it's the curved-side building block `point_in_polygon` needs to apply
the even-odd rule to a region with one or more arc sides.
"""
function _ray_crossings(p::EGPoint, arc::EGCircularArc2)
    horiz = EGLine(p, EGPoint(p[1] + 1.0, p[2]))
    θ1, Δθ = _arc_angle(arc, arc.p1), measure(arc)
    count = 0
    for q in intersection(horiz, arc.circle)
        q[1] > p[1] || continue
        _angle_in_arc_range(_arc_angle(arc, q), θ1, Δθ) && (count += 1)
    end
    return count
end

"""
    p in arc::EGCircularArc2

Whether `p` lies exactly on `arc` itself: on the circle, and within its
angular sweep from `p1` to `p2` (not just anywhere on the full circle).
"""
function Base.in(p::EGPoint, arc::EGCircularArc2; atol=1e-9)
    c = arc.circle
    abs(distance(p, c.center) - c.r) <= sqrt(atol) * max(c.r, norm(c.center), 1.0) || return false
    return _angle_in_arc_range(_arc_angle(arc, p), _arc_angle(arc, arc.p1), measure(arc))
end

rotate(arc::EGCircularArc2, angle::Real, center::EGPoint=EGPoint(0.0, 0.0)) =
    EGCircularArc2(rotate(arc.circle, angle, center), rotate(arc.p1, angle, center), rotate(arc.p2, angle, center))
homothety(arc::EGCircularArc2, k::Real, center::EGPoint=EGPoint(0.0, 0.0)) =
    EGCircularArc2(homothety(arc.circle, k, center), homothety(arc.p1, k, center), homothety(arc.p2, k, center))
reflection(arc::EGCircularArc2, about::EGPoint) =
    EGCircularArc2(reflection(arc.circle, about), reflection(arc.p1, about), reflection(arc.p2, about))
reflection(arc::EGCircularArc2, about::EGLine) =
    EGCircularArc2(reflection(arc.circle, about), reflection(arc.p2, about), reflection(arc.p1, about))
translate(arc::EGCircularArc2, v::EGVector) =
    EGCircularArc2(translate(arc.circle, v), translate(arc.p1, v), translate(arc.p2, v))

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
function EGEllipticArc2(ellipse::EGEllipse2, p1::EGPointLike, p2::EGPointLike)
    p1, p2 = _topoint(p1), _topoint(p2)
    T = promote_type(eltype(ellipse.center), eltype(p1), eltype(p2))
    return EGEllipticArc2{T}(convert(EGEllipse2{T}, ellipse), convert(EGPoint{2,T}, p1), convert(EGPoint{2,T}, p2))
end
Base.convert(::Type{EGEllipticArc2{T}}, a::EGEllipticArc2) where {T} = EGEllipticArc2{T}(a.ellipse, a.p1, a.p2)

"""
    reverse(arc::EGEllipticArc2)

The *complementary* arc: same ellipse, `p1`/`p2` swapped, so it sweeps the
rest of the way around. See [`reverse(::EGAngle2)`](@ref) for why this
exists — the same already-mirrored-coordinates gotcha applies here.
"""
Base.reverse(arc::EGEllipticArc2) = EGEllipticArc2(arc.ellipse, arc.p2, arc.p1)

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

"""
    EGBoundingBox(arc::EGEllipticArc2)

The axis-aligned bounding box of `arc` itself (not the full ellipse):
exact, from `arc.p1`/`arc.p2` plus whichever of the ellipse's own
axis-extreme points fall within `arc`'s own angular sweep (the same
critical angles used implicitly by [`EGBoundingBox(::EGEllipse2)`](@ref),
found here from `x(θ) = cx + A cosθ + B sinθ`/`y(θ) = cy + C cosθ + D sinθ`,
each an unrotated sinusoid in `θ` whose own extrema are at `θ = atan(B,A)`/
`atan(D,C)` and their `+π` counterparts).
"""
function EGBoundingBox(arc::EGEllipticArc2)
    e = arc.ellipse
    c, s = cos(e.angle), sin(e.angle)
    A, B = e.a * c, -e.b * s
    C, D = e.a * s, e.b * c
    θ1, Δθ = _ellipse_param(arc, arc.p1), measure(arc)
    xs, ys = [arc.p1[1], arc.p2[1]], [arc.p1[2], arc.p2[2]]
    θx = atan(B, A)
    for θ in (θx, θx + π)
        _angle_in_arc_range(θ, θ1, Δθ) && push!(xs, e.center[1] + A * cos(θ) + B * sin(θ))
    end
    θy = atan(D, C)
    for θ in (θy, θy + π)
        _angle_in_arc_range(θ, θ1, Δθ) && push!(ys, e.center[2] + C * cos(θ) + D * sin(θ))
    end
    return EGBoundingBox(EGPoint(minimum(xs), minimum(ys)), EGPoint(maximum(xs), maximum(ys)))
end

"""
    arc_length(arc::EGEllipticArc2)

The length of `arc`. Unlike [`arc_length(::EGCircularArc2)`](@ref),
there's no elementary closed form for this (an elliptic arc length is,
true to the name, an elliptic integral) — found instead by numerically
integrating the parametrization speed `|Δθ|·√(a²sin²θ + b²cos²θ)` over
`arc`'s own angular range.
"""
function arc_length(arc::EGEllipticArc2)
    e = arc.ellipse
    θ1 = _ellipse_param(arc, arc.p1)
    Δθ = measure(arc)
    speed(t) = abs(Δθ) * sqrt((e.a * sin(θ1 + t * Δθ))^2 + (e.b * cos(θ1 + t * Δθ))^2)
    return _simpson_integrate(speed, 0.0, 1.0)
end

"""
    distance(p::EGPoint, arc::EGEllipticArc2)

Distance from `p` to `arc` itself: if the closest point on the *full*
ellipse falls within the arc's own parameter range, that's the answer
(via the same Newton solve as
[`distance(::EGPoint, ::EGEllipse2)`](@ref)); otherwise it's the closer
of the two endpoints.
"""
function distance(p::EGPoint, arc::EGEllipticArc2)
    e = arc.ellipse
    lx, ly = _to_ellipse_local(p, e)
    t1 = _ellipse_param(arc, arc.p1)
    d = _closest_ellipse_local_param_in_range(lx, ly, e.a, e.b, t1, measure(arc))
    return min(d, distance(p, arc.p1), distance(p, arc.p2))
end
distance(arc::EGEllipticArc2, p::EGPoint) = distance(p, arc)

function _ray_crossings(p::EGPoint, arc::EGEllipticArc2)
    horiz = EGLine(p, EGPoint(p[1] + 1.0, p[2]))
    θ1, Δθ = _ellipse_param(arc, arc.p1), measure(arc)
    count = 0
    for q in intersection(horiz, arc.ellipse)
        q[1] > p[1] || continue
        _angle_in_arc_range(_ellipse_param(arc, q), θ1, Δθ) && (count += 1)
    end
    return count
end

"""
    p in arc::EGEllipticArc2

Whether `p` lies exactly on `arc` itself: on the ellipse, and within its
swept parameter range from `p1` to `p2`.
"""
function Base.in(p::EGPoint, arc::EGEllipticArc2; atol=1e-9)
    is_on_ellipse(p, arc.ellipse; atol=atol) || return false
    return _angle_in_arc_range(_ellipse_param(arc, p), _ellipse_param(arc, arc.p1), measure(arc))
end

rotate(arc::EGEllipticArc2, angle::Real, center::EGPoint=EGPoint(0.0, 0.0)) =
    EGEllipticArc2(rotate(arc.ellipse, angle, center), rotate(arc.p1, angle, center), rotate(arc.p2, angle, center))
homothety(arc::EGEllipticArc2, k::Real, center::EGPoint=EGPoint(0.0, 0.0)) =
    EGEllipticArc2(homothety(arc.ellipse, k, center), homothety(arc.p1, k, center), homothety(arc.p2, k, center))
reflection(arc::EGEllipticArc2, about::EGPoint) =
    EGEllipticArc2(reflection(arc.ellipse, about), reflection(arc.p1, about), reflection(arc.p2, about))
reflection(arc::EGEllipticArc2, about::EGLine) =
    EGEllipticArc2(reflection(arc.ellipse, about), reflection(arc.p2, about), reflection(arc.p1, about))
translate(arc::EGEllipticArc2, v::EGVector) =
    EGEllipticArc2(translate(arc.ellipse, v), translate(arc.p1, v), translate(arc.p2, v))

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
function EGParabolicArc2(parabola::EGParabola2, p1::EGPointLike, p2::EGPointLike)
    p1, p2 = _topoint(p1), _topoint(p2)
    T = promote_type(eltype(parabola.focus), eltype(p1), eltype(p2))
    return EGParabolicArc2{T}(convert(EGParabola2{T}, parabola), convert(EGPoint{2,T}, p1), convert(EGPoint{2,T}, p2))
end
Base.convert(::Type{EGParabolicArc2{T}}, a::EGParabolicArc2) where {T} = EGParabolicArc2{T}(a.parabola, a.p1, a.p2)

"""
    reverse(arc::EGParabolicArc2)

`p1`/`p2` swapped: since a parabola is open, this is the *same* arc (same
point set) with its parametrization direction reversed — unlike
[`reverse(::EGCircularArc2)`](@ref)/[`reverse(::EGEllipticArc2)`](@ref),
there's no complementary-arc ambiguity to resolve here. Provided mainly
for consistency with the closed-conic arcs' `reverse`.
"""
Base.reverse(arc::EGParabolicArc2) = EGParabolicArc2(arc.parabola, arc.p2, arc.p1)

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

"""
    EGBoundingBox(arc::EGParabolicArc2)

The axis-aligned bounding box of `arc`: exact, from `arc.p1`/`arc.p2` plus
the critical points of `x(s) = Vx + (s²/2pf)u₁ + s·w₁`/
`y(s) = Vy + (s²/2pf)u₂ + s·w₂` (each a plain parabola in the scalar
parameter `s`, critical at `s = -pf·w/u` for its own `u`/`w` component)
that fall within `arc`'s own parameter range.
"""
function EGBoundingBox(arc::EGParabolicArc2)
    par = arc.parabola
    V, u, w = _parabola_frame(par)
    pf = focal_parameter(par)
    s1, s2 = _parabola_param(arc, arc.p1), _parabola_param(arc, arc.p2)
    smin, smax = minmax(s1, s2)
    xs, ys = [arc.p1[1], arc.p2[1]], [arc.p1[2], arc.p2[2]]
    if u[1] != 0
        s = -pf * w[1] / u[1]
        smin <= s <= smax && push!(xs, (V + (s^2 / (2pf)) * u + s * w)[1])
    end
    if u[2] != 0
        s = -pf * w[2] / u[2]
        smin <= s <= smax && push!(ys, (V + (s^2 / (2pf)) * u + s * w)[2])
    end
    return EGBoundingBox(EGPoint(minimum(xs), minimum(ys)), EGPoint(maximum(xs), maximum(ys)))
end

"""
    arc_length(arc::EGParabolicArc2)

The length of `arc`, found by numerically integrating the parametrization
speed `|s2-s1|·√((s/pf)² + 1)` over `arc`'s own parameter range (no
elementary closed form exists for this either).
"""
function arc_length(arc::EGParabolicArc2)
    par = arc.parabola
    pf = focal_parameter(par)
    s1, s2 = _parabola_param(arc, arc.p1), _parabola_param(arc, arc.p2)
    speed(t) = abs(s2 - s1) * sqrt(((s1 + t * (s2 - s1)) / pf)^2 + 1)
    return _simpson_integrate(speed, 0.0, 1.0)
end

"""
    distance(p::EGPoint, arc::EGParabolicArc2)

Distance from `p` to `arc` itself: if the closest point on the *full*
parabola falls within the arc's own parameter range, that's the answer
(via the same Newton solve as
[`distance(::EGPoint, ::EGParabola2)`](@ref)); otherwise it's the closer
of the two endpoints.
"""
function distance(p::EGPoint, arc::EGParabolicArc2)
    par = arc.parabola
    V, u, w = _parabola_frame(par)
    X0, Y0 = _to_local_frame(p, V, u, w)
    s1, s2 = _parabola_param(arc, arc.p1), _parabola_param(arc, arc.p2)
    smin, smax = minmax(s1, s2)
    d = _closest_parabola_local_param_in_range(X0, Y0, focal_parameter(par), smin, smax)
    return min(d, distance(p, arc.p1), distance(p, arc.p2))
end
distance(arc::EGParabolicArc2, p::EGPoint) = distance(p, arc)

function _ray_crossings(p::EGPoint, arc::EGParabolicArc2)
    horiz = EGLine(p, EGPoint(p[1] + 1.0, p[2]))
    smin, smax = minmax(_parabola_param(arc, arc.p1), _parabola_param(arc, arc.p2))
    count = 0
    for q in intersection(horiz, arc.parabola)
        q[1] > p[1] || continue
        s = _parabola_param(arc, q)
        smin <= s <= smax && (count += 1)
    end
    return count
end

"""
    p in arc::EGParabolicArc2

Whether `p` lies exactly on `arc` itself: on the parabola, and within its
parameter range from `p1` to `p2`.
"""
function Base.in(p::EGPoint, arc::EGParabolicArc2; atol=1e-9)
    is_on_parabola(p, arc.parabola; atol=atol) || return false
    smin, smax = minmax(_parabola_param(arc, arc.p1), _parabola_param(arc, arc.p2))
    return smin <= _parabola_param(arc, p) <= smax
end

rotate(arc::EGParabolicArc2, angle::Real, center::EGPoint=EGPoint(0.0, 0.0)) =
    EGParabolicArc2(rotate(arc.parabola, angle, center), rotate(arc.p1, angle, center), rotate(arc.p2, angle, center))
homothety(arc::EGParabolicArc2, k::Real, center::EGPoint=EGPoint(0.0, 0.0)) =
    EGParabolicArc2(homothety(arc.parabola, k, center), homothety(arc.p1, k, center), homothety(arc.p2, k, center))
reflection(arc::EGParabolicArc2, about) =
    EGParabolicArc2(reflection(arc.parabola, about), reflection(arc.p1, about), reflection(arc.p2, about))
translate(arc::EGParabolicArc2, v::EGVector) =
    EGParabolicArc2(translate(arc.parabola, v), translate(arc.p1, v), translate(arc.p2, v))

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
function EGHyperbolicArc2(hyperbola::EGHyperbola2, p1::EGPointLike, p2::EGPointLike)
    p1, p2 = _topoint(p1), _topoint(p2)
    T = promote_type(eltype(hyperbola.center), eltype(p1), eltype(p2))
    return EGHyperbolicArc2{T}(convert(EGHyperbola2{T}, hyperbola), convert(EGPoint{2,T}, p1), convert(EGPoint{2,T}, p2))
end
Base.convert(::Type{EGHyperbolicArc2{T}}, a::EGHyperbolicArc2) where {T} = EGHyperbolicArc2{T}(a.hyperbola, a.p1, a.p2)

"""
    reverse(arc::EGHyperbolicArc2)

`p1`/`p2` swapped: since a single hyperbola branch is open, this is the
*same* arc (same point set) with its parametrization direction reversed
— see [`reverse(::EGParabolicArc2)`](@ref) for the same reasoning.
"""
Base.reverse(arc::EGHyperbolicArc2) = EGHyperbolicArc2(arc.hyperbola, arc.p2, arc.p1)

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

# Critical parameter(s) (within [tmin,tmax]) of f(t) = P·cosh(t) + Q·sinh(t)
# — used by `EGBoundingBox(::EGHyperbolicArc2)` for each of x(t)/y(t)
# separately. f'(t) = P·sinh(t) + Q·cosh(t) = 0 ⟺ tanh(t) = -Q/P, which
# has a real solution only when |Q/P| < 1 (tanh's range) — otherwise f is
# monotonic on the whole real line and the arc's extremes are just its
# endpoints.
function _hyperbola_axis_critical_t(P::Real, Q::Real, tmin::Real, tmax::Real)
    P == 0 && return Float64[]
    r = -Q / P
    abs(r) >= 1 && return Float64[]
    t = atanh(r)
    return tmin <= t <= tmax ? [t] : Float64[]
end

"""
    EGBoundingBox(arc::EGHyperbolicArc2)

The axis-aligned bounding box of `arc`: exact, from `arc.p1`/`arc.p2` plus
the critical points of `x(t) = cx + P·cosh(t) + Q·sinh(t)`/
`y(t) = cy + R·cosh(t) + S·sinh(t)` (each solved via `_hyperbola_axis_critical_t`)
that fall within `arc`'s own parameter range.
"""
function EGBoundingBox(arc::EGHyperbolicArc2)
    h = arc.hyperbola
    c, s = cos(h.angle), sin(h.angle)
    t1, branch = _hyperbola_param(arc, arc.p1)
    t2, _ = _hyperbola_param(arc, arc.p2)
    tmin, tmax = minmax(t1, t2)
    P, Q = branch * h.a * c, -h.b * s
    R, S = branch * h.a * s, h.b * c
    xs, ys = [arc.p1[1], arc.p2[1]], [arc.p1[2], arc.p2[2]]
    for t in _hyperbola_axis_critical_t(P, Q, tmin, tmax)
        push!(xs, h.center[1] + P * cosh(t) + Q * sinh(t))
    end
    for t in _hyperbola_axis_critical_t(R, S, tmin, tmax)
        push!(ys, h.center[2] + R * cosh(t) + S * sinh(t))
    end
    return EGBoundingBox(EGPoint(minimum(xs), minimum(ys)), EGPoint(maximum(xs), maximum(ys)))
end

"""
    arc_length(arc::EGHyperbolicArc2)

The length of `arc`, found by numerically integrating the parametrization
speed `|t2-t1|·√(a²sinh²t + b²cosh²t)` over `arc`'s own parameter range
(no elementary closed form exists for this either).
"""
function arc_length(arc::EGHyperbolicArc2)
    h = arc.hyperbola
    t1, _ = _hyperbola_param(arc, arc.p1)
    t2, _ = _hyperbola_param(arc, arc.p2)
    speed(t) = abs(t2 - t1) * sqrt((h.a * sinh(t1 + t * (t2 - t1)))^2 + (h.b * cosh(t1 + t * (t2 - t1)))^2)
    return _simpson_integrate(speed, 0.0, 1.0)
end

"""
    distance(p::EGPoint, arc::EGHyperbolicArc2)

Distance from `p` to `arc` itself: if the closest point on `arc`'s own
branch of the *full* hyperbola falls within the arc's own parameter
range, that's the answer (via the same Newton solve as
[`distance(::EGPoint, ::EGHyperbola2)`](@ref)); otherwise it's the closer
of the two endpoints.
"""
function distance(p::EGPoint, arc::EGHyperbolicArc2)
    h = arc.hyperbola
    lx, ly = _to_hyperbola_local(p, h)
    t1, branch = _hyperbola_param(arc, arc.p1)
    t2, _ = _hyperbola_param(arc, arc.p2)
    tmin, tmax = minmax(t1, t2)
    d = _closest_hyperbola_local_param_in_range(lx, ly, h.a, h.b, branch, tmin, tmax)
    return min(d, distance(p, arc.p1), distance(p, arc.p2))
end
distance(arc::EGHyperbolicArc2, p::EGPoint) = distance(p, arc)

function _ray_crossings(p::EGPoint, arc::EGHyperbolicArc2)
    horiz = EGLine(p, EGPoint(p[1] + 1.0, p[2]))
    t1, branch = _hyperbola_param(arc, arc.p1)
    t2, _ = _hyperbola_param(arc, arc.p2)
    tmin, tmax = minmax(t1, t2)
    count = 0
    for q in intersection(horiz, arc.hyperbola)
        q[1] > p[1] || continue
        t, b = _hyperbola_param(arc, q)
        b == branch && tmin <= t <= tmax && (count += 1)
    end
    return count
end

"""
    p in arc::EGHyperbolicArc2

Whether `p` lies exactly on `arc` itself: on the same branch of the
hyperbola, and within its parameter range from `p1` to `p2`.
"""
function Base.in(p::EGPoint, arc::EGHyperbolicArc2; atol=1e-9)
    is_on_hyperbola(p, arc.hyperbola; atol=atol) || return false
    t1, branch = _hyperbola_param(arc, arc.p1)
    t2, _ = _hyperbola_param(arc, arc.p2)
    t, b = _hyperbola_param(arc, p)
    b == branch || return false
    tmin, tmax = minmax(t1, t2)
    return tmin <= t <= tmax
end

rotate(arc::EGHyperbolicArc2, angle::Real, center::EGPoint=EGPoint(0.0, 0.0)) =
    EGHyperbolicArc2(rotate(arc.hyperbola, angle, center), rotate(arc.p1, angle, center), rotate(arc.p2, angle, center))
homothety(arc::EGHyperbolicArc2, k::Real, center::EGPoint=EGPoint(0.0, 0.0)) =
    EGHyperbolicArc2(homothety(arc.hyperbola, k, center), homothety(arc.p1, k, center), homothety(arc.p2, k, center))
reflection(arc::EGHyperbolicArc2, about) =
    EGHyperbolicArc2(reflection(arc.hyperbola, about), reflection(arc.p1, about), reflection(arc.p2, about))
translate(arc::EGHyperbolicArc2, v::EGVector) =
    EGHyperbolicArc2(translate(arc.hyperbola, v), translate(arc.p1, v), translate(arc.p2, v))
