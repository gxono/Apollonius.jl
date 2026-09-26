"""
    APParabolicRay2(parabola::APParabola2, p::APPoint, dir::Int)

The half-infinite piece of `parabola` starting at `p` (assumed to lie on
`parabola`) and extending toward increasing `s` (`dir = 1`) or decreasing
`s` (`dir = -1`), in [`point_on`](@ref)`(parabola, s)`'s own parameter. The
[`APRay`](@ref) of the two open conics: what clipping a parabola against a
region (see [Unbounded Regions: Half-Planes, Strips & Angles](@ref)) leaves
when only one side of a crossing survives.
"""
struct APParabolicRay2{T<:Real} <: APCurve{2,T}
    parabola::APParabola2{T}
    p::APPoint{2,T}
    dir::Int
end
function APParabolicRay2(parabola::APParabola2, p::APPoint, dir::Int)
    T = promote_type(eltype(parabola.focus), eltype(p))
    return APParabolicRay2{T}(convert(APParabola2{T}, parabola), convert(APPoint{2,T}, p), dir)
end
Base.:(==)(x::APParabolicRay2, y::APParabolicRay2) = x.parabola == y.parabola && x.p == y.p && x.dir == y.dir
Base.hash(x::APParabolicRay2, h::UInt) = hash((x.parabola, x.p, x.dir), hash(:APParabolicRay2, h))
Base.isapprox(x::APParabolicRay2, y::APParabolicRay2; kwargs...) =
    isapprox(x.parabola, y.parabola; kwargs...) && isapprox(x.p, y.p; kwargs...) && x.dir == y.dir
Base.show(io::IO, r::APParabolicRay2) = print(io, "APParabolicRay2(", r.parabola, ", ", r.p, ", dir=", r.dir, ")")
APBoundingBox(::APParabolicRay2) = APBoundingBox()

"""
    APHyperbolicRay2(hyperbola::APHyperbola2, p::APPoint, branch::Int, dir::Int)

The half-infinite piece of `hyperbola`'s given `branch` (see
[`point_on`](@ref)`(hyperbola, t; branch)`) starting at `p` and extending
toward increasing (`dir = 1`) or decreasing (`dir = -1`) `t`.
"""
struct APHyperbolicRay2{T<:Real} <: APCurve{2,T}
    hyperbola::APHyperbola2{T}
    p::APPoint{2,T}
    branch::Int
    dir::Int
end
function APHyperbolicRay2(hyperbola::APHyperbola2, p::APPoint, branch::Int, dir::Int)
    T = promote_type(eltype(hyperbola.center), eltype(p))
    return APHyperbolicRay2{T}(convert(APHyperbola2{T}, hyperbola), convert(APPoint{2,T}, p), branch, dir)
end
Base.:(==)(x::APHyperbolicRay2, y::APHyperbolicRay2) =
    x.hyperbola == y.hyperbola && x.p == y.p && x.branch == y.branch && x.dir == y.dir
Base.hash(x::APHyperbolicRay2, h::UInt) = hash((x.hyperbola, x.p, x.branch, x.dir), hash(:APHyperbolicRay2, h))
Base.isapprox(x::APHyperbolicRay2, y::APHyperbolicRay2; kwargs...) =
    isapprox(x.hyperbola, y.hyperbola; kwargs...) && isapprox(x.p, y.p; kwargs...) && x.branch == y.branch && x.dir == y.dir
Base.show(io::IO, r::APHyperbolicRay2) =
    print(io, "APHyperbolicRay2(", r.hyperbola, ", ", r.p, ", branch=", r.branch, ", dir=", r.dir, ")")
APBoundingBox(::APHyperbolicRay2) = APBoundingBox()

"""
    APHyperbolaBranch2(hyperbola::APHyperbola2, branch::Int)

One whole branch of `hyperbola` (see [`point_on`](@ref)`(hyperbola, t;
branch)`), both ends still unbounded: what's left of [`intersection`](@ref)
against a region when a branch survives clipping entirely untouched while
the other branch may not.
"""
struct APHyperbolaBranch2{T<:Real} <: APCurve{2,T}
    hyperbola::APHyperbola2{T}
    branch::Int
end
Base.:(==)(x::APHyperbolaBranch2, y::APHyperbolaBranch2) = x.hyperbola == y.hyperbola && x.branch == y.branch
Base.hash(x::APHyperbolaBranch2, h::UInt) = hash((x.hyperbola, x.branch), hash(:APHyperbolaBranch2, h))
Base.isapprox(x::APHyperbolaBranch2, y::APHyperbolaBranch2; kwargs...) =
    isapprox(x.hyperbola, y.hyperbola; kwargs...) && x.branch == y.branch
Base.show(io::IO, b::APHyperbolaBranch2) = print(io, "APHyperbolaBranch2(", b.hyperbola, ", branch=", b.branch, ")")
APBoundingBox(::APHyperbolaBranch2) = APBoundingBox()

"""
    point_on(r::APParabolicRay2, u::Real)
    point_on(r::APHyperbolicRay2, u::Real)
    point_on(b::APHyperbolaBranch2, t::Real)

`u >= 0` moves away from `r.p` in the direction `r.dir`; `point_on(b, t)`
is just `point_on(b.hyperbola, t; branch=b.branch)`.
"""
point_on(r::APParabolicRay2, u::Real) = point_on(r.parabola, _parabola_param(r.parabola, r.p) + r.dir * u)
point_on(r::APHyperbolicRay2, u::Real) =
    point_on(r.hyperbola, _hyperbola_param(r.hyperbola, r.p)[1] + r.dir * u; branch=r.branch)
point_on(b::APHyperbolaBranch2, t::Real) = point_on(b.hyperbola, t; branch=b.branch)

"""
    p in r::APParabolicRay2
    p in r::APHyperbolicRay2
    p in b::APHyperbolaBranch2

Whether `p` lies exactly on the ray/branch: on the underlying conic, on the
matching branch, and within the ray's one-sided parameter range.
"""
function Base.in(p::APPoint, r::APParabolicRay2; atol=1e-9)
    is_on_parabola(p, r.parabola; atol=atol) || return false
    s0, s = _parabola_param(r.parabola, r.p), _parabola_param(r.parabola, p)
    return r.dir > 0 ? s >= s0 - atol : s <= s0 + atol
end
function Base.in(p::APPoint, r::APHyperbolicRay2; atol=1e-9)
    is_on_hyperbola(p, r.hyperbola; atol=atol) || return false
    t, branch = _hyperbola_param(r.hyperbola, p)
    branch == r.branch || return false
    t0 = _hyperbola_param(r.hyperbola, r.p)[1]
    return r.dir > 0 ? t >= t0 - atol : t <= t0 + atol
end
function Base.in(p::APPoint, b::APHyperbolaBranch2; atol=1e-9)
    is_on_hyperbola(p, b.hyperbola; atol=atol) || return false
    return _hyperbola_param(b.hyperbola, p)[2] == b.branch
end

function _closest_parabola_local_param_one_sided(X0::Real, Y0::Real, pf::Real, bound::Real, dir::Int; atol=1e-12, maxiter=100)
    best_y = bound
    best_d2 = (bound^2 / (2pf) - X0)^2 + (bound - Y0)^2
    scale = max(abs(X0), abs(Y0), pf, 1.0)
    for step in (1.0, 4.0, 16.0, 64.0)
        y0 = bound + dir * step * scale
        y = _newton_parabola_y(y0, X0, Y0, pf; atol=atol, maxiter=maxiter)
        (dir > 0 ? y >= bound - 1e-7 : y <= bound + 1e-7) || continue
        x = y^2 / (2pf)
        d2 = (x - X0)^2 + (y - Y0)^2
        d2 < best_d2 && ((best_d2, best_y) = (d2, y))
    end
    return best_y
end
function _closest_hyperbola_local_param_one_sided(lx::Real, ly::Real, a::Real, b::Real, branch::Int, bound::Real, dir::Int; atol=1e-12, maxiter=100)
    cx0, cy0 = branch * a * cosh(bound), b * sinh(bound)
    best_t, best_d2 = bound, (lx - cx0)^2 + (ly - cy0)^2
    scale = max(abs(lx), abs(ly), a, b, 1.0)
    for step in (1.0, 4.0, 16.0, 64.0)
        t0 = bound + dir * step * scale / max(a, b)
        t = _newton_hyperbola_t(t0, lx, ly, a, b, branch; atol=atol, maxiter=maxiter)
        (dir > 0 ? t >= bound - 1e-7 : t <= bound + 1e-7) || continue
        cx, cy = branch * a * cosh(t), b * sinh(t)
        d2 = (lx - cx)^2 + (ly - cy)^2
        d2 < best_d2 && ((best_d2, best_t) = (d2, t))
    end
    return best_t
end

"""
    distance(p::APPoint, r::APParabolicRay2)
    distance(p::APPoint, r::APHyperbolicRay2)
    distance(p::APPoint, b::APHyperbolaBranch2)
"""
function distance(p::APPoint, r::APParabolicRay2)
    par = r.parabola
    V, u, w = _parabola_frame(par)
    X0, Y0 = _to_local_frame(p, V, u, w)
    pf = focal_parameter(par)
    s0 = _parabola_param(par, r.p)
    s = _closest_parabola_local_param_one_sided(X0, Y0, pf, s0, r.dir)
    return distance(p, point_on(par, s))
end
distance(r::APParabolicRay2, p::APPoint) = distance(p, r)
function distance(p::APPoint, r::APHyperbolicRay2)
    h = r.hyperbola
    lx, ly = _to_hyperbola_local(p, h)
    t0 = _hyperbola_param(h, r.p)[1]
    t = _closest_hyperbola_local_param_one_sided(lx, ly, h.a, h.b, r.branch, t0, r.dir)
    return distance(p, point_on(h, t; branch=r.branch))
end
distance(r::APHyperbolicRay2, p::APPoint) = distance(p, r)
function distance(p::APPoint, b::APHyperbolaBranch2)
    h = b.hyperbola
    lx, ly = _to_hyperbola_local(p, h)
    t = _closest_hyperbola_local_param(lx, ly, h.a, h.b, b.branch)
    return distance(p, point_on(h, t; branch=b.branch))
end
distance(b::APHyperbolaBranch2, p::APPoint) = distance(p, b)

rotate(r::APParabolicRay2, angle::Real, center::APPoint=APPoint(0.0, 0.0)) =
    APParabolicRay2(rotate(r.parabola, angle, center), rotate(r.p, angle, center), r.dir)
homothety(r::APParabolicRay2, k::Real, center::APPoint=APPoint(0.0, 0.0)) =
    APParabolicRay2(homothety(r.parabola, k, center), homothety(r.p, k, center), r.dir)
translate(r::APParabolicRay2, v::APVector) = APParabolicRay2(translate(r.parabola, v), translate(r.p, v), r.dir)
reflection(r::APParabolicRay2, about::APPoint) = APParabolicRay2(reflection(r.parabola, about), reflection(r.p, about), r.dir)
reflection(r::APParabolicRay2, about::APLine) = APParabolicRay2(reflection(r.parabola, about), reflection(r.p, about), -r.dir)

rotate(r::APHyperbolicRay2, angle::Real, center::APPoint=APPoint(0.0, 0.0)) =
    APHyperbolicRay2(rotate(r.hyperbola, angle, center), rotate(r.p, angle, center), r.branch, r.dir)
homothety(r::APHyperbolicRay2, k::Real, center::APPoint=APPoint(0.0, 0.0)) =
    APHyperbolicRay2(homothety(r.hyperbola, k, center), homothety(r.p, k, center), r.branch, r.dir)
translate(r::APHyperbolicRay2, v::APVector) = APHyperbolicRay2(translate(r.hyperbola, v), translate(r.p, v), r.branch, r.dir)
reflection(r::APHyperbolicRay2, about::APPoint) =
    APHyperbolicRay2(reflection(r.hyperbola, about), reflection(r.p, about), r.branch, r.dir)
reflection(r::APHyperbolicRay2, about::APLine) =
    APHyperbolicRay2(reflection(r.hyperbola, about), reflection(r.p, about), r.branch, -r.dir)

rotate(b::APHyperbolaBranch2, angle::Real, center::APPoint=APPoint(0.0, 0.0)) = APHyperbolaBranch2(rotate(b.hyperbola, angle, center), b.branch)
homothety(b::APHyperbolaBranch2, k::Real, center::APPoint=APPoint(0.0, 0.0)) = APHyperbolaBranch2(homothety(b.hyperbola, k, center), b.branch)
translate(b::APHyperbolaBranch2, v::APVector) = APHyperbolaBranch2(translate(b.hyperbola, v), b.branch)
reflection(b::APHyperbolaBranch2, about) = APHyperbolaBranch2(reflection(b.hyperbola, about), b.branch)

(m::APAffineMap)(r::APParabolicRay2) = APParabolicRay2(m(r.parabola), m(r.p), r.dir)
(m::APAffineMap)(r::APHyperbolicRay2) = APHyperbolicRay2(m(r.hyperbola), m(r.p), r.branch, r.dir)
(m::APAffineMap)(b::APHyperbolaBranch2) = APHyperbolaBranch2(m(b.hyperbola), b.branch)
