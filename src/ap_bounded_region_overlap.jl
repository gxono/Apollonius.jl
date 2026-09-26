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

_any_crossing(loop_a, loop_b; atol::Real=1e-9) =
    any(!isempty(intersection(pa, pb; atol=atol)) for pa in loop_a for pb in loop_b)

_whole_loop_kept(runs, loop) = length(runs) == 1 && runs[1] == loop

function _pool_and_classify(fragments::Vector; atol::Real=1e-9)
    loops = _stitch_closed_loops(fragments; atol=atol)
    return [_classify_loop(loop) for loop in loops]
end

_hole_error() = ArgumentError("intersection: this difference would carve b entirely out of a's interior, leaving a hole; no type here can represent a region with a hole")

function _region_overlap(a, b; atol::Real=1e-9)
    a == b && return Any[a]
    loop_a, loop_b = _ccw_pieces(a), _ccw_pieces(b)
    if !_any_crossing(loop_a, loop_b; atol=atol)
        _rep_point(loop_a) in b && return Any[a]
        _rep_point(loop_b) in a && return Any[b]
        return Any[]
    end
    runs_a = _clip_loop_to_region(loop_a, b; atol=atol)
    runs_b = _clip_loop_to_region(loop_b, a; atol=atol)
    # a lone tangent touch (no genuine transversal crossing) can still trip
    # `_any_crossing` above; when that leaves one loop kept whole and uncut,
    # there is nothing to stitch, so short-circuit the same way the
    # no-crossing branch already does
    _whole_loop_kept(runs_a, loop_a) && return Any[a]
    _whole_loop_kept(runs_b, loop_b) && return Any[b]
    fragments = Any[]
    for run in runs_a
        append!(fragments, run)
    end
    for run in runs_b
        append!(fragments, run)
    end
    return _pool_and_classify(fragments; atol=atol)
end

function _region_union(a, b; atol::Real=1e-9)
    a == b && return Any[a]
    loop_a, loop_b = _ccw_pieces(a), _ccw_pieces(b)
    if !_any_crossing(loop_a, loop_b; atol=atol)
        _rep_point(loop_a) in b && return Any[b]
        _rep_point(loop_b) in a && return Any[a]
        return Any[a, b]
    end
    runs_a = _clip_loop_to_region(loop_a, b; atol=atol, invert=true)
    runs_b = _clip_loop_to_region(loop_b, a; atol=atol, invert=true)
    # a's whole boundary surviving the "outside b" clip is ambiguous on its
    # own: it also happens when b sits entirely inside a (tangent at one
    # point), not just when a and b are merely touching from outside, so the
    # two cases need telling apart by where b actually is
    if _whole_loop_kept(runs_a, loop_a)
        return _rep_point(loop_b) in a ? Any[a] : Any[a, b]
    end
    if _whole_loop_kept(runs_b, loop_b)
        return _rep_point(loop_a) in b ? Any[b] : Any[a, b]
    end
    fragments = Any[]
    for run in runs_a
        append!(fragments, run)
    end
    for run in runs_b
        append!(fragments, run)
    end
    return _pool_and_classify(fragments; atol=atol)
end

function _region_difference(a, b; atol::Real=1e-9)
    a == b && return Any[]
    loop_a, loop_b = _ccw_pieces(a), _ccw_pieces(b)
    if !_any_crossing(loop_a, loop_b; atol=atol)
        _rep_point(loop_b) in a && throw(_hole_error())
        _rep_point(loop_a) in b && return Any[]
        return Any[a]
    end
    runs_a = _clip_loop_to_region(loop_a, b; atol=atol, invert=true)
    runs_b = _clip_loop_to_region(loop_b, a; atol=atol)
    # same tangent ambiguity as in _region_union: a's whole boundary
    # surviving "outside b" also happens when b sits entirely inside a
    # (tangent at one point), which is the hole case, not "disjoint"
    if _whole_loop_kept(runs_a, loop_a)
        _rep_point(loop_b) in a && throw(_hole_error())
        return Any[a]
    end
    fragments = Any[]
    for run in runs_a
        append!(fragments, run)
    end
    for run in runs_b
        append!(fragments, [_reverse_piece(piece) for piece in Base.reverse(run)])
    end
    return _pool_and_classify(fragments; atol=atol)
end

function _region_symdiff(a, b; atol::Real=1e-9)
    return vcat(_region_difference(a, b; atol=atol), _region_difference(b, a; atol=atol))
end

_overlaps(a, b; atol::Real=1e-9) = !isempty(_region_overlap(a, b; atol=atol))

function _touches(a, b; atol::Real=1e-9)
    _overlaps(a, b; atol=atol) && return false
    return _any_crossing(_ccw_pieces(a), _ccw_pieces(b); atol=atol)
end

function _is_walkable(pg)
    pg isa Union{APCircle2,APEllipse2} && return true
    try
        _ccw_pieces(pg)
        return true
    catch e
        e isa ArgumentError && return false
        rethrow()
    end
end

function _try_merge_one!(pieces::Vector; atol::Real=1e-9)
    n = length(pieces)
    for i in 1:n, j in (i+1):n
        merged = _region_union(pieces[i], pieces[j]; atol=atol)
        if length(merged) == 1
            pieces[i] = only(merged)
            deleteat!(pieces, j)
            return true
        end
    end
    return false
end

function _region_union_all(shapes; atol::Real=1e-9)
    isempty(shapes) && return Any[]
    pieces = Any[shapes...]
    while _try_merge_one!(pieces; atol=atol)
    end
    return pieces
end

function _region_intersection_all(shapes; atol::Real=1e-9)
    isempty(shapes) && throw(ArgumentError("intersection: needs at least one shape"))
    pieces = Any[shapes[1]]
    for s in shapes[2:end]
        next_pieces = Any[]
        for p in pieces
            append!(next_pieces, _region_overlap(p, s; atol=atol))
        end
        pieces = next_pieces
        isempty(pieces) && return pieces
    end
    return pieces
end

function _region_difference_all(a, others; atol::Real=1e-9)
    pieces = Any[a]
    for b in others
        next_pieces = Any[]
        for p in pieces
            append!(next_pieces, _region_difference(p, b; atol=atol))
        end
        pieces = next_pieces
        isempty(pieces) && return pieces
    end
    return pieces
end
