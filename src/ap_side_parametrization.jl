_side_periodic(::Any) = false
_side_periodic(::Union{APCircle2,APEllipse2}) = true

_side_domain(s::APSegment) = (0.0, 1.0)
_side_domain(arc::APCircularArc2) = (θ1 = _arc_angle(arc, arc.p1); (θ1, θ1 + measure(arc)))
_side_domain(arc::APEllipticArc2) = (θ1 = _ellipse_param(arc, arc.p1); (θ1, θ1 + measure(arc)))
_side_domain(arc::APParabolicArc2) = minmax(_parabola_param(arc, arc.p1), _parabola_param(arc, arc.p2))
_side_domain(arc::APHyperbolicArc2) = minmax(_hyperbola_param(arc, arc.p1)[1], _hyperbola_param(arc, arc.p2)[1])
_side_domain(c::APCircle2) = (0.0, 2π)
_side_domain(e::APEllipse2) = (0.0, 2π)

function _side_param(s::APSegment, p::APPoint)
    d = s.p2 - s.p1
    return dot(p - s.p1, d) / dot(d, d)
end
function _side_param(arc::APCircularArc2, p::APPoint)
    θ1 = _arc_angle(arc, arc.p1)
    return θ1 + mod(_arc_angle(arc, p) - θ1, 2π)
end
function _side_param(arc::APEllipticArc2, p::APPoint)
    θ1 = _ellipse_param(arc, arc.p1)
    return θ1 + mod(_ellipse_param(arc, p) - θ1, 2π)
end
_side_param(arc::APParabolicArc2, p::APPoint) = _parabola_param(arc, p)
_side_param(arc::APHyperbolicArc2, p::APPoint) = _hyperbola_param(arc, p)[1]
_side_param(c::APCircle2, p::APPoint) = mod(_closed_param_of(c, p), 2π)
_side_param(e::APEllipse2, p::APPoint) = mod(_closed_param_of(e, p), 2π)

_side_between(s::APSegment, t1::Real, t2::Real) = APSegment(point_on(s, t1), point_on(s, t2))
_side_between(arc::APCircularArc2, t1::Real, t2::Real) = _make_closed_arc(arc.circle, t1, t2)
_side_between(arc::APEllipticArc2, t1::Real, t2::Real) = _make_closed_arc(arc.ellipse, t1, t2)
_side_between(arc::APParabolicArc2, t1::Real, t2::Real) = _open_object_from_range(arc.parabola, 0, t1, t2)
function _side_between(arc::APHyperbolicArc2, t1::Real, t2::Real)
    branch = _hyperbola_param(arc, arc.p1)[2]
    return _open_object_from_range(arc.hyperbola, branch, t1, t2)
end
_side_between(c::APCircle2, t1::Real, t2::Real) = _closed_object_from_range(c, t1, t2 - t1)
_side_between(e::APEllipse2, t1::Real, t2::Real) = _closed_object_from_range(e, t1, t2 - t1)

_side_point_at(s::APSegment, t::Real) = point_on(s, t)
_side_point_at(arc::APCircularArc2, t::Real) = _closed_param_point(arc.circle, t)
_side_point_at(arc::APEllipticArc2, t::Real) = _closed_param_point(arc.ellipse, t)
_side_point_at(arc::APParabolicArc2, t::Real) = point_on(arc.parabola, t)
_side_point_at(arc::APHyperbolicArc2, t::Real) = point_on(arc.hyperbola, t; branch=_hyperbola_param(arc, arc.p1)[2])
_side_point_at(c::APCircle2, t::Real) = _closed_param_point(c, t)
_side_point_at(e::APEllipse2, t::Real) = _closed_param_point(e, t)
