"""
    is_collinear(a::APPoint, b::APPoint, c::APPoint; atol=1e-9)

Whether points `a`, `b` and `c` lie on a common line.
"""
is_collinear(a::APPoint, b::APPoint, c::APPoint; atol=1e-9) =
    abs(cross2(b - a, c - a)) <= atol * norm(b - a) * norm(c - a)
"""
    is_coplanar(a::APPoint{3}, b::APPoint{3}, c::APPoint{3}, d::APPoint{3}; atol=1e-9)

Whether the four 3D points lie on a common plane (via the scalar triple
product `(b-a, c-a, d-a)`, which vanishes exactly when they're coplanar --
the 3D analogue of [`is_collinear`](@ref)).
"""
function is_coplanar(a::APPoint{3}, b::APPoint{3}, c::APPoint{3}, d::APPoint{3}; atol=1e-9)
    u, v, w = b - a, c - a, d - a
    scale = max(norm(u) * norm(v), norm(u) * norm(w), norm(v) * norm(w), 1.0)
    return abs(dot(cross3(u, v), w)) <= atol * scale
end
"""
    line_line_position(l1::APLine{3}, l2::APLine{3}; atol=1e-9)

How two 3D lines relate: `:coincident` (the same line), `:parallel`
(same direction, distinct), `:intersecting` (coplanar, cross at a single
point), or `:skew` (not coplanar at all -- the genuinely 3D case that never
arises for `APLine{2}`, where two non-parallel lines always meet).
"""
function line_line_position(l1::APLine{3}, l2::APLine{3}; atol=1e-9)
    d1, d2 = direction(l1), direction(l2)
    tol = sqrt(atol) * max(norm(d1) * norm(d2), 1.0)
    if norm(cross3(d1, d2)) <= tol
        return on_line(l2.p1, l1; atol=atol) ? :coincident : :parallel
    end
    return is_coplanar(l1.p1, l1.p2, l2.p1, l2.p2; atol=atol) ? :intersecting : :skew
end
"""
    on_line(p::APPoint, l::APLine; atol=1e-9)

Whether point `p` lies on the infinite line `l`.
"""
on_line(p::APPoint, l::APLine; atol=1e-9) = distance(p, l) <= sqrt(atol)
"""
    on_line(l::APLine; atol=1e-9)

`p -> on_line(p, l; atol=atol)` -- for composing with `filter`/`map`, e.g.
`filter(on_line(l), points)`.
"""
on_line(l::APLine; atol=1e-9) = p -> on_line(p, l; atol=atol)
"""
    on_segment(p::APPoint, s::APSegment; atol=1e-9)

Whether point `p` lies on the finite segment `s` (endpoints included).
"""
function on_segment(p::APPoint, s::APSegment; atol=1e-9)
    a, b = s[1], s[2]
    is_collinear(a, b, p; atol=atol) || return false
    ab2 = dot(b - a, b - a)
    ab2 <= atol^2 && return distance(p, a) <= atol
    t = dot(p - a, b - a) / ab2
    return -atol <= t <= 1 + atol
end
"""
    on_segment(s::APSegment; atol=1e-9)

`p -> on_segment(p, s; atol=atol)` -- see the single-argument [`on_line`](@ref).
"""
on_segment(s::APSegment; atol=1e-9) = p -> on_segment(p, s; atol=atol)
"""
    on_ray(p::APPoint, r::APRay; atol=1e-9)

Whether point `p` lies on the half-line `r` (the origin included).
"""
function on_ray(p::APPoint, r::APRay; atol=1e-9)
    a, b = r.origin, r.through
    is_collinear(a, b, p; atol=atol) || return false
    ab2 = dot(b - a, b - a)
    ab2 <= atol^2 && return distance(p, a) <= atol
    t = dot(p - a, b - a) / ab2
    return t >= -atol
end
"""
    on_ray(r::APRay; atol=1e-9)

`p -> on_ray(p, r; atol=atol)` -- see the single-argument [`on_line`](@ref).
"""
on_ray(r::APRay; atol=1e-9) = p -> on_ray(p, r; atol=atol)
Base.in(p::APPoint, s::APSegment) = on_segment(p, s)
Base.in(p::APPoint, l::APLine) = on_line(p, l)
Base.in(p::APPoint, r::APRay) = on_ray(p, r)
"""
    side_of_line(p::APPoint, l::APLine)

`+1` if `p` is to the left of `l` (oriented from `l.p1` to `l.p2`), `-1` if
to the right, `0` if `p` is on `l`.
"""
function side_of_line(p::APPoint, l::APLine)
    v = cross2(direction(l), p - l.p1)
    return v > 0 ? 1 : (v < 0 ? -1 : 0)
end
"""
    is_degenerate(t::APTriangle; atol=1e-9)

Whether the three vertices of `t` are collinear (zero area).
"""
is_degenerate(t::APTriangle; atol=1e-9) = is_collinear(t.a, t.b, t.c; atol=atol)
"""
    line_circle_position(l::APLine, c::APCircle2; atol=1e-9)

How `l` and `c` relate: `:disjoint` (no intersection), `:tangent` (touch at
exactly one point), or `:secant` (cross at two points).
"""
function line_circle_position(l::APLine, c::APCircle2; atol=1e-9)
    d = distance(c.center, l)
    tol = sqrt(atol) * max(c.r, 1.0)
    d > c.r + tol && return :disjoint
    abs(d - c.r) <= tol && return :tangent
    return :secant
end
"""
    circles_position(c1::APCircle2, c2::APCircle2; atol=1e-9)

How `c1` and `c2` relate, as one of: `:identical` (same center and
radius), `:concentric` (same center, different radius), `:disjoint_ext`
(too far apart to meet), `:tangent_ext` (externally tangent),
`:secant` (cross at two points), `:tangent_int` (internally tangent), or
`:disjoint_int` (one strictly inside the other, not touching).
"""
function circles_position(c1::APCircle2, c2::APCircle2; atol=1e-9)
    d = distance(c1.center, c2.center)
    tol = sqrt(atol) * max(c1.r, c2.r, 1.0)
    if d <= tol
        return isapprox(c1.r, c2.r; atol=tol) ? :identical : :concentric
    end
    rsum, rdiff = c1.r + c2.r, abs(c1.r - c2.r)
    d > rsum + tol && return :disjoint_ext
    abs(d - rsum) <= tol && return :tangent_ext
    d < rdiff - tol && return :disjoint_int
    abs(d - rdiff) <= tol && return :tangent_int
    return :secant
end
"""
    is_concyclic(a::APPoint, b::APPoint, c::APPoint, d::APPoint; atol=1e-9)

Whether the four points lie on a common circle (or are collinear, treated
as a degenerate "circle" of infinite radius). `a`, `b`, `c` must not be
collinear unless `d` is collinear with them too.
"""
function is_concyclic(a::APPoint, b::APPoint, c::APPoint, d::APPoint; atol=1e-9)
    if is_degenerate(APTriangle(a, b, c); atol=atol)
        return is_collinear(a, b, d; atol=atol)
    end
    t = APTriangle(a, b, c)
    cc, cr = circumcenter(t), circumradius(t)
    return abs(distance(cc, d) - cr) <= sqrt(atol) * max(cr, 1.0)
end
