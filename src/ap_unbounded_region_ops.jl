const _UnboundedRegion2 = Union{APHalfPlane2,APStrip2,APAngle2}

_complement_pieces(hp::APHalfPlane2) = [_flip(hp)]
_complement_pieces(s::APStrip2) = [_flip(h) for h in _halfplanes_of(s)]
_complement_pieces(ang::APAngle2) = [Base.reverse(ang)]

_as_pieces(::Nothing) = Any[]
_as_pieces(x::AbstractVector) = Any[x...]
_as_pieces(x) = Any[x]

function _region_difference_unbounded(a, b; atol::Real=1e-9)
    pieces = Any[]
    for c in _complement_pieces(b)
        append!(pieces, _as_pieces(intersection(a, c; atol=atol)))
    end
    return pieces
end

function _region_symdiff_unbounded(a, b; atol::Real=1e-9)
    return vcat(_region_difference_unbounded(a, b; atol=atol), _region_difference_unbounded(b, a; atol=atol))
end

_merge_crossing_halfplanes(a, b; atol::Real=1e-9) = nothing
function _merge_crossing_halfplanes(a::APHalfPlane2, b::APHalfPlane2; atol::Real=1e-9)
    d1, d2 = direction(a.boundary), direction(b.boundary)
    abs(cross2(d1, d2)) <= atol * norm(d1) * norm(d2) && return nothing
    inter = intersection(_flip(a), _flip(b); atol=atol)
    inter isa APAngle2 && return Base.reverse(inter)
    return nothing
end

function _region_union_unbounded(a, b; atol::Real=1e-9)
    a == b && return Any[a]
    merged = _merge_crossing_halfplanes(a, b; atol=atol)
    merged === nothing || return Any[merged]
    return Any[a, b]
end

"""
    region_union(a, b; atol=1e-9)

The union of two unbounded regions (`APHalfPlane2`/`APStrip2`/`APAngle2`),
as a `Vector`. Two half-planes with crossing (non-parallel) boundaries
merge into a single reflex `APAngle2` (the wedge, at the crossing point,
that is *outside* neither): every other combination that doesn't collapse
to one shape outright (`a` and `b` identical) comes back as `[a, b]`,
`a` and `b` unmerged. That `Vector` is still an exact answer, since a
`Vector` of pieces here means their union, the same as it does for
[`region_union`](@ref)'s bounded-region form; it just isn't always the
*simplest* one, since spotting that one region is a redundant subset of
the other (two parallel half-planes, or a strip inside a wider strip)
isn't attempted. Both argument orders work.
"""
function region_union(a::_UnboundedRegion2, b::_UnboundedRegion2; atol::Real=1e-9)
    return _region_union_unbounded(a, b; atol=atol)
end

"""
    region_difference(a, b; atol=1e-9)

The part of the unbounded region `a` (`APHalfPlane2`/`APStrip2`/`APAngle2`)
that lies outside `b`, as a `Vector` (0, 1, or 2 pieces: 2 exactly when
`b` is an `APStrip2` and `a` reaches across both sides of it). Built as
`a` intersected with `b`'s own complement (the region outside `b`, itself
already one of these three types, or the union of two half-planes for a
strip's complement), reusing [`intersection`](@ref) directly: no new
geometry beyond what already existed for `intersection` and
[`Base.reverse`](@ref)`(::APAngle2)`. Unlike [`region_union`](@ref), the
argument order matters here. Never raises an `ArgumentError`: every
combination in this family has a representable difference.
"""
function region_difference(a::_UnboundedRegion2, b::_UnboundedRegion2; atol::Real=1e-9)
    return _region_difference_unbounded(a, b; atol=atol)
end

"""
    region_symdiff(a, b; atol=1e-9)

The symmetric difference of two unbounded regions, `(a ∖ b) ∪ (b ∖ a)`, as
a `Vector` holding every surviving piece from both
[`region_difference`](@ref) calls (the two sides never overlap each
other, so nothing needs merging). Both argument orders give the same
pieces.
"""
function region_symdiff(a::_UnboundedRegion2, b::_UnboundedRegion2; atol::Real=1e-9)
    return _region_symdiff_unbounded(a, b; atol=atol)
end
