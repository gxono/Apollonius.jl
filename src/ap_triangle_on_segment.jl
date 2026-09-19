"""
    equilateral_triangle_on_segment(a::APPoint, b::APPoint; ccw::Bool=true)

The equilateral triangle with side `[a, b]`, built counterclockwise from
`a` to `b` (`ccw=false` builds it on the other side).
"""
function equilateral_triangle_on_segment(a::APPoint, b::APPoint; ccw::Bool=true)
    return APTriangle(a, b, rotate(b, ccw ? pi / 3 : -pi / 3, a))
end
"""
    equilateral_triangle_on_segment(s::APSegment; ccw::Bool=true)
"""
function equilateral_triangle_on_segment(s::APSegment; ccw::Bool=true)
    return equilateral_triangle_on_segment(s.p1, s.p2; ccw=ccw)
end
"""
    isosceles_triangle_on_segment(a::APPoint, b::APPoint, leg::Real; ccw::Bool=true)

The isosceles triangle with base `[a, b]` and the given equal leg length
(`distance(a, c) == distance(b, c) == leg`), built counterclockwise from
`a` to `b` (`ccw=false` builds it on the other side). Throws an
`ArgumentError` if `leg` is too short to reach across the base.
"""
isosceles_triangle_on_segment(a::APPoint, b::APPoint, leg::Real; ccw::Bool=true) =
    triangle_on_segment_sss(a, b, leg, leg; ccw=ccw)
"""
    isosceles_triangle_on_segment(s::APSegment, leg::Real; ccw::Bool=true)
"""
function isosceles_triangle_on_segment(s::APSegment, leg::Real; ccw::Bool=true)
    return isosceles_triangle_on_segment(s.p1, s.p2, leg; ccw=ccw)
end
"""
    triangle_on_segment_sss(a::APPoint, b::APPoint, len_a::Real, len_b::Real; ccw::Bool=true)

The triangle with base `[a, b]` and two new side lengths, `len_a` from
`a` and `len_b` from `b` (SSS: all three sides then known), built
counterclockwise from `a` to `b` (`ccw=false` builds it on the other
side). Generalizes [`isosceles_triangle_on_segment`](@ref) (`len_a ==
len_b`). Throws an `ArgumentError` if `len_a`/`len_b` can't reach across
`[a, b]` (triangle inequality).
"""
function triangle_on_segment_sss(a::APPoint, b::APPoint, len_a::Real, len_b::Real; ccw::Bool=true)
    pts = intersection(APCircle2(a, len_a), APCircle2(b, len_b))
    length(pts) != 2 &&
        throw(ArgumentError("triangle_on_segment_sss: len_a and len_b can't reach across [a, b] (triangle inequality)"))
    p1, p2 = pts
    on_ccw_side = cross2(b - a, p1 - a) > 0
    return APTriangle(a, b, on_ccw_side == ccw ? p1 : p2)
end
"""
    triangle_on_segment_sss(s::APSegment, len_a::Real, len_b::Real; ccw::Bool=true)
"""
function triangle_on_segment_sss(s::APSegment, len_a::Real, len_b::Real; ccw::Bool=true)
    return triangle_on_segment_sss(s.p1, s.p2, len_a, len_b; ccw=ccw)
end
"""
    triangle_on_segment(a::APPoint, b::APPoint, angle_a::Real, angle_b::Real; ccw::Bool=true)

The triangle with base `[a, b]`, angle `angle_a` (radians) at `a` and
`angle_b` at `b`, built counterclockwise from `a` to `b` (`ccw=false`
builds it on the other side): the generic ASA construction every
fixed-shape `*_on_segment` constructor in this file is a special case of
(e.g. [`triangle_30_60_90_on_segment`](@ref) is
`triangle_on_segment(a, b, pi/6, pi/3)`). Throws an `ArgumentError` unless
both angles are in `(0, π)` and sum to less than `π`, since otherwise the
two rays from `a` and `b` never meet on a genuine triangle's side.
"""
function triangle_on_segment(a::APPoint, b::APPoint, angle_a::Real, angle_b::Real; ccw::Bool=true)
    (0 < angle_a < pi && 0 < angle_b < pi && angle_a + angle_b < pi) ||
        throw(ArgumentError("triangle_on_segment: angle_a and angle_b must each be in (0, π) and sum to less than π"))
    s = ccw ? 1 : -1
    ray_a = APLine(a, rotate(b, s * angle_a, a))
    ray_b = APLine(b, rotate(a, -s * angle_b, b))
    return APTriangle(a, b, only(intersection(ray_a, ray_b)))
end
"""
    triangle_on_segment(s::APSegment, angle_a::Real, angle_b::Real; ccw::Bool=true)
"""
function triangle_on_segment(s::APSegment, angle_a::Real, angle_b::Real; ccw::Bool=true)
    return triangle_on_segment(s.p1, s.p2, angle_a, angle_b; ccw=ccw)
end
"""
    triangle_on_segment_sas(a::APPoint, b::APPoint, angle::Real, len::Real; at::Symbol=:a, ccw::Bool=true)

The triangle with base `[a, b]` and a new side of length `len` from
vertex `at` (`:a` or `:b`), making `angle` (radians) with the base at
that same vertex (SAS: two sides and the angle between them then known),
built counterclockwise from `a` to `b` (`ccw=false` builds it on the
other side). Throws an `ArgumentError` unless `angle` is in `(0, π)` and
`at` is `:a` or `:b`.
"""
function triangle_on_segment_sas(a::APPoint, b::APPoint, angle::Real, len::Real; at::Symbol=:a, ccw::Bool=true)
    0 < angle < pi || throw(ArgumentError("triangle_on_segment_sas: angle must be in (0, π)"))
    s = ccw ? 1 : -1
    if at === :a
        c = a + len * normalize(rotate(b, s * angle, a) - a)
    elseif at === :b
        c = b + len * normalize(rotate(a, -s * angle, b) - b)
    else
        throw(ArgumentError("triangle_on_segment_sas: at must be :a or :b, got $(repr(at))"))
    end
    return APTriangle(a, b, c)
end
"""
    triangle_on_segment_sas(s::APSegment, angle::Real, len::Real; at::Symbol=:a, ccw::Bool=true)
"""
function triangle_on_segment_sas(s::APSegment, angle::Real, len::Real; at::Symbol=:a, ccw::Bool=true)
    return triangle_on_segment_sas(s.p1, s.p2, angle, len; at=at, ccw=ccw)
end
"""
    triangle_on_segment_ssa(a::APPoint, b::APPoint, angle::Real, opposite_len::Real;
                            at::Symbol=:a, ccw::Bool=true, second_solution::Bool=false)

The triangle with base `[a, b]`, an angle at vertex `at` (`:a` or `:b`),
and the length `opposite_len` of the side *not* touching `at` (SSA: the
classically ambiguous case). Built via a ray from `at` (at `angle` from
the base) intersected with the circle of radius `opposite_len` centered
at the other base vertex ([`intersection`](@ref)`(::APRay,
::APCircle2)`), which can have 0, 1 or 2 real solutions:

  - none: throws an `ArgumentError` (`opposite_len` too short to reach
    the ray at all);
  - one (the ray is tangent to the circle): that triangle, `swap` has no
    effect;
  - two: returns the one with the larger angle at the *other* base
    vertex by default; pass `second_solution=true` for the other one.

`ccw=false` builds on the other side of the base, same as every other
`*_on_segment` constructor in this file.
"""
function triangle_on_segment_ssa(a::APPoint, b::APPoint, angle::Real, opposite_len::Real;
    at::Symbol=:a, ccw::Bool=true, second_solution::Bool=false)
    0 < angle < pi || throw(ArgumentError("triangle_on_segment_ssa: angle must be in (0, π)"))
    s = ccw ? 1 : -1
    if at === :a
        ray = APRay(a, rotate(b, s * angle, a))
        opp_center, base_vertex, other_vertex = b, b, a
    elseif at === :b
        ray = APRay(b, rotate(a, -s * angle, b))
        opp_center, base_vertex, other_vertex = a, a, b
    else
        throw(ArgumentError("triangle_on_segment_ssa: at must be :a or :b, got $(repr(at))"))
    end
    pts = intersection(ray, APCircle2(opp_center, opposite_len))
    isempty(pts) &&
        throw(ArgumentError("triangle_on_segment_ssa: opposite_len is too short to reach the ray from $at"))
    length(pts) == 1 && return APTriangle(a, b, pts[1])
    primary = angle_at(base_vertex, other_vertex, pts[1]) >= angle_at(base_vertex, other_vertex, pts[2]) ? pts[1] : pts[2]
    secondary = primary === pts[1] ? pts[2] : pts[1]
    return APTriangle(a, b, second_solution ? secondary : primary)
end
"""
    triangle_on_segment_ssa(s::APSegment, angle::Real, opposite_len::Real;
                            at::Symbol=:a, ccw::Bool=true, second_solution::Bool=false)
"""
function triangle_on_segment_ssa(s::APSegment, angle::Real, opposite_len::Real;
    at::Symbol=:a, ccw::Bool=true, second_solution::Bool=false)
    return triangle_on_segment_ssa(s.p1, s.p2, angle, opposite_len; at=at, ccw=ccw, second_solution=second_solution)
end
"""
    triangle_30_60_90_on_segment(a::APPoint, b::APPoint; ccw::Bool=true)

The right triangle with hypotenuse `[a, b]`, angle `30°` at `a` and `60°`
at `b`, built counterclockwise from `a` to `b` (`ccw=false` builds it on
the other side).
"""
triangle_30_60_90_on_segment(a::APPoint, b::APPoint; ccw::Bool=true) =
    triangle_on_segment(a, b, pi / 6, pi / 3; ccw=ccw)
"""
    triangle_30_60_90_on_segment(s::APSegment; ccw::Bool=true)
"""
function triangle_30_60_90_on_segment(s::APSegment; ccw::Bool=true)
    return triangle_30_60_90_on_segment(s.p1, s.p2; ccw=ccw)
end
"""
    isosceles_right_triangle_on_segment(a::APPoint, b::APPoint; ccw::Bool=true)

The isosceles right triangle with hypotenuse `[a, b]`, built via Thales'
theorem (the right-angle vertex lies on the circle with diameter `[a, b]`),
counterclockwise from `a` to `b` (`ccw=false` builds it on the other side).
"""
isosceles_right_triangle_on_segment(a::APPoint, b::APPoint; ccw::Bool=true) =
    triangle_on_segment(a, b, pi / 4, pi / 4; ccw=ccw)
"""
    isosceles_right_triangle_on_segment(s::APSegment; ccw::Bool=true)
"""
function isosceles_right_triangle_on_segment(s::APSegment; ccw::Bool=true)
    return isosceles_right_triangle_on_segment(s.p1, s.p2; ccw=ccw)
end
"""
    golden_triangle_on_segment(a::APPoint, b::APPoint; ccw::Bool=true)

The golden triangle with base `[a, b]`: isosceles with base angles `72°`
and apex angle `36°`, built counterclockwise from `a` to `b` (`ccw=false`
builds it on the other side).
"""
golden_triangle_on_segment(a::APPoint, b::APPoint; ccw::Bool=true) =
    triangle_on_segment(a, b, 2pi / 5, 2pi / 5; ccw=ccw)
"""
    golden_triangle_on_segment(s::APSegment; ccw::Bool=true)
"""
function golden_triangle_on_segment(s::APSegment; ccw::Bool=true)
    return golden_triangle_on_segment(s.p1, s.p2; ccw=ccw)
end
"""
    golden_gnomon_on_segment(a::APPoint, b::APPoint; ccw::Bool=true)

The golden gnomon with base `[a, b]`: isosceles with base angles `36°` and
apex angle `108°`, built counterclockwise from `a` to `b` (`ccw=false`
builds it on the other side).
"""
golden_gnomon_on_segment(a::APPoint, b::APPoint; ccw::Bool=true) =
    triangle_on_segment(a, b, pi / 5, pi / 5; ccw=ccw)
"""
    golden_gnomon_on_segment(s::APSegment; ccw::Bool=true)
"""
function golden_gnomon_on_segment(s::APSegment; ccw::Bool=true)
    return golden_gnomon_on_segment(s.p1, s.p2; ccw=ccw)
end
"""
    egyptian_triangle_on_segment(a::APPoint, b::APPoint; ccw::Bool=true)

The `3-4-5` right triangle with `[a, b]` as its "4" side: the right angle
is at `b`, and the "3" side `[b, c]` is perpendicular to `[a, b]` with
length `0.75 * distance(a, b)`, giving hypotenuse `[a, c]` the remaining
"5" side automatically. Built counterclockwise from `a` to `b` (`ccw=false`
builds it on the other side).
"""
egyptian_triangle_on_segment(a::APPoint, b::APPoint; ccw::Bool=true) =
    triangle_on_segment_sas(a, b, pi / 2, 0.75 * distance(a, b); at=:b, ccw=ccw)
"""
    egyptian_triangle_on_segment(s::APSegment; ccw::Bool=true)
"""
function egyptian_triangle_on_segment(s::APSegment; ccw::Bool=true)
    return egyptian_triangle_on_segment(s.p1, s.p2; ccw=ccw)
end
"""
    cheops_triangle_on_segment(a::APPoint, b::APPoint; ccw::Bool=true)

The isosceles triangle with base `[a, b]` whose sides are proportional to
`2`, `φ` and `φ` (the profile of the pyramid of Cheops): the two equal sides
have length `φ / 2 * distance(a, b)`. Built counterclockwise from `a` to `b`
(`ccw=false` builds it on the other side).
"""
cheops_triangle_on_segment(a::APPoint, b::APPoint; ccw::Bool=true) =
    isosceles_triangle_on_segment(a, b, golden / 2 * distance(a, b); ccw=ccw)
"""
    cheops_triangle_on_segment(s::APSegment; ccw::Bool=true)
"""
cheops_triangle_on_segment(s::APSegment; ccw::Bool=true) = cheops_triangle_on_segment(s.p1, s.p2; ccw=ccw)
"""
    golden_right_triangle_on_segment(a::APPoint, b::APPoint; ccw::Bool=true)

The right triangle with the right angle at `b`, whose two legs are in the
golden ratio: `[a, b]` is the long leg and `[b, c]` the short one, of length
`distance(a, b) / φ` (the half of a golden rectangle cut by a diagonal).
Built counterclockwise from `a` to `b` (`ccw=false` builds it on the other
side).
"""
golden_right_triangle_on_segment(a::APPoint, b::APPoint; ccw::Bool=true) =
    triangle_on_segment_sas(a, b, pi / 2, distance(a, b) / golden; at=:b, ccw=ccw)
"""
    golden_right_triangle_on_segment(s::APSegment; ccw::Bool=true)
"""
golden_right_triangle_on_segment(s::APSegment; ccw::Bool=true) = golden_right_triangle_on_segment(s.p1, s.p2; ccw=ccw)
