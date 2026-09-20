# Measures that were missing: eccentricity and axes of conics, chord and sagitta of arcs, curvature,
# side lengths, interior angles and signed area of polygons, area and perimeter of boxes.

# ---- conics ----
"""
    eccentricity(conic)

The eccentricity `e` of a conic: `0` for a circle, `c / a` for an ellipse (with
`a` the semi-major axis and `c` the [`linear_eccentricity`](@ref)), `1` for a
parabola and `c / a` for a hyperbola (with `a` the transverse semi-axis), so it
is below `1` for ellipses and above `1` for hyperbolas.
"""
eccentricity(::APCircle2) = 0.0
eccentricity(e::APEllipse2) = linear_eccentricity(e) / semi_major(e)
eccentricity(h::APHyperbola2) = linear_eccentricity(h) / h.a
eccentricity(::APParabola2) = 1.0
"""
    linear_eccentricity(conic)

The distance `c` from the center of an ellipse or a hyperbola to each focus:
`√|a² − b²|` for an ellipse and `√(a² + b²)` for a hyperbola.
"""
linear_eccentricity(e::APEllipse2) = sqrt(abs(e.a^2 - e.b^2))
linear_eccentricity(h::APHyperbola2) = sqrt(h.a^2 + h.b^2)
"""
    semi_major(e::APEllipse2)
    semi_minor(e::APEllipse2)

The longer and the shorter semi-axis of an ellipse. The fields `a` and `b` are
the semi-axes along the ellipse's own `x` and `y` directions, and either can be
the longer one.
"""
semi_major(e::APEllipse2) = max(e.a, e.b)
"""
    semi_minor(e::APEllipse2)

The shorter semi-axis of an ellipse. See [`semi_major`](@ref).
"""
semi_minor(e::APEllipse2) = min(e.a, e.b)

# ---- curvature ----
"""
    curvature(circle)
    curvature(arc::APCircularArc2)
    curvature(conic, p)

The curvature `κ` of a curve, the inverse of the radius of its osculating
circle. A circle and a circular arc have the constant curvature `1 / r`. For an
ellipse, a hyperbola or a parabola it depends on the point, which must lie on
the curve (an `ArgumentError` otherwise). For an ellipse or a hyperbola with
local coordinates `(x, y)` it is `a⁴b⁴ / (b⁴x² + a⁴y²)^(3/2)`, and for a
parabola with parameter `p` ([`focal_parameter`](@ref)) and `x` measured from
the vertex along the tangent, `p² / (p² + x²)^(3/2)`.
"""
curvature(c::APCircle2) = 1 / c.r
curvature(a::APCircularArc2) = 1 / a.circle.r
function curvature(e::APEllipse2, p::APPoint; atol=1e-9)
    is_on_ellipse(p, e; atol=atol) || throw(ArgumentError("curvature: the point is not on the ellipse"))
    x, y = _to_ellipse_local(p, e)
    return (e.a * e.b)^4 / (e.b^4 * x^2 + e.a^4 * y^2)^1.5
end
function curvature(h::APHyperbola2, p::APPoint; atol=1e-9)
    is_on_hyperbola(p, h; atol=atol) || throw(ArgumentError("curvature: the point is not on the hyperbola"))
    x, y = _to_local_frame(p, h.center, h.angle)
    return (h.a * h.b)^4 / (h.b^4 * x^2 + h.a^4 * y^2)^1.5
end
function curvature(par::APParabola2, p::APPoint; atol=1e-9)
    is_on_parabola(p, par; atol=atol) || throw(ArgumentError("curvature: the point is not on the parabola"))
    v = vertex(par)
    axis = normalize(par.focus - v)
    x = cross2(axis, p - v)
    q = focal_parameter(par)
    return q^2 / (q^2 + x^2)^1.5
end

# central differences, one-sided (4 points) within a step of the ends of the range
function _curve_derivatives(c::APParametricCurve2, t::Real)
    lo, hi = c.trange
    lo <= t <= hi || throw(ArgumentError("curvature: t = $t is outside the range $(c.trange)"))
    h = 1e-4 * (hi - lo)
    if t - h < lo || t + h > hi
        σ = t - h < lo ? 1 : -1
        f0 = c.f(t)
        g1, g2, g3 = (c.f(t + σ * k * h) - f0 for k in 1:3)
        return σ * (18 * g1 - 9 * g2 + 2 * g3) / (6h), (-5 * g1 + 4 * g2 - g3) / h^2
    end
    p0 = c.f(t)
    a, b = c.f(t + h) - p0, c.f(t - h) - p0
    return (a - b) / (2h), (a + b) / h^2
end
"""
    signed_curvature(c::APParametricCurve2, t)

The curvature of a parametric curve at parameter `t` with a sign: positive when
the curve turns counterclockwise (to its left) as `t` grows, negative when it
turns clockwise, and zero on a straight stretch. It is `(x′y″ − y′x″) / (x′² +
y′²)^(3/2)`, with the derivatives found by finite differences, so it is
approximate (about seven digits) and the curve must have a nonzero derivative at
`t`.
"""
function signed_curvature(c::APParametricCurve2, t::Real)
    d1, d2 = _curve_derivatives(c, t)
    speed = norm(d1)
    iszero(speed) && throw(ArgumentError("curvature: the curve has no direction at t = $t"))
    return cross2(d1, d2) / speed^3
end
"""
    curvature(c::APParametricCurve2, t)

The curvature of a parametric curve at parameter `t`: the absolute value of
[`signed_curvature`](@ref), computed numerically. The radius of the osculating
circle is its inverse.
"""
curvature(c::APParametricCurve2, t::Real) = abs(signed_curvature(c, t))

# ---- arcs ----
"""
    chord_length(arc)

The length of the chord of an arc: the distance between its two endpoints.
"""
chord_length(a::Union{APCircularArc2,APEllipticArc2,APHyperbolicArc2,APParabolicArc2}) = distance(a.p1, a.p2)
"""
    sagitta(arc::APCircularArc2)

The height of a circular arc over its chord: `r (1 − cos(θ / 2))`, with `θ` the
[`measure`](@ref) of the arc. It is `r` for a semicircle and more than `r` for
an arc larger than one.
"""
sagitta(a::APCircularArc2) = a.circle.r * (1 - cos(measure(a) / 2))
arc_length(s::APSegment) = distance(s.p1, s.p2)

# ---- polygons ----
const _StraightPolygon2 = Union{APTriangle{2},APQuadrilateral{2},APStraightNgon{2}}
"""
    side_lengths(pg::APPolygon)

The lengths of the [`sides`](@ref) of a polygon, in order.
"""
side_lengths(pg::APPolygon) = [_side_length(s) for s in sides(pg)]
"""
    semiperimeter(pg::APPolygon)

Half the [`perimeter`](@ref). For a triangle it is the `s` of Heron's formula.
"""
semiperimeter(pg::APPolygon) = perimeter(pg) / 2
"""
    signed_area(pg)

The area of a polygon with a sign: positive when its vertices run
counterclockwise, negative when clockwise. [`area`](@ref) is its absolute
value. For triangles, quadrilaterals and straight polygons in the plane.
"""
function signed_area(pg::_StraightPolygon2)
    vs = vertices(pg)
    o = vs[1]
    n = length(vs)
    return sum(cross2(vs[i] - o, vs[mod1(i + 1, n)] - o) for i in 1:n) / 2
end
"""
    interior_angles(pg)

The interior angle at each vertex of a triangle, a quadrilateral or a straight
polygon in the plane, in radians and in the order of [`vertices`](@ref). An
angle is above `π` at a reflex vertex, and the angles of a polygon with `n`
vertices add up to `(n − 2)π`, whichever way the vertices are listed.
"""
function interior_angles(pg::_StraightPolygon2)
    vs = vertices(pg)
    n = length(vs)
    ccw = signed_area(pg) >= 0
    return map(1:n) do i
        v = vs[i]
        to_next, to_prev = vs[mod1(i + 1, n)] - v, vs[mod1(i - 1, n)] - v
        u, w = ccw ? (to_next, to_prev) : (to_prev, to_next)
        return mod(atan(cross2(u, w), dot(u, w)), 2π)
    end
end

# ---- bounding boxes ----
"""
    area(bb::APBoundingBox)
    perimeter(bb::APBoundingBox)

The area and the perimeter of a bounding box: `bbox_width * bbox_height` and
twice their sum.
"""
area(bb::APBoundingBox{2}) = bbox_width(bb) * bbox_height(bb)
perimeter(bb::APBoundingBox{2}) = 2 * (bbox_width(bb) + bbox_height(bb))
