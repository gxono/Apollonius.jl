function _sh_clip_polygon(poly::Vector{<:APPoint}, hp::APHalfPlane2; atol=1e-9)
    isempty(poly) && return poly
    out = APPoint{2,Float64}[]
    n = length(poly)
    for i in 1:n
        cur = poly[i]
        prev = poly[mod1(i - 1, n)]
        cur_in = cur in hp
        prev_in = prev in hp
        cross = () -> only(intersection(APLine(prev, cur), hp.boundary; atol=atol))
        if cur_in
            if !prev_in
                c = cross()
                isapprox(c, cur; atol=atol) || push!(out, c)
            end
            push!(out, cur)
        elseif prev_in
            c = cross()
            isapprox(c, prev; atol=atol) || push!(out, c)
        end
    end
    return out
end

function _clip_polygon_to_halfplanes(verts, hps; atol=1e-9)
    poly = collect(verts)
    for hp in hps
        poly = _sh_clip_polygon(poly, hp; atol=atol)
        isempty(poly) && return poly
    end
    return poly
end

function _polygon_result(verts::Vector{<:APPoint})
    isempty(verts) && return nothing
    length(verts) == 1 && return only(verts)
    length(verts) == 2 && return APSegment(verts[1], verts[2])
    length(verts) == 3 && return APTriangle(verts...)
    length(verts) == 4 && return APQuadrilateral(verts...)
    return APStraightNgon(verts)
end

"""
    intersection(hp::APHalfPlane2, pg::Union{APTriangle,APQuadrilateral,APStraightNgon}; atol=1e-9)
    intersection(s::APStrip2, pg::Union{APTriangle,APQuadrilateral,APStraightNgon}; atol=1e-9)

The part of `pg` inside the region, in the tightest fitting type
(`nothing`, an [`APPoint`](@ref), an [`APSegment`](@ref), or a bounded
polygon with however many vertices survive), not the points where the
region's boundary crosses `pg`'s perimeter. Both argument orders work.
"""
intersection(hp::APHalfPlane2, pg::_StraightPolygon2; atol=1e-9) =
    _polygon_result(_clip_polygon_to_halfplanes(vertices(pg), _halfplanes_of(hp); atol=atol))
intersection(pg::_StraightPolygon2, hp::APHalfPlane2; atol=1e-9) = intersection(hp, pg; atol=atol)
intersection(s::APStrip2, pg::_StraightPolygon2; atol=1e-9) =
    _polygon_result(_clip_polygon_to_halfplanes(vertices(pg), _halfplanes_of(s); atol=atol))
intersection(pg::_StraightPolygon2, s::APStrip2; atol=1e-9) = intersection(s, pg; atol=atol)

"""
    intersection(ang::APAngle2, pg::Union{APTriangle,APQuadrilateral,APStraightNgon}; atol=1e-9)

The part of `pg` inside the wedge, as a `Vector` (see
[Points, Lines & Rays: Angles](@ref) for why any pair involving an
[`APAngle2`](@ref) always returns one): 0, 1, or, only for a reflex `ang`,
up to 2 pieces. Both argument orders work.
"""
function intersection(ang::APAngle2, pg::_StraightPolygon2; atol=1e-9)
    pieces = Any[]
    for g in _angle_groups(ang; atol=atol)
        r = _polygon_result(_clip_polygon_to_halfplanes(vertices(pg), g; atol=atol))
        r === nothing || push!(pieces, r)
    end
    return pieces
end
intersection(pg::_StraightPolygon2, ang::APAngle2; atol=1e-9) = intersection(ang, pg; atol=atol)
