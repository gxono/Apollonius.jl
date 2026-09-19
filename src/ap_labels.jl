const _COMPASS_ALIGNMENTS = (:E, :SE, :S, :SW, :W, :NW, :N, :NE)
function _compass_alignment(v::APVector)
    norm(v) > 0 || return :N
    k = mod(round(Int, atan(v[2], v[1]) / (pi / 4)), 8)
    return _COMPASS_ALIGNMENTS[k+1]
end
"""
    label_anchor(obj, t=0.5; side=:left)
    label_anchor(ang::APAngle2; dist=nothing)
    label_anchor(c::APCircle2, θ::Real)
    label_anchor(p::APPoint, from::APPoint)

Where to put a text label and how to align it, as a `NamedTuple`
`(alignment, point)` in the argument order of Luxor's `label`, so that
`label("a", label_anchor(s)...)` works (the `label` method for an
[`APPoint`](@ref) comes with the Luxor extension; Luxor's own `offset` then
sets the gap). `alignment` is one of Luxor's compass symbols (`:N`, `:NE`,
`:E`, ...), chosen so the text sits on the side of `point` away from the
object.

  - a segment or an arc (any curve [`tangent_at`](@ref) handles) at parameter
    `t`, on `side = :left` or `:right` of the direction of travel;
  - an [`APAngle2`](@ref): on its bisector, `dist` from the vertex (default
    `0.25` times the shorter ray, just past the default marks of
    [`marks`](@ref)), aligned away from the vertex;
  - a circle at the polar angle `θ`, aligned outward;
  - a point, away from the point `from` (the usual way to keep the label of a
    vertex outside the figure: pass the centroid as `from`).

Alignments are read in screen coordinates, the ones Luxor draws in (`y`
grows downward, so `:N` is up): call this on the objects as they will be
drawn, for example the ones [`@to_luxor_picture`](@ref) returns, and `:left`
is then the left of the direction of travel as seen on screen.
"""
function label_anchor(obj::Union{APSegment,APCircularArc2,APEllipticArc2,APParabolicArc2,APHyperbolicArc2}, t::Real=0.5;
    side::Symbol=:left)
    side in (:left, :right) || throw(ArgumentError("label_anchor: side must be :left or :right, got $(repr(side))"))
    frame = tangent_at(obj, t)
    n = orthogonal(frame.vector)
    return (alignment=_compass_alignment(side === :left ? -n : n), point=frame.point)
end
function label_anchor(ang::APAngle2; dist::Union{Nothing,Real}=nothing)
    va, vb = ang.a - ang.vertex, ang.b - ang.vertex
    (norm(va) > 0 && norm(vb) > 0) || throw(ArgumentError("label_anchor: the angle has a ray of zero length"))
    shorter = min(norm(va), norm(vb))
    mid = midpoint(APCircularArc2(ang.vertex, shorter, ang.vertex + va, ang.vertex + vb))
    u = normalize(mid - ang.vertex)   # the wedge's own middle, right even for a reflex angle
    d = dist === nothing ? 0.25 * shorter : dist
    return (alignment=_compass_alignment(u), point=ang.vertex + d * u)
end
function label_anchor(c::APCircle2, θ::Real)
    u = APVector(cos(θ), sin(θ))
    return (alignment=_compass_alignment(u), point=c.center + c.r * u)
end
label_anchor(p::APPoint, from::APPoint) = (alignment=_compass_alignment(p - from), point=p)
"""
    brace_anchor(p1::APPoint, p2::APPoint; height=nothing, side=:left)

Where to put the text of a [`brace`](@ref) with the same arguments: the
point of the brace (in the middle, `height` away from `[p1, p2]` on `side`),
with the alignment that puts the label beyond it, as a `NamedTuple`
`(alignment, point)` like [`label_anchor`](@ref), so that
`label("60", brace_anchor(p1, p2)...)` works. Same conventions as `brace`:
screen coordinates, and the same errors for a `height` that is too large.
"""
function brace_anchor(p1::APPoint, p2::APPoint; height::Union{Nothing,Real}=nothing, side::Symbol=:left)
    L, r, ex, ey = _brace_frame(p1, p2, height, side)
    return (alignment=_compass_alignment(ey), point=p1 + (L / 2) * ex + 2r * ey)
end
