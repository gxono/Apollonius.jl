function _assemble_run(run::Vector, whole, loop::Vector)
    length(run) == length(loop) && run == loop && return whole
    length(run) == 1 && return only(run)
    all(p -> p isa APSegment, run) && return APPolyline2([run[1].p1; [s.p2 for s in run]])
    return APCurvilinearPolyline2(run)
end

function _boundary_clip(a, region; atol::Real=1e-9)
    loop = collect(_pieces(a))
    runs = _clip_loop_to_region(loop, region; atol=atol)
    return [_assemble_run(run, a, loop) for run in runs]
end

_reverse_piece(s::APSegment) = APSegment(s.p2, s.p1)
_reverse_piece(arc::Union{APParabolicArc2,APHyperbolicArc2}) = Base.reverse(arc)
_reverse_piece(::Union{APCircularArc2,APEllipticArc2}) =
    throw(ArgumentError("mode=:region: this polygon's circular/elliptic-arc side is wound clockwise; build it with the opposite arc direction"))

function _ccw_pieces(pg)
    pg isa Union{APCircle2,APEllipse2} && return collect(_pieces(pg))
    pcs = collect(_pieces(pg))
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
        push!(loops, loop)
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
        rep_a = _side_point_at(loop_a[1], _side_domain(loop_a[1])[1])
        rep_a in b && return Any[a]
        rep_b = _side_point_at(loop_b[1], _side_domain(loop_b[1])[1])
        rep_b in a && return Any[b]
        return Any[]
    end
    runs_a = _clip_loop_to_region(loop_a, b; atol=atol)
    runs_b = _clip_loop_to_region(loop_b, a; atol=atol)
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
