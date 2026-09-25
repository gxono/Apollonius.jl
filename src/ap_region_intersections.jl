# Phase 3 of the region-clipping intersections (see ap_unbounded_intersections.jl
# for Phase 1, ap_conic_region_intersections.jl for Phase 2): APAngle2/
# APHalfPlane2/APStrip2 against EACH OTHER.
#
# APHalfPlane2 is one halfplane; APStrip2 is the AND of two (parallel,
# opposite-facing); a convex APAngle2 (normalized_measure <= π) is the AND of
# two (the lines through its rays, each kept on the side of the other ray); a
# reflex APAngle2 is instead the OR of those same two, flipped. So any pair of
# these three, as long as neither is reflex, reduces to ANDing 2-4 halfplanes;
# a reflex operand distributes the OR over the intersection, `(A∪B)∩R =
# (A∩R)∪(B∩R)`, which is why (and the only way) two disjoint pieces can appear.
#
# ANDing halfplanes: each boundary line, clipped by ALL of them (including
# itself, a no-op) using Phase 1's own _clip_to_halfplane, gives that
# boundary's surviving edge -- nothing (redundant), a point, a segment, a ray,
# or the whole unclipped line. Classifying the set of survivors (see
# _classify_halfplane_intersection) says exactly what the AND is, with no
# further casework: APHalfPlane2/APStrip2/APLine/APAngle2/APPoint/nothing when
# it collapses to something already known, APTriangle/APQuadrilateral when
# it's bounded, or the new APUnboundedPolygon2 otherwise.

_halfplanes_of(hp::APHalfPlane2) = [hp]
_halfplanes_of(s::APStrip2) = [
    APHalfPlane2(s.line1, side_of_line(s.line2.p1, s.line1)),
    APHalfPlane2(s.line2, side_of_line(s.line1.p1, s.line2)),
]
_halfplanes_of(ang::APAngle2) = [_hp_for_ray(ang.vertex, ang.a, ang.b), _hp_for_ray(ang.vertex, ang.b, ang.a)]
_flip(hp::APHalfPlane2) = APHalfPlane2(hp.boundary, -hp.side)

function _same_line(l1::APLine, l2::APLine; atol=1e-9)
    d1, d2 = direction(l1), direction(l2)
    abs(cross2(d1, d2)) <= atol * norm(d1) * norm(d2) || return false
    diff = l2.p1 - l1.p1
    return abs(cross2(d1, diff)) <= atol * norm(d1) * max(norm(diff), 1.0)
end

# Walks segments nose-to-tail (matching p1 of the next to p2 of the last),
# starting from `start` (or the first segment's own p1 if not given), until no
# more segments connect: an open chain if some are left dangling, a closed
# loop (path[1] == path[end]) if they use every segment and return to start.
function _stitch_chain(segs::AbstractVector; start::Union{APPoint,Nothing}=nothing, atol=1e-9)
    remaining = collect(segs)
    current = start === nothing ? remaining[1].p1 : start
    path = [current]
    while true
        idx = findfirst(s -> isapprox(s.p1, current; atol=atol), remaining)
        idx === nothing && break
        current = popat!(remaining, idx).p2
        push!(path, current)
    end
    return path
end

_edges_equal(a::APPoint, b::APPoint; atol) = isapprox(a, b; atol=atol)
# same origin AND same (not just parallel) direction: two rays with the same
# origin pointing opposite ways along one line are NOT the same ray
function _edges_equal(a::APRay, b::APRay; atol)
    isapprox(a.origin, b.origin; atol=atol) || return false
    d1, d2 = direction(a), direction(b)
    return abs(cross2(d1, d2)) <= atol * norm(d1) * norm(d2) && dot(d1, d2) > 0
end
_edges_equal(a::APSegment, b::APSegment; atol) =
    (isapprox(a.p1, b.p1; atol=atol) && isapprox(a.p2, b.p2; atol=atol)) ||
    (isapprox(a.p1, b.p2; atol=atol) && isapprox(a.p2, b.p1; atol=atol))
_edges_equal(::Any, ::Any; atol) = false

# Whether hp1 and hp2 are the same physical region (same boundary line,
# possibly stored with p1/p2 in either order, and same side): unlike
# comparing the two boundary APLines directly, this tells apart "redundant
# duplicate of one halfplane" from "the OTHER side of the same line", which
# must stay distinguishable in _classify_halfplane_intersection below.
function _same_halfplane(hp1::APHalfPlane2, hp2::APHalfPlane2; atol=1e-9)
    _same_line(hp1.boundary, hp2.boundary; atol=atol) || return false
    d = direction(hp1.boundary)
    test_pt = hp1.boundary.p1 + APVector(-d[2], d[1])
    return (test_pt in hp1) == (test_pt in hp2)
end

# Two different boundary lines can clip down to the exact same physical edge
# (e.g. two angles sharing a boundary ray: the ray's own line is also the
# OTHER ray's boundary line, seen twice, from two different owning
# halfplanes) -- deduping first is what lets a single leftover edge collapse
# correctly below instead of being mistaken for a second, distinct one. A
# full-line edge only dedupes against another from the SAME physical
# halfplane: two opposite-side halfplanes sharing a line both surviving
# unclipped is the genuine "AND reduces to just that line" case (handled
# below), not a redundant duplicate.
function _dedup_owned(owned::Vector{<:Tuple{APHalfPlane2,Any}}; atol=1e-9)
    kept = Tuple{APHalfPlane2,Any}[]
    for (hp, e) in owned
        dup = any(kept) do owned2
            hp2, e2 = owned2
            e isa APLine && e2 isa APLine ? _same_halfplane(hp, hp2; atol=atol) : _edges_equal(e, e2; atol=atol)
        end
        dup || push!(kept, (hp, e))
    end
    return kept
end

function _classify_halfplane_intersection(survivors::Vector{<:Tuple{APHalfPlane2,Any}}; atol=1e-9)
    owned = _dedup_owned(survivors; atol=atol)
    edges = [e for (_, e) in owned]

    if length(edges) == 1
        e = edges[1]
        return e isa APLine ? owned[1][1] : e
    end

    lines = filter(e -> e isa APLine, edges)
    if length(edges) == 2 && length(lines) == 2
        return _same_line(lines[1], lines[2]; atol=atol) ? lines[1] : APStrip2(lines[1], lines[2])
    end

    rays = filter(e -> e isa APRay, edges)
    if length(edges) == 2 && length(rays) == 2
        vertex = rays[1].origin
        ang = APAngle2(vertex, vertex + direction(rays[1]), vertex + direction(rays[2]))
        return normalized_measure(ang) <= pi + atol ? ang : reverse(ang)
    end

    # a lone surviving point alongside the rest is redundant with a
    # neighboring edge's own endpoint (the constraints agree exactly there),
    # so it carries no extra information and is dropped
    rest = filter(e -> !(e isa APPoint), edges)
    segs = filter(e -> e isa APSegment, rest)
    rays2 = filter(e -> e isa APRay, rest)
    if length(rays2) == 0
        loop = _stitch_chain(segs; atol=atol)[1:end-1]
        length(loop) == 3 && return APTriangle(loop[1], loop[2], loop[3])
        length(loop) == 4 && return APQuadrilateral(loop[1], loop[2], loop[3], loop[4])
        error("APUnboundedPolygon2: unexpected bounded intersection with $(length(loop)) vertices")
    elseif length(rays2) == 1
        return only(rays2)
    elseif length(rays2) == 2
        ray_a, ray_b = rays2
        starts_at_a = any(seg -> isapprox(seg.p1, ray_a.origin; atol=atol), segs)
        ray1, ray2 = starts_at_a ? (ray_a, ray_b) : (ray_b, ray_a)
        chain = _stitch_chain(segs; start=ray1.origin, atol=atol)
        return APUnboundedPolygon2(ray1, chain[2:end-1], ray2)
    else
        error("APUnboundedPolygon2: unexpected halfplane intersection configuration")
    end
end

"""
    _intersect_halfplanes(halfplanes; atol=1e-9)

The AND of 2-4 halfplanes: `nothing`, an `APPoint`, `APLine`, `APRay`,
`APSegment`, `APHalfPlane2`, `APStrip2`, `APAngle2`, `APTriangle`,
`APQuadrilateral`, or an `APUnboundedPolygon2`, whichever it collapses to.
"""
function _intersect_halfplanes(halfplanes::AbstractVector{<:APHalfPlane2}; atol=1e-9)
    survivors = Tuple{APHalfPlane2,Any}[]
    for hp in halfplanes
        dir = hp.side == 1 ? direction(hp.boundary) : -direction(hp.boundary)
        base = hp.boundary.p1
        lo, hi = -Inf, Inf
        ok = true
        for hp2 in halfplanes
            r = _clip_to_halfplane(base, dir, lo, hi, hp2; atol=atol)
            if r === nothing
                ok = false
                break
            end
            lo, hi = r
        end
        ok && push!(survivors, (hp, _object_from_range(base, dir, lo, hi)))
    end
    isempty(survivors) && return nothing
    return _classify_halfplane_intersection(survivors; atol=atol)
end

"""
    intersection(a::APHalfPlane2, b::APHalfPlane2; atol=1e-9)
    intersection(hp::APHalfPlane2, s::APStrip2; atol=1e-9)
    intersection(s1::APStrip2, s2::APStrip2; atol=1e-9)

The region common to both, whichever type it collapses to (see
[Unbounded Regions: Half-Planes, Strips & Angles](@ref)): `nothing` if
disjoint, an `APLine` if the two halfplanes share a boundary from opposite
sides, `APHalfPlane2`/`APStrip2` unchanged if one is redundant, an
[`APAngle2`](@ref) for two crossing halfplanes, `APTriangle`/`APQuadrilateral`
when the result is bounded, or an [`APUnboundedPolygon2`](@ref) otherwise.
Both argument orders work; these three pairs never involve a reflex angle, so
the result is never a `Vector`.
"""
intersection(a::APHalfPlane2, b::APHalfPlane2; atol=1e-9) = _intersect_halfplanes([a, b]; atol=atol)
intersection(hp::APHalfPlane2, s::APStrip2; atol=1e-9) = _intersect_halfplanes(vcat([hp], _halfplanes_of(s)); atol=atol)
intersection(s::APStrip2, hp::APHalfPlane2; atol=1e-9) = intersection(hp, s; atol=atol)
intersection(s1::APStrip2, s2::APStrip2; atol=1e-9) = _intersect_halfplanes(vcat(_halfplanes_of(s1), _halfplanes_of(s2)); atol=atol)

# A convex ang contributes its 2 halfplanes AND'ed together, as one group; a
# reflex one is the OR of its 2 flipped halfplanes, so it contributes 2
# separate 1-halfplane groups instead. Combining every group from one operand
# with every group from the other (see the 3 methods below) is exactly the
# distributive expansion of (A∪B) ∩ (C∪D), and reduces to a single group when
# neither side is reflex.
_angle_groups(ang::APAngle2; atol=1e-9) =
    normalized_measure(ang) <= pi + atol ? [_halfplanes_of(ang)] : [[h] for h in map(_flip, _halfplanes_of(ang))]

"""
    intersection(hp::APHalfPlane2, ang::APAngle2; atol=1e-9)
    intersection(s::APStrip2, ang::APAngle2; atol=1e-9)
    intersection(ang1::APAngle2, ang2::APAngle2; atol=1e-9)

The region common to both, as a `Vector` (see [Points, Lines & Rays: Angles](@ref)
for why any pair involving an [`APAngle2`](@ref) always returns one, even when
this particular `ang` isn't reflex): 0, 1, or, only when at least one operand
is a *reflex* angle, up to 2 (or up to 4 for `ang1`/`ang2` both reflex) pieces,
each whichever type the corresponding [`APHalfPlane2`](@ref)/[`APStrip2`](@ref)
pair collapses to. Both argument orders work for the first two.
"""
function intersection(hp::APHalfPlane2, ang::APAngle2; atol=1e-9)
    pieces = Any[]
    for g in _angle_groups(ang; atol=atol)
        r = _intersect_halfplanes(vcat([hp], g); atol=atol)
        r === nothing || push!(pieces, r)
    end
    return pieces
end
intersection(ang::APAngle2, hp::APHalfPlane2; atol=1e-9) = intersection(hp, ang; atol=atol)

function intersection(s::APStrip2, ang::APAngle2; atol=1e-9)
    hps = _halfplanes_of(s)
    pieces = Any[]
    for g in _angle_groups(ang; atol=atol)
        r = _intersect_halfplanes(vcat(hps, g); atol=atol)
        r === nothing || push!(pieces, r)
    end
    return pieces
end
intersection(ang::APAngle2, s::APStrip2; atol=1e-9) = intersection(s, ang; atol=atol)

function intersection(ang1::APAngle2, ang2::APAngle2; atol=1e-9)
    pieces = Any[]
    for g1 in _angle_groups(ang1; atol=atol), g2 in _angle_groups(ang2; atol=atol)
        r = _intersect_halfplanes(vcat(g1, g2); atol=atol)
        r === nothing || push!(pieces, r)
    end
    return pieces
end
