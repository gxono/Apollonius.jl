"""
    APDecoration{Dim,T}

The parent of [`APDecorationBrace2`](@ref) and any future decoration type: a
`path`-drawable recipe for a figure annotation, not a geometric object in
its own right (it has no `in`, doesn't take part in `intersection`), which
is why `APDecoration` sits outside the [`APObject`](@ref) tree entirely,
the same way [`APTransform`](@ref) does.
"""
abstract type APDecoration{Dim,T} end

"""
    APDecorationBrace2(p1::APPoint, p2::APPoint; height=nothing, pos=0.5, side=:left)

A curly brace along `[p1, p2]`, the mark that says "this whole length is so
much". `height` is how deep the brace is (default `10`, or half the length
if that is smaller, and at most half the length always). `side` (`:left` or
`:right` of `p1 -> p2` as seen on screen, like [`label_anchor`](@ref)) picks
which way it opens. `pos` (default `0.5`, the middle) moves the tip along
`[p1, p2]`: at `pos = 0` the tip sits `height/2` past `p1` (not on `p1`
itself, there's no room for its corner arc any closer), at `pos = 1`
symmetrically near `p2`.

[`path`](@ref) draws it, [`vertices`](@ref) gives `(p1, tip, p2)` (the tip is
where a label goes), and [`direction`](@ref)/[`slope_angle`](@ref)/
[`distance`](@ref) all work on it directly, the same as on the segment
`[p1, p2]` it decorates.

| Keyword | Default | Meaning |
|:--------|:--------|:--------|
| `height` | `min(10.0, L/2)` | depth of the brace, at most half of `L = distance(p1, p2)` |
| `pos` | `0.5` | where the tip sits along `[p1, p2]`, in `[0, 1]` |
| `side` | `:left` | `:left` or `:right` of `p1 -> p2` as drawn |
"""
struct APDecorationBrace2{T<:Real} <: APDecoration{2,T}
    p1::APPoint{2,T}
    p2::APPoint{2,T}
    arc_radius::T
    pos::T
    side::Symbol
    function APDecorationBrace2{T}(p1::APPoint{2,T}, p2::APPoint{2,T}, arc_radius::T, pos::T, side::Symbol) where {T<:Real}
        side in (:left, :right) || throw(ArgumentError("APDecorationBrace2: side must be :left or :right, got $(repr(side))"))
        0 <= pos <= 1 || throw(ArgumentError("APDecorationBrace2: pos must be in [0, 1], got $pos"))
        L = distance(p1, p2)
        L > 0 || throw(ArgumentError("APDecorationBrace2: p1 and p2 must differ"))
        arc_radius > 0 || throw(ArgumentError("APDecorationBrace2: arc_radius must be positive"))
        4 * arc_radius <= L * (1 + 1e-12) || throw(ArgumentError("APDecorationBrace2: arc_radius must be at most a quarter of the distance between p1 and p2"))
        return new{T}(p1, p2, arc_radius, pos, side)
    end
end
function APDecorationBrace2(p1::APPoint{2}, p2::APPoint{2}, arc_radius::Real, pos::Real, side::Symbol)
    T = promote_type(eltype(p1), eltype(p2), typeof(float(arc_radius)), typeof(float(pos)))
    return APDecorationBrace2{T}(convert(APPoint{2,T}, p1), convert(APPoint{2,T}, p2), T(arc_radius), T(pos), side)
end
function APDecorationBrace2(p1::APPoint{2}, p2::APPoint{2}; height::Union{Nothing,Real}=nothing, pos::Real=0.5, side::Symbol=:left)
    L = distance(p1, p2)
    h = height === nothing ? min(10.0, L / 2) : height
    h > 0 || throw(ArgumentError("APDecorationBrace2: height must be positive"))
    return APDecorationBrace2(p1, p2, h / 2, pos, side)
end
Base.:(==)(x::APDecorationBrace2, y::APDecorationBrace2) =
    x.p1 == y.p1 && x.p2 == y.p2 && x.arc_radius == y.arc_radius && x.pos == y.pos && x.side == y.side
Base.hash(x::APDecorationBrace2, h::UInt) = hash((x.p1, x.p2, x.arc_radius, x.pos, x.side), hash(:APDecorationBrace2, h))
Base.isapprox(x::APDecorationBrace2, y::APDecorationBrace2; kwargs...) =
    isapprox(x.p1, y.p1; kwargs...) && isapprox(x.p2, y.p2; kwargs...) &&
    isapprox(x.arc_radius, y.arc_radius; kwargs...) && isapprox(x.pos, y.pos; kwargs...) && x.side == y.side
Base.show(io::IO, dec::APDecorationBrace2) =
    print(io, "APDecorationBrace2(", dec.p1, ", ", dec.p2, ", arc_radius=", dec.arc_radius, ", pos=", dec.pos, ", side=", dec.side, ")")

function _brace_frame(dec::APDecorationBrace2)
    L = distance(dec.p1, dec.p2)
    ex = (dec.p2 - dec.p1) / L
    n = orthogonal(ex)
    return L, dec.arc_radius, ex, dec.side === :left ? -n : n
end

"""
    vertices(dec::APDecorationBrace2)

`dec`'s two braced points and its tip, as `(p1, tip, p2)`.
"""
function vertices(dec::APDecorationBrace2)
    L, r, ex, ey = _brace_frame(dec)
    tip_x = r + dec.pos * (L - 2r)
    tip = dec.p1 + tip_x * ex + 2r * ey
    return (dec.p1, tip, dec.p2)
end
direction(dec::APDecorationBrace2) = dec.p2 - dec.p1
distance(dec::APDecorationBrace2) = distance(dec.p1, dec.p2)

function _brace_pieces(dec::APDecorationBrace2)
    L, r, ex, ey = _brace_frame(dec)
    tip_x = r + dec.pos * (L - 2r)
    G(x, y) = dec.p1 + x * ex + y * ey
    function quarter(cx, cy, xa, ya, xb, yb)
        c, pa, pb = G(cx, cy), G(xa, ya), G(xb, yb)
        return APCircularArc2(c, r, pa, pb; ccw=cross2(pa - c, pb - c) > 0)
    end
    out = APObject[quarter(r, 0, 0, 0, r, r)]
    tip_x - 2r > 1e-12 * L && push!(out, APSegment(G(r, r), G(tip_x - r, r)))
    push!(out, quarter(tip_x - r, 2r, tip_x - r, r, tip_x, 2r))
    push!(out, quarter(tip_x + r, 2r, tip_x, 2r, tip_x + r, r))
    L - tip_x - 2r > 1e-12 * L && push!(out, APSegment(G(tip_x + r, r), G(L - r, r)))
    push!(out, quarter(L - r, 0, L - r, r, L, 0))
    return out
end
APBoundingBox(dec::APDecorationBrace2) = reduce(bbox_union, APBoundingBox.(_brace_pieces(dec)); init=APBoundingBox())

function _brace_walk(dec::APDecorationBrace2)
    atol = 1e-9 * max(1.0, dec.arc_radius, distance(dec.p1, dec.p2))
    current = dec.p1
    order = Tuple{APObject,Bool}[]
    for piece in _brace_pieces(dec)
        reversed = !isapprox(piece.p1, current; atol=atol)
        push!(order, (piece, reversed))
        current = reversed ? piece.p1 : piece.p2
    end
    return order
end

translate(dec::APDecorationBrace2, v::APVector) =
    APDecorationBrace2(translate(dec.p1, v), translate(dec.p2, v), dec.arc_radius, dec.pos, dec.side)
rotate(dec::APDecorationBrace2, angle::Real, center::APPoint=APPoint(0.0, 0.0)) =
    APDecorationBrace2(rotate(dec.p1, angle, center), rotate(dec.p2, angle, center), dec.arc_radius, dec.pos, dec.side)
homothety(dec::APDecorationBrace2, k::Real, center::APPoint=APPoint(0.0, 0.0)) =
    APDecorationBrace2(homothety(dec.p1, k, center), homothety(dec.p2, k, center), abs(k) * dec.arc_radius, dec.pos, dec.side)
reflection(dec::APDecorationBrace2, about::APPoint) =
    APDecorationBrace2(reflection(dec.p1, about), reflection(dec.p2, about), dec.arc_radius, dec.pos, dec.side)
reflection(dec::APDecorationBrace2, about::APLine) =
    APDecorationBrace2(reflection(dec.p1, about), reflection(dec.p2, about), dec.arc_radius, dec.pos, dec.side === :left ? :right : :left)
