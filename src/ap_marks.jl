function _unit_direction(v::APVector, what::AbstractString)
    n = norm(v)
    n > 0 || throw(ArgumentError("tangent_at: $what has no direction (zero-length)"))
    return v / n
end
"""
    tangent_at(obj, t)

The point of `obj` at parameter `t` together with the unit tangent there,
as an [`APEquipollentVector`](@ref) (`.point` is the point, `.vector` the
unit direction of travel as `t` increases). `t = 0` is the start of `obj` and
`t = 1` its end, with the same parametrization as [`point_on_arc`](@ref):
for an [`APSegment`](@ref) it is proportional to length, for the
elliptic, parabolic and hyperbolic arcs it follows the conic's own
parameter (not arc length), and for a circular arc it is proportional to
the swept angle. An [`APLine`](@ref) and an [`APRay`](@ref) use
`p1 + t*(p2 - p1)` and `origin + t*(through - origin)`, so `t` can leave
`[0, 1]`.

This is the common building block of the decorations that hang off a curve:
[`marks`](@ref), and anything that needs "the normal at this point" (take
[`orthogonal`](@ref) of the vector). Throws an `ArgumentError` for a
degenerate object with no direction.
"""
function tangent_at(s::APSegment, t::Real)
    d = s.p2 - s.p1
    return APEquipollentVector(_unit_direction(d, "a zero-length segment"), s.p1 + t * d)
end
function tangent_at(l::APLine, t::Real)
    d = l.p2 - l.p1
    return APEquipollentVector(_unit_direction(d, "a line with equal defining points"), l.p1 + t * d)
end
function tangent_at(r::APRay, t::Real)
    d = r.through - r.origin
    return APEquipollentVector(_unit_direction(d, "a ray with equal defining points"), r.origin + t * d)
end
function tangent_at(arc::APCircularArc2, t::Real)
    a = _arc_angle(arc, arc.p1) + t * measure(arc)
    return APEquipollentVector(APVector(-sin(a), cos(a)), point_on_arc(arc, t))
end
function tangent_at(arc::APEllipticArc2, t::Real)
    e = arc.ellipse
    s = _ellipse_param(arc, arc.p1) + t * measure(arc)
    dx, dy = -e.a * sin(s), e.b * cos(s)
    c, sn = cos(e.angle), sin(e.angle)
    v = dx * APVector(c, sn) + dy * APVector(-sn, c)
    return APEquipollentVector(_unit_direction(v, "an elliptic arc"), point_on_arc(arc, t))
end
function tangent_at(arc::APParabolicArc2, t::Real)
    par = arc.parabola
    _, u, w = _parabola_frame(par)
    s1, s2 = _parabola_param(arc, arc.p1), _parabola_param(arc, arc.p2)
    s = s1 + t * (s2 - s1)
    v = ((s / focal_parameter(par)) * u + w) * (s2 >= s1 ? 1 : -1)
    return APEquipollentVector(_unit_direction(v, "a parabolic arc"), point_on_arc(arc, t))
end
function tangent_at(arc::APHyperbolicArc2, t::Real)
    h = arc.hyperbola
    t1, branch = _hyperbola_param(arc, arc.p1)
    t2, _ = _hyperbola_param(arc, arc.p2)
    τ = t1 + t * (t2 - t1)
    dx, dy = branch * h.a * sinh(τ), h.b * cosh(τ)
    c, sn = cos(h.angle), sin(h.angle)
    v = (dx * APVector(c, sn) + dy * APVector(-sn, c)) * (t2 >= t1 ? 1 : -1)
    return APEquipollentVector(_unit_direction(v, "a hyperbolic arc"), point_on_arc(arc, t))
end
const _MARK_STYLES = (:tick, :slash, :chevron, :cross, :circle)
function _marks_at(frame::APEquipollentVector, count::Integer, style::Symbol, size::Real, gap::Real, slant::Real)
    count >= 1 || throw(ArgumentError("marks: count must be at least 1"))
    size > 0 || throw(ArgumentError("marks: size must be positive"))
    style in _MARK_STYLES || throw(ArgumentError("marks: style must be one of $(_MARK_STYLES), got $(repr(style))"))
    P, T = frame.point, frame.vector
    N = orthogonal(T)
    out = APObject[]
    half = size / 2
    for i in 1:count
        C = P + ((i - (count + 1) / 2) * gap) * T
        if style === :tick
            push!(out, APSegment(C - half * N, C + half * N))
        elseif style === :slash
            d = cos(slant) * N + sin(slant) * T
            push!(out, APSegment(C - half * d, C + half * d))
        elseif style === :cross
            d1, d2 = (N + T) / sqrt(2), (N - T) / sqrt(2)
            push!(out, APSegment(C - half * d1, C + half * d1))
            push!(out, APSegment(C - half * d2, C + half * d2))
        elseif style === :circle
            push!(out, APCircle2(C, half))
        else
            tip = C + (size / 4) * T
            back = -half * (cos(pi / 4) * T)
            push!(out, APSegment(tip, tip + back + half * sin(pi / 4) * N))
            push!(out, APSegment(tip, tip + back - half * sin(pi / 4) * N))
        end
    end
    return identity.(out)
end
"""
    marks(obj; count=1, style=:tick, at=0.5, size=6.0, gap=4.0, slant=π/6)

The equality marks of a construction figure (the little ticks that say two
sides or arcs are congruent), as a `Vector` of geometric objects ready for
`path`: `count` marks centered at parameter `at` of `obj` (see
[`tangent_at`](@ref); `0.5` is the middle), `gap` apart along the tangent
there. Defined for an [`APSegment`](@ref) and the four conic arcs.

`size` is the full length of one mark (the diameter for `:circle`); both
`size` and `gap` are in the units of the coordinates of `obj`, so build the
marks from objects already transformed to the drawing (for example the ones
[`@to_luxor_picture`](@ref) returns) to get a size in canvas units.

`style` picks the shape:

| `style` | Mark |
|:--------|:-----|
| `:tick` | a straight stroke perpendicular to `obj` |
| `:slash` | a stroke tilted `slant` radians from the perpendicular |
| `:chevron` | a `>` pointing along the direction of travel (parallel-line marks) |
| `:cross` | an `x`, two strokes per mark |
| `:circle` | a small circle |

Throws an `ArgumentError` for an unknown `style`, `count < 1` or
`size <= 0`.
"""
function marks(obj::Union{APSegment,APCircularArc2,APEllipticArc2,APParabolicArc2,APHyperbolicArc2};
    count::Integer=1, style::Symbol=:tick, at::Real=0.5, size::Real=6.0, gap::Real=4.0, slant::Real=pi / 6)
    return _marks_at(tangent_at(obj, at), count, style, size, gap, slant)
end
"""
    marks(ang::APAngle2; count=1, style=:arcs, at=0.5, size=nothing, gap=4.0, mark_size=6.0, slant=π/6)

The equality marks of an angle. With the default `style = :arcs`, `count`
concentric [`APCircularArc2`](@ref)s centered at the vertex and swept from
`ang.a` to `ang.b`: the first of radius `size`, each further one `gap`
larger (one, two or three arcs is the usual way to say two angles are
equal). `size` defaults to `0.15` times the shorter of the two rays, the
same radius [`path`](@ref)`(ang)` uses.

Any other `style` (`:tick`, `:slash`, `:chevron`, `:cross`, `:circle`, see
[`marks`](@ref)) instead puts `count` symbols of size `mark_size` on the arc
of radius `size`, centered at parameter `at` of it. To combine arcs and a
symbol, call `marks` twice and concatenate, passing the same `size`.
Throws an `ArgumentError` if a ray has zero length.
"""
function marks(ang::APAngle2; count::Integer=1, style::Symbol=:arcs, at::Real=0.5,
    size::Union{Nothing,Real}=nothing, gap::Real=4.0, mark_size::Real=6.0, slant::Real=pi / 6)
    count >= 1 || throw(ArgumentError("marks: count must be at least 1"))
    va, vb = ang.a - ang.vertex, ang.b - ang.vertex
    (norm(va) > 0 && norm(vb) > 0) || throw(ArgumentError("marks: the angle has a ray of zero length"))
    r = size === nothing ? 0.15 * min(norm(va), norm(vb)) : size
    r > 0 || throw(ArgumentError("marks: size must be positive"))
    arc_at(radius) = APCircularArc2(ang.vertex, radius, ang.vertex + va, ang.vertex + vb)
    style === :arcs && return [arc_at(r + (i - 1) * gap) for i in 1:count]
    return _marks_at(tangent_at(arc_at(r), at), count, style, mark_size, gap, slant)
end
