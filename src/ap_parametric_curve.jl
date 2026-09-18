"""
    APParametricCurve2{T<:Real} <: APCurve{2,T}
    APParametricCurve2(f::Function, trange::Tuple{<:Real,<:Real})

A curve given by an arbitrary parametrization `f(t)::APPoint{2}` over
`t ∈ trange = (tmin, tmax)`, for anything outside this package's fixed
analytic families (line, circle, the conics and their arcs). An ordinary
`y = f(x)` curve is just `APParametricCurve2(x -> APPoint(x, f(x)),
(xmin, xmax))`.

`translate`/`rotate`/`homothety`/`reflection` wrap `f` in a new closure
rather than sampling it, so they stay exact regardless of how `f` is
defined. [`APBoundingBox`](@ref) and drawing (see
[Drawing with Luxor.jl](@ref)) have no closed form for an arbitrary `f`,
so both fall back to sampling it over `trange`.
"""
struct APParametricCurve2{T<:Real} <: APCurve{2,T}
    f::Function
    trange::NTuple{2,T}
end
function APParametricCurve2(f::Function, trange::Tuple{<:Real,<:Real})
    T = float(promote_type(typeof(trange[1]), typeof(trange[2])))
    return APParametricCurve2{T}(f, (T(trange[1]), T(trange[2])))
end
Base.show(io::IO, curve::APParametricCurve2) = print(io, "APParametricCurve2(f, ", curve.trange, ")")
"""
    point_on_curve(curve::APParametricCurve2, t::Real)

The point at parameter `t`: `curve.f(t)`. `t` is expected to lie within
`curve.trange`, but this isn't enforced.
"""
point_on_curve(curve::APParametricCurve2, t::Real) = curve.f(t)
translate(curve::APParametricCurve2, v::APVector) = APParametricCurve2(t -> translate(curve.f(t), v), curve.trange)
rotate(curve::APParametricCurve2, angle::Real, center::APPoint=APPoint(0.0, 0.0)) =
    APParametricCurve2(t -> rotate(curve.f(t), angle, center), curve.trange)
homothety(curve::APParametricCurve2, k::Real, center::APPoint=APPoint(0.0, 0.0)) =
    APParametricCurve2(t -> homothety(curve.f(t), k, center), curve.trange)
reflection(curve::APParametricCurve2, about) = APParametricCurve2(t -> reflection(curve.f(t), about), curve.trange)
"""
    APBoundingBox(curve::APParametricCurve2; n::Int=200)

A sampled bounding box: `f` has no closed form in general, so this
evaluates `curve.f` at `n` evenly spaced points over `curve.trange` and
takes the union of their individual (degenerate) boxes. Unlike every
other `APBoundingBox` method in this package, this is an approximation,
not exact -- a sharply curving `f` between sample points can poke outside
the box this returns. Raise `n` for a tighter fit.
"""
function APBoundingBox(curve::APParametricCurve2; n::Int=200)
    tmin, tmax = curve.trange
    return APBoundingBox([curve.f(t) for t in range(tmin, tmax; length=n)])
end
