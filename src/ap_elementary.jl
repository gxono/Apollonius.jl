# Elementary operations that every object of its kind should have: the direction and angle of a vector,
# the center and radius of a circle-like object, comparison of arcs and curvilinear polygons, the
# tangent and the distance for polylines and parametric curves.

# ---- vectors and angles ----
direction(v::APVector) = v
"""
    polar_angle(p::APPoint, center::APPoint=APPoint(0.0, 0.0))

The polar angle of `p` around `center` (the origin by default): the angle,
in radians in `(-π, π]`, that the vector from `center` to `p` makes with the
positive `x` axis, counterclockwise. It is the inverse of
[`polar_point`](@ref) together with [`distance`](@ref):
`polar_point(distance(c, p), polar_angle(p, c), c) ≈ p`. It is `0` when `p` is
`center`. For the angle of a vector, a line, a ray or a segment, see
[`slope_angle`](@ref).
"""
polar_angle(p::APPoint{2}, center::APPoint{2}=APPoint(0.0, 0.0)) = atan(p[2] - center[2], p[1] - center[1])
Base.:-(ev::APEquipollentVector) = APEquipollentVector(-ev.vector, ev.point)
Base.:*(k::Real, ev::APEquipollentVector) = APEquipollentVector(k * ev.vector, ev.point)
Base.:*(ev::APEquipollentVector, k::Real) = k * ev
Base.:/(ev::APEquipollentVector, k::Real) = APEquipollentVector(ev.vector / k, ev.point)
orthogonal(ev::APEquipollentVector{2}) = APEquipollentVector(orthogonal(ev.vector), ev.point)

# ---- center and radius ----
"""
    center(obj)

The center of a circle, an ellipse, a hyperbola, a circular, elliptic or
hyperbolic arc, a sector, a circular segment or an annular sector (the one of
its outer circle), and of an [`APBoundingBox`](@ref) (the midpoint of its
corners). It is the same as reading the field, in the same way for every type.
"""
center(c::APCircle2) = c.center
center(e::APEllipse2) = e.center
center(h::APHyperbola2) = h.center
center(a::APCircularArc2) = a.circle.center
center(a::APEllipticArc2) = a.ellipse.center
center(a::APHyperbolicArc2) = a.hyperbola.center
center(s::Union{APCircularSector2,APCircularSegment2}) = center(s.arc)
center(s::APAnnularSector2) = center(s.outer)
center(bb::APBoundingBox{2}) = bbox_center(bb)
"""
    radius(obj)

The radius of a circle, of a circular arc, and of a sector, circular segment or
annular sector (the outer one).
"""
radius(c::APCircle2) = c.r
radius(a::APCircularArc2) = a.circle.r
radius(s::Union{APCircularSector2,APCircularSegment2}) = radius(s.arc)
radius(s::APAnnularSector2) = radius(s.outer)
"""
    centroid(c::APCircle2)
    centroid(e::APEllipse2)

The center of mass of the disk or of the elliptical region: its center.
"""
centroid(c::APCircle2) = c.center
centroid(e::APEllipse2) = e.center

# ---- comparing arcs, curvilinear polygons and parametric curves ----
Base.:(==)(x::APEllipticArc2, y::APEllipticArc2) = x.ellipse == y.ellipse && x.p1 == y.p1 && x.p2 == y.p2
Base.:(==)(x::APHyperbolicArc2, y::APHyperbolicArc2) = x.hyperbola == y.hyperbola && x.p1 == y.p1 && x.p2 == y.p2
Base.:(==)(x::APParabolicArc2, y::APParabolicArc2) = x.parabola == y.parabola && x.p1 == y.p1 && x.p2 == y.p2
Base.isapprox(x::APEllipticArc2, y::APEllipticArc2; kwargs...) =
    isapprox(x.ellipse, y.ellipse; kwargs...) && isapprox(x.p1, y.p1; kwargs...) && isapprox(x.p2, y.p2; kwargs...)
Base.isapprox(x::APHyperbolicArc2, y::APHyperbolicArc2; kwargs...) =
    isapprox(x.hyperbola, y.hyperbola; kwargs...) && isapprox(x.p1, y.p1; kwargs...) && isapprox(x.p2, y.p2; kwargs...)
Base.isapprox(x::APParabolicArc2, y::APParabolicArc2; kwargs...) =
    isapprox(x.parabola, y.parabola; kwargs...) && isapprox(x.p1, y.p1; kwargs...) && isapprox(x.p2, y.p2; kwargs...)
const _CurvilinearRegion2 = Union{APCurvilinearTriangle2,APCurvilinearQuadrilateral2,APCurvilinearNgon2}
Base.isapprox(x::T, y::T; kwargs...) where {T<:_CurvilinearRegion2} =
    length(x.sides) == length(y.sides) && all(isapprox(a, b; kwargs...) for (a, b) in zip(x.sides, y.sides))
Base.:(==)(x::APParametricCurve2, y::APParametricCurve2) = x.f === y.f && x.trange == y.trange
"""
    isapprox(x::APParametricCurve2, y::APParametricCurve2; kwargs...)

Two parametric curves are approximately equal when they have the same range
and their functions agree at 17 evenly spaced parameters. Functions cannot be
compared any other way.
"""
function Base.isapprox(x::APParametricCurve2, y::APParametricCurve2; kwargs...)
    isapprox(collect(x.trange), collect(y.trange); kwargs...) || return false
    return all(t -> isapprox(x.f(t), y.f(t); kwargs...), range(x.trange[1], x.trange[2]; length=17))
end

# ---- polylines and chains as curves ----
_chain_lengths(sides) = [_side_length(s) for s in sides]
function _point_along(sides, t::Real)
    0 <= t <= 1 || throw(ArgumentError("point_on_curve: t must be in [0, 1]"))
    lens = _chain_lengths(sides)
    target = t * sum(lens)
    acc = 0.0
    for (s, l) in zip(sides, lens)
        if target <= acc + l || s === last(sides)
            u = l == 0 ? 0.0 : clamp((target - acc) / l, 0.0, 1.0)
            return s isa APSegment ? point_on_line(s, u) : point_on_arc(s, u)
        end
        acc += l
    end
end
"""
    point_on_curve(curve, t)

The point at fraction `t` of the way along `curve`, with `t = 0` at its start
and `t = 1` at its end. For an [`APParametricCurve2`](@ref) it is `curve.f(t)`
for `t` in its own range. For an [`APPolyline2`](@ref) it is the point at
`t` times the total length, following the sides. For an
[`APCurvilinearPolyline2`](@ref), each side takes the fraction of `t` that its
length is of the total, and inside a side the point follows the side's own
parameter, which is the arc length for segments and circular arcs and not for
the other arcs.
"""
point_on_curve(pl::APPolyline2, t::Real) = _point_along(collect(sides(pl)), t)
point_on_curve(pl::APCurvilinearPolyline2, t::Real) = _point_along(collect(sides(pl)), t)

# ---- tangents and distance for polylines and parametric curves ----
function tangent_line(pl::Union{APPolyline2,APCurvilinearPolyline2}, p::APPoint; atol=1e-9)
    for s in sides(pl)
        hit = s isa APSegment ? on_segment(p, s; atol=atol) : in(p, s; atol=atol)
        hit && return tangent_line(s, p; atol=atol)
    end
    throw(ArgumentError("tangent_line: the point is not on the chain"))
end
_param_step(c::APParametricCurve2) = (c.trange[2] - c.trange[1]) * 1e-6
"""
    tangent_at(curve::APParametricCurve2, t)

The point of the curve at parameter `t` with the unit tangent there, as an
[`APEquipollentVector`](@ref), like the other [`tangent_at`](@ref) methods. The
derivative is a central difference, so it is approximate, and the curve must
have a nonzero derivative at `t`.
"""
function tangent_at(c::APParametricCurve2, t::Real)
    h = _param_step(c)
    a, b = max(c.trange[1], t - h), min(c.trange[2], t + h)
    d = c.f(b) - c.f(a)
    iszero(norm(d)) && throw(ArgumentError("tangent_at: the curve has no direction at t = $t"))
    return APEquipollentVector(normalize(d), c.f(t))
end
# parameter of the point of the curve nearest to p: coarse sampling, then golden-section refinement
function _nearest_parameter(c::APParametricCurve2, p::APPoint; n::Integer=400)
    ts = range(c.trange[1], c.trange[2]; length=n + 1)
    ds = [distance(p, c.f(t)) for t in ts]
    i = argmin(ds)
    a, b = ts[max(i - 1, 1)], ts[min(i + 1, n + 1)]
    φ = (sqrt(5) - 1) / 2
    for _ in 1:60
        x1, x2 = b - φ * (b - a), a + φ * (b - a)
        distance(p, c.f(x1)) < distance(p, c.f(x2)) ? (b = x2) : (a = x1)
    end
    return (a + b) / 2
end
"""
    distance(p::APPoint, c::APParametricCurve2; n=400)
    distance(c::APParametricCurve2, p::APPoint; n=400)

The distance from a point to a parametric curve, found numerically: the curve
is sampled at `n` parameters and the best interval is refined. A curve that
comes back close to `p` between two samples can be missed: increase `n`.

| Keyword | Default | Meaning |
|:--------|:--------|:--------|
| `n` | `400` | number of parameter samples along the curve |
"""
distance(p::APPoint{2}, c::APParametricCurve2; n::Integer=400) = distance(p, c.f(_nearest_parameter(c, p; n=n)))
distance(c::APParametricCurve2, p::APPoint{2}; n::Integer=400) = distance(p, c; n=n)
function tangent_line(c::APParametricCurve2, p::APPoint; atol=1e-9, n::Integer=400)
    t = _nearest_parameter(c, p; n=n)
    q = c.f(t)
    distance(p, q) <= sqrt(atol) * max(1.0, norm(p)) || throw(ArgumentError("tangent_line: the point is not on the curve"))
    ev = tangent_at(c, t)
    return APLine(ev.point, ev.vector)
end

# ---- element type conversion ----
_cv(::Type{T}, p::APPoint{Dim}) where {T,Dim} = convert(APPoint{Dim,T}, p)
Base.convert(::Type{APTriangle{D,T}}, t::APTriangle) where {D,T} = APTriangle{D,T}(_cv(T, t.a), _cv(T, t.b), _cv(T, t.c))
Base.convert(::Type{APQuadrilateral{D,T}}, q::APQuadrilateral) where {D,T} =
    APQuadrilateral{D,T}(_cv(T, q.a), _cv(T, q.b), _cv(T, q.c), _cv(T, q.d))
Base.convert(::Type{APStraightNgon{D,T}}, g::APStraightNgon) where {D,T} = APStraightNgon{D,T}(APPoint{D,T}[_cv(T, v) for v in g.vertices])
Base.convert(::Type{APPolyline2{T}}, pl::APPolyline2) where {T} = APPolyline2{T}(APPoint{2,T}[_cv(T, v) for v in pl.vertices])
Base.convert(::Type{APBoundingBox{D,T}}, b::APBoundingBox) where {D,T} = APBoundingBox{D,T}(_cv(T, b.min), _cv(T, b.max))
Base.convert(::Type{APAngle2{T}}, a::APAngle2) where {T} = APAngle2{T}(_cv(T, a.vertex), _cv(T, a.a), _cv(T, a.b))
Base.convert(::Type{APEquipollentVector{D,T}}, e::APEquipollentVector) where {D,T} =
    APEquipollentVector{D,T}(convert(APVector{D,T}, e.vector), _cv(T, e.point))

# ---- centroid of points, segments, boxes and polylines ----
"""
    centroid(obj)

The center of mass. For a point it is the point itself, for a segment its
midpoint, for a bounding box its center and for an [`APPolyline2`](@ref) the
average of the midpoints of its sides weighted by their length (the mass is on
the curve, not on the region it encloses). For polygons, circles and ellipses
see the methods of [`APPolygon`](@ref) and [`APCircle2`](@ref).
"""
centroid(p::APPoint) = p
centroid(s::APSegment) = midpoint(s.p1, s.p2)
centroid(b::APBoundingBox) = bbox_center(b)
function centroid(pl::APPolyline2)
    ss = collect(sides(pl))
    ls = [distance(s.p1, s.p2) for s in ss]
    o = pl.vertices[1]
    iszero(sum(ls)) && return o
    w = sum(l * (midpoint(s.p1, s.p2) - o) for (s, l) in zip(ss, ls)) / sum(ls)
    return o + w
end
