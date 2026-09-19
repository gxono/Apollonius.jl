const _CompositeCurve2 = Union{APPolyline2,APCurvilinearPolyline2,APPolygon{2},APBoundingBox{2},APAngle2,APHalfPlane2,APStrip2,APEquipollentVector{2}}
const _PrimitiveCurve2 = Union{APLine{2},APRay{2},APSegment{2},APCircle2,APEllipse2,APHyperbola2,APParabola2,APConicArc2}
# the primitive curves whose union is the curve (or boundary) of `x`
_pieces(x) = [x]
_pieces(pl::Union{APPolyline2,APCurvilinearPolyline2}) = collect(sides(pl))
_pieces(pg::APPolygon{2}) = collect(sides(pg))
function _pieces(bb::APBoundingBox{2})
    isempty(bb) && return APSegment{2,eltype(bb.min)}[]
    a, b = bb.min, bb.max
    c, d = APPoint(b[1], a[2]), APPoint(a[1], b[2])
    return [APSegment(a, c), APSegment(c, b), APSegment(b, d), APSegment(d, a)]
end
_pieces(ang::APAngle2) = [APRay(ang.vertex, ang.a), APRay(ang.vertex, ang.b)]
_pieces(h::APHalfPlane2) = [h.boundary]
_pieces(s::APStrip2) = [s.line1, s.line2]
_pieces(e::APEquipollentVector{2}) = [APSegment(e.point, e.point + e.vector)]
function _unique_points(pts, atol)
    out = eltype(pts)[]
    for p in pts
        tol = 1e3 * atol + 100 * eps(float(maximum(abs, p)))
        any(q -> distance(p, q) <= tol, out) || push!(out, p)
    end
    return out
end
_scalar_type(x) = typeof(x).parameters[end]
function _intersect_pieces(a, b, atol)
    pts = [p for pa in _pieces(a) for pb in _pieces(b) for p in intersection(pa, pb; atol=atol)]
    isempty(pts) && return APPoint{2,promote_type(_scalar_type(a), _scalar_type(b))}[]
    return _unique_points(pts, atol)
end
"""
    intersection(a, b; atol=1e-9)

For composite objects, the points where the *curves* (or boundaries) of `a`
and `b` meet. A polyline, a polygon or a chain counts as the union of its
sides, a bounding box as its four sides, an [`APAngle2`](@ref) as its two
rays, an [`APHalfPlane2`](@ref) as its boundary line, an
[`APStrip2`](@ref) as its two lines and an [`APEquipollentVector`](@ref) as
the segment it draws. The result lists the points side by side in the order
of the sides, with a point shared by two sides (a vertex) given once. Two
sides that overlap along a stretch give no point of their own, only the
endpoints where other sides cross them. The inside of a region is not part of
its curve: to test whether a point is inside, use `in`.
"""
intersection(a::_CompositeCurve2, b::_CompositeCurve2; atol=1e-9) = _intersect_pieces(a, b, atol)
intersection(a::_CompositeCurve2, b::_PrimitiveCurve2; atol=1e-9) = _intersect_pieces(a, b, atol)
intersection(a::_PrimitiveCurve2, b::_CompositeCurve2; atol=1e-9) = _intersect_pieces(a, b, atol)
"""
    intersection(p::APPoint, x; atol=1e-9)
    intersection(x, p::APPoint; atol=1e-9)

`[p]` if the point lies on the curve (or, for a region, on its boundary) `x`, and an
empty vector if not. The test is the one of [`on_line`](@ref): a distance
of at most `sqrt(atol)`.
"""
function intersection(p::APPoint{2}, x::Union{_CompositeCurve2,_PrimitiveCurve2}; atol=1e-9)
    hit = any(piece -> distance(p, piece) <= sqrt(atol), _pieces(x))
    return hit ? [p] : typeof(p)[]
end
intersection(x::Union{_CompositeCurve2,_PrimitiveCurve2}, p::APPoint{2}; atol=1e-9) = intersection(p, x; atol=atol)
intersection(p::APPoint{2}, q::APPoint{2}; atol=1e-9) = distance(p, q) <= sqrt(atol) ? [p] : typeof(p)[]
# parametric curves: sign changes of the signed distance to a line-like piece or a circle, refined by bisection
_residual(o::APLine) = p -> cross2(direction(o), p - o.p1) / norm(direction(o))
_residual(o::APRay) = _residual(APLine(o.origin, o.through))
_residual(o::APSegment) = _residual(APLine(o.p1, o.p2))
_residual(o::APCircle2) = p -> distance(p, o.center) - o.r
_residual(o::APEllipse2) = (f = foci(o); p -> distance(p, f[1]) + distance(p, f[2]) - 2 * o.a)
_residual(o::APHyperbola2) = (f = foci(o); p -> abs(distance(p, f[1]) - distance(p, f[2])) - 2 * o.a)
_residual(o::APParabola2) = p -> distance(p, o.focus) - distance(p, o.directrix)
_residual(o::APCircularArc2) = _residual(o.circle)
_residual(o::APEllipticArc2) = _residual(o.ellipse)
_residual(o::APHyperbolicArc2) = _residual(o.hyperbola)
_residual(o::APParabolicArc2) = _residual(o.parabola)
_ParametricTarget = Union{APLine{2},APRay{2},APSegment{2},APCircle2,APEllipse2,APHyperbola2,APParabola2,APConicArc2}
"""
    intersection(curve::APParametricCurve2, obj; n=400, atol=1e-9)

The points where a parametric curve meets a line, ray, segment, conic or conic arc
(or any composite made of them: a polygon, a polyline, a bounding box...). Two
parametric curves are not supported. The curve is
sampled at `n` parameters, every sign change of the signed distance to `obj` is
refined by bisection, and points off a ray or segment are dropped. A curve that
only touches `obj` without crossing it, or that crosses it twice between two
samples, is missed: increase `n`.

| Keyword | Default | Meaning |
|:--------|:--------|:--------|
| `n` | `400` | number of parameter samples along the curve |
| `atol` | `1e-9` | tolerance for merging repeated points |
"""
function intersection(c::APParametricCurve2, o::_ParametricTarget; n::Integer=400, atol=1e-9)
    g = _residual(o)
    t0, t1 = c.trange
    ts = range(t0, t1; length=n + 1)
    vals = [g(c.f(t)) for t in ts]
    pts = typeof(c.f(t0))[]
    for i in 1:n
        a, b, va, vb = ts[i], ts[i+1], vals[i], vals[i+1]
        va * vb > 0 && continue
        for _ in 1:80
            m = (a + b) / 2
            vm = g(c.f(m))
            if va * vm <= 0
                b, vb = m, vm
            else
                a, va = m, vm
            end
        end
        p = c.f((a + b) / 2)
        (o isa APRay || o isa APSegment || o isa APConicArc2 ? p in o : true) && push!(pts, p)
    end
    return _unique_points(pts, atol)
end
intersection(o::_ParametricTarget, c::APParametricCurve2; kwargs...) = intersection(c, o; kwargs...)
function intersection(c::APParametricCurve2, o::_CompositeCurve2; n::Integer=400, atol=1e-9)
    pts = [p for piece in _pieces(o) for p in intersection(c, piece; n=n, atol=atol)]
    return _unique_points(pts, atol)
end
intersection(o::_CompositeCurve2, c::APParametricCurve2; kwargs...) = intersection(c, o; kwargs...)
