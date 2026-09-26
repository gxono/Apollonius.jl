function _assemble_run(run::Vector, whole, loop::Vector)
    length(run) == length(loop) && run == loop && return whole
    length(run) == 1 && return only(run)
    all(p -> p isa APSegment, run) && return APPolyline2([run[1].p1; [s.p2 for s in run]])
    return APCurvilinearPolyline2(run)
end

function _boundary_clip(a, region; atol::Real=1e-9)
    loop = _walked_pieces(a)
    runs = _clip_loop_to_region(loop, region; atol=atol)
    return [_assemble_run(run, a, loop) for run in runs]
end

_reverse_piece(s::APSegment) = APSegment(s.p2, s.p1)
_reverse_piece(arc::Union{APParabolicArc2,APHyperbolicArc2}) = Base.reverse(arc)
_reverse_piece(::Union{APCircularArc2,APEllipticArc2}) =
    throw(ArgumentError("intersection: mode=:region/:boundary needs to walk one of this shape's circular or elliptic arcs backward, which APCircularArc2/APEllipticArc2 (always a counterclockwise sweep) cannot represent; this happens for a concave, hole-like boundary such as APAnnularSector2's inner arc, and isn't supported yet"))

function _walked_pieces(pg)
    pg isa Union{APCircle2,APEllipse2} && return collect(_pieces(pg))
    return [reversed ? _reverse_piece(piece) : piece for (piece, reversed) in _polygon_walk(sides(pg))]
end
function _ccw_pieces(pg)
    pg isa Union{APCircle2,APEllipse2} && return collect(_pieces(pg))
    pcs = _walked_pieces(pg)
    signed_area(pg) >= 0 && return pcs
    return [_reverse_piece(p) for p in Base.reverse(pcs)]
end

function _stitch_closed_loops(fragments::Vector; atol::Real=1e-9)
    isempty(fragments) && return Vector{Any}[]
    scale = max(1.0, maximum(_side_scale, fragments))
    tol = sqrt(atol) * scale
    used = falses(length(fragments))
    loops = Vector{Any}[]
    for start_i in eachindex(fragments)
        used[start_i] && continue
        loop = Any[fragments[start_i]]
        used[start_i] = true
        start_pt = _side_p1(fragments[start_i])
        last_pt = _side_p2(fragments[start_i])
        while !isapprox(last_pt, start_pt; atol=tol)
            found = false
            for j in eachindex(fragments)
                used[j] && continue
                if isapprox(_side_p1(fragments[j]), last_pt; atol=tol)
                    push!(loop, fragments[j])
                    used[j] = true
                    last_pt = _side_p2(fragments[j])
                    found = true
                    break
                end
            end
            found || break
        end
        # a fragment left over from a merely-touching boundary (shared edge,
        # single tangent point) never finds its way back to start_pt; such an
        # unclosed "loop" is not a real overlap piece, so it is dropped here
        isapprox(last_pt, start_pt; atol=tol) && length(loop) >= 2 && push!(loops, loop)
    end
    return loops
end

function _classify_loop(loop::Vector)
    n = length(loop)
    if all(p -> p isa APSegment, loop)
        vs = [s.p1 for s in loop]
        n == 3 && return APTriangle(vs...)
        n == 4 && return APQuadrilateral(vs...)
        return APStraightNgon(vs)
    end
    n == 3 && return APCurvilinearTriangle2(loop...)
    n == 4 && return APCurvilinearQuadrilateral2(loop...)
    return APCurvilinearNgon2(loop)
end

function _region_overlap(a, b; atol::Real=1e-9)
    loop_a = _ccw_pieces(a)
    loop_b = _ccw_pieces(b)
    has_crossing = any(!isempty(intersection(pa, pb; atol=atol)) for pa in loop_a for pb in loop_b)
    if !has_crossing
        rep_a = _rep_point(loop_a)
        rep_a in b && return Any[a]
        rep_b = _rep_point(loop_b)
        rep_b in a && return Any[b]
        return Any[]
    end
    runs_a = _clip_loop_to_region(loop_a, b; atol=atol)
    runs_b = _clip_loop_to_region(loop_b, a; atol=atol)
    # a lone tangent touch (no genuine transversal crossing) can still trip
    # `has_crossing` above; when that leaves one loop kept whole and uncut,
    # there is nothing to stitch, so short-circuit the same way the
    # `!has_crossing` branch already does
    length(runs_a) == 1 && runs_a[1] == loop_a && return Any[a]
    length(runs_b) == 1 && runs_b[1] == loop_b && return Any[b]
    fragments = Any[]
    for run in runs_a
        append!(fragments, run)
    end
    for run in runs_b
        append!(fragments, run)
    end
    loops = _stitch_closed_loops(fragments; atol=atol)
    return [_classify_loop(loop) for loop in loops]
end

function _region_union(a, b; atol::Real=1e-9)
    loop_a = _ccw_pieces(a)
    loop_b = _ccw_pieces(b)
    has_crossing = any(!isempty(intersection(pa, pb; atol=atol)) for pa in loop_a for pb in loop_b)
    if !has_crossing
        rep_a = _rep_point(loop_a)
        rep_a in b && return Any[b]
        rep_b = _rep_point(loop_b)
        rep_b in a && return Any[a]
        return Any[a, b]
    end
    runs_a = _clip_loop_to_region(loop_a, b; atol=atol, invert=true)
    runs_b = _clip_loop_to_region(loop_b, a; atol=atol, invert=true)
    # a's whole boundary surviving the "outside b" clip is ambiguous on its
    # own: it also happens when b sits entirely inside a (tangent at one
    # point), not just when a and b are merely touching from outside, so the
    # two cases need telling apart by where b actually is
    if length(runs_a) == 1 && runs_a[1] == loop_a
        rep_b = _rep_point(loop_b)
        return rep_b in a ? Any[a] : Any[a, b]
    end
    if length(runs_b) == 1 && runs_b[1] == loop_b
        rep_a = _rep_point(loop_a)
        return rep_a in b ? Any[b] : Any[a, b]
    end
    fragments = Any[]
    for run in runs_a
        append!(fragments, run)
    end
    for run in runs_b
        append!(fragments, run)
    end
    loops = _stitch_closed_loops(fragments; atol=atol)
    return [_classify_loop(loop) for loop in loops]
end

function _region_difference(a, b; atol::Real=1e-9)
    a == b && return Any[]
    loop_a = _ccw_pieces(a)
    loop_b = _ccw_pieces(b)
    has_crossing = any(!isempty(intersection(pa, pb; atol=atol)) for pa in loop_a for pb in loop_b)
    if !has_crossing
        rep_b = _rep_point(loop_b)
        rep_b in a && throw(ArgumentError("intersection: this difference would carve b entirely out of a's interior, leaving a hole; no type here can represent a region with a hole"))
        rep_a = _rep_point(loop_a)
        rep_a in b && return Any[]
        return Any[a]
    end
    runs_a = _clip_loop_to_region(loop_a, b; atol=atol, invert=true)
    runs_b = _clip_loop_to_region(loop_b, a; atol=atol)
    # same tangent ambiguity as in _region_union: a's whole boundary
    # surviving "outside b" also happens when b sits entirely inside a
    # (tangent at one point), which is the hole case, not "disjoint"
    if length(runs_a) == 1 && runs_a[1] == loop_a
        rep_b = _rep_point(loop_b)
        rep_b in a && throw(ArgumentError("intersection: this difference would carve b entirely out of a's interior, leaving a hole; no type here can represent a region with a hole"))
        return Any[a]
    end
    fragments = Any[]
    for run in runs_a
        append!(fragments, run)
    end
    for run in runs_b
        append!(fragments, [_reverse_piece(piece) for piece in Base.reverse(run)])
    end
    loops = _stitch_closed_loops(fragments; atol=atol)
    return [_classify_loop(loop) for loop in loops]
end
