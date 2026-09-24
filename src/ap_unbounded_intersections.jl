# Intersection of an unbounded region (APAngle2, APHalfPlane2, APStrip2) with a
# straight object (APLine, APRay, APSegment): the portion of the object that lies
# INSIDE the region, not the points where the region's boundary crosses it. This is
# a different convention from the rest of `intersection` (always Vector{APPoint}
# elsewhere), agreed on with the user since these three types are the only ones
# where "region" and "curve" are genuinely different questions, and this package
# doesn't publish anything yet, so the break has no external cost.
#
# All three regions are convex halfplane intersections except a reflex APAngle2
# (measure > π), which is instead the UNION of the two flipped halfplanes -- the
# one case that can give two disjoint pieces of the object instead of one.

_param_base_dir(l::APLine) = (l.p1, direction(l))
_param_base_dir(r::APRay) = (r.origin, direction(r))
_param_base_dir(s::APSegment) = (s.p1, direction(s))
_param_domain(::APLine) = (-Inf, Inf)
_param_domain(::APRay) = (0.0, Inf)
_param_domain(::APSegment) = (0.0, 1.0)

# Clips the parameter range [lo, hi] of point(t) = base + t*dir to the side of
# hp.boundary that hp keeps. Returns `nothing` for an empty result, else (lo, hi).
function _clip_to_halfplane(base::APPoint, dir::APVector, lo::Real, hi::Real, hp::APHalfPlane2; atol=1e-9)
    d = direction(hp.boundary)
    A = cross2(d, base - hp.boundary.p1)
    B = cross2(d, dir)
    scale = atol * norm(d) * max(norm(dir), 1.0)
    if abs(B) <= scale
        inside = abs(A) <= scale || sign(A) == sign(hp.side)
        return inside ? (lo, hi) : nothing
    end
    t0 = -A / B
    if sign(B) == sign(hp.side)
        newlo, newhi = max(lo, t0), hi
    else
        newlo, newhi = lo, min(hi, t0)
    end
    return newlo <= newhi ? (newlo, newhi) : nothing
end

# Converts a clipped parameter range back to the natural type: a point when the
# range is a single value, a segment/ray/line depending on which ends are finite.
function _object_from_range(base::APPoint, dir::APVector, lo::Real, hi::Real)
    lo == hi && return base + lo * dir
    isfinite(lo) && isfinite(hi) && return APSegment(base + lo * dir, base + hi * dir)
    isfinite(lo) && return APRay(base + lo * dir, base + (lo + 1) * dir)
    isfinite(hi) && return APRay(base + hi * dir, base + (hi - 1) * dir)
    return APLine(base, base + dir)
end

function _union_ranges(r1, r2)
    r1 === nothing && r2 === nothing && return Tuple{Float64,Float64}[]
    r1 === nothing && return [r2]
    r2 === nothing && return [r1]
    (lo1, hi1), (lo2, hi2) = r1, r2
    lo1 > lo2 && ((lo1, hi1, lo2, hi2) = (lo2, hi2, lo1, hi1))
    lo2 <= hi1 && return [(lo1, max(hi1, hi2))]
    return [(lo1, hi1), (lo2, hi2)]
end

const _StraightObject = Union{APLine{2},APRay{2},APSegment{2}}

"""
    intersection(hp::APHalfPlane2, obj::Union{APLine,APRay,APSegment}; atol=1e-9)

The portion of `obj` that lies inside `hp`: a point, a segment, a ray, all of
`obj`, or `nothing` if `obj` never enters `hp`. Unlike every other
`intersection` method, this is not the points where a boundary is crossed: `hp`
is a region, and this is the part of `obj` inside it, in `obj`'s own type
family (a clipped `APSegment` stays an `APSegment`, a clipped `APLine`/`APRay`
that still reaches infinity stays a `APLine`/`APRay`).
"""
function intersection(hp::APHalfPlane2, obj::_StraightObject; atol=1e-9)
    base, dir = _param_base_dir(obj)
    lo, hi = _param_domain(obj)
    r = _clip_to_halfplane(base, dir, lo, hi, hp; atol=atol)
    return r === nothing ? nothing : _object_from_range(base, dir, r...)
end
intersection(obj::_StraightObject, hp::APHalfPlane2; atol=1e-9) = intersection(hp, obj; atol=atol)
intersection(hp::APHalfPlane2, p::APPoint{2}) = p in hp ? p : nothing
intersection(p::APPoint{2}, hp::APHalfPlane2) = intersection(hp, p)

"""
    intersection(s::APStrip2, obj::Union{APLine,APRay,APSegment}; atol=1e-9)

The portion of `obj` inside the band `s`, computed as `obj` clipped to each of
`s`'s two bounding half-planes in turn: a point, a segment, a ray, all of
`obj`, or `nothing`. See [`intersection(::APHalfPlane2, ::APLine)`](@ref) for
why this isn't the usual `Vector{APPoint}` of crossing points.
"""
function intersection(s::APStrip2, obj::_StraightObject; atol=1e-9)
    base, dir = _param_base_dir(obj)
    lo, hi = _param_domain(obj)
    hp1 = APHalfPlane2(s.line1, side_of_line(s.line2.p1, s.line1))
    hp2 = APHalfPlane2(s.line2, side_of_line(s.line1.p1, s.line2))
    r = _clip_to_halfplane(base, dir, lo, hi, hp1; atol=atol)
    r === nothing && return nothing
    r = _clip_to_halfplane(base, dir, r..., hp2; atol=atol)
    return r === nothing ? nothing : _object_from_range(base, dir, r...)
end
intersection(obj::_StraightObject, s::APStrip2; atol=1e-9) = intersection(s, obj; atol=atol)
intersection(s::APStrip2, p::APPoint{2}) = p in s ? p : nothing
intersection(p::APPoint{2}, s::APStrip2) = intersection(s, p)

_hp_for_ray(vertex::APPoint, from::APPoint, other::APPoint) = APHalfPlane2(APLine(vertex, from), other)

"""
    intersection(ang::APAngle2, obj::Union{APLine,APRay,APSegment}; atol=1e-9)

The portion of `obj` inside the wedge `ang`, as a `Vector` (0, 1 or 2
elements, each a point, a segment, a ray or all of `obj`) rather than the bare
value [`intersection(::APHalfPlane2, ::APLine)`](@ref)/[`intersection(::APStrip2, ::APLine)`](@ref)
give: a *reflex* `ang` (`normalized_measure(ang) > π`) is not convex, and
`obj` can then cross into it, out, and back in, leaving two disjoint pieces
(see [Points, Lines & Rays: Angles](@ref)). A convex `ang` never gives more than one.
"""
function intersection(ang::APAngle2, obj::_StraightObject; atol=1e-9)
    base, dir = _param_base_dir(obj)
    lo, hi = _param_domain(obj)
    hp_a = _hp_for_ray(ang.vertex, ang.a, ang.b)
    hp_b = _hp_for_ray(ang.vertex, ang.b, ang.a)
    pieces = if normalized_measure(ang) <= pi + atol
        r = _clip_to_halfplane(base, dir, lo, hi, hp_a; atol=atol)
        r = r === nothing ? nothing : _clip_to_halfplane(base, dir, r..., hp_b; atol=atol)
        r === nothing ? Tuple{Float64,Float64}[] : [r]
    else
        flip_a = APHalfPlane2(hp_a.boundary, -hp_a.side)
        flip_b = APHalfPlane2(hp_b.boundary, -hp_b.side)
        r1 = _clip_to_halfplane(base, dir, lo, hi, flip_a; atol=atol)
        r2 = _clip_to_halfplane(base, dir, lo, hi, flip_b; atol=atol)
        _union_ranges(r1, r2)
    end
    return [_object_from_range(base, dir, p...) for p in pieces]
end
intersection(obj::_StraightObject, ang::APAngle2; atol=1e-9) = intersection(ang, obj; atol=atol)
intersection(ang::APAngle2, p::APPoint{2}) = p in ang ? p : nothing
intersection(p::APPoint{2}, ang::APAngle2) = intersection(ang, p)
