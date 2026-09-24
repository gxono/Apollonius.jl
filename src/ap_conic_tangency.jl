"""
    intersection(l::APLine, e::APEllipse2; atol=1e-9)

Intersection points of `l` and `e`. Returns a `Vector{APPoint{2,Float64}}`
with 0, 1 or 2 points.
"""
function intersection(l::APLine, e::APEllipse2; atol=1e-9)
    ax, ay = _to_ellipse_local(l.p1, e)
    bx, by = _to_ellipse_local(l.p2, e)
    dx, dy = bx - ax, by - ay
    aa = (dx / e.a)^2 + (dy / e.b)^2
    bb = 2 * (ax * dx / e.a^2 + ay * dy / e.b^2)
    cc = (ax / e.a)^2 + (ay / e.b)^2 - 1
    ts = _solve_quadratic(aa, bb, cc; atol=atol)
    return [(p = _from_ellipse_local(ax + t * dx, ay + t * dy, e); APPoint(p[1], p[2])) for t in ts]
end
intersection(e::APEllipse2, l::APLine; atol=1e-9) = intersection(l, e; atol=atol)
intersection(s::APSegment, e::APEllipse2; atol=1e-9) = filter(p -> is_on_segment(p, s; atol=atol), intersection(APLine(s), e; atol=atol))
intersection(e::APEllipse2, s::APSegment; atol=1e-9) = intersection(s, e; atol=atol)
intersection(r::APRay, e::APEllipse2; atol=1e-9) = filter(p -> is_on_ray(p, r; atol=atol), intersection(APLine(r), e; atol=atol))
intersection(e::APEllipse2, r::APRay; atol=1e-9) = intersection(r, e; atol=atol)
"""
    polar_line(e::APEllipse2, p::APPoint; atol=1e-9)

The polar line of `p` with respect to `e`. When `p` is outside `e`, this is
the chord of contact of the two tangent lines from `p`; when `p` is on `e`,
it's the tangent line at `p`. `nothing` when `p` is `e`'s center (its polar
is the line at infinity).
"""
function polar_line(e::APEllipse2, p::APPoint; atol=1e-9)
    lx, ly = _to_ellipse_local(p, e)
    (lx / e.a)^2 + (ly / e.b)^2 <= atol && return nothing
    A, B = lx / e.a^2, ly / e.b^2
    denom = A^2 + B^2
    p0x, p0y = A / denom, B / denom
    dirlen = sqrt(denom)
    s = max(e.a, e.b)
    p1 = _from_ellipse_local(p0x, p0y, e)
    p2 = _from_ellipse_local(p0x - s * B / dirlen, p0y + s * A / dirlen, e)
    return APLine(APPoint(p1[1], p1[2]), APPoint(p2[1], p2[2]))
end
"""
    tangent_points(e::APEllipse2, p::APPoint; atol=1e-9)

Points of tangency on `e` of the lines from `p` tangent to `e`, found by
intersecting `e` with the polar line of `p`. Returns a
`Vector{APPoint{2,Float64}}` with 0 or 2 points (1 if `p` is on `e`; empty
if `p` is `e`'s center).
"""
function tangent_points(e::APEllipse2, p::APPoint; atol=1e-9)
    pl = polar_line(e, p; atol=atol)
    pl === nothing && return APPoint{2,Float64}[]
    return intersection(pl, e; atol=atol)
end
tangent_points(p::APPoint, e::APEllipse2; atol=1e-9) = tangent_points(e, p; atol=atol)
function _tangent_lines_via_polar(conic, p::APPoint; atol=1e-9)
    tps = tangent_points(conic, p; atol=atol)
    any(tp -> isapprox(tp, p; atol=sqrt(atol)), tps) && return [polar_line(conic, p; atol=atol)]
    return [APLine(p, tp) for tp in tps]
end
"""
    tangent_lines(e::APEllipse2, p::APPoint; atol=1e-9)

The line(s) through `p` tangent to `e` (see [`tangent_points`](@ref)). When
`p` is on `e`, this is the single tangent line *at* `p` (its polar line)
rather than the degenerate `APLine(p, p)`.
"""
tangent_lines(e::APEllipse2, p::APPoint; atol=1e-9) = _tangent_lines_via_polar(e, p; atol=atol)
tangent_lines(p::APPoint, e::APEllipse2; atol=1e-9) = tangent_lines(e, p; atol=atol)
"""
    intersection(l::APLine, h::APHyperbola2; atol=1e-9)

Intersection points of `l` and `h`. Returns a `Vector{APPoint{2,Float64}}`
with 0, 1 or 2 points.
"""
function intersection(l::APLine, h::APHyperbola2; atol=1e-9)
    ax, ay = _to_hyperbola_local(l.p1, h)
    bx, by = _to_hyperbola_local(l.p2, h)
    dx, dy = bx - ax, by - ay
    qa = (dx / h.a)^2 - (dy / h.b)^2
    qb = 2 * (ax * dx / h.a^2 - ay * dy / h.b^2)
    qc = (ax / h.a)^2 - (ay / h.b)^2 - 1
    ts = _solve_quadratic(qa, qb, qc; atol=atol)
    pts = APPoint{2,Float64}[]
    for t in ts
        x, y = ax + t * dx, ay + t * dy
        q = _from_hyperbola_local(x, y, h)
        push!(pts, APPoint(q[1], q[2]))
    end
    return pts
end
intersection(h::APHyperbola2, l::APLine; atol=1e-9) = intersection(l, h; atol=atol)
intersection(s::APSegment, h::APHyperbola2; atol=1e-9) = filter(p -> is_on_segment(p, s; atol=atol), intersection(APLine(s), h; atol=atol))
intersection(h::APHyperbola2, s::APSegment; atol=1e-9) = intersection(s, h; atol=atol)
intersection(r::APRay, h::APHyperbola2; atol=1e-9) = filter(p -> is_on_ray(p, r; atol=atol), intersection(APLine(r), h; atol=atol))
intersection(h::APHyperbola2, r::APRay; atol=1e-9) = intersection(r, h; atol=atol)
"""
    polar_line(h::APHyperbola2, p::APPoint; atol=1e-9)

The polar line of `p` with respect to `h` (see
[`polar_line(::APEllipse2, ::APPoint)`](@ref)). `nothing` when `p` is
`h`'s center.
"""
function polar_line(h::APHyperbola2, p::APPoint; atol=1e-9)
    lx, ly = _to_hyperbola_local(p, h)
    (lx / h.a)^2 + (ly / h.b)^2 <= atol && return nothing
    A, B = lx / h.a^2, -ly / h.b^2
    denom = A^2 + B^2
    p0x, p0y = A / denom, B / denom
    dirlen = sqrt(denom)
    s = max(h.a, h.b)
    p1 = _from_hyperbola_local(p0x, p0y, h)
    p2 = _from_hyperbola_local(p0x - s * B / dirlen, p0y + s * A / dirlen, h)
    return APLine(APPoint(p1[1], p1[2]), APPoint(p2[1], p2[2]))
end
"""
    tangent_points(h::APHyperbola2, p::APPoint; atol=1e-9)

Points of tangency on `h` of the lines from `p` tangent to `h`, found via
`p`'s polar line. Returns a `Vector{APPoint{2,Float64}}` with 0 or 2
points (1 if `p` is on `h`).
"""
function tangent_points(h::APHyperbola2, p::APPoint; atol=1e-9)
    pl = polar_line(h, p; atol=atol)
    pl === nothing && return APPoint{2,Float64}[]
    return intersection(pl, h; atol=atol)
end
tangent_points(p::APPoint, h::APHyperbola2; atol=1e-9) = tangent_points(h, p; atol=atol)
"""
    tangent_lines(h::APHyperbola2, p::APPoint; atol=1e-9)

The line(s) through `p` tangent to `h` (see [`tangent_points`](@ref)). When
`p` is on `h`, this is the single tangent line *at* `p` (its polar line)
rather than the degenerate `APLine(p, p)`.
"""
tangent_lines(h::APHyperbola2, p::APPoint; atol=1e-9) = _tangent_lines_via_polar(h, p; atol=atol)
tangent_lines(p::APPoint, h::APHyperbola2; atol=1e-9) = tangent_lines(h, p; atol=atol)
"""
    intersection(l::APLine, par::APParabola2; atol=1e-9)

Intersection points of `l` and `par`. Returns a `Vector{APPoint{2,Float64}}`
with 0, 1 or 2 points.
"""
function intersection(l::APLine, par::APParabola2; atol=1e-9)
    p = focal_parameter(par)
    p <= sqrt(atol) && return APPoint{2,Float64}[]
    V, u, w = _parabola_frame(par)
    Ax, Ay = _to_local_frame(l.p1, V, u, w)
    Bx, By = _to_local_frame(l.p2, V, u, w)
    dx, dy = Bx - Ax, By - Ay
    ts = _solve_quadratic(dy^2, 2Ay * dy - 2p * dx, Ay^2 - 2p * Ax; atol=atol)
    return [(q = _from_local_frame(Ax + t * dx, Ay + t * dy, V, u, w); APPoint(q[1], q[2])) for t in ts]
end
intersection(par::APParabola2, l::APLine; atol=1e-9) = intersection(l, par; atol=atol)
intersection(s::APSegment, par::APParabola2; atol=1e-9) = filter(p -> is_on_segment(p, s; atol=atol), intersection(APLine(s), par; atol=atol))
intersection(par::APParabola2, s::APSegment; atol=1e-9) = intersection(s, par; atol=atol)
intersection(r::APRay, par::APParabola2; atol=1e-9) = filter(p -> is_on_ray(p, r; atol=atol), intersection(APLine(r), par; atol=atol))
intersection(par::APParabola2, r::APRay; atol=1e-9) = intersection(r, par; atol=atol)
"""
    polar_line(par::APParabola2, p::APPoint; atol=1e-9)

The polar line of `p` with respect to `par` (see
[`polar_line(::APEllipse2, ::APPoint)`](@ref)). `nothing` when `par`'s
focus is on its directrix (degenerate parabola).
"""
function polar_line(par::APParabola2, p::APPoint; atol=1e-9)
    pfoc = focal_parameter(par)
    pfoc <= sqrt(atol) && return nothing
    V, u, w = _parabola_frame(par)
    X0, Y0 = _to_local_frame(p, V, u, w)
    Ax, Ay, K = -pfoc, Y0, -pfoc * X0
    step = pfoc
    p1 = _from_local_frame(-K / Ax, 0.0, V, u, w)
    p2 = _from_local_frame(-(K + Ay * step) / Ax, step, V, u, w)
    return APLine(APPoint(p1[1], p1[2]), APPoint(p2[1], p2[2]))
end
"""
    tangent_points(par::APParabola2, p::APPoint; atol=1e-9)

Points of tangency on `par` of the lines from `p` tangent to `par`, found
via `p`'s polar line. Returns a `Vector{APPoint{2,Float64}}` with 0 or 2
points (1 if `p` is on `par`).
"""
function tangent_points(par::APParabola2, p::APPoint; atol=1e-9)
    pl = polar_line(par, p; atol=atol)
    pl === nothing && return APPoint{2,Float64}[]
    return intersection(pl, par; atol=atol)
end
tangent_points(p::APPoint, par::APParabola2; atol=1e-9) = tangent_points(par, p; atol=atol)
"""
    tangent_lines(par::APParabola2, p::APPoint; atol=1e-9)

The line(s) through `p` tangent to `par` (see [`tangent_points`](@ref)).
When `p` is on `par`, this is the single tangent line *at* `p` (its polar
line) rather than the degenerate `APLine(p, p)`.
"""
tangent_lines(par::APParabola2, p::APPoint; atol=1e-9) = _tangent_lines_via_polar(par, p; atol=atol)
_conic(arc::APCircularArc2) = arc.circle
_conic(arc::APEllipticArc2) = arc.ellipse
_conic(arc::APParabolicArc2) = arc.parabola
_conic(arc::APHyperbolicArc2) = arc.hyperbola
"""
    intersection(l::APLine, arc::APConicArc2; atol=1e-9)
    intersection(s::APSegment, arc::APConicArc2; atol=1e-9)
    intersection(r::APRay, arc::APConicArc2; atol=1e-9)

Intersection points of `l`/`s`/`r` with `arc` itself, not the full conic
it's cut from: found by intersecting against `arc`'s own circle/ellipse/
parabola/hyperbola and keeping only the points that also fall within
`arc`'s own angular/parameter sweep (via `in`). Returns a
`Vector{APPoint{2,Float64}}`, same convention as every other
`intersection` method.
"""
intersection(l::APLine, arc::APConicArc2; atol=1e-9) = filter(p -> in(p, arc; atol=atol), intersection(l, _conic(arc); atol=atol))
intersection(arc::APConicArc2, l::APLine; atol=1e-9) = intersection(l, arc; atol=atol)
intersection(s::APSegment, arc::APConicArc2; atol=1e-9) = filter(p -> in(p, arc; atol=atol), intersection(s, _conic(arc); atol=atol))
intersection(arc::APConicArc2, s::APSegment; atol=1e-9) = intersection(s, arc; atol=atol)
intersection(r::APRay, arc::APConicArc2; atol=1e-9) = filter(p -> in(p, arc; atol=atol), intersection(r, _conic(arc); atol=atol))
intersection(arc::APConicArc2, r::APRay; atol=1e-9) = intersection(r, arc; atol=atol)
"""
    intersection(c::APCircle2, arc::APCircularArc2; atol=1e-9)
    intersection(arc::APCircularArc2, c::APCircle2; atol=1e-9)
    intersection(a1::APCircularArc2, a2::APCircularArc2; atol=1e-9)

The circular-arc-specific overloads: since circle-vs-circle intersection
already exists, a circular arc can also intersect a full `APCircle2` or
another circular arc the same way: intersect the underlying circles,
then keep only the points within each arc's own sweep. There is no
general `intersection` between an arc and a *different* conic type it
isn't cut from (an elliptic arc against a circle, two elliptic arcs from
different ellipses, ...): that needs general conic-vs-conic intersection,
which this package doesn't implement yet.
"""
intersection(c::APCircle2, arc::APCircularArc2; atol=1e-9) = filter(p -> in(p, arc; atol=atol), intersection(c, arc.circle; atol=atol))
intersection(arc::APCircularArc2, c::APCircle2; atol=1e-9) = intersection(c, arc; atol=atol)
intersection(a1::APCircularArc2, a2::APCircularArc2; atol=1e-9) =
    filter(p -> in(p, a1; atol=atol) && in(p, a2; atol=atol), intersection(a1.circle, a2.circle; atol=atol))
tangent_lines(p::APPoint, par::APParabola2; atol=1e-9) = tangent_lines(par, p; atol=atol)
