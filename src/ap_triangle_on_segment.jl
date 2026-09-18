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
function isosceles_triangle_on_segment(a::APPoint, b::APPoint, leg::Real; ccw::Bool=true)
    pts = intersection(APCircle2(a, leg), APCircle2(b, leg))
    length(pts) != 2 &&
        throw(ArgumentError("isosceles_triangle_on_segment: leg is too short to reach across [a, b]"))
    p1, p2 = pts
    on_ccw_side = cross2(b - a, p1 - a) > 0
    return APTriangle(a, b, on_ccw_side == ccw ? p1 : p2)
end
"""
    isosceles_triangle_on_segment(s::APSegment, leg::Real; ccw::Bool=true)
"""
function isosceles_triangle_on_segment(s::APSegment, leg::Real; ccw::Bool=true)
    return isosceles_triangle_on_segment(s.p1, s.p2, leg; ccw=ccw)
end
"""
    triangle_30_60_90_on_segment(a::APPoint, b::APPoint; ccw::Bool=true)

The right triangle with hypotenuse `[a, b]`, angle `30°` at `a` and `60°`
at `b`, built counterclockwise from `a` to `b` (`ccw=false` builds it on
the other side).
"""
function triangle_30_60_90_on_segment(a::APPoint, b::APPoint; ccw::Bool=true)
    s = ccw ? 1 : -1
    ray_a = APLine(a, rotate(b, s * pi / 6, a))
    ray_b = APLine(b, rotate(a, -s * pi / 3, b))
    return APTriangle(a, b, only(intersection(ray_a, ray_b)))
end
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
function isosceles_right_triangle_on_segment(a::APPoint, b::APPoint; ccw::Bool=true)
    x = midpoint(a, b)
    return APTriangle(a, b, rotate(b, ccw ? pi / 2 : -pi / 2, x))
end
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
function golden_triangle_on_segment(a::APPoint, b::APPoint; ccw::Bool=true)
    s = ccw ? 1 : -1
    ray_a = APLine(a, rotate(b, s * 2pi / 5, a))
    ray_b = APLine(b, rotate(a, -s * 2pi / 5, b))
    return APTriangle(a, b, only(intersection(ray_a, ray_b)))
end
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
function golden_gnomon_on_segment(a::APPoint, b::APPoint; ccw::Bool=true)
    s = ccw ? 1 : -1
    ray_a = APLine(a, rotate(b, s * pi / 5, a))
    ray_b = APLine(b, rotate(a, -s * pi / 5, b))
    return APTriangle(a, b, only(intersection(ray_a, ray_b)))
end
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
length `0.75 * distance(a, b)` — giving hypotenuse `[a, c]` the remaining
"5" side automatically. Built counterclockwise from `a` to `b` (`ccw=false`
builds it on the other side).
"""
function egyptian_triangle_on_segment(a::APPoint, b::APPoint; ccw::Bool=true)
    s = ccw ? 1 : -1
    n = rotate(a, -s * pi / 2, b)
    dir = (n - b) / norm(n - b)
    return APTriangle(a, b, b + dir * 0.75 * distance(a, b))
end
"""
    egyptian_triangle_on_segment(s::APSegment; ccw::Bool=true)
"""
function egyptian_triangle_on_segment(s::APSegment; ccw::Bool=true)
    return egyptian_triangle_on_segment(s.p1, s.p2; ccw=ccw)
end
