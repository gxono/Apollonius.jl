# Constructors of objects from the data one usually has at hand: a direction, a diameter,
# a focus and a directrix, a center and a size, a ratio.

# ---- lines, rays and segments from a direction ----
"""
    APLine(p::APPoint, v::APVector)
    APLine(p::APPoint{2}, angle::Real)

The line through `p` with direction `v`, or with the direction that makes
`angle` radians with the positive `x` axis. The two defining points of the
result are `p` and `p + v` (or `p` and `p + (cos(angle), sin(angle))`).
"""
function APLine(p::APPoint{Dim}, v::APVector{Dim}) where {Dim}
    iszero(norm(v)) && throw(ArgumentError("APLine: the direction vector is zero"))
    return APLine(p, p + v)
end
APLine(p::APPoint{2}, angle::Real) = APLine(p, APVector(cos(angle), sin(angle)))
"""
    APRay(origin::APPoint, v::APVector)
    APRay(origin::APPoint{2}, angle::Real)

The ray from `origin` in the direction of `v`, or making `angle` radians
with the positive `x` axis. Its `through` point is `origin + v`, or
`origin + (cos(angle), sin(angle))`.
"""
function APRay(o::APPoint{Dim}, v::APVector{Dim}) where {Dim}
    iszero(norm(v)) && throw(ArgumentError("APRay: the direction vector is zero"))
    return APRay(o, o + v)
end
APRay(o::APPoint{2}, angle::Real) = APRay(o, APVector(cos(angle), sin(angle)))
"""
    APSegment(p::APPoint, v::APVector)
    APSegment(p::APPoint{2}, length::Real, angle::Real)

The segment from `p` to `p + v`, or the segment of the given `length` that
starts at `p` and makes `angle` radians with the positive `x` axis.
"""
APSegment(p::APPoint{Dim}, v::APVector{Dim}) where {Dim} = APSegment(p, p + v)
APSegment(p::APPoint{2}, len::Real, angle::Real) = APSegment(p, polar_point(len, angle, p))

# ---- points on lines, segments and curves ----
"""
    point_at_distance(l, d)

The point of a line, ray or segment at distance `d` from its first defining
point (`l.p1`, or the `origin` of a ray), measured along its direction.
Unlike [`point_on`](@ref), which takes a fraction of `distance(l.p1, l.p2)`,
`d` is a length. A negative `d` goes the other way.
"""
point_at_distance(l::Union{APLine,APSegment}, d::Real) = l.p1 + d * normalize(l.p2 - l.p1)
point_at_distance(r::APRay, d::Real) = r.origin + d * normalize(r.through - r.origin)
"""
    divide_segment(s::APSegment, n::Integer)
    divide_segment(s::APSegment, m::Real, n::Real)

With an integer `n`, the `n - 1` points that cut `s` into `n` equal parts,
in order from `s.p1`. With two numbers, the point `P` that divides `s` in
the ratio `m : n`, `|s.p1 P| : |P s.p2| = m : n`. A negative `n` gives the
external division, the point outside the segment where the ratio is `m : |n|`.
"""
function divide_segment(s::APSegment, n::Integer)
    n >= 2 || throw(ArgumentError("divide_segment: n must be at least 2"))
    return [point_on(s, k / n) for k in 1:n-1]
end
function divide_segment(s::APSegment, m::Real, n::Real)
    m + n != 0 || throw(ArgumentError("divide_segment: m + n must not be zero"))
    return point_on(s, m / (m + n))
end
"""
    equally_spaced_points(obj, n; start=0.0)

`n` points spaced evenly along `obj`:

* a [`APSegment`](@ref) or a [`APCircularArc2`](@ref): both ends and `n - 2` between, so `n >= 2`, evenly by length;
* an [`APCircle2`](@ref): `n` points at angles `start + 2πk/n`, evenly by arc length;
* an [`APEllipse2`](@ref): `n` points at parameters `start + 2πk/n`, evenly by parameter, not by arc length.

| Keyword | Default | Meaning |
|:--------|:--------|:--------|
| `start` | `0.0` | angle or parameter of the first point, for the circle and the ellipse |
"""
function equally_spaced_points(s::APSegment, n::Integer)
    n >= 2 || throw(ArgumentError("equally_spaced_points: n must be at least 2"))
    return [point_on(s, k / (n - 1)) for k in 0:n-1]
end
function equally_spaced_points(arc::APCircularArc2, n::Integer)
    n >= 2 || throw(ArgumentError("equally_spaced_points: n must be at least 2"))
    return [point_on(arc, k / (n - 1)) for k in 0:n-1]
end
function equally_spaced_points(c::APCircle2, n::Integer; start::Real=0.0)
    n >= 1 || throw(ArgumentError("equally_spaced_points: n must be at least 1"))
    return [point_on(c, start + 2pi * k / n) for k in 0:n-1]
end
function equally_spaced_points(e::APEllipse2, n::Integer; start::Real=0.0)
    n >= 1 || throw(ArgumentError("equally_spaced_points: n must be at least 1"))
    return [point_on(e, start + 2pi * k / n) for k in 0:n-1]
end

# ---- angles ----
"""
    angle_with_measure(vertex::APPoint, p::APPoint, θ::Real)

The [`APAngle2`](@ref) with its first ray through `p` and its second ray
`θ` radians counterclockwise from it. A negative `θ` opens the angle
clockwise.
"""
angle_with_measure(vertex::APPoint{2}, p::APPoint{2}, θ::Real) = APAngle2(vertex, p, rotate(p, θ, vertex))
"""
    APAngle2(l1::APLine, l2::APLine)

The angle at the point where two lines cross, measured counterclockwise from
the direction of `l1` to the direction of `l2`, so it is more than a straight
angle when `l2` is clockwise from `l1`: swap the lines to get the other one.
Throws an `ArgumentError` for parallel lines.
"""
function APAngle2(l1::APLine{2}, l2::APLine{2})
    pts = intersection(l1, l2)
    isempty(pts) && throw(ArgumentError("APAngle2: the lines are parallel or coincide"))
    v = only(pts)
    return APAngle2(v, v + normalize(direction(l1)), v + normalize(direction(l2)))
end

# ---- rounded corners ----
"""
    fillet(a::APPoint, v::APPoint, b::APPoint, r::Real)

Round the corner at `v` of the path `a → v → b` with an arc of radius `r`
tangent to both sides. Returns a `NamedTuple` `(arc, center, t1, t2)`: the
[`APCircularArc2`](@ref) that faces the corner, the center of the circle, and
the two points where it touches the sides (`t1` on `[v, a]`, `t2` on `[v, b]`).
The arc runs counterclockwise, so its endpoints are `t1` and `t2` in that
order when the corner turns left, and `t2` and `t1` when it turns right.
Throws an `ArgumentError` if the three points are collinear or `r` is too
large for the sides.
"""
function fillet(a::APPoint{2}, v::APPoint{2}, b::APPoint{2}, r::Real)
    r > 0 || throw(ArgumentError("fillet: the radius must be positive"))
    θ = angle_measure_at(v, a, b)
    (θ > 1e-12 && θ < pi - 1e-12) || throw(ArgumentError("fillet: the three points are collinear"))
    t = r / tan(θ / 2)
    (t <= distance(v, a) && t <= distance(v, b)) || throw(ArgumentError("fillet: the radius is too large for the sides"))
    u1, u2 = normalize(a - v), normalize(b - v)
    t1, t2 = v + t * u1, v + t * u2
    center = v + (r / sin(θ / 2)) * normalize(u1 + u2)
    circle = APCircle2(center, r)
    arc = APCircularArc2(circle, t1, t2)
    measure(arc) < pi || (arc = APCircularArc2(circle, t2, t1))
    return (arc=arc, center=center, t1=t1, t2=t2)
end
"""
    round_corners(pg::APPolygon, r::Real)
    round_corners(pl::APPolyline2, r::Real)

Round every corner of a convex polygon, or every interior corner of a
polyline, with arcs of radius `r`. A polygon gives an
[`APCurvilinearNgon2`](@ref) (its vertices are listed counterclockwise, so a
clockwise one is reversed). A polyline gives an
[`APCurvilinearPolyline2`](@ref); all its interior corners must turn the
same way, and when they turn right it is traversed from the end so that they
turn left, which is the direction an arc can run. Throws an `ArgumentError`
if a corner is collinear, a corner turns the other way, or `r` is too large
for a side.
"""
function round_corners(pg::APPolygon{2}, r::Real)
    is_convex(pg) || throw(ArgumentError("round_corners: only convex polygons can be rounded"))
    vs = collect(vertices(pg))
    area2 = sum(cross2(vs[i], vs[mod1(i + 1, length(vs))]) for i in eachindex(vs))
    area2 < 0 && reverse!(vs)
    n = length(vs)
    fs = [fillet(vs[mod1(i - 1, n)], vs[i], vs[mod1(i + 1, n)], r) for i in 1:n]
    for i in 1:n
        j = mod1(i + 1, n)
        distance(vs[i], fs[i].t2) + distance(vs[j], fs[j].t1) <= distance(vs[i], vs[j]) + 1e-12 ||
            throw(ArgumentError("round_corners: the radius is too large for a side"))
    end
    sides = APSide{Float64}[]
    for i in 1:n
        push!(sides, fs[i].arc)
        push!(sides, APSegment(fs[i].t2, fs[mod1(i + 1, n)].t1))
    end
    return APCurvilinearNgon2(sides)
end
function round_corners(pl::APPolyline2, r::Real)
    vs = collect(vertices(pl))
    length(vs) >= 3 || throw(ArgumentError("round_corners: a polyline needs an interior corner"))
    turn(i) = cross2(vs[i] - vs[i-1], vs[i+1] - vs[i])
    turns = [turn(i) for i in 2:length(vs)-1]
    all(>(0), turns) || all(<(0), turns) || throw(ArgumentError("round_corners: the interior corners must all turn the same way"))
    turns[1] < 0 && reverse!(vs)
    n = length(vs)
    fs = [fillet(vs[i-1], vs[i], vs[i+1], r) for i in 2:n-1]
    sides = APSide{Float64}[]
    start = vs[1]
    for (k, f) in enumerate(fs)
        push!(sides, APSegment(start, f.t1))
        push!(sides, f.arc)
        start = f.t2
    end
    push!(sides, APSegment(start, vs[n]))
    return APCurvilinearPolyline2(sides)
end

# ---- tangent and normal lines ----
_on_curve_tol(atol, scale) = sqrt(atol) * max(scale, 1.0)
"""
    tangent_line(curve, p::APPoint; atol=1e-9)

The tangent line to `curve` at its point `p`, for a circle, an ellipse, a
hyperbola, a parabola or an arc of any of them. For a line, a ray or a
segment it is the line itself. Throws an `ArgumentError` if `p` is not on
the curve (or, for an arc, not on the arc). See also [`normal_line`](@ref),
and [`tangent_lines`](@ref) for the tangents from a point off the curve.
"""
function tangent_line(c::APCircle2, p::APPoint; atol=1e-9)
    abs(distance(p, c.center) - c.r) <= _on_curve_tol(atol, c.r) || throw(ArgumentError("tangent_line: the point is not on the circle"))
    return perpendicular_through(APLine(c.center, p), p)
end
function tangent_line(e::APEllipse2, p::APPoint; atol=1e-9)
    is_on_ellipse(p, e; atol=atol) || throw(ArgumentError("tangent_line: the point is not on the ellipse"))
    return polar_line(e, p; atol=atol)
end
function tangent_line(h::APHyperbola2, p::APPoint; atol=1e-9)
    is_on_hyperbola(p, h; atol=atol) || throw(ArgumentError("tangent_line: the point is not on the hyperbola"))
    return polar_line(h, p; atol=atol)
end
function tangent_line(par::APParabola2, p::APPoint; atol=1e-9)
    is_on_parabola(p, par; atol=atol) || throw(ArgumentError("tangent_line: the point is not on the parabola"))
    return polar_line(par, p; atol=atol)
end
_underlying_conic(arc::APCircularArc2) = arc.circle
_underlying_conic(arc::APEllipticArc2) = arc.ellipse
_underlying_conic(arc::APHyperbolicArc2) = arc.hyperbola
_underlying_conic(arc::APParabolicArc2) = arc.parabola
function tangent_line(arc::APConicArc2, p::APPoint; atol=1e-9)
    in(p, arc; atol=atol) || throw(ArgumentError("tangent_line: the point is not on the arc"))
    return tangent_line(_underlying_conic(arc), p; atol=atol)
end
function tangent_line(l::Union{APLine,APSegment,APRay}, p::APPoint; atol=1e-9)
    p in l || throw(ArgumentError("tangent_line: the point is not on the line"))
    return APLine(l)
end
"""
    normal_line(curve, p::APPoint; atol=1e-9)

The line through the point `p` of `curve` perpendicular to its tangent
there: [`perpendicular_through`](@ref)`(tangent_line(curve, p), p)`. It
accepts the same curves as [`tangent_line`](@ref).
"""
normal_line(curve, p::APPoint; atol=1e-9) = perpendicular_through(tangent_line(curve, p; atol=atol), p)

# ---- quadrilaterals and other polygons ----
"""
    regular_polygon_on_segment(a::APPoint, b::APPoint, n::Integer; ccw=true)

The regular `n`-gon with side `[a, b]`, built counterclockwise from `a` to
`b` (`ccw=false` builds it on the other side). It is an
[`APStraightNgon`](@ref), whose vertices start at `a` and `b`. For a polygon
given by its center and one vertex, see [`regular_polygon`](@ref).

| Keyword | Default | Meaning |
|:--------|:--------|:--------|
| `ccw` | `true` | `true` puts the polygon on the left of `a → b`, `false` on the right |
"""
function regular_polygon_on_segment(a::APPoint{2}, b::APPoint{2}, n::Integer; ccw::Bool=true)
    n >= 3 || throw(ArgumentError("regular_polygon_on_segment needs n >= 3"))
    s = distance(a, b)
    left = orthogonal(normalize(b - a))
    center = midpoint(a, b) + (ccw ? 1 : -1) * (s / (2 * tan(pi / n))) * left
    step = ccw ? 2pi / n : -2pi / n
    return APStraightNgon([rotate(a, k * step, center) for k in 0:n-1])
end
"""
    rhombus_on_segment(a::APPoint, b::APPoint, angle::Real; ccw=true)

The rhombus with side `[a, b]` whose angle at `a` is `angle` (in `(0, π)`,
radians), built counterclockwise from `a` to `b` (`ccw=false` builds it on the
other side). With `angle = π/2` it is the square of [`square_on_segment`](@ref).

| Keyword | Default | Meaning |
|:--------|:--------|:--------|
| `ccw` | `true` | `true` puts the rhombus on the left of `a → b`, `false` on the right |
"""
function rhombus_on_segment(a::APPoint{2}, b::APPoint{2}, angle::Real; ccw::Bool=true)
    0 < angle < pi || throw(ArgumentError("rhombus_on_segment: the angle must be in (0, π)"))
    w = rotate(b, ccw ? angle : -angle, a) - a
    return APQuadrilateral(a, b, b + w, a + w)
end
"""
    square_from_diagonal(a::APPoint, c::APPoint; ccw=true)

The square with diagonal `[a, c]`, with vertices `a`, `b`, `c`, `d` in
counterclockwise order (`ccw=false` lists them clockwise).

| Keyword | Default | Meaning |
|:--------|:--------|:--------|
| `ccw` | `true` | `true` lists the vertices counterclockwise, `false` clockwise |
"""
function square_from_diagonal(a::APPoint{2}, c::APPoint{2}; ccw::Bool=true)
    m = midpoint(a, c)
    b, d = rotate(a, pi / 2, m), rotate(a, -pi / 2, m)
    return ccw ? APQuadrilateral(a, b, c, d) : APQuadrilateral(a, d, c, b)
end
"""
    rectangle_from_diagonal(a::APPoint, c::APPoint, angle::Real; ccw=true)

The rectangle with diagonal `[a, c]` in which the diagonal makes `angle`
(radians, in `(0, π/2)`) with the side that starts at `a`. The vertices `a`,
`b`, `c`, `d` are counterclockwise for `ccw=true` (`b` on the right of `a → c`),
and clockwise for `ccw=false`. With `angle = π/4` it is a square.

| Keyword | Default | Meaning |
|:--------|:--------|:--------|
| `ccw` | `true` | `true` lists the vertices counterclockwise, `false` clockwise |
"""
function rectangle_from_diagonal(a::APPoint{2}, c::APPoint{2}, angle::Real; ccw::Bool=true)
    0 < angle < pi / 2 || throw(ArgumentError("rectangle_from_diagonal: the angle must be in (0, π/2)"))
    diag = c - a
    b = a + (norm(diag) * cos(angle)) * normalize(rotate(diag, ccw ? -angle : angle))
    d = a + (c - b)
    return ccw ? APQuadrilateral(a, b, c, d) : APQuadrilateral(a, d, c, b)
end
"""
    rectangle_with_center(center::APPoint, width::Real, height::Real; angle=0.0)

The rectangle with the given center and size, turned `angle`
radians counterclockwise about its center. The vertices are counterclockwise,
starting at the lower left one before turning.

| Keyword | Default | Meaning |
|:--------|:--------|:--------|
| `angle` | `0.0` | rotation about the center, in radians |
"""
function rectangle_with_center(center::APPoint{2}, width::Real, height::Real; angle::Real=0.0)
    corners = (APVector(-width / 2, -height / 2), APVector(width / 2, -height / 2), APVector(width / 2, height / 2), APVector(-width / 2, height / 2))
    v = [center + rotate(u, angle) for u in corners]
    return APQuadrilateral(v[1], v[2], v[3], v[4])
end
"""
    square_with_center(center::APPoint, side::Real; angle=0.0)

The square with the given center and side, turned `angle` radians
counterclockwise about its center. It is [`rectangle_with_center`](@ref)
with equal width and height.

| Keyword | Default | Meaning |
|:--------|:--------|:--------|
| `angle` | `0.0` | rotation about the center, in radians |
"""
square_with_center(center::APPoint{2}, side::Real; angle::Real=0.0) = rectangle_with_center(center, side, side; angle=angle)
"""
    isosceles_trapezoid_on_segment(a::APPoint, b::APPoint, top::Real, height::Real; ccw=true)

The trapezoid with base `[a, b]`, a parallel side of length `top` at distance
`height`, and vertices `a`, `b`, `c`, `d` counterclockwise (`ccw=false` builds it
on the other side of the base). The top side is centered over the base, so the
legs are equal. See also [`right_trapezoid_on_segment`](@ref).

| Keyword | Default | Meaning |
|:--------|:--------|:--------|
| `ccw` | `true` | `true` puts the trapezoid on the left of `a → b`, `false` on the right |
"""
function isosceles_trapezoid_on_segment(a::APPoint{2}, b::APPoint{2}, top::Real, height::Real; ccw::Bool=true)
    top > 0 && height > 0 || throw(ArgumentError("isosceles_trapezoid_on_segment: top and height must be positive"))
    u = normalize(b - a)
    n = (ccw ? 1 : -1) * height * orthogonal(u)
    m = midpoint(a, b)
    return APQuadrilateral(a, b, m + (top / 2) * u + n, m - (top / 2) * u + n)
end
"""
    right_trapezoid_on_segment(a::APPoint, b::APPoint, top::Real, height::Real; ccw=true)

The trapezoid with base `[a, b]`, a parallel side of length `top` at distance
`height`, and vertices `a`, `b`, `c`, `d` counterclockwise (`ccw=false` builds it
on the other side of the base). The leg `[d, a]` is perpendicular to the base, so
the angles at `a` and `d` are right angles.

| Keyword | Default | Meaning |
|:--------|:--------|:--------|
| `ccw` | `true` | `true` puts the trapezoid on the left of `a → b`, `false` on the right |
"""
function right_trapezoid_on_segment(a::APPoint{2}, b::APPoint{2}, top::Real, height::Real; ccw::Bool=true)
    top > 0 && height > 0 || throw(ArgumentError("right_trapezoid_on_segment: top and height must be positive"))
    u = normalize(b - a)
    d = a + (ccw ? 1 : -1) * height * orthogonal(u)
    return APQuadrilateral(a, b, d + top * u, d)
end
"""
    kite_on_diagonal(a::APPoint, c::APPoint, t::Real, half_width::Real)

The kite with the diagonal `[a, c]` as its axis of symmetry. The other two
vertices are at distance `half_width` on each side of the point at the
fraction `t` of the way from `a` to `c` (see [`point_on`](@ref)), so the
kite is convex for `0 < t < 1`. The vertices `a`, `b`, `c`, `d` are counterclockwise.
"""
function kite_on_diagonal(a::APPoint{2}, c::APPoint{2}, t::Real, half_width::Real)
    half_width > 0 || throw(ArgumentError("kite_on_diagonal: half_width must be positive"))
    m = point_on(APSegment(a, c), t)
    w = half_width * orthogonal(normalize(c - a))
    return APQuadrilateral(a, m - w, c, m + w)
end
"""
    star_polygon(center::APPoint, vertex::APPoint, n::Integer, k::Integer)

The star polygon `{n/k}`: the `n` vertices of the regular `n`-gon around
`center` that has `vertex` as one of them, joined every `k`-th one. `n` and `k`
must have no common divisor, and `2 <= k < n/2`. It is a self-intersecting
[`APStraightNgon`](@ref); `{5/2}` is the pentagram.
"""
function star_polygon(center::APPoint{2}, vertex::APPoint{2}, n::Integer, k::Integer)
    (n >= 5 && 2 <= k && 2k < n && gcd(n, k) == 1) || throw(ArgumentError("star_polygon: needs 2 <= k < n/2 and gcd(n, k) = 1"))
    return APStraightNgon([rotate(vertex, 2pi * k * j / n, center) for j in 0:n-1])
end
"""
    offset_polygon(pg::APPolygon, d::Real)

The polygon parallel to a polygon with straight sides, at distance `d`:
outward for `d > 0` and inward for `d < 0`. Each side moves along its normal
and every new vertex is where two neighbouring moved sides meet. It is an
[`APStraightNgon`](@ref) with the same number of vertices. An inward offset
larger than the polygon, or any offset of a concave one, can cross itself.
"""
function offset_polygon(pg::APPolygon{2}, d::Real)
    vs = collect(vertices(pg))
    area2 = sum(cross2(vs[i], vs[mod1(i + 1, length(vs))]) for i in eachindex(vs))
    area2 < 0 && reverse!(vs)
    n = length(vs)
    lines = map(1:n) do i
        u = normalize(vs[mod1(i + 1, n)] - vs[i])
        shift = -d * orthogonal(u)
        APLine(vs[i] + shift, vs[mod1(i + 1, n)] + shift)
    end
    out = map(1:n) do i
        pts = intersection(lines[mod1(i - 1, n)], lines[i])
        isempty(pts) ? vs[i] + (-d * orthogonal(normalize(vs[mod1(i + 1, n)] - vs[i]))) : only(pts)
    end
    return APStraightNgon(out)
end
"""
    circumcircle(pg::APQuadrilateral)
    circumcircle(pg::APStraightNgon)

The circle through all the vertices of a polygon. It exists only when they
are concyclic (a cyclic quadrilateral, a regular polygon), and throws an
`ArgumentError` otherwise. For a triangle see [`circumcircle`](@ref)`(::APTriangle)`.
"""
function circumcircle(pg::Union{APQuadrilateral{2},APStraightNgon{2}}; atol=1e-9)
    vs = collect(vertices(pg))
    c = APCircle2(vs[1], vs[2], vs[3])
    all(v -> abs(distance(v, c.center) - c.r) <= _on_curve_tol(atol, c.r), vs) ||
        throw(ArgumentError("circumcircle: the vertices are not on a circle"))
    return c
end
"""
    incircle(pg::APQuadrilateral)
    incircle(pg::APStraightNgon)

The circle inside a convex polygon that touches all its sides. It exists only
for tangential polygons (a quadrilateral with `a + c = b + d` for its sides,
a regular polygon), and throws an `ArgumentError` otherwise. For a triangle
see [`incircle`](@ref)`(::APTriangle)`.
"""
function incircle(pg::Union{APQuadrilateral{2},APStraightNgon{2}}; atol=1e-9)
    vs = collect(vertices(pg))
    n = length(vs)
    is_convex(pg) || throw(ArgumentError("incircle: the polygon must be convex"))
    bis(i) = APLine(vs[i], vs[i] + normalize(normalize(vs[mod1(i - 1, n)] - vs[i]) + normalize(vs[mod1(i + 1, n)] - vs[i])))
    pts = intersection(bis(1), bis(2))
    isempty(pts) && throw(ArgumentError("incircle: the polygon has no inscribed circle"))
    center = only(pts)
    r = distance(center, APLine(vs[1], vs[2]))
    all(i -> abs(distance(center, APLine(vs[i], vs[mod1(i + 1, n)])) - r) <= _on_curve_tol(atol, r), 1:n) ||
        throw(ArgumentError("incircle: the polygon has no inscribed circle"))
    return APCircle2(center, r)
end
"""
    circumscribed_triangle(c::APCircle2, p1::APPoint, p2::APPoint, p3::APPoint)

The triangle whose sides touch the circle `c` at the three points `p1`, `p2`
and `p3` of it, each side lying on the tangent at its point. Vertex `i` is
opposite the side that touches at `p_i`, so `c` is the incircle of the result
when the points are not in a half circle. Throws an `ArgumentError` if two
of the tangents are parallel.
"""
function circumscribed_triangle(c::APCircle2, p1::APPoint, p2::APPoint, p3::APPoint)
    t1, t2, t3 = tangent_line(c, p1), tangent_line(c, p2), tangent_line(c, p3)
    corner(la, lb) = (pts = intersection(la, lb); isempty(pts) ? throw(ArgumentError("circumscribed_triangle: two tangents are parallel")) : only(pts))
    return APTriangle(corner(t2, t3), corner(t3, t1), corner(t1, t2))
end

# ---- circles and arcs ----
"""
    offset_circle(c::APCircle2, d::Real)

The circle concentric with `c` whose radius is `c.r + d`: outside for `d > 0`
and inside for `d < 0`. The counterpart of [`offset_line`](@ref). Throws an
`ArgumentError` unless the new radius is positive.
"""
function offset_circle(c::APCircle2, d::Real)
    c.r + d > 0 || throw(ArgumentError("offset_circle: the new radius must be positive"))
    return APCircle2(c.center, c.r + d)
end
"""
    chord(c::APCircle2, θ1::Real, θ2::Real)

The [`APSegment`](@ref) between the points of the circle at the polar angles
`θ1` and `θ2` (radians), from the first to the second.
"""
chord(c::APCircle2, θ1::Real, θ2::Real) = APSegment(point_on(c, θ1), point_on(c, θ2))
"""
    diameter(c::APCircle2, angle::Real=0.0)

The diameter of the circle through the point at the polar `angle` (radians) and
its [`antipode`](@ref), as an [`APSegment`](@ref) from the first to the second.
See also [`chord`](@ref).
"""
diameter(c::APCircle2, angle::Real=0.0) = chord(c, angle, angle + pi)
"""
    arc_through_points(a::APPoint, b::APPoint, c::APPoint)

The circular arc from `a` to `c` that passes through `b`. Arcs run
counterclockwise, so when `a → b → c` goes clockwise the result has `c` as its
first point and `a` as its second. Throws an `ArgumentError` for collinear points.
"""
function arc_through_points(a::APPoint{2}, b::APPoint{2}, c::APPoint{2})
    is_collinear(a, b, c) && throw(ArgumentError("arc_through_points: the three points are collinear"))
    circle = APCircle2(a, b, c)
    ang(p) = atan(p[2] - circle.center[2], p[1] - circle.center[1])
    ccw = mod(ang(b) - ang(a), 2pi) < mod(ang(c) - ang(a), 2pi)
    return ccw ? APCircularArc2(circle, a, c) : APCircularArc2(circle, c, a)
end
"""
    arc_with_radius(a::APPoint, b::APPoint, r::Real; large=false)

The circular arc of radius `r` that goes counterclockwise from `a` to `b`. Two
circles of that radius pass through both points, and the arc is the short one
of the circle whose center is on the left of `a → b`. With `large=true` it is
the long arc of the other circle, that is, the complement of the arc from `b`
to `a`. Throws an `ArgumentError` if `r` is less than half of `distance(a, b)`.

| Keyword | Default | Meaning |
|:--------|:--------|:--------|
| `large` | `false` | `true` returns the arc of more than half a turn |
"""
function arc_with_radius(a::APPoint{2}, b::APPoint{2}, r::Real; large::Bool=false)
    d = distance(a, b)
    r >= d / 2 || throw(ArgumentError("arc_with_radius: the radius is less than half the distance between the points"))
    h = sqrt(max(r^2 - d^2 / 4, 0.0))
    center = midpoint(a, b) + (large ? -h : h) * orthogonal(normalize(b - a))
    return APCircularArc2(APCircle2(center, r), a, b)
end
"""
    tangent_circle_at_point(l::APLine, p::APPoint, q::APPoint)

The circle tangent to the line `l` at its point `p` and through the point `q`.
Throws an `ArgumentError` if `p` is not on `l`, or `q` is on `l`. For
circles tangent to a line that pass through two points, see
[`tangent_circles`](@ref). With a radius instead of a point, see
[`tangent_circles_at_point`](@ref).
"""
function tangent_circle_at_point(l::APLine{2}, p::APPoint{2}, q::APPoint{2})
    is_on_line(p, l) || throw(ArgumentError("tangent_circle_at_point: p is not on the line"))
    is_on_line(q, l) && throw(ArgumentError("tangent_circle_at_point: q is on the line, no circle is tangent there"))
    center = only(intersection(perpendicular_through(l, p), perpendicular_bisector(p, q)))
    return APCircle2(center, distance(center, p))
end
"""
    tangent_circles_at_point(l::APLine, p::APPoint, r::Real)

The two circles of radius `r` tangent to the line `l` at its point `p`, one on
each side, as a `Vector`. Throws an `ArgumentError` if `p` is not on `l` or `r`
is not positive.
"""
function tangent_circles_at_point(l::APLine{2}, p::APPoint{2}, r::Real)
    is_on_line(p, l) || throw(ArgumentError("tangent_circles_at_point: p is not on the line"))
    r > 0 || throw(ArgumentError("tangent_circles_at_point: the radius must be positive"))
    n = orthogonal(normalize(direction(l)))
    return [APCircle2(p + r * n, r), APCircle2(p - r * n, r)]
end

# ---- maps ----
"""
    similarity_map(k::Real, angle::Real, center::APPoint=APPoint(0.0, 0.0))
    similarity_map(p1 => q1, p2 => q2)

The similarity that scales by `k` and turns by `angle` radians about `center`
(the origin by default), or the unique one that sends `p1` to `q1` and `p2` to
`q2`. It is an [`APAffineMap`](@ref) that keeps circles as circles (see
[`APAffineMap`](@ref)`(::APCircle2)`). The two points of each pair must differ.
"""
function similarity_map(k::Real, angle::Real, center::APPoint{2}=APPoint(0.0, 0.0))
    c, s = k * cos(angle), k * sin(angle)
    return APAffineMap(c, -s, s, c, center[1] - (c * center[1] - s * center[2]), center[2] - (s * center[1] + c * center[2]))
end
function similarity_map(pq1::Pair{<:APPoint{2},<:APPoint{2}}, pq2::Pair{<:APPoint{2},<:APPoint{2}})
    p1, q1 = pq1
    p2, q2 = pq2
    distance(p1, p2) > 0 || throw(ArgumentError("similarity_map: the two source points must differ"))
    z(p) = complex(p[1], p[2])
    α = (z(q2) - z(q1)) / (z(p2) - z(p1))
    β = z(q1) - α * z(p1)
    return APAffineMap(real(α), -imag(α), imag(α), real(α), real(β), imag(β))
end
"""
    scaling_map(sx::Real, sy::Real, center::APPoint=APPoint(0.0, 0.0))

The [`APAffineMap`](@ref) that scales by `sx` along the `x` direction and by
`sy` along `y` about `center`. With `sx == sy` it is [`homothety_map`](@ref);
otherwise it turns circles into ellipses. See also [`shear_map`](@ref).
"""
scaling_map(sx::Real, sy::Real, center::APPoint{2}=APPoint(0.0, 0.0)) =
    APAffineMap(sx, 0.0, 0.0, sy, center[1] * (1 - sx), center[2] * (1 - sy))
"""
    shear_map(kx::Real, ky::Real=0.0, center::APPoint=APPoint(0.0, 0.0))

The [`APAffineMap`](@ref) that shears: a point `(x, y)` moves to
`(x + kx·y, y + ky·x)` in coordinates relative to `center`. It turns circles
into ellipses.
"""
shear_map(kx::Real, ky::Real=0.0, center::APPoint{2}=APPoint(0.0, 0.0)) =
    APAffineMap(1.0, kx, ky, 1.0, -(center[1] + kx * center[2]) + center[1], -(ky * center[1] + center[2]) + center[2])

# ---- conics ----
"""
    conic_with_focus(focus::APPoint, directrix::APLine, e::Real; atol=1e-9)

The conic whose points are at a distance from `focus` that is `e` times their
distance to `directrix`: an [`APEllipse2`](@ref) for `e < 1`, an
[`APParabola2`](@ref) for `e = 1` and an [`APHyperbola2`](@ref) for `e > 1`. The
focus must not be on the directrix. For a circle, the limit `e = 0`, use
[`APCircle2`](@ref).

| Keyword | Default | Meaning |
|:--------|:--------|:--------|
| `atol` | `1e-9` | how close `e` must be to `1` to give a parabola |
"""
function conic_with_focus(focus::APPoint{2}, directrix::APLine{2}, e::Real; atol=1e-9)
    e > 0 || throw(ArgumentError("conic_with_focus: the eccentricity must be positive"))
    foot = projection(focus, directrix)
    p = distance(focus, foot)
    p > 0 || throw(ArgumentError("conic_with_focus: the focus is on the directrix"))
    abs(e - 1) <= atol && return APParabola2(focus, directrix)
    u = normalize(foot - focus)
    ang = atan(u[2], u[1])
    if e < 1
        a = e * p / (1 - e^2)
        return APEllipse2(focus - (a * e) * u, a, a * sqrt(1 - e^2), ang)
    end
    a = e * p / (e^2 - 1)
    return APHyperbola2(focus + (a * e) * u, a, a * sqrt(e^2 - 1), ang)
end
"""
    ellipse_with_axis(center::APPoint, vertex::APPoint, p::APPoint)

The ellipse centered at `center` that has `vertex` as the end of one of its
axes and passes through `p`. The axis along `[center, vertex]` has semi-length
`distance(center, vertex)`; the other is found from `p`. The point must be
strictly inside the strip that the two tangents at the ends of the axis limit,
and off the axis.
"""
function ellipse_with_axis(center::APPoint{2}, vertex::APPoint{2}, p::APPoint{2})
    a = distance(center, vertex)
    u = normalize(vertex - center)
    v = p - center
    x, y = dot(v, u), dot(v, orthogonal(u))
    abs(x) < a && abs(y) > 0 || throw(ArgumentError("ellipse_with_axis: the point cannot be on an ellipse with that axis"))
    return APEllipse2(center, a, abs(y) / sqrt(1 - (x / a)^2), atan(u[2], u[1]))
end
"""
    hyperbola_with_asymptotes(l1::APLine, l2::APLine, p::APPoint)

The hyperbola with the lines `l1` and `l2` as asymptotes that passes through
`p`. The center is where the asymptotes cross, and the transverse axis is the
bisector of the two lines that lies in the angle that contains `p`. Throws an
`ArgumentError` for parallel lines, or if `p` is on an asymptote or the center.
"""
function hyperbola_with_asymptotes(l1::APLine{2}, l2::APLine{2}, p::APPoint{2})
    pts = intersection(l1, l2)
    isempty(pts) && throw(ArgumentError("hyperbola_with_asymptotes: the asymptotes are parallel"))
    c = only(pts)
    d1, d2 = normalize(direction(l1)), normalize(direction(l2))
    e1 = normalize(d1 + d2)
    v = p - c
    for u in (e1, orthogonal(e1))
        cosφ = abs(dot(u, d1))
        cosφ < 1e-12 && continue
        tan2 = (1 - cosφ^2) / cosφ^2
        x, y = dot(v, u), dot(v, orthogonal(u))
        a2 = x^2 - y^2 / tan2
        a2 > 0 && return APHyperbola2(c, sqrt(a2), sqrt(a2 * tan2), atan(u[2], u[1]))
    end
    throw(ArgumentError("hyperbola_with_asymptotes: the point is on an asymptote or at the center"))
end
"""
    parabola_through_points(p1::APPoint, p2::APPoint, p3::APPoint, axis::APVector)

The parabola whose axis has the direction `axis` and that passes through the
three points. There is one for every triple of points that no two of which
are on a line parallel to the axis. Throws an `ArgumentError` when there is none,
that is, when the points are on a line, or two share a coordinate across the axis.
"""
function parabola_through_points(p1::APPoint{2}, p2::APPoint{2}, p3::APPoint{2}, axis::APVector{2})
    ua = normalize(axis)
    w = orthogonal(ua)
    s2, v2 = dot(p2 - p1, w), dot(p2 - p1, ua)
    s3, v3 = dot(p3 - p1, w), dot(p3 - p1, ua)
    det = s2 * s3 * (s2 - s3)
    abs(det) > 1e-12 * max(1.0, norm(p2 - p1) * norm(p3 - p1) * norm(p3 - p2)) || throw(ArgumentError("parabola_through_points: no parabola with that axis goes through the points"))
    α = (v2 * s3 - v3 * s2) / det
    β = (s2^2 * v3 - s3^2 * v2) / det
    abs(α) > 1e-12 || throw(ArgumentError("parabola_through_points: the points are on a line"))
    f = 1 / (4α)
    vertex = p1 + (-β / (2α)) * w + (-β^2 / (4α)) * ua
    focus = vertex + f * ua
    corner = vertex - f * ua
    return APParabola2(focus, APLine(corner, corner + w))
end

# ---- regions and boxes ----
"""
    APStrip2(l::APLine, width::Real)

The strip between `l` and the parallel line at distance `width` to its left
(to its right for a negative `width`), built with [`offset_line`](@ref).
"""
APStrip2(l::APLine{2}, width::Real) = APStrip2(l, offset_line(l, width))
"""
    APHalfPlane2(p::APPoint, normal::APVector)

The half-plane whose boundary passes through `p` perpendicular to `normal`, on
the side `normal` points to.
"""
APHalfPlane2(p::APPoint{2}, normal::APVector{2}) = APHalfPlane2(APLine(p, p + orthogonal(normal)), p + normal)
"""
    APBoundingBox(center::APPoint{2}, width::Real, height::Real)

The box with the given center and size, with its sides parallel to the axes.
"""
APBoundingBox(center::APPoint{2}, width::Real, height::Real) =
    APBoundingBox(center - APVector(width / 2, height / 2), center + APVector(width / 2, height / 2))
"""
    inflate(bb::APBoundingBox, margin::Real)
    inflate(bb::APBoundingBox, mx::Real, my::Real)

The box `bb` grown by `margin` on every side, or by `mx` on the left and right
and `my` above and below. A negative margin shrinks it. An empty box stays empty.
"""
inflate(bb::APBoundingBox{2}, mx::Real, my::Real) = isempty(bb) ? bb : APBoundingBox(bb.min - APVector(mx, my), bb.max + APVector(mx, my))
inflate(bb::APBoundingBox{2}, margin::Real) = inflate(bb, margin, margin)
