# Phase 2: region vs APCircle2/APEllipse2/arcs, described as a base curve
# plus an angular range (start, sweep in (0, 2π]) in its own parameter.

_closed_param_point(c::APCircle2, θ::Real) = c.center + c.r * APVector(cos(θ), sin(θ))
_closed_param_point(e::APEllipse2, θ::Real) = point_on(e, θ)
_closed_param_of(c::APCircle2, p::APPoint) = atan(p[2] - c.center[2], p[1] - c.center[1])
_closed_param_of(e::APEllipse2, p::APPoint) = _ellipse_param(e, p)

_closed_curve_and_range(c::APCircle2) = (c, 0.0, 2π)
_closed_curve_and_range(e::APEllipse2) = (e, 0.0, 2π)
_closed_curve_and_range(a::APCircularArc2) = (a.circle, _arc_angle(a, a.p1), measure(a))
_closed_curve_and_range(a::APEllipticArc2) = (a.ellipse, _ellipse_param(a, a.p1), measure(a))

_make_closed_arc(c::APCircle2, θ1::Real, θ2::Real) = APCircularArc2(c, _closed_param_point(c, θ1), _closed_param_point(c, θ2))
_make_closed_arc(e::APEllipse2, θ1::Real, θ2::Real) = APEllipticArc2(e, _closed_param_point(e, θ1), _closed_param_point(e, θ2))

function _closed_object_from_range(curve::Union{APCircle2,APEllipse2}, θ::Real, sweep::Real; atol=1e-9)
    sweep <= atol && return _closed_param_point(curve, θ)
    sweep >= 2π - atol && return curve
    return _make_closed_arc(curve, θ, θ + sweep)
end
function _closed_object_from_range(arc::Union{APCircularArc2,APEllipticArc2}, θ::Real, sweep::Real; atol=1e-9)
    sweep <= atol && return _closed_param_point(_closed_curve_and_range(arc)[1], θ)
    sweep >= _closed_curve_and_range(arc)[3] - atol && return arc
    curve = _closed_curve_and_range(arc)[1]
    return _make_closed_arc(curve, θ, θ + sweep)
end

function _clip_range_to_halfplane(curve, θ::Real, sweep::Real, hp::APHalfPlane2; atol=1e-9)
    pts = intersection(hp.boundary, curve)
    scale = atol * max(1.0, norm(_closed_param_point(curve, θ) - hp.boundary.p1))
    if isempty(pts)
        sample = _closed_param_point(curve, θ + sweep / 2)
        return sample in hp ? (θ, sweep) : nothing
    elseif length(pts) == 1
        p = only(pts)
        φ = mod(_closed_param_of(curve, p) - θ, 2π)
        φ > sweep + scale && return nothing   # the tangency isn't even within this range
        sample = _closed_param_point(curve, θ + mod(φ + 0.1 * sweep, sweep))
        sample in hp && return (θ, sweep)   # tangent from the inside: nothing lost
        return (θ + φ, 0.0)   # tangent from the outside: only that single point survives
    else
        pa, pb = pts
        φa = mod(_closed_param_of(curve, pa) - θ, 2π)
        φb = mod(_closed_param_of(curve, pb) - θ, 2π)
        φa > φb && ((φa, φb) = (φb, φa))
        # 3 candidate pieces of [0, sweep] cut by φa, φb (whichever fall inside it)
        cuts = sort(filter(x -> 0 <= x <= sweep, [0.0, φa, φb, sweep]))
        pieces = Tuple{Float64,Float64}[]
        for i in 1:length(cuts)-1
            lo, hi = cuts[i], cuts[i+1]
            hi - lo <= scale && continue
            mid = (lo + hi) / 2
            (_closed_param_point(curve, θ + mid) in hp) && push!(pieces, (lo, hi))
        end
        isempty(pieces) && return nothing
        # a full period wraps: start and end are the same point
        if sweep >= 2π - scale && length(pieces) > 1 && pieces[1][1] <= scale && pieces[end][2] >= sweep - scale
            hi1 = pieces[1][2]
            lo2 = pieces[end][1]
            pieces = [(lo2, hi1 + sweep); pieces[2:end-1]]
        end
        merged_lo, merged_hi = pieces[1]
        result = Tuple{Float64,Float64}[]
        for (lo, hi) in pieces[2:end]
            if lo - merged_hi <= scale
                merged_hi = hi
            else
                push!(result, (merged_lo, merged_hi))
                merged_lo, merged_hi = lo, hi
            end
        end
        push!(result, (merged_lo, merged_hi))
        length(result) == 1 && return (mod(θ + result[1][1], 2π), result[1][2] - result[1][1])
        return [(mod(θ + lo, 2π), hi - lo) for (lo, hi) in result]
    end
end

# union of two (θ, sweep) ranges (or nothing): 1 piece if they touch/overlap
# (possibly wrapping into a full circle), else both
function _or_ranges(a, b)
    a === nothing && return b === nothing ? Tuple{Float64,Float64}[] : [b]
    b === nothing && return [a]
    θa, sa = a
    θb, sb = b
    sa >= 2π - 1e-9 && return [(θa, 2π)]
    sb >= 2π - 1e-9 && return [(θb, 2π)]
    b0 = mod(θb - θa, 2π)
    bend = b0 + sb
    if b0 <= sa + 1e-9
        newhi = max(sa, bend)
        newhi >= 2π - 1e-9 && return [(θa, 2π)]
        return [(θa, newhi)]
    elseif bend >= 2π - 1e-9
        return [(θa, 2π)]
    else
        return [a, b]
    end
end

function _merge_all_ranges(ranges::Vector{Tuple{Float64,Float64}})
    rs = copy(ranges)
    changed = true
    while changed
        changed = false
        for i in eachindex(rs), j in eachindex(rs)
            i == j && continue
            merged = _or_ranges(rs[i], rs[j])
            length(merged) == 1 || continue
            rs = [merged[1]; [rs[k] for k in eachindex(rs) if k != i && k != j]]
            changed = true
            break
        end
    end
    return rs
end

const _ClosedCurve2 = Union{APCircle2,APEllipse2,APCircularArc2,APEllipticArc2}

function _region_clip_closed(hp::APHalfPlane2, curve::_ClosedCurve2; atol=1e-9)
    base, θ, sweep = _closed_curve_and_range(curve)
    r = _clip_range_to_halfplane(base, θ, sweep, hp; atol=atol)
    r === nothing && return nothing
    r isa Vector && return [_closed_object_from_range(curve, p...; atol=atol) for p in r]
    return _closed_object_from_range(curve, r...; atol=atol)
end

function _region_clip_closed(s::APStrip2, curve::_ClosedCurve2; atol=1e-9)
    base, θ, sweep = _closed_curve_and_range(curve)
    hp1 = APHalfPlane2(s.line1, side_of_line(s.line2.p1, s.line1))
    hp2 = APHalfPlane2(s.line2, side_of_line(s.line1.p1, s.line2))
    r1 = _clip_range_to_halfplane(base, θ, sweep, hp1; atol=atol)
    r1 === nothing && return APObject[]
    r1_pieces = r1 isa Vector ? r1 : [r1]
    pieces = Tuple{Float64,Float64}[]
    for (θ1, s1) in r1_pieces
        r2 = _clip_range_to_halfplane(base, θ1, s1, hp2; atol=atol)
        r2 === nothing && continue
        append!(pieces, r2 isa Vector ? r2 : [r2])
    end
    return [_closed_object_from_range(curve, p...; atol=atol) for p in pieces]
end

function _region_clip_closed(ang::APAngle2, curve::_ClosedCurve2; atol=1e-9)
    base, θ, sweep = _closed_curve_and_range(curve)
    hp_a = _hp_for_ray(ang.vertex, ang.a, ang.b)
    hp_b = _hp_for_ray(ang.vertex, ang.b, ang.a)
    pieces = if normalized_measure(ang) <= pi + atol
        r1 = _clip_range_to_halfplane(base, θ, sweep, hp_a; atol=atol)
        if r1 === nothing
            Tuple{Float64,Float64}[]
        else
            r1_pieces = r1 isa Vector ? r1 : [r1]
            out = Tuple{Float64,Float64}[]
            for (θ1, s1) in r1_pieces
                r2 = _clip_range_to_halfplane(base, θ1, s1, hp_b; atol=atol)
                r2 === nothing && continue
                append!(out, r2 isa Vector ? r2 : [r2])
            end
            out
        end
    else
        flip_a = APHalfPlane2(hp_a.boundary, -hp_a.side)
        flip_b = APHalfPlane2(hp_b.boundary, -hp_b.side)
        r1 = _clip_range_to_halfplane(base, θ, sweep, flip_a; atol=atol)
        r2 = _clip_range_to_halfplane(base, θ, sweep, flip_b; atol=atol)
        all_pieces = Tuple{Float64,Float64}[]
        r1 !== nothing && append!(all_pieces, r1 isa Vector ? r1 : [r1])
        r2 !== nothing && append!(all_pieces, r2 isa Vector ? r2 : [r2])
        _merge_all_ranges(all_pieces)
    end
    return [_closed_object_from_range(curve, p...; atol=atol) for p in pieces]
end

"""
    intersection(hp::APHalfPlane2, curve::Union{APCircle2,APEllipse2,APCircularArc2,APEllipticArc2}; atol=1e-9)

The part of `curve` that lies inside `hp`, in `curve`'s own type, not the
points where `hp`'s boundary crosses it (see [Unbounded Regions: Half-Planes,
Strips & Angles](@ref)). A circle/ellipse crossed by the boundary comes back
as an arc; one already fully inside comes back unchanged; one fully outside,
or tangent to the boundary from the outside, comes back as `nothing` or as
the single touch point, respectively. Both argument orders work.
"""
intersection(hp::APHalfPlane2, curve::_ClosedCurve2; atol=1e-9) = _region_clip_closed(hp, curve; atol=atol)
intersection(curve::_ClosedCurve2, hp::APHalfPlane2; atol=1e-9) = intersection(hp, curve; atol=atol)

"""
    intersection(s::APStrip2, curve::Union{APCircle2,APEllipse2,APCircularArc2,APEllipticArc2}; atol=1e-9)

The part of `curve` that lies inside `s`, in `curve`'s own type. Unlike a
line/segment/ray (always a single piece against a strip, see
[Unbounded Regions: Half-Planes, Strips & Angles](@ref)), a closed curve can
cross each of the strip's two boundary lines twice, so the result is always a
`Vector` and can hold two disjoint arcs (one where the curve pokes out on
each side). Both argument orders work.
"""
intersection(s::APStrip2, curve::_ClosedCurve2; atol=1e-9) = _region_clip_closed(s, curve; atol=atol)
intersection(curve::_ClosedCurve2, s::APStrip2; atol=1e-9) = intersection(s, curve; atol=atol)

"""
    intersection(ang::APAngle2, curve::Union{APCircle2,APEllipse2,APCircularArc2,APEllipticArc2}; atol=1e-9)

The part of `curve` that lies inside `ang`, in `curve`'s own type (see
[Points, Lines & Rays: Angles](@ref) for the same idea against a line,
segment or ray). The result is always a `Vector`: a convex `ang`
(`normalized_measure(ang) <= π`) never gives more than one piece, but a
**reflex** one can give two, the same way it can for a straight object. Both
argument orders work.
"""
intersection(ang::APAngle2, curve::_ClosedCurve2; atol=1e-9) = _region_clip_closed(ang, curve; atol=atol)
intersection(curve::_ClosedCurve2, ang::APAngle2; atol=1e-9) = intersection(ang, curve; atol=atol)
