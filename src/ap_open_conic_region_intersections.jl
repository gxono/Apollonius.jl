# Phase 2b: region vs APParabola2/APHyperbola2/APParabolicArc2/APHyperbolicArc2.
# Full design in scratch/TODO.md. Always returns a Vector: even a single
# halfplane can split an open curve into two disjoint surviving pieces.

_open_point(par::APParabola2, ::Int, s::Real) = point_on(par, s)
_open_point(h::APHyperbola2, branch::Int, t::Real) = point_on(h, t; branch=branch)
_open_param(par::APParabola2, ::Int, p::APPoint) = _parabola_param(par, p)
_open_param(h::APHyperbola2, ::Int, p::APPoint) = _hyperbola_param(h, p)[1]
_open_crossings(par::APParabola2, ::Int, l::APLine) = intersection(l, par)
_open_crossings(h::APHyperbola2, branch::Int, l::APLine) = filter(p -> _hyperbola_param(h, p)[2] == branch, intersection(l, h))

# (base curve, branch, lo, hi) for one branch of `curve`; `branch` is ignored
# for parabola-family curves (always 0).
_open_range_for_branch(par::APParabola2, ::Int) = (par, 0, -Inf, Inf)
_open_range_for_branch(h::APHyperbola2, branch::Int) = (h, branch, -Inf, Inf)
function _open_range_for_branch(arc::APParabolicArc2, ::Int)
    lo, hi = minmax(_parabola_param(arc.parabola, arc.p1), _parabola_param(arc.parabola, arc.p2))
    return (arc.parabola, 0, lo, hi)
end
function _open_range_for_branch(arc::APHyperbolicArc2, branch::Int)
    lo, hi = minmax(_hyperbola_param(arc.hyperbola, arc.p1)[1], _hyperbola_param(arc.hyperbola, arc.p2)[1])
    return (arc.hyperbola, branch, lo, hi)
end

function _open_object_from_range(par::APParabola2, ::Int, lo::Real, hi::Real)
    lo == hi && return point_on(par, lo)
    isfinite(lo) && isfinite(hi) && return APParabolicArc2(par, point_on(par, lo), point_on(par, hi))
    isfinite(lo) && return APParabolicRay2(par, point_on(par, lo), 1)
    isfinite(hi) && return APParabolicRay2(par, point_on(par, hi), -1)
    return par
end
function _open_object_from_range(h::APHyperbola2, branch::Int, lo::Real, hi::Real)
    lo == hi && return point_on(h, lo; branch=branch)
    isfinite(lo) && isfinite(hi) && return APHyperbolicArc2(h, point_on(h, lo; branch=branch), point_on(h, hi; branch=branch))
    isfinite(lo) && return APHyperbolicRay2(h, point_on(h, lo; branch=branch), branch, 1)
    isfinite(hi) && return APHyperbolicRay2(h, point_on(h, hi; branch=branch), branch, -1)
    return APHyperbolaBranch2(h, branch)
end

# Clips (lo,hi) of curve's own open (non-periodic) parameter to hp's side.
# Returns a Vector of surviving (lo',hi') ranges (possibly empty).
function _clip_open_range_to_halfplane(curve, branch::Int, lo::Real, hi::Real, hp::APHalfPlane2; atol=1e-9)
    sample_in(s) = _open_point(curve, branch, s) in hp
    ref = isfinite(lo) ? lo : (isfinite(hi) ? hi : 0.0)
    scale = atol * max(abs(ref), 1.0)

    pts = _open_crossings(curve, branch, hp.boundary)
    cuts = sort(unique(round.(_open_param.(Ref(curve), Ref(branch), pts); digits=9)))
    cuts = filter(s -> lo - scale <= s <= hi + scale, cuts)

    if isempty(cuts)
        mid = isfinite(lo) && isfinite(hi) ? (lo + hi) / 2 :
              isfinite(lo) ? lo + max(1.0, abs(lo)) :
              isfinite(hi) ? hi - max(1.0, abs(hi)) : 0.0
        return sample_in(mid) ? [(lo, hi)] : Tuple{Float64,Float64}[]
    end

    step(s0) = max(scale, 1e-6 * max(abs(s0), 1.0))
    if length(cuts) == 1
        s0 = cuts[1]
        d = step(s0)
        left_in, right_in = sample_in(s0 - d), sample_in(s0 + d)
        if left_in == right_in
            left_in && return [(lo, hi)]
            return (lo - scale <= s0 <= hi + scale) ? [(s0, s0)] : Tuple{Float64,Float64}[]
        end
        pieces = Tuple{Float64,Float64}[]
        left_in && s0 - lo > scale && push!(pieces, (lo, s0))
        right_in && hi - s0 > scale && push!(pieces, (s0, hi))
        return pieces
    end
    # 2 crossings: at most one line can meet an open conic branch twice
    s0, s1 = cuts[1], cuts[2]
    pieces = Tuple{Float64,Float64}[]
    sample_in(s0 - step(s0)) && s0 - lo > scale && push!(pieces, (lo, s0))
    sample_in((s0 + s1) / 2) && s1 - s0 > scale && push!(pieces, (s0, s1))
    sample_in(s1 + step(s1)) && hi - s1 > scale && push!(pieces, (s1, hi))
    return pieces
end

# Merge overlapping/touching ranges (needed only when OR-ing a reflex angle's
# two flipped halfplane results; no wraparound to worry about, unlike Phase 2).
function _merge_open_ranges(ranges::Vector{Tuple{Float64,Float64}}; atol=1e-9)
    isempty(ranges) && return ranges
    sorted = sort(ranges; by=first)
    result = [sorted[1]]
    for (lo, hi) in sorted[2:end]
        plo, phi = result[end]
        if lo <= phi + atol * max(abs(phi), 1.0)
            result[end] = (plo, max(phi, hi))
        else
            push!(result, (lo, hi))
        end
    end
    return result
end

const _OpenConic2 = Union{APParabola2,APHyperbola2,APParabolicArc2,APHyperbolicArc2}
_branches(::APParabola2) = (0,)
_branches(::APParabolicArc2) = (0,)
_branches(::APHyperbola2) = (1, -1)
_branches(arc::APHyperbolicArc2) = (_hyperbola_param(arc.hyperbola, arc.p1)[2],)

function _region_clip_open(hp::APHalfPlane2, curve::_OpenConic2; atol=1e-9)
    pieces = Any[]
    for branch in _branches(curve)
        base, b, lo, hi = _open_range_for_branch(curve, branch)
        for r in _clip_open_range_to_halfplane(base, b, lo, hi, hp; atol=atol)
            push!(pieces, _open_object_from_range(base, b, r...))
        end
    end
    return pieces
end

function _region_clip_open(s::APStrip2, curve::_OpenConic2; atol=1e-9)
    hp1 = APHalfPlane2(s.line1, side_of_line(s.line2.p1, s.line1))
    hp2 = APHalfPlane2(s.line2, side_of_line(s.line1.p1, s.line2))
    pieces = Any[]
    for branch in _branches(curve)
        base, b, lo, hi = _open_range_for_branch(curve, branch)
        for r1 in _clip_open_range_to_halfplane(base, b, lo, hi, hp1; atol=atol)
            for r2 in _clip_open_range_to_halfplane(base, b, r1..., hp2; atol=atol)
                push!(pieces, _open_object_from_range(base, b, r2...))
            end
        end
    end
    return pieces
end

function _region_clip_open(ang::APAngle2, curve::_OpenConic2; atol=1e-9)
    hp_a = _hp_for_ray(ang.vertex, ang.a, ang.b)
    hp_b = _hp_for_ray(ang.vertex, ang.b, ang.a)
    pieces = Any[]
    for branch in _branches(curve)
        base, b, lo, hi = _open_range_for_branch(curve, branch)
        ranges = if normalized_measure(ang) <= pi + atol
            out = Tuple{Float64,Float64}[]
            for r1 in _clip_open_range_to_halfplane(base, b, lo, hi, hp_a; atol=atol)
                append!(out, _clip_open_range_to_halfplane(base, b, r1..., hp_b; atol=atol))
            end
            out
        else
            flip_a = APHalfPlane2(hp_a.boundary, -hp_a.side)
            flip_b = APHalfPlane2(hp_b.boundary, -hp_b.side)
            all_ranges = Tuple{Float64,Float64}[]
            append!(all_ranges, _clip_open_range_to_halfplane(base, b, lo, hi, flip_a; atol=atol))
            append!(all_ranges, _clip_open_range_to_halfplane(base, b, lo, hi, flip_b; atol=atol))
            _merge_open_ranges(all_ranges; atol=atol)
        end
        for r in ranges
            push!(pieces, _open_object_from_range(base, b, r...))
        end
    end
    return pieces
end

"""
    intersection(hp::APHalfPlane2, curve::Union{APParabola2,APHyperbola2,APParabolicArc2,APHyperbolicArc2}; atol=1e-9)
    intersection(s::APStrip2, curve::...; atol=1e-9)
    intersection(ang::APAngle2, curve::...; atol=1e-9)

The part(s) of `curve` that lie inside the region, in `curve`'s own type
family (see [Unbounded Regions: Half-Planes, Strips & Angles](@ref)):
always a `Vector`, since even a single halfplane can split an open curve
into two disjoint surviving pieces (unlike a circle/ellipse). Elements are
whichever of [`APParabolicArc2`](@ref)/[`APHyperbolicArc2`](@ref) (bounded),
[`APParabolicRay2`](@ref)/[`APHyperbolicRay2`](@ref) (one end still
infinite), the whole curve (or [`APHyperbolaBranch2`](@ref) for one whole
branch of a hyperbola), or an [`APPoint`](@ref) fits. Both argument orders
work.
"""
intersection(hp::APHalfPlane2, curve::_OpenConic2; atol=1e-9) = _region_clip_open(hp, curve; atol=atol)
intersection(curve::_OpenConic2, hp::APHalfPlane2; atol=1e-9) = intersection(hp, curve; atol=atol)
intersection(s::APStrip2, curve::_OpenConic2; atol=1e-9) = _region_clip_open(s, curve; atol=atol)
intersection(curve::_OpenConic2, s::APStrip2; atol=1e-9) = intersection(s, curve; atol=atol)
intersection(ang::APAngle2, curve::_OpenConic2; atol=1e-9) = _region_clip_open(ang, curve; atol=atol)
intersection(curve::_OpenConic2, ang::APAngle2; atol=1e-9) = intersection(ang, curve; atol=atol)
