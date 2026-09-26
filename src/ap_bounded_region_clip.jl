_merge_adjacent(a, b; atol::Real=1e-9) = nothing
function _merge_adjacent(a::APCircularArc2, b::APCircularArc2; atol::Real=1e-9)
    a.circle == b.circle && isapprox(a.p2, b.p1; atol=atol) || return nothing
    return APCircularArc2(a.circle, a.p1, b.p2)
end
function _merge_adjacent(a::APEllipticArc2, b::APEllipticArc2; atol::Real=1e-9)
    a.ellipse == b.ellipse && isapprox(a.p2, b.p1; atol=atol) || return nothing
    return APEllipticArc2(a.ellipse, a.p1, b.p2)
end
function _merge_adjacent(a::APSegment, b::APSegment; atol::Real=1e-9)
    isapprox(a.p2, b.p1; atol=atol) || return nothing
    d1, d2 = direction(a), direction(b)
    abs(cross2(d1, d2)) <= atol * norm(d1) * norm(d2) || return nothing
    return APSegment(a.p1, b.p2)
end
function _coalesce_run(run::Vector; atol::Real=1e-9)
    isempty(run) && return run
    out = Any[run[1]]
    for i in 2:length(run)
        merged = _merge_adjacent(out[end], run[i]; atol=atol)
        merged === nothing ? push!(out, run[i]) : (out[end] = merged)
    end
    return out
end

function _clip_loop_to_region(loop_pieces::Vector, region; atol::Real=1e-9)
    region_pieces = _pieces(region)
    has_crossing = any(!isempty(intersection(piece, rp; atol=atol)) for piece in loop_pieces for rp in region_pieces)
    if !has_crossing
        rep = _side_point_at(loop_pieces[1], _side_domain(loop_pieces[1])[1])
        return rep in region ? Vector{Any}[collect(loop_pieces)] : Vector{Any}[]
    end
    runs = Vector{Any}[]
    current = Any[]
    first_survived = nothing
    for piece in loop_pieces
        lo, hi = _side_domain(piece)
        pts = [pt for rp in region_pieces for pt in intersection(piece, rp; atol=atol)]
        cuts = sort(unique(round.([clamp(_side_param(piece, p), lo, hi) for p in pts]; digits=9)))
        bounds = vcat(lo, cuts, hi)
        scale = max(1.0, hi - lo)
        for j in 1:length(bounds)-1
            a, b = bounds[j], bounds[j+1]
            (b - a) <= atol * scale && continue
            survives = _side_point_at(piece, (a + b) / 2) in region
            first_survived === nothing && (first_survived = survives)
            if survives
                push!(current, _side_between(piece, a, b))
            elseif !isempty(current)
                push!(runs, current)
                current = Any[]
            end
        end
    end
    if !isempty(current)
        if first_survived === true && !isempty(runs)
            runs[1] = vcat(current, runs[1])
        else
            push!(runs, current)
        end
    end
    return [_coalesce_run(run; atol=atol) for run in runs]
end
