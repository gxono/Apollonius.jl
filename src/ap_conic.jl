"""
    APConic2{T} <: APCurve{2,T}

The parent of the four 2D conic types: [`APCircle2`](@ref),
[`APEllipse2`](@ref), [`APParabola2`](@ref), [`APHyperbola2`](@ref).
`APCircle2` is a *sibling* here, not a subtype of `APEllipse2` — despite
being the degenerate `a == b` case mathematically, it's a genuinely
different (simpler, one-parameter) struct rather than an `APEllipse2`
with equal axes.
"""
abstract type APConic2{T} <: APCurve{2,T} end
"""
    APConicArc2{T} <: APCurve{2,T}

The parent of the four conic-arc types, each a bounded piece of the
matching [`APConic2`](@ref): [`APCircularArc2`](@ref), `APEllipticArc2`,
`APParabolicArc2`, `APHyperbolicArc2`. For the two closed conics (circle,
ellipse) two points leave a "which way around" ambiguity, so
`reflection` about an `APLine` swaps the arc's endpoints to stay a true
mirror image rather than jumping to the complementary arc; the two open
curves (parabola, a single hyperbola branch) have no such ambiguity, so
their `reflection` never swaps.
"""
abstract type APConicArc2{T} <: APCurve{2,T} end
_to_local_frame(p::APPoint, origin::APPoint, u::APVector, w::APVector) = (dot(p - origin, u), dot(p - origin, w))
function _to_local_frame(p::APPoint, origin::APPoint, angle::Real)
    c, s = cos(angle), sin(angle)
    return _to_local_frame(p, origin, APVector(c, s), APVector(-s, c))
end
_from_local_frame(x::Real, y::Real, origin::APPoint, u::APVector, w::APVector) = origin + x * u + y * w
function _from_local_frame(x::Real, y::Real, origin::APPoint, angle::Real)
    c, s = cos(angle), sin(angle)
    return _from_local_frame(x, y, origin, APVector(c, s), APVector(-s, c))
end
function _simpson_integrate(f, t0::Real, t1::Real; n::Int=128)
    n = isodd(n) ? n + 1 : n
    h = (t1 - t0) / n
    total = f(t0) + f(t1)
    for i in 1:n-1
        total += f(t0 + i * h) * (isodd(i) ? 4 : 2)
    end
    return total * h / 3
end
"""
    APCircle2(center, r)
"""
struct APCircle2{T<:Real} <: APConic2{T}
    center::APPoint{2,T}
    r::T
end
APCircle2(center::APPoint{2,T1}, r::T2) where {T1,T2<:Real} = APCircle2{promote_type(T1, T2)}(center, promote_type(T1, T2)(r))
"""
    APCircle2(center::APPoint, through::APPoint)

The circle centered at `center` passing through `through` — same as
`APCircle2(center, distance(center, through))`, for when a point on the
circle is more natural to give than the radius itself.
"""
APCircle2(center::APPoint, through::APPoint) =
    APCircle2(center, distance(center, through))
"""
    APCircle2(p1::APPoint, p2::APPoint, p3::APPoint; atol=1e-9)

The circle through three points — their circumcircle, computed directly
(same formula [`circumcenter`](@ref) uses on an [`APTriangle`](@ref),
without needing to build one first). Throws an `ArgumentError` if `p1`,
`p2`, `p3` are (or are too close to) collinear, since then no finite
circle passes through all three.
"""
function APCircle2(p1::APPoint, p2::APPoint, p3::APPoint; atol=1e-9)
    is_collinear(p1, p2, p3; atol=atol) &&
        throw(ArgumentError("APCircle2: p1, p2, p3 must not be collinear (no finite circle through them)"))
    x1, y1 = p1[1], p1[2]
    x2, y2 = p2[1], p2[2]
    x3, y3 = p3[1], p3[2]
    d = 2 * (x1 * (y2 - y3) + x2 * (y3 - y1) + x3 * (y1 - y2))
    s1, s2, s3 = x1^2 + y1^2, x2^2 + y2^2, x3^2 + y3^2
    ux = (s1 * (y2 - y3) + s2 * (y3 - y1) + s3 * (y1 - y2)) / d
    uy = (s1 * (x3 - x2) + s2 * (x1 - x3) + s3 * (x2 - x1)) / d
    center = APPoint(ux, uy)
    return APCircle2(center, distance(center, p1))
end
Base.:(==)(a::APCircle2, b::APCircle2) = a.center == b.center && a.r == b.r
Base.convert(::Type{APCircle2{T}}, c::APCircle2) where {T} = APCircle2{T}(c.center, T(c.r))
Base.isapprox(a::APCircle2, b::APCircle2; kwargs...) = isapprox(a.center, b.center; kwargs...) && isapprox(a.r, b.r; kwargs...)
Base.show(io::IO, c::APCircle2) = print(io, "APCircle2(", c.center, ", ", c.r, ")")
Base.in(p::APPoint, c::APCircle2) = distance(p, c.center) <= c.r
area(c::APCircle2) = pi * c.r^2
perimeter(c::APCircle2) = 2 * pi * c.r
rotate(c::APCircle2, angle::Real, center::APPoint=APPoint(0.0, 0.0)) = APCircle2(rotate(c.center, angle, center), c.r)
homothety(c::APCircle2, k::Real, center::APPoint=APPoint(0.0, 0.0)) = APCircle2(homothety(c.center, k, center), abs(k) * c.r)
reflection(c::APCircle2, about) = APCircle2(reflection(c.center, about), c.r)
translate(c::APCircle2, v::APVector) = APCircle2(translate(c.center, v), c.r)
"""
    antipode(p::APPoint, c::APCircle2)

The point diametrically opposite `p` on `c`: `c.center` is the midpoint of
`p` and its antipode, so this is just `reflection(p, c.center)`. Most
meaningful when `p` is actually on `c`, but works the same way (a plain
point reflection through `c.center`) for any `p`.
"""
antipode(p::APPoint, c::APCircle2) = reflection(p, c.center)
"""
    distance(p::APPoint, c::APCircle2)

Distance from `p` to the *curve* of `c` (like every other `APCurve` — not
to the filled disk `Base.in` tests membership of).
"""
distance(p::APPoint, c::APCircle2) = abs(distance(p, c.center) - c.r)
distance(c::APCircle2, p::APPoint) = distance(p, c)
"""
    distance(c::APCircle2, l::APLine)

`0` if `l` crosses or is tangent to `c`; otherwise the gap between them.
"""
distance(c::APCircle2, l::APLine) = max(distance(c.center, l) - c.r, 0.0)
distance(l::APLine, c::APCircle2) = distance(c, l)
"""
    distance(c1::APCircle2, c2::APCircle2)

The distance between the two *curves*: `0` whenever they touch or cross
(tangent, secant, or one properly inside the other without touching is
the only case this is nonzero for *and* nested — see below), otherwise
the gap — either the external gap (`d - r1 - r2`, when disjoint) or the
gap between a smaller circle and the inside of a bigger one that encloses
it (`|r1-r2| - d`, when nested without touching).
"""
function distance(c1::APCircle2, c2::APCircle2)
    d = distance(c1.center, c2.center)
    return max(d - c1.r - c2.r, abs(c1.r - c2.r) - d, 0.0)
end
APBoundingBox(c::APCircle2) = APBoundingBox(c.center - APVector(c.r, c.r), c.center + APVector(c.r, c.r))
"""
    APEllipse2(center, a, b, angle=0.0)
    APEllipse2(f1::APPoint, f2::APPoint, a::Real)
    APEllipse2(f1::APPoint, f2::APPoint, p::APPoint)
"""
struct APEllipse2{T<:Real} <: APConic2{T}
    center::APPoint{2,T}
    a::T
    b::T
    angle::T
end
function APEllipse2(center::APPoint{2}, a::Real, b::Real, angle::Real=0.0)
    T = promote_type(eltype(center), typeof(float(a)), typeof(float(b)), typeof(float(angle)))
    return APEllipse2{T}(APPoint{2,T}(center.coords), T(a), T(b), T(angle))
end
function APEllipse2(f1::APPoint, f2::APPoint, a::Real)
    c = distance(f1, f2) / 2
    a <= c && throw(ArgumentError("APEllipse2: a must be greater than half the distance between the foci"))
    d = f2 - f1
    return APEllipse2(midpoint(f1, f2), a, sqrt(a^2 - c^2), atan(d[2], d[1]))
end
function APEllipse2(f1::APPoint, f2::APPoint, p::APPoint)
    return APEllipse2(f1, f2, (distance(p, f1) + distance(p, f2)) / 2)
end
Base.:(==)(x::APEllipse2, y::APEllipse2) = x.center == y.center && x.a == y.a && x.b == y.b && x.angle == y.angle
Base.convert(::Type{APEllipse2{T}}, e::APEllipse2) where {T} = APEllipse2{T}(e.center, T(e.a), T(e.b), T(e.angle))
function Base.isapprox(x::APEllipse2, y::APEllipse2; atol=1e-9, kwargs...)
    isapprox(x.center, y.center; atol=atol, kwargs...) && isapprox(x.a, y.a; atol=atol, kwargs...) &&
        isapprox(x.b, y.b; atol=atol, kwargs...) || return false
    # angle and angle + π describe the identical ellipse (e.g. APEllipse2(f1, f2, a) vs.
    # APEllipse2(f2, f1, a), the two foci swapped), so compare it mod π rather than directly
    d = mod(x.angle - y.angle, pi)
    return min(d, pi - d) <= atol
end
Base.show(io::IO, e::APEllipse2) = print(io, "APEllipse2(center=", e.center, ", a=", e.a, ", b=", e.b, ", angle=", e.angle, ")")
_to_ellipse_local(p::APPoint, e::APEllipse2) = _to_local_frame(p, e.center, e.angle)
_from_ellipse_local(x, y, e::APEllipse2) = _from_local_frame(x, y, e.center, e.angle)
Base.in(p::APPoint, e::APEllipse2) = begin
    lx, ly = _to_ellipse_local(p, e)
    (lx / e.a)^2 + (ly / e.b)^2 <= 1
end
"""
    point_on_ellipse(e::APEllipse2, t::Real)
"""
point_on_ellipse(e::APEllipse2, t::Real) = _from_ellipse_local(e.a * cos(t), e.b * sin(t), e)
"""
    is_on_ellipse(p::APPoint, e::APEllipse2; atol=1e-9)
"""
function is_on_ellipse(p::APPoint, e::APEllipse2; atol=1e-9)
    lx, ly = _to_ellipse_local(p, e)
    return abs((lx / e.a)^2 + (ly / e.b)^2 - 1) <= atol
end
area(e::APEllipse2) = pi * e.a * e.b
function perimeter(e::APEllipse2)
    a, b = e.a, e.b
    h = ((a - b) / (a + b))^2
    return pi * (a + b) * (1 + 3h / (10 + sqrt(4 - 3h)))
end
"""
    orthoptic(e::APEllipse2)

The orthoptic (director) circle of `e`: the locus of points from which the
two tangent lines to `e` are perpendicular. Always a real circle, of
radius `sqrt(a^2 + b^2)` centered at `e.center`.
"""
orthoptic(e::APEllipse2) = APCircle2(e.center, sqrt(e.a^2 + e.b^2))
"""
    foci(e::APEllipse2)

The two foci of `e`, as a 2-tuple.
"""
function foci(e::APEllipse2)
    c = sqrt(abs(e.a^2 - e.b^2))
    dir = e.a >= e.b ? APVector(cos(e.angle), sin(e.angle)) : APVector(-sin(e.angle), cos(e.angle))
    return (e.center + c * dir, e.center - c * dir)
end
"""
    vertices(e::APEllipse2)

The two vertices of `e`: the endpoints of its major axis, as a 2-tuple.
"""
function vertices(e::APEllipse2)
    r = max(e.a, e.b)
    dir = e.a >= e.b ? APVector(cos(e.angle), sin(e.angle)) : APVector(-sin(e.angle), cos(e.angle))
    return (e.center + r * dir, e.center - r * dir)
end
"""
    APBoundingBox(e::APEllipse2)

The axis-aligned bounding box of `e`: exact, via the standard closed form
for a rotated ellipse's extent, `half-width = √(a²cos²φ + b²sin²φ)`,
`half-height = √(a²sin²φ + b²cos²φ)`.
"""
function APBoundingBox(e::APEllipse2)
    c, s = cos(e.angle), sin(e.angle)
    dx = sqrt((e.a * c)^2 + (e.b * s)^2)
    dy = sqrt((e.a * s)^2 + (e.b * c)^2)
    return APBoundingBox(e.center - APVector(dx, dy), e.center + APVector(dx, dy))
end
rotate(e::APEllipse2, angle::Real, center::APPoint=APPoint(0.0, 0.0)) =
    APEllipse2(rotate(e.center, angle, center), e.a, e.b, e.angle + angle)
homothety(e::APEllipse2, k::Real, center::APPoint=APPoint(0.0, 0.0)) =
    APEllipse2(homothety(e.center, k, center), abs(k) * e.a, abs(k) * e.b, e.angle)
reflection(e::APEllipse2, about::APPoint) = APEllipse2(reflection(e.center, about), e.a, e.b, e.angle)
function reflection(e::APEllipse2, about::APLine)
    φ = atan(direction(about)[2], direction(about)[1])
    return APEllipse2(reflection(e.center, about), e.a, e.b, 2 * φ - e.angle)
end
translate(e::APEllipse2, v::APVector) = APEllipse2(translate(e.center, v), e.a, e.b, e.angle)
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
    distance(p::APPoint, e::APEllipse2)

Distance from `p` to the curve of `e`. Unlike every other conic distance
in this package, there's no closed form for this — it's found by Newton's
method on the ellipse's own parametrization (essentially exact in
practice, converging to machine precision in a handful of iterations for
any non-degenerate ellipse).
"""
function distance(p::APPoint, e::APEllipse2)
    lx, ly = _to_ellipse_local(p, e)
    isapprox(e.a, e.b) && return abs(sqrt(lx^2 + ly^2) - e.a)
    t = _closest_ellipse_local_param(lx, ly, e.a, e.b)
    cx, cy = e.a * cos(t), e.b * sin(t)
    return sqrt((lx - cx)^2 + (ly - cy)^2)
end
distance(e::APEllipse2, p::APPoint) = distance(p, e)
"""
    APHyperbola2(center, a, b, angle=0.0)
    APHyperbola2(f1::APPoint, f2::APPoint, a::Real)
    APHyperbola2(f1::APPoint, f2::APPoint, p::APPoint)
"""
struct APHyperbola2{T<:Real} <: APConic2{T}
    center::APPoint{2,T}
    a::T
    b::T
    angle::T
end
function APHyperbola2(center::APPoint{2}, a::Real, b::Real, angle::Real=0.0)
    T = promote_type(eltype(center), typeof(float(a)), typeof(float(b)), typeof(float(angle)))
    return APHyperbola2{T}(APPoint{2,T}(center.coords), T(a), T(b), T(angle))
end
function APHyperbola2(f1::APPoint, f2::APPoint, a::Real)
    c = distance(f1, f2) / 2
    a >= c && throw(ArgumentError("APHyperbola2: a must be less than half the distance between the foci"))
    d = f2 - f1
    return APHyperbola2(midpoint(f1, f2), a, sqrt(c^2 - a^2), atan(d[2], d[1]))
end
function APHyperbola2(f1::APPoint, f2::APPoint, p::APPoint)
    return APHyperbola2(f1, f2, abs(distance(p, f1) - distance(p, f2)) / 2)
end
Base.:(==)(x::APHyperbola2, y::APHyperbola2) = x.center == y.center && x.a == y.a && x.b == y.b && x.angle == y.angle
Base.convert(::Type{APHyperbola2{T}}, h::APHyperbola2) where {T} = APHyperbola2{T}(h.center, T(h.a), T(h.b), T(h.angle))
function Base.isapprox(x::APHyperbola2, y::APHyperbola2; atol=1e-9, kwargs...)
    isapprox(x.center, y.center; atol=atol, kwargs...) && isapprox(x.a, y.a; atol=atol, kwargs...) &&
        isapprox(x.b, y.b; atol=atol, kwargs...) || return false
    # same π-periodicity as APEllipse2's isapprox (see there): angle and angle + π describe
    # the identical hyperbola (e.g. the two foci swapped in the bifocal constructor)
    d = mod(x.angle - y.angle, pi)
    return min(d, pi - d) <= atol
end
Base.show(io::IO, h::APHyperbola2) = print(io, "APHyperbola2(center=", h.center, ", a=", h.a, ", b=", h.b, ", angle=", h.angle, ")")
_to_hyperbola_local(p::APPoint, h::APHyperbola2) = _to_local_frame(p, h.center, h.angle)
_from_hyperbola_local(x, y, h::APHyperbola2) = _from_local_frame(x, y, h.center, h.angle)
Base.in(p::APPoint, h::APHyperbola2) = begin
    lx, ly = _to_hyperbola_local(p, h)
    (lx / h.a)^2 - (ly / h.b)^2 >= 1
end
"""
    point_on_hyperbola(h::APHyperbola2, t::Real; branch::Int=1)
"""
function point_on_hyperbola(h::APHyperbola2, t::Real; branch::Int=1)
    x, y = branch * h.a * cosh(t), h.b * sinh(t)
    return _from_hyperbola_local(x, y, h)
end
"""
    is_on_hyperbola(p::APPoint, h::APHyperbola2; atol=1e-9)
"""
function is_on_hyperbola(p::APPoint, h::APHyperbola2; atol=1e-9)
    lx, ly = _to_hyperbola_local(p, h)
    return abs((lx / h.a)^2 - (ly / h.b)^2 - 1) <= atol
end
"""
    foci(h::APHyperbola2)

The two foci of `h`, as a 2-tuple.
"""
function foci(h::APHyperbola2)
    c = sqrt(h.a^2 + h.b^2)
    dir = APVector(cos(h.angle), sin(h.angle))
    return (h.center + c * dir, h.center - c * dir)
end
"""
    vertices(h::APHyperbola2)

The two vertices of `h`: the points where each branch meets its own
transverse axis, as a 2-tuple.
"""
function vertices(h::APHyperbola2)
    dir = APVector(cos(h.angle), sin(h.angle))
    return (h.center + h.a * dir, h.center - h.a * dir)
end
"""
    orthoptic(h::APHyperbola2)

The orthoptic (director) circle of `h`: the locus of points from which the
two tangent lines to `h` are perpendicular. Only real when `a > b` (radius
`sqrt(a^2 - b^2)`, centered at `h.center`); throws an `ArgumentError`
otherwise, since then no real such circle exists.
"""
function orthoptic(h::APHyperbola2)
    h.a <= h.b && throw(ArgumentError("orthoptic: no real orthoptic circle exists when a <= b"))
    return APCircle2(h.center, sqrt(h.a^2 - h.b^2))
end
"""
    asymptotes(h::APHyperbola2)

The two asymptote lines of `h`, as a 2-tuple.
"""
function asymptotes(h::APHyperbola2)
    p1 = _from_hyperbola_local(h.a, h.b, h)
    p2 = _from_hyperbola_local(h.a, -h.b, h)
    return (APLine(h.center, p1), APLine(h.center, p2))
end
rotate(h::APHyperbola2, angle::Real, center::APPoint=APPoint(0.0, 0.0)) =
    APHyperbola2(rotate(h.center, angle, center), h.a, h.b, h.angle + angle)
homothety(h::APHyperbola2, k::Real, center::APPoint=APPoint(0.0, 0.0)) =
    APHyperbola2(homothety(h.center, k, center), abs(k) * h.a, abs(k) * h.b, h.angle)
reflection(h::APHyperbola2, about::APPoint) = APHyperbola2(reflection(h.center, about), h.a, h.b, h.angle)
function reflection(h::APHyperbola2, about::APLine)
    φ = atan(direction(about)[2], direction(about)[1])
    return APHyperbola2(reflection(h.center, about), h.a, h.b, 2 * φ - h.angle)
end
translate(h::APHyperbola2, v::APVector) = APHyperbola2(translate(h.center, v), h.a, h.b, h.angle)
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
    distance(p::APPoint, h::APHyperbola2)

Distance from `p` to the curve of `h` (either branch — whichever is
closer). Like [`distance(::APPoint, ::APEllipse2)`](@ref), found via
Newton's method rather than a closed form.
"""
function distance(p::APPoint, h::APHyperbola2)
    lx, ly = _to_hyperbola_local(p, h)
    best = Inf
    for branch in (1, -1)
        t = _closest_hyperbola_local_param(lx, ly, h.a, h.b, branch)
        cx, cy = branch * h.a * cosh(t), h.b * sinh(t)
        best = min(best, sqrt((lx - cx)^2 + (ly - cy)^2))
    end
    return best
end
distance(h::APHyperbola2, p::APPoint) = distance(p, h)
"""
    APParabola2(focus::APPoint, directrix::APLine)
"""
struct APParabola2{T<:Real} <: APConic2{T}
    focus::APPoint{2,T}
    directrix::APLine{2,T}
end
function APParabola2(focus::APPoint{2,T1}, directrix::APLine{2,T2}) where {T1,T2}
    T = promote_type(T1, T2)
    return APParabola2{T}(APPoint{2,T}(focus.coords), APLine{2,T}(directrix.p1, directrix.p2))
end
Base.:(==)(x::APParabola2, y::APParabola2) = x.focus == y.focus && x.directrix == y.directrix
Base.convert(::Type{APParabola2{T}}, p::APParabola2) where {T} = APParabola2{T}(p.focus, p.directrix)
Base.isapprox(x::APParabola2, y::APParabola2; kwargs...) =
    isapprox(x.focus, y.focus; kwargs...) && isapprox(x.directrix, y.directrix; kwargs...)
Base.show(io::IO, par::APParabola2) = print(io, "APParabola2(focus=", par.focus, ", directrix=", par.directrix, ")")
Base.in(p::APPoint, par::APParabola2) = distance(p, par.focus) <= distance(p, par.directrix)
"""
    vertex(par::APParabola2)

The vertex of `par`: the midpoint between its focus and the foot of the
perpendicular from the focus to the directrix.
"""
vertex(par::APParabola2) = midpoint(par.focus, projection(par.focus, par.directrix))
"""
    vertices(par::APParabola2)

`(vertex(par),)`: a 1-tuple, for the same `vertices` name to work
uniformly across every conic that has one.
"""
vertices(par::APParabola2) = (vertex(par),)
"""
    focal_parameter(par::APParabola2)

The distance between the focus and the directrix of `par` (often denoted `p`).
"""
focal_parameter(par::APParabola2) = distance(par.focus, par.directrix)
"""
    orthoptic(par::APParabola2)

The orthoptic curve of `par`: the locus of points from which the two
tangent lines to `par` are perpendicular. For a parabola this is,
somewhat surprisingly, exactly its own directrix.
"""
orthoptic(par::APParabola2) = par.directrix
function _parabola_frame(par::APParabola2)
    foot = projection(par.focus, par.directrix)
    u = (par.focus - foot) / norm(par.focus - foot)
    return midpoint(par.focus, foot), APVector(u), orthogonal(APVector(u))
end
"""
    point_on_parabola(par::APParabola2, s::Real)
"""
function point_on_parabola(par::APParabola2, s::Real)
    V, u, w = _parabola_frame(par)
    p = focal_parameter(par)
    return _from_local_frame(s^2 / (2p), s, V, u, w)
end
"""
    is_on_parabola(p::APPoint, par::APParabola2; atol=1e-9)
"""
is_on_parabola(p::APPoint, par::APParabola2; atol=1e-9) =
    abs(distance(p, par.focus) - distance(p, par.directrix)) <=
    sqrt(atol) * max(focal_parameter(par), 1.0)
rotate(par::APParabola2, angle::Real, center::APPoint=APPoint(0.0, 0.0)) =
    APParabola2(rotate(par.focus, angle, center), rotate(par.directrix, angle, center))
reflection(par::APParabola2, about) = APParabola2(reflection(par.focus, about), reflection(par.directrix, about))
homothety(par::APParabola2, k::Real, center::APPoint=APPoint(0.0, 0.0)) =
    APParabola2(homothety(par.focus, k, center), homothety(par.directrix, k, center))
translate(par::APParabola2, v::APVector) = APParabola2(translate(par.focus, v), translate(par.directrix, v))
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
    distance(p::APPoint, par::APParabola2)

Distance from `p` to the curve of `par`. Like the ellipse/hyperbola
cases, found via Newton's method rather than a closed form.
"""
function distance(p::APPoint, par::APParabola2)
    V, u, w = _parabola_frame(par)
    pf = focal_parameter(par)
    X0, Y0 = _to_local_frame(p, V, u, w)
    s = _closest_parabola_local_param(X0, Y0, pf)
    return distance(p, point_on_parabola(par, s))
end
distance(par::APParabola2, p::APPoint) = distance(p, par)
function _project_onto_circle2(circle::APCircle2, p::APPoint)
    v = p - circle.center
    d2 = dot(v, v)
    d2 <= 0 && throw(ArgumentError("APCircularArc2: p1/p2 must not coincide with the circle's own center"))
    return circle.center + (circle.r / sqrt(d2)) * v
end
"""
    APCircularArc2(circle::APCircle2, p1::APPoint, p2::APPoint)

The arc of `circle` traversed counterclockwise from `p1` to `p2`. `p1`/
`p2` need not lie exactly on `circle` -- only their *angle* from
`circle.center` matters, so the constructor projects each onto `circle`
(same angle, radius `circle.r`) before storing it. This keeps `arc.p1`/
`arc.p2` always genuinely on the circle, matching what
[`point_on_arc`](@ref)/[`midpoint`](@ref) already compute from the angle
alone -- without it, anything built directly from the raw `arc.p1`/
`arc.p2` (e.g. [`APCircularSector2`](@ref)'s own radii,
`APSegment(circle.center, arc.p1)`) would end at the wrong point whenever
the caller passed an off-circle `p1`/`p2`, visibly disagreeing with the
arc curve itself.
"""
struct APCircularArc2{T<:Real} <: APConicArc2{T}
    circle::APCircle2{T}
    p1::APPoint{2,T}
    p2::APPoint{2,T}
    function APCircularArc2{T}(circle::APCircle2, p1::APPoint{2}, p2::APPoint{2}) where {T<:Real}
        return new{T}(circle, _project_onto_circle2(circle, p1), _project_onto_circle2(circle, p2))
    end
end
function APCircularArc2(circle::APCircle2, p1::APPoint, p2::APPoint)
    T = promote_type(eltype(circle.center), eltype(p1), eltype(p2))
    return APCircularArc2{T}(APCircle2{T}(APPoint{2,T}(circle.center.coords), T(circle.r)), APPoint{2,T}(p1.coords), APPoint{2,T}(p2.coords))
end
"""
    APCircularArc2(center::APPoint, r::Real, p1::APPoint, p2::APPoint; ccw::Bool=true)

The arc of the circle centered at `center` with radius `r`, from `p1` to
`p2` (neither point's own distance from `center` has to be `r` -- same
projection rule as the `circle`-based constructor above, only their angle
matters). `ccw=true` (the default) sweeps counterclockwise from `p1` to
`p2`; `ccw=false` builds the complementary arc instead (as if `p1`/`p2`
were swapped).
"""
function APCircularArc2(center::APPoint, r::Real, p1::APPoint, p2::APPoint; ccw::Bool=true)
    circle = APCircle2(center, r)
    return ccw ? APCircularArc2(circle, p1, p2) : APCircularArc2(circle, p2, p1)
end
"""
    APCircularArc2(center::APPoint, p1::APPoint, p2::APPoint; ccw::Bool=true)

Same as [`APCircularArc2(::APPoint, ::Real, ::APPoint, ::APPoint)`](@ref)
above, with `r` taken to be `distance(center, p1)`.
"""
APCircularArc2(center::APPoint, p1::APPoint, p2::APPoint; ccw::Bool=true) =
    APCircularArc2(center, distance(center, p1), p1, p2; ccw=ccw)
Base.:(==)(x::APCircularArc2, y::APCircularArc2) = x.circle == y.circle && x.p1 == y.p1 && x.p2 == y.p2
Base.convert(::Type{APCircularArc2{T}}, a::APCircularArc2) where {T} = APCircularArc2{T}(a.circle, a.p1, a.p2)
Base.isapprox(x::APCircularArc2, y::APCircularArc2; kwargs...) =
    isapprox(x.circle, y.circle; kwargs...) && isapprox(x.p1, y.p1; kwargs...) && isapprox(x.p2, y.p2; kwargs...)
Base.show(io::IO, arc::APCircularArc2) = print(io, "APCircularArc2(", arc.circle, ", ", arc.p1, " -> ", arc.p2, ")")
"""
    reverse(arc::APCircularArc2)

The *complementary* arc: same circle, `p1`/`p2` swapped, so it sweeps the
rest of the way around (`measure` goes from `θ` to `2π - θ`, 0 stays 0).
See [`reverse(::APAngle2)`](@ref) for why this exists — the same
already-mirrored-coordinates gotcha applies here.
"""
Base.reverse(arc::APCircularArc2) = APCircularArc2(arc.circle, arc.p2, arc.p1)
_arc_angle(arc::APCircularArc2, p::APPoint) = atan(p[2] - arc.circle.center[2], p[1] - arc.circle.center[1])
_angle_in_arc_range(θ::Real, θ1::Real, Δθ::Real) = mod(θ - θ1, 2π) <= Δθ
"""
    measure(arc::APCircularArc2)
"""
measure(arc::APCircularArc2) = mod(_arc_angle(arc, arc.p2) - _arc_angle(arc, arc.p1), 2π)
"""
    arc_length(arc::APCircularArc2)

The length of `arc`: `circle.r * measure(arc)`.
"""
arc_length(arc::APCircularArc2) = arc.circle.r * measure(arc)
"""
    point_on_arc(arc, t::Real)

The point on `arc` at parameter `t` (`t = 0` gives `arc.p1`, `t = 1`
gives `arc.p2`) — defined for [`APCircularArc2`](@ref), `APEllipticArc2`,
`APParabolicArc2` and `APHyperbolicArc2`.
"""
function point_on_arc(arc::APCircularArc2, t::Real)
    a = _arc_angle(arc, arc.p1) + t * measure(arc)
    return arc.circle.center + arc.circle.r * APVector(cos(a), sin(a))
end
midpoint(arc::APCircularArc2) = point_on_arc(arc, 0.5)
"""
    APBoundingBox(arc::APCircularArc2)

The axis-aligned bounding box of `arc` itself (not the full circle):
exact, from `arc.p1`/`arc.p2` plus whichever of the circle's own
axis-extreme points (angle `0`, `π/2`, `π`, `3π/2`) fall within `arc`'s
own angular sweep.
"""
function APBoundingBox(arc::APCircularArc2)
    c = arc.circle
    θ1, Δθ = _arc_angle(arc, arc.p1), measure(arc)
    xs, ys = [arc.p1[1], arc.p2[1]], [arc.p1[2], arc.p2[2]]
    _angle_in_arc_range(0.0, θ1, Δθ) && push!(xs, c.center[1] + c.r)
    _angle_in_arc_range(π, θ1, Δθ) && push!(xs, c.center[1] - c.r)
    _angle_in_arc_range(π / 2, θ1, Δθ) && push!(ys, c.center[2] + c.r)
    _angle_in_arc_range(3π / 2, θ1, Δθ) && push!(ys, c.center[2] - c.r)
    return APBoundingBox(APPoint(minimum(xs), minimum(ys)), APPoint(maximum(xs), maximum(ys)))
end
"""
    distance(p::APPoint, arc::APCircularArc2)

Distance from `p` to `arc` itself — not the full circle: if `p`'s
angular projection falls within the arc's own sweep, this is the same as
[`distance(::APPoint, ::APCircle2)`](@ref); otherwise it's the closer of
the two endpoints.
"""
function distance(p::APPoint, arc::APCircularArc2)
    c = arc.circle
    a1 = _arc_angle(arc, arc.p1)
    ap = atan(p[2] - c.center[2], p[1] - c.center[1])
    0 <= mod(ap - a1, 2π) <= measure(arc) && return abs(distance(p, c.center) - c.r)
    return min(distance(p, arc.p1), distance(p, arc.p2))
end
distance(arc::APCircularArc2, p::APPoint) = distance(p, arc)
"""
    _ray_crossings(p::APPoint, arc::APCircularArc2)

How many times the rightward horizontal ray from `p` crosses `arc`
itself (not the full circle) — `0`, `1` or `2`. See
[`_ray_crossings(::APPoint, ::APSegment)`](@ref) for why this exists:
it's the curved-side building block `point_in_polygon` needs to apply
the even-odd rule to a region with one or more arc sides.
"""
function _ray_crossings(p::APPoint, arc::APCircularArc2)
    horiz = APLine(p, APPoint(p[1] + 1.0, p[2]))
    θ1, Δθ = _arc_angle(arc, arc.p1), measure(arc)
    count = 0
    for q in intersection(horiz, arc.circle)
        q[1] > p[1] || continue
        _angle_in_arc_range(_arc_angle(arc, q), θ1, Δθ) && (count += 1)
    end
    return count
end
"""
    p in arc::APCircularArc2

Whether `p` lies exactly on `arc` itself: on the circle, and within its
angular sweep from `p1` to `p2` (not just anywhere on the full circle).
"""
function Base.in(p::APPoint, arc::APCircularArc2; atol=1e-9)
    c = arc.circle
    abs(distance(p, c.center) - c.r) <= sqrt(atol) * max(c.r, 1.0) || return false
    return _angle_in_arc_range(_arc_angle(arc, p), _arc_angle(arc, arc.p1), measure(arc))
end
rotate(arc::APCircularArc2, angle::Real, center::APPoint=APPoint(0.0, 0.0)) =
    APCircularArc2(rotate(arc.circle, angle, center), rotate(arc.p1, angle, center), rotate(arc.p2, angle, center))
homothety(arc::APCircularArc2, k::Real, center::APPoint=APPoint(0.0, 0.0)) =
    APCircularArc2(homothety(arc.circle, k, center), homothety(arc.p1, k, center), homothety(arc.p2, k, center))
reflection(arc::APCircularArc2, about::APPoint) =
    APCircularArc2(reflection(arc.circle, about), reflection(arc.p1, about), reflection(arc.p2, about))
reflection(arc::APCircularArc2, about::APLine) =
    APCircularArc2(reflection(arc.circle, about), reflection(arc.p2, about), reflection(arc.p1, about))
translate(arc::APCircularArc2, v::APVector) =
    APCircularArc2(translate(arc.circle, v), translate(arc.p1, v), translate(arc.p2, v))
"""
    APEllipticArc2(ellipse::APEllipse2, p1::APPoint, p2::APPoint)

The arc of `ellipse` traversed counterclockwise (in the ellipse's own
parametrization) from `p1` to `p2` — the ellipse analogue of
[`APCircularArc2`](@ref), same swept/complementary-arc convention.
"""
struct APEllipticArc2{T<:Real} <: APConicArc2{T}
    ellipse::APEllipse2{T}
    p1::APPoint{2,T}
    p2::APPoint{2,T}
end
function APEllipticArc2(ellipse::APEllipse2, p1::APPoint, p2::APPoint)
    T = promote_type(eltype(ellipse.center), eltype(p1), eltype(p2))
    return APEllipticArc2{T}(convert(APEllipse2{T}, ellipse), convert(APPoint{2,T}, p1), convert(APPoint{2,T}, p2))
end
Base.convert(::Type{APEllipticArc2{T}}, a::APEllipticArc2) where {T} = APEllipticArc2{T}(a.ellipse, a.p1, a.p2)
"""
    reverse(arc::APEllipticArc2)

The *complementary* arc: same ellipse, `p1`/`p2` swapped, so it sweeps the
rest of the way around. See [`reverse(::APAngle2)`](@ref) for why this
exists — the same already-mirrored-coordinates gotcha applies here.
"""
Base.reverse(arc::APEllipticArc2) = APEllipticArc2(arc.ellipse, arc.p2, arc.p1)
function _ellipse_param(e::APEllipse2, p::APPoint)
    lx, ly = _to_ellipse_local(p, e)
    return atan(ly / e.b, lx / e.a)
end
_ellipse_param(arc::APEllipticArc2, p::APPoint) = _ellipse_param(arc.ellipse, p)
"""
    measure(arc::APEllipticArc2)

The swept parameter range from `p1` to `p2`, counterclockwise, in
`[0, 2π)` (the ellipse's own angular parameter, not true arc angle).
"""
measure(arc::APEllipticArc2) = mod(_ellipse_param(arc, arc.p2) - _ellipse_param(arc, arc.p1), 2π)
function point_on_arc(arc::APEllipticArc2, t::Real)
    a = _ellipse_param(arc, arc.p1) + t * measure(arc)
    return point_on_ellipse(arc.ellipse, a)
end
midpoint(arc::APEllipticArc2) = point_on_arc(arc, 0.5)
"""
    APBoundingBox(arc::APEllipticArc2)

The axis-aligned bounding box of `arc` itself (not the full ellipse):
exact, from `arc.p1`/`arc.p2` plus whichever of the ellipse's own
axis-extreme points fall within `arc`'s own angular sweep (the same
critical angles used implicitly by [`APBoundingBox(::APEllipse2)`](@ref),
found here from `x(θ) = cx + A cosθ + B sinθ`/`y(θ) = cy + C cosθ + D sinθ`,
each an unrotated sinusoid in `θ` whose own extrema are at `θ = atan(B,A)`/
`atan(D,C)` and their `+π` counterparts).
"""
function APBoundingBox(arc::APEllipticArc2)
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
    return APBoundingBox(APPoint(minimum(xs), minimum(ys)), APPoint(maximum(xs), maximum(ys)))
end
"""
    arc_length(arc::APEllipticArc2)

The length of `arc`. Unlike [`arc_length(::APCircularArc2)`](@ref),
there's no elementary closed form for this (an elliptic arc length is,
true to the name, an elliptic integral) — found instead by numerically
integrating the parametrization speed `|Δθ|·√(a²sin²θ + b²cos²θ)` over
`arc`'s own angular range.
"""
function arc_length(arc::APEllipticArc2)
    e = arc.ellipse
    θ1 = _ellipse_param(arc, arc.p1)
    Δθ = measure(arc)
    speed(t) = abs(Δθ) * sqrt((e.a * sin(θ1 + t * Δθ))^2 + (e.b * cos(θ1 + t * Δθ))^2)
    return _simpson_integrate(speed, 0.0, 1.0)
end
"""
    distance(p::APPoint, arc::APEllipticArc2)

Distance from `p` to `arc` itself: if the closest point on the *full*
ellipse falls within the arc's own parameter range, that's the answer
(via the same Newton solve as
[`distance(::APPoint, ::APEllipse2)`](@ref)); otherwise it's the closer
of the two endpoints.
"""
function distance(p::APPoint, arc::APEllipticArc2)
    e = arc.ellipse
    lx, ly = _to_ellipse_local(p, e)
    t1 = _ellipse_param(arc, arc.p1)
    d = _closest_ellipse_local_param_in_range(lx, ly, e.a, e.b, t1, measure(arc))
    return min(d, distance(p, arc.p1), distance(p, arc.p2))
end
distance(arc::APEllipticArc2, p::APPoint) = distance(p, arc)
function _ray_crossings(p::APPoint, arc::APEllipticArc2)
    horiz = APLine(p, APPoint(p[1] + 1.0, p[2]))
    θ1, Δθ = _ellipse_param(arc, arc.p1), measure(arc)
    count = 0
    for q in intersection(horiz, arc.ellipse)
        q[1] > p[1] || continue
        _angle_in_arc_range(_ellipse_param(arc, q), θ1, Δθ) && (count += 1)
    end
    return count
end
"""
    p in arc::APEllipticArc2

Whether `p` lies exactly on `arc` itself: on the ellipse, and within its
swept parameter range from `p1` to `p2`.
"""
function Base.in(p::APPoint, arc::APEllipticArc2; atol=1e-9)
    is_on_ellipse(p, arc.ellipse; atol=atol) || return false
    return _angle_in_arc_range(_ellipse_param(arc, p), _ellipse_param(arc, arc.p1), measure(arc))
end
rotate(arc::APEllipticArc2, angle::Real, center::APPoint=APPoint(0.0, 0.0)) =
    APEllipticArc2(rotate(arc.ellipse, angle, center), rotate(arc.p1, angle, center), rotate(arc.p2, angle, center))
homothety(arc::APEllipticArc2, k::Real, center::APPoint=APPoint(0.0, 0.0)) =
    APEllipticArc2(homothety(arc.ellipse, k, center), homothety(arc.p1, k, center), homothety(arc.p2, k, center))
reflection(arc::APEllipticArc2, about::APPoint) =
    APEllipticArc2(reflection(arc.ellipse, about), reflection(arc.p1, about), reflection(arc.p2, about))
reflection(arc::APEllipticArc2, about::APLine) =
    APEllipticArc2(reflection(arc.ellipse, about), reflection(arc.p2, about), reflection(arc.p1, about))
translate(arc::APEllipticArc2, v::APVector) =
    APEllipticArc2(translate(arc.ellipse, v), translate(arc.p1, v), translate(arc.p2, v))
"""
    APParabolicArc2(parabola::APParabola2, p1::APPoint, p2::APPoint)

The arc of `parabola` between `p1` and `p2`. Unlike a circle/ellipse (a
closed curve, where two points leave the "which way around" arc
ambiguous), a parabola is open — two points on it always determine a
single, unambiguous arc, with no complementary alternative — so, unlike
[`APCircularArc2`](@ref)/[`APEllipticArc2`](@ref), `reflection` never
needs to swap `p1`/`p2`.
"""
struct APParabolicArc2{T<:Real} <: APConicArc2{T}
    parabola::APParabola2{T}
    p1::APPoint{2,T}
    p2::APPoint{2,T}
end
function APParabolicArc2(parabola::APParabola2, p1::APPoint, p2::APPoint)
    T = promote_type(eltype(parabola.focus), eltype(p1), eltype(p2))
    return APParabolicArc2{T}(convert(APParabola2{T}, parabola), convert(APPoint{2,T}, p1), convert(APPoint{2,T}, p2))
end
Base.convert(::Type{APParabolicArc2{T}}, a::APParabolicArc2) where {T} = APParabolicArc2{T}(a.parabola, a.p1, a.p2)
"""
    reverse(arc::APParabolicArc2)

`p1`/`p2` swapped: since a parabola is open, this is the *same* arc (same
point set) with its parametrization direction reversed — unlike
[`reverse(::APCircularArc2)`](@ref)/[`reverse(::APEllipticArc2)`](@ref),
there's no complementary-arc ambiguity to resolve here. Provided mainly
for consistency with the closed-conic arcs' `reverse`.
"""
Base.reverse(arc::APParabolicArc2) = APParabolicArc2(arc.parabola, arc.p2, arc.p1)
function _parabola_param(par::APParabola2, p::APPoint)
    V, u, w = _parabola_frame(par)
    _, y = _to_local_frame(p, V, u, w)
    return y
end
_parabola_param(arc::APParabolicArc2, p::APPoint) = _parabola_param(arc.parabola, p)
function point_on_arc(arc::APParabolicArc2, t::Real)
    s1, s2 = _parabola_param(arc, arc.p1), _parabola_param(arc, arc.p2)
    return point_on_parabola(arc.parabola, s1 + t * (s2 - s1))
end
midpoint(arc::APParabolicArc2) = point_on_arc(arc, 0.5)
"""
    APBoundingBox(arc::APParabolicArc2)

The axis-aligned bounding box of `arc`: exact, from `arc.p1`/`arc.p2` plus
the critical points of `x(s) = Vx + (s²/2pf)u₁ + s·w₁`/
`y(s) = Vy + (s²/2pf)u₂ + s·w₂` (each a plain parabola in the scalar
parameter `s`, critical at `s = -pf·w/u` for its own `u`/`w` component)
that fall within `arc`'s own parameter range.
"""
function APBoundingBox(arc::APParabolicArc2)
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
    return APBoundingBox(APPoint(minimum(xs), minimum(ys)), APPoint(maximum(xs), maximum(ys)))
end
"""
    arc_length(arc::APParabolicArc2)

The length of `arc`, found by numerically integrating the parametrization
speed `|s2-s1|·√((s/pf)² + 1)` over `arc`'s own parameter range (no
elementary closed form exists for this either).
"""
function arc_length(arc::APParabolicArc2)
    par = arc.parabola
    pf = focal_parameter(par)
    s1, s2 = _parabola_param(arc, arc.p1), _parabola_param(arc, arc.p2)
    speed(t) = abs(s2 - s1) * sqrt(((s1 + t * (s2 - s1)) / pf)^2 + 1)
    return _simpson_integrate(speed, 0.0, 1.0)
end
"""
    distance(p::APPoint, arc::APParabolicArc2)

Distance from `p` to `arc` itself: if the closest point on the *full*
parabola falls within the arc's own parameter range, that's the answer
(via the same Newton solve as
[`distance(::APPoint, ::APParabola2)`](@ref)); otherwise it's the closer
of the two endpoints.
"""
function distance(p::APPoint, arc::APParabolicArc2)
    par = arc.parabola
    V, u, w = _parabola_frame(par)
    X0, Y0 = _to_local_frame(p, V, u, w)
    s1, s2 = _parabola_param(arc, arc.p1), _parabola_param(arc, arc.p2)
    smin, smax = minmax(s1, s2)
    d = _closest_parabola_local_param_in_range(X0, Y0, focal_parameter(par), smin, smax)
    return min(d, distance(p, arc.p1), distance(p, arc.p2))
end
distance(arc::APParabolicArc2, p::APPoint) = distance(p, arc)
function _ray_crossings(p::APPoint, arc::APParabolicArc2)
    horiz = APLine(p, APPoint(p[1] + 1.0, p[2]))
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
    p in arc::APParabolicArc2

Whether `p` lies exactly on `arc` itself: on the parabola, and within its
parameter range from `p1` to `p2`.
"""
function Base.in(p::APPoint, arc::APParabolicArc2; atol=1e-9)
    is_on_parabola(p, arc.parabola; atol=atol) || return false
    smin, smax = minmax(_parabola_param(arc, arc.p1), _parabola_param(arc, arc.p2))
    return smin <= _parabola_param(arc, p) <= smax
end
rotate(arc::APParabolicArc2, angle::Real, center::APPoint=APPoint(0.0, 0.0)) =
    APParabolicArc2(rotate(arc.parabola, angle, center), rotate(arc.p1, angle, center), rotate(arc.p2, angle, center))
homothety(arc::APParabolicArc2, k::Real, center::APPoint=APPoint(0.0, 0.0)) =
    APParabolicArc2(homothety(arc.parabola, k, center), homothety(arc.p1, k, center), homothety(arc.p2, k, center))
reflection(arc::APParabolicArc2, about) =
    APParabolicArc2(reflection(arc.parabola, about), reflection(arc.p1, about), reflection(arc.p2, about))
translate(arc::APParabolicArc2, v::APVector) =
    APParabolicArc2(translate(arc.parabola, v), translate(arc.p1, v), translate(arc.p2, v))
"""
    APHyperbolicArc2(hyperbola::APHyperbola2, p1::APPoint, p2::APPoint)

The arc of `hyperbola` between `p1` and `p2`, assumed to lie on the same
branch. Like [`APParabolicArc2`](@ref) (and unlike the closed conics), a
single branch of a hyperbola is open, so `reflection` never needs to swap
`p1`/`p2`.
"""
struct APHyperbolicArc2{T<:Real} <: APConicArc2{T}
    hyperbola::APHyperbola2{T}
    p1::APPoint{2,T}
    p2::APPoint{2,T}
end
function APHyperbolicArc2(hyperbola::APHyperbola2, p1::APPoint, p2::APPoint)
    T = promote_type(eltype(hyperbola.center), eltype(p1), eltype(p2))
    return APHyperbolicArc2{T}(convert(APHyperbola2{T}, hyperbola), convert(APPoint{2,T}, p1), convert(APPoint{2,T}, p2))
end
Base.convert(::Type{APHyperbolicArc2{T}}, a::APHyperbolicArc2) where {T} = APHyperbolicArc2{T}(a.hyperbola, a.p1, a.p2)
"""
    reverse(arc::APHyperbolicArc2)

`p1`/`p2` swapped: since a single hyperbola branch is open, this is the
*same* arc (same point set) with its parametrization direction reversed
— see [`reverse(::APParabolicArc2)`](@ref) for the same reasoning.
"""
Base.reverse(arc::APHyperbolicArc2) = APHyperbolicArc2(arc.hyperbola, arc.p2, arc.p1)
function _hyperbola_param(h::APHyperbola2, p::APPoint)
    lx, ly = _to_hyperbola_local(p, h)
    return asinh(ly / h.b), (lx >= 0 ? 1 : -1)
end
_hyperbola_param(arc::APHyperbolicArc2, p::APPoint) = _hyperbola_param(arc.hyperbola, p)
function point_on_arc(arc::APHyperbolicArc2, t::Real)
    t1, branch = _hyperbola_param(arc, arc.p1)
    t2, _ = _hyperbola_param(arc, arc.p2)
    return point_on_hyperbola(arc.hyperbola, t1 + t * (t2 - t1); branch=branch)
end
midpoint(arc::APHyperbolicArc2) = point_on_arc(arc, 0.5)
function _hyperbola_axis_critical_t(P::Real, Q::Real, tmin::Real, tmax::Real)
    P == 0 && return Float64[]
    r = -Q / P
    abs(r) >= 1 && return Float64[]
    t = atanh(r)
    return tmin <= t <= tmax ? [t] : Float64[]
end
"""
    APBoundingBox(arc::APHyperbolicArc2)

The axis-aligned bounding box of `arc`: exact, from `arc.p1`/`arc.p2` plus
the critical points of `x(t) = cx + P·cosh(t) + Q·sinh(t)`/
`y(t) = cy + R·cosh(t) + S·sinh(t)` (each solved via `_hyperbola_axis_critical_t`)
that fall within `arc`'s own parameter range.
"""
function APBoundingBox(arc::APHyperbolicArc2)
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
    return APBoundingBox(APPoint(minimum(xs), minimum(ys)), APPoint(maximum(xs), maximum(ys)))
end
"""
    arc_length(arc::APHyperbolicArc2)

The length of `arc`, found by numerically integrating the parametrization
speed `|t2-t1|·√(a²sinh²t + b²cosh²t)` over `arc`'s own parameter range
(no elementary closed form exists for this either).
"""
function arc_length(arc::APHyperbolicArc2)
    h = arc.hyperbola
    t1, _ = _hyperbola_param(arc, arc.p1)
    t2, _ = _hyperbola_param(arc, arc.p2)
    speed(t) = abs(t2 - t1) * sqrt((h.a * sinh(t1 + t * (t2 - t1)))^2 + (h.b * cosh(t1 + t * (t2 - t1)))^2)
    return _simpson_integrate(speed, 0.0, 1.0)
end
"""
    distance(p::APPoint, arc::APHyperbolicArc2)

Distance from `p` to `arc` itself: if the closest point on `arc`'s own
branch of the *full* hyperbola falls within the arc's own parameter
range, that's the answer (via the same Newton solve as
[`distance(::APPoint, ::APHyperbola2)`](@ref)); otherwise it's the closer
of the two endpoints.
"""
function distance(p::APPoint, arc::APHyperbolicArc2)
    h = arc.hyperbola
    lx, ly = _to_hyperbola_local(p, h)
    t1, branch = _hyperbola_param(arc, arc.p1)
    t2, _ = _hyperbola_param(arc, arc.p2)
    tmin, tmax = minmax(t1, t2)
    d = _closest_hyperbola_local_param_in_range(lx, ly, h.a, h.b, branch, tmin, tmax)
    return min(d, distance(p, arc.p1), distance(p, arc.p2))
end
distance(arc::APHyperbolicArc2, p::APPoint) = distance(p, arc)
function _ray_crossings(p::APPoint, arc::APHyperbolicArc2)
    horiz = APLine(p, APPoint(p[1] + 1.0, p[2]))
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
    p in arc::APHyperbolicArc2

Whether `p` lies exactly on `arc` itself: on the same branch of the
hyperbola, and within its parameter range from `p1` to `p2`.
"""
function Base.in(p::APPoint, arc::APHyperbolicArc2; atol=1e-9)
    is_on_hyperbola(p, arc.hyperbola; atol=atol) || return false
    t1, branch = _hyperbola_param(arc, arc.p1)
    t2, _ = _hyperbola_param(arc, arc.p2)
    t, b = _hyperbola_param(arc, p)
    b == branch || return false
    tmin, tmax = minmax(t1, t2)
    return tmin <= t <= tmax
end
rotate(arc::APHyperbolicArc2, angle::Real, center::APPoint=APPoint(0.0, 0.0)) =
    APHyperbolicArc2(rotate(arc.hyperbola, angle, center), rotate(arc.p1, angle, center), rotate(arc.p2, angle, center))
homothety(arc::APHyperbolicArc2, k::Real, center::APPoint=APPoint(0.0, 0.0)) =
    APHyperbolicArc2(homothety(arc.hyperbola, k, center), homothety(arc.p1, k, center), homothety(arc.p2, k, center))
reflection(arc::APHyperbolicArc2, about) =
    APHyperbolicArc2(reflection(arc.hyperbola, about), reflection(arc.p1, about), reflection(arc.p2, about))
translate(arc::APHyperbolicArc2, v::APVector) =
    APHyperbolicArc2(translate(arc.hyperbola, v), translate(arc.p1, v), translate(arc.p2, v))
