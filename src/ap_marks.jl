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
`t = 1` its end, with the same parametrization as [`point_on`](@ref):
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
    return APEquipollentVector(APVector(-sin(a), cos(a)), point_on(arc, t))
end
function tangent_at(arc::APEllipticArc2, t::Real)
    e = arc.ellipse
    s = _ellipse_param(arc, arc.p1) + t * measure(arc)
    dx, dy = -e.a * sin(s), e.b * cos(s)
    c, sn = cos(e.angle), sin(e.angle)
    v = dx * APVector(c, sn) + dy * APVector(-sn, c)
    return APEquipollentVector(_unit_direction(v, "an elliptic arc"), point_on(arc, t))
end
function tangent_at(arc::APParabolicArc2, t::Real)
    par = arc.parabola
    _, u, w = _parabola_frame(par)
    s1, s2 = _parabola_param(arc, arc.p1), _parabola_param(arc, arc.p2)
    s = s1 + t * (s2 - s1)
    v = ((s / focal_parameter(par)) * u + w) * (s2 >= s1 ? 1 : -1)
    return APEquipollentVector(_unit_direction(v, "a parabolic arc"), point_on(arc, t))
end
function tangent_at(arc::APHyperbolicArc2, t::Real)
    h = arc.hyperbola
    t1, branch = _hyperbola_param(arc, arc.p1)
    t2, _ = _hyperbola_param(arc, arc.p2)
    τ = t1 + t * (t2 - t1)
    dx, dy = branch * h.a * sinh(τ), h.b * cosh(τ)
    c, sn = cos(h.angle), sin(h.angle)
    v = (dx * APVector(c, sn) + dy * APVector(-sn, c)) * (t2 >= t1 ? 1 : -1)
    return APEquipollentVector(_unit_direction(v, "a hyperbolic arc"), point_on(arc, t))
end
const _MARK_STYLES = (:tick, :slash, :chevron, :cross, :circle, :z, :s)
function _marks_at(frame::APEquipollentVector, count::Integer, style::Symbol, size::Real, gap::Real, slant::Real)
    count >= 1 || throw(ArgumentError("marks: count must be at least 1"))
    size > 0 || throw(ArgumentError("marks: size must be positive"))
    style in _MARK_STYLES || throw(ArgumentError("marks: style must be one of $(_MARK_STYLES), got $(repr(style))"))
    P, T = frame.point, frame.vector
    N = orthogonal(T)
    out = APObject[]
    half = size / 2
    step = style in (:circle, :z, :s) ? max(gap, size) : gap   # circles are at least tangent, letters do not overlap
    for i in 1:count
        C = P + ((i - (count + 1) / 2) * step) * T
        if style === :tick
            push!(out, APSegment(C - half * N, C + half * N))
        elseif style === :slash
            d = cos(slant) * N + sin(slant) * T
            push!(out, APSegment(C - half * d, C + half * d))
        elseif style === :cross
            d1, d2 = (N + T) / sqrt(2), (N - T) / sqrt(2)
            push!(out, APSegment(C - half * d1, C + half * d1))
            push!(out, APSegment(C - half * d2, C + half * d2))
        elseif style === :z
            # upright "Z" when the segment is vertical on the drawn (y down) canvas
            a, b = size / 4, half
            push!(out, APPolyline2([C - a * N + b * T, C + a * N + b * T, C - a * N - b * T, C + a * N - b * T]))
        elseif style === :s
            r, up, dn = size / 4, C + (size / 4) * T, C - (size / 4) * T
            top, mid, bot = up + r * cos(pi / 6) * N + r * sin(pi / 6) * T, up - r * T, dn - r * cos(pi / 6) * N - r * sin(pi / 6) * T
            push!(out, APCircularArc2(up, r, mid, top))
            push!(out, APCircularArc2(dn, r, up - r * T, bot))
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

| Keyword | Default | Meaning |
|:--------|:--------|:--------|
| `count` | `1` | number of marks |
| `style` | `:tick` | shape of each mark, see below |
| `at` | `0.5` | where along `obj`, in `[0, 1]` |
| `size` | `6.0` | full length of one mark: the diameter of a `:circle`, the height of a `:z` or `:s` |
| `gap` | `4.0` | distance between neighbouring marks along the tangent; raised to `size` for `:circle`, `:z` and `:s` so they do not overlap |
| `slant` | `π/6` | tilt of a `:slash` from the perpendicular |

`size` and `gap` are in the units of the coordinates of `obj`, so build the
marks from objects already transformed to the drawing (for example the ones
[`@prepare_to_picture`](@ref) returns) to get a size in canvas units.

`style` picks the shape:

| `style` | Mark |
|:--------|:-----|
| `:tick` | a straight stroke perpendicular to `obj` |
| `:slash` | a stroke tilted `slant` radians from the perpendicular |
| `:chevron` | a `>` pointing along the direction of travel (parallel-line marks) |
| `:cross` | an `x`, two strokes per mark |
| `:circle` | a small circle |
| `:z` | a zigzag, a `Z` that stands upright when the segment is vertical on the drawn canvas |
| `:s` | an `S` drawn the same way, from two arcs |

Throws an `ArgumentError` for an unknown `style`, `count < 1` or
`size <= 0`.
"""
function marks(obj::Union{APSegment,APCircularArc2,APEllipticArc2,APParabolicArc2,APHyperbolicArc2};
    count::Integer=1, style::Symbol=:tick, at::Real=0.5, size::Real=6.0, gap::Real=4.0, slant::Real=pi / 6)
    return _marks_at(tangent_at(obj, at), count, style, size, gap, slant)
end
"""
    marks(ang::APAngle2; count=1, style=:arcs, at=0.5, size=nothing, gap=4.0, mark_size=6.0, slant=π/6, arcs=0)

The equality marks of an angle. With the default `style = :arcs`, `count`
concentric [`APCircularArc2`](@ref)s centered at the vertex and swept from
`ang.a` to `ang.b`: the first of radius `size`, each further one `gap`
larger (one, two or three arcs is the usual way to say two angles are
equal). `size` defaults to `0.15` times the shorter of the two rays, the
same radius [`path`](@ref)`(ang)` uses. Wrap the (single, `count=1`) arc in
[`APCircularSector2`](@ref) for a fillable pie-wedge marker instead of just
the open arc.

With `style = :parallelogram`, `count` nested open
[`APPolyline2`](@ref)`(pa, pc, pb)` markers instead: `pa`/`pb` at distance
`size`, `size + gap`, ... along each ray, and `pc = pa + pb - vertex`
completing the parallelogram by the parallelogram law (a square corner at
exactly 90°, a rhombus otherwise, the same right-angle-marker idea
generalized to any angle). Wrap `poly.vertices` in
[`APQuadrilateral`](@ref)`(ang.vertex, poly.vertices...)` for the closed,
fillable form.

| Keyword | Default | Meaning |
|:--------|:--------|:--------|
| `count` | `1` | number of arcs, parallelograms, or symbols |
| `style` | `:arcs` | `:arcs`, `:parallelogram`, or any style of [`marks`](@ref) for symbols |
| `at` | `0.5` | where the symbols sit along the arc |
| `size` | `0.15` times the shorter ray | radius of the first arc, or ray-distance of the first parallelogram |
| `gap` | `4.0` | radial gap between arcs/parallelograms, or gap between symbols |
| `mark_size` | `6.0` | size of each symbol, when `style` is not `:arcs`/`:parallelogram` |
| `slant` | `π/6` | tilt of a `:slash` |
| `arcs` | `0` | with a symbol style, also draw this many arcs, see below |

Any other `style` (`:tick`, `:slash`, `:chevron`, `:cross`, `:circle`, `:z`, `:s`, see
[`marks`](@ref)) instead puts `count` symbols of size `mark_size` on the arc
of radius `size`, centered at parameter `at` of it. With `arcs = n > 0` the
result also has `n` concentric arcs (radii `size`, `size + gap`, ...) and
the symbols are centered across them, at the middle radius, and made at
least as long as the arcs are spread out plus one `gap`, so that a `:tick`
crosses every arc.
Throws an `ArgumentError` if a ray has zero length or `arcs < 0`.
"""
function marks(ang::APAngle2; count::Integer=1, style::Symbol=:arcs, at::Real=0.5,
    size::Union{Nothing,Real}=nothing, gap::Real=4.0, mark_size::Real=6.0, slant::Real=pi / 6, arcs::Integer=0)
    arcs >= 0 || throw(ArgumentError("marks: arcs must not be negative"))
    count >= 1 || throw(ArgumentError("marks: count must be at least 1"))
    va, vb = ang.a - ang.vertex, ang.b - ang.vertex
    (norm(va) > 0 && norm(vb) > 0) || throw(ArgumentError("marks: the angle has a ray of zero length"))
    r = size === nothing ? 0.15 * min(norm(va), norm(vb)) : size
    r > 0 || throw(ArgumentError("marks: size must be positive"))
    arc_at(radius) = APCircularArc2(ang.vertex, radius, ang.vertex + va, ang.vertex + vb)
    style === :arcs && return [arc_at(r + (i - 1) * gap) for i in 1:count]
    if style === :parallelogram
        ua, ub = va / norm(va), vb / norm(vb)
        poly_at(radius) = (pa = ang.vertex + radius * ua; pb = ang.vertex + radius * ub; APPolyline2(pa, pa + (pb - ang.vertex), pb))
        return [poly_at(r + (i - 1) * gap) for i in 1:count]
    end
    arcs == 0 && return _marks_at(tangent_at(arc_at(r), at), count, style, mark_size, gap, slant)
    span = (arcs - 1) * gap
    symbols = _marks_at(tangent_at(arc_at(r + span / 2), at), count, style, max(mark_size, span + gap), gap, slant)
    return identity.(vcat(APObject[arc_at(r + (i - 1) * gap) for i in 1:arcs], symbols))
end
"""
    arrow_head(obj; at=0.5, size=10.0, angle=π/8, place=:center, style=:triangle)

An arrowhead on `obj`, to draw with `path`: at parameter `at` of `obj` (see
[`tangent_at`](@ref)), pointing in the direction of travel. `size` is the
length of each side arm and `angle` the half-opening angle, the same
meaning as Luxor's `arrowheadlength` and `arrowheadangle`. With
`place = :center` (the default) the head is centered on the point, which is
what a mid-arrow on a segment or an arc wants; with `place = :tip` its tip
is on the point, which is what an arrow at the end of an arc wants
(`at = 1.0`). Defined for an [`APSegment`](@ref), an [`APLine`](@ref), an
[`APRay`](@ref) and the four conic arcs; `size` is in the units of the
coordinates of `obj`, as for [`marks`](@ref).

| Keyword | Default | Meaning |
|:--------|:--------|:--------|
| `at` | `0.5` | where along `obj`, in `[0, 1]` |
| `size` | `10.0` | length of each side arm |
| `angle` | `π/8` | half the opening angle, in `(0, π/2)` |
| `place` | `:center` | `:center` puts the middle of the head on the point, `:tip` its tip |
| `style` | `:triangle` | shape of the head, see below |

`style` picks the shape:

| `style` | Head | Returns | Draw with |
|:--------|:-----|:--------|:----------|
| `:triangle` | a filled triangle | [`APTriangle`](@ref) | `action=:fill` |
| `:stealth` | a triangle with a notch in its back | [`APStraightNgon`](@ref) | `action=:fill` |
| `:open` | two arms (a `>`) | [`APPolyline2`](@ref) | `action=:stroke` |

Throws an `ArgumentError` for `size <= 0`, an `angle` outside `(0, π/2)` or
an unknown `place` or `style`.
"""
function arrow_head(obj::Union{APSegment,APLine,APRay,APCircularArc2,APEllipticArc2,APParabolicArc2,APHyperbolicArc2};
    at::Real=0.5, size::Real=10.0, angle::Real=pi / 8, place::Symbol=:center, style::Symbol=:triangle)
    size > 0 || throw(ArgumentError("arrow_head: size must be positive"))
    style in (:triangle, :stealth, :open) ||
        throw(ArgumentError("arrow_head: style must be :triangle, :stealth or :open, got $(repr(style))"))
    0 < angle < pi / 2 || throw(ArgumentError("arrow_head: angle must be in (0, π/2)"))
    place in (:center, :tip) || throw(ArgumentError("arrow_head: place must be :center or :tip, got $(repr(place))"))
    frame = tangent_at(obj, at)
    P, T = frame.point, frame.vector
    N = orthogonal(T)
    h, w = size * cos(angle), size * sin(angle)
    tip = place === :tip ? P : P + (h / 2) * T
    base = tip - h * T
    style === :triangle && return APTriangle(tip, base + w * N, base - w * N)
    style === :stealth && return APStraightNgon(tip, base + w * N, tip - 0.65h * T, base - w * N)
    return APPolyline2(base + w * N, tip, base - w * N)
end
function _brace_frame(p1::APPoint, p2::APPoint, height, side::Symbol)
    side in (:left, :right) || throw(ArgumentError("brace: side must be :left or :right, got $(repr(side))"))
    L = distance(p1, p2)
    L > 0 || throw(ArgumentError("brace: p1 and p2 must differ"))
    h = height === nothing ? min(10.0, L / 2) : height
    h > 0 || throw(ArgumentError("brace: height must be positive"))
    r = h / 2
    4r <= L * (1 + 1e-12) || throw(ArgumentError("brace: height must be at most half the distance between p1 and p2"))
    ex = (p2 - p1) / L
    n = orthogonal(ex)
    return L, r, ex, side === :left ? -n : n
end
"""
    brace(p1::APPoint, p2::APPoint; height=nothing, side=:left)

A curly brace along `[p1, p2]`, the mark that says "this whole length is
so much", as a `Vector` of quarter [`APCircularArc2`](@ref)s and straight
[`APSegment`](@ref)s to draw with `path(brace(...); action=:stroke)`. The
brace is `height` deep (default `10` or half the length if that is smaller),
its two ends touching `p1` and `p2` and its point in the middle, on `side`
(`:left` or `:right` of `p1 -> p2` as seen on screen: call it on the
objects as they will be drawn, like [`label_anchor`](@ref)). `height` must be
at most half of `distance(p1, p2)`. Every piece keeps its own natural
orientation, so they are separate pieces rather than one chained curve.

| Keyword | Default | Meaning |
|:--------|:--------|:--------|
| `height` | `min(10.0, L/2)` | depth of the brace, at most half of `L = distance(p1, p2)` |
| `side` | `:left` | `:left` or `:right` of `p1 -> p2` as drawn |
"""
function brace(p1::APPoint, p2::APPoint; height::Union{Nothing,Real}=nothing, side::Symbol=:left)
    L, r, ex, ey = _brace_frame(p1, p2, height, side)
    G(x, y) = p1 + x * ex + y * ey
    function quarter(cx, cy, xa, ya, xb, yb)
        c, pa, pb = G(cx, cy), G(xa, ya), G(xb, yb)
        return APCircularArc2(c, r, pa, pb; ccw=cross2(pa - c, pb - c) > 0)
    end
    m = L / 2
    out = APObject[quarter(r, 0, 0, 0, r, r)]
    m - 2r > 1e-12 * L && push!(out, APSegment(G(r, r), G(m - r, r)))
    push!(out, quarter(m - r, 2r, m - r, r, m, 2r))
    push!(out, quarter(m + r, 2r, m, 2r, m + r, r))
    m - 2r > 1e-12 * L && push!(out, APSegment(G(m + r, r), G(L - r, r)))
    push!(out, quarter(L - r, 0, L - r, r, L, 0))
    return identity.(out)
end
"""
    coordinate_guides(p::APPoint; origin=APPoint(0.0, 0.0))

The two guide segments that show the coordinates of `p`: the one from `p`
straight to the x axis (the line `y = origin[2]`) and the one from `p`
straight to the y axis (`x = origin[1]`), as a `Vector` of
[`APSegment`](@ref)s, ready for `path`; draw them dashed
(`setdash("dot")` in Luxor) for the usual look. A guide of length zero (a
point on an axis) is left out, so the vector has two, one or no segments.

| Keyword | Default | Meaning |
|:--------|:--------|:--------|
| `origin` | `APPoint(0.0, 0.0)` | the point where the two axes cross |
"""
function coordinate_guides(p::APPoint; origin::APPoint=APPoint(0.0, 0.0))
    px, py, ox, oy = Float64.((p[1], p[2], origin[1], origin[2]))
    out = APSegment{2,Float64}[]
    py != oy && push!(out, APSegment(APPoint(px, py), APPoint(px, oy)))
    px != ox && push!(out, APSegment(APPoint(px, py), APPoint(ox, py)))
    return out
end
