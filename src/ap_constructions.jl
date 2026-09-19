"""
    polar_point(r, angle, center::APPoint)

The point at distance `r` from `center`, at `angle` radians counterclockwise
from the positive x-axis: `center + (r*cos(angle), r*sin(angle))`.

No zero-argument default for `center` here (unlike the `Point2`-based
`polar_point`, which already claims the `(r::Real, angle::Real)`
default-elided fallback -- see [`rotation_map`](@ref) for why an AP-typed
default would collide with it): pass `center` explicitly.
"""
polar_point(r::Real, angle::Real, center::APPoint{2}) =
    center + APVector(r * cos(angle), r * sin(angle))
polar_point(r::Real, angle::Real) = polar_point(r, angle, APPoint(0.0,0.0))
"""
    polar_point_deg(r, angle, center::APPoint)

Like [`polar_point`](@ref), but `angle` is given in degrees.
"""
polar_point_deg(r::Real, angle::Real, center::APPoint{2}) =
    polar_point(r, deg2rad(angle), center)
polar_point_deg(r::Real, angle::Real) = polar_point_deg(r, angle, APPoint(0.0,0.0))
"""
    barycenter(points, weights)

The weighted barycenter (center of mass) of `points` with the given
`weights` -- `points` an `AbstractVector`/`Tuple` of `APPoint`, `weights`
an `AbstractVector`/`Tuple` of `Real` (e.g. `barycenter(vertices(t),
[1.0, 1.0, 2.0])` works directly, even though `vertices(::APTriangle)`
returns a `Tuple` rather than a `Vector`).
"""
function barycenter(points::Union{AbstractVector{<:APPoint},NTuple{N,<:APPoint} where N},
    weights::Union{AbstractVector{<:Real},NTuple{N,<:Real} where N})
    length(points) == length(weights) ||
        throw(ArgumentError("points and weights must have the same length"))
    W = sum(weights)
    p0 = first(points)
    return p0 + sum(w * (p - p0) for (w, p) in zip(weights, points)) / W
end
"""
    parallel_through(l::APLine, p::APPoint)

The line through `p` parallel to `l`.
"""
parallel_through(l::APLine, p::APPoint) = APLine(p, p + direction(l))
"""
    perpendicular_through(l::APLine, p::APPoint)

The line through `p` perpendicular to `l`.
"""
perpendicular_through(l::APLine, p::APPoint) = APLine(p, p + orthogonal(direction(l)))
"""
    perpendicular_bisector(a::APPoint, b::APPoint)
    perpendicular_bisector(s::APSegment)

The perpendicular bisector (mediatrix) of segment `[a, b]`.
"""
perpendicular_bisector(a::APPoint, b::APPoint) = perpendicular_through(APLine(a, b), midpoint(a, b))
perpendicular_bisector(s::APSegment) = perpendicular_bisector(s[1], s[2])
"""
    angle_bisectors(l1::APLine, l2::APLine; atol=1e-9)

The angle bisector(s) of `l1` and `l2`: two mutually perpendicular lines
through their intersection point (the internal and external bisectors) if
they intersect, or a single midline if they're parallel.
"""
function angle_bisectors(l1::APLine, l2::APLine; atol=1e-9)
    pts = intersection(l1, l2; atol=atol)
    if isempty(pts)
        foot = projection(l1.p1, l2)
        m = midpoint(l1.p1, foot)
        return [APLine(m, m + direction(l1))]
    end
    x = pts[1]
    u1 = direction(l1) / norm(direction(l1))
    u2 = direction(l2) / norm(direction(l2))
    return [APLine(x, x + (u1 + u2)), APLine(x, x + (u1 - u2))]
end
"""
    angle_trisectors(vertex::APPoint, p1::APPoint, p2::APPoint)

The two rays from `vertex` that trisect the angle `∠(p1, vertex, p2)` into
three equal parts (the oriented angle from `vertex -> p1` to
`vertex -> p2`, i.e. going counterclockwise when that angle is positive).
Always exactly 2 rays, so returned as a `Tuple` (unlike
[`angle_bisectors`](@ref)`(l1, l2)`, whose count genuinely varies with the
input and so must be a `Vector`).
"""
function angle_trisectors(vertex::APPoint, p1::APPoint, p2::APPoint)
    θ = angle_between(p1 - vertex, p2 - vertex)
    return (APRay(vertex, rotate(p1, θ / 3, vertex)), APRay(vertex, rotate(p1, 2θ / 3, vertex)))
end
"""
    angle_bisectors(ang::APAngle2)

`ang` split into its two equal halves by its bisector, each as its own
`APAngle2`: `(APAngle2(vertex, a, bis), APAngle2(vertex, bis, b))`.
"""
function angle_bisectors(ang::APAngle2)
    bis = rotate(ang.a, measure(ang) / 2, ang.vertex)
    return (APAngle2(ang.vertex, ang.a, bis), APAngle2(ang.vertex, bis, ang.b))
end
"""
    angle_trisectors(ang::APAngle2)

`ang` split into its three equal thirds by its two trisectors, each as its
own `APAngle2`: `(APAngle2(vertex, a, r1), APAngle2(vertex, r1, r2),
APAngle2(vertex, r2, b))`.
"""
function angle_trisectors(ang::APAngle2)
    θ = measure(ang)
    r1 = rotate(ang.a, θ / 3, ang.vertex)
    r2 = rotate(ang.a, 2θ / 3, ang.vertex)
    return (APAngle2(ang.vertex, ang.a, r1), APAngle2(ang.vertex, r1, r2), APAngle2(ang.vertex, r2, ang.b))
end
"""
    golden_ratio_point(a::APPoint, b::APPoint)
    golden_ratio_point(l::APLine)

The point on segment `[a, b]` (or `[l.p1, l.p2]`) dividing it in the golden
ratio from `a`, i.e. `a + (b - a) / φ`.
"""
golden_ratio_point(a::APPoint, b::APPoint) = a + (b - a) / golden
golden_ratio_point(l::APLine) = golden_ratio_point(l.p1, l.p2)
"""
    harmonic_conjugate(a::APPoint, b::APPoint, p::APPoint; atol=1e-9)
    harmonic_conjugate(l::APLine, p::APPoint; atol=1e-9)

The harmonic conjugate of `p` with respect to `a` and `b`: the point `q`
(collinear with `a`, `b`, `p`) such that the cross-ratio `(a, b; p, q)`
equals `-1`. Throws an error if `p` is the midpoint of `[a, b]` (its
harmonic conjugate is the point at infinity).
"""
function harmonic_conjugate(a::APPoint, b::APPoint, p::APPoint; atol=1e-9)
    d = b - a
    t = dot(p - a, d) / dot(d, d)
    denom = 2t - 1
    abs(denom) <= atol && throw(ArgumentError(
        "harmonic_conjugate: p is the midpoint of (a, b); its harmonic conjugate is the point at infinity"))
    return a + (t / denom) * d
end
harmonic_conjugate(l::APLine, p::APPoint; atol=1e-9) = harmonic_conjugate(l.p1, l.p2, p; atol=atol)
"""
    apollonius_circle(a::APPoint, b::APPoint, k::Real; atol=1e-9)

The Apollonius circle of `a`, `b` and ratio `k`: the locus of points `p`
with `distance(p, a) / distance(p, b) == k`. Its diameter endpoints are the
points dividing `[a, b]` internally and externally in ratio `k`. Throws an
`ArgumentError` if `k ≈ 1` (the locus is then the perpendicular bisector of
`[a, b]`, a line rather than a circle).
"""
function apollonius_circle(a::APPoint, b::APPoint, k::Real; atol=1e-9)
    k <= 0 && throw(ArgumentError("apollonius_circle: k must be positive (it's a ratio of distances)"))
    abs(k - 1) <= atol && throw(ArgumentError(
        "apollonius_circle: k ≈ 1; the locus is the perpendicular bisector of [a,b], not a circle"))
    p_int = a + k * (b - a) / (1 + k)
    p_ext = a + k * (b - a) / (k - 1)
    return APCircle2(midpoint(p_int, p_ext), distance(p_int, p_ext) / 2)
end
"""
    arc_with_angle(center::APPoint, p::APPoint, angle::Real)

The circular arc of the circle centered at `center` through `p`, sweeping
`angle` radians from `p`: counterclockwise for a positive `angle`,
clockwise for a negative one -- the compass arc of a ruler-and-compass
construction, set to `distance(center, p)` and swung through a given
angle. Since an [`APCircularArc2`](@ref) always runs counterclockwise from
`p1` to `p2`, a clockwise sweep comes back with `p` as `arc.p2` instead
of `arc.p1`. `angle` must satisfy `0 < abs(angle) < 2π` (an arc can't be a
full circle or empty); `p` must differ from `center`.

See [`arc_with_length`](@ref) to give the sweep as an arc length instead.
"""
function arc_with_angle(center::APPoint, p::APPoint, angle::Real)
    0 < abs(angle) < 2pi || throw(ArgumentError("arc_with_angle: abs(angle) must be in (0, 2π)"))
    q = rotate(p, angle, center)
    return angle > 0 ? APCircularArc2(center, distance(center, p), p, q) :
           APCircularArc2(center, distance(center, p), q, p)
end
"""
    arc_with_length(center::APPoint, p::APPoint, len::Real)

Like [`arc_with_angle`](@ref), but the sweep is given as an arc length
`len` along the circle centered at `center` through `p` (so the angle is
`len / distance(center, p)`); a negative `len` sweeps clockwise. `len` must
be nonzero and shorter than the whole circumference.
"""
function arc_with_length(center::APPoint, p::APPoint, len::Real)
    r = distance(center, p)
    r > 0 || throw(ArgumentError("arc_with_length: p must differ from center"))
    return arc_with_angle(center, p, len / r)
end
"""
    APCircularArc2(center::APPoint, r::Real, θ1::Real, θ2::Real; ccw::Bool=true)

The arc of the circle centered at `center` with radius `r` from the polar
angle `θ1` to `θ2` (radians), counterclockwise for `ccw=true` (the
default) and clockwise for `ccw=false`. Equal angles (mod `2π`) give an
empty arc. See [`APCircularArc2`](@ref)`(center, r, p1, p2)` for the same
arc given by points.
"""
function APCircularArc2(center::APPoint, r::Real, θ1::Real, θ2::Real; ccw::Bool=true)
    p1 = center + r * APVector(cos(θ1), sin(θ1))
    p2 = center + r * APVector(cos(θ2), sin(θ2))
    return APCircularArc2(center, r, p1, p2; ccw=ccw)
end
"""
    semicircle(center::APPoint, p::APPoint; ccw::Bool=true)

The half circle centered at `center` starting at `p` and ending at the
antipode of `p`, counterclockwise for `ccw=true` (the default). Shorthand
for [`arc_with_angle`](@ref)`(center, p, π)`.
"""
semicircle(center::APPoint, p::APPoint; ccw::Bool=true) = arc_with_angle(center, p, ccw ? pi : -pi)
"""
    extend_arc(arc::APCircularArc2, δ::Real)

`arc` grown by `δ` radians at each end (shrunk if `δ` is negative), on the
same circle. Throws an `ArgumentError` unless the result still sweeps
strictly between `0` and `2π`.
"""
function extend_arc(arc::APCircularArc2, δ::Real)
    total = measure(arc) + 2δ
    0 < total < 2pi || throw(ArgumentError("extend_arc: the extended arc must sweep strictly between 0 and 2π"))
    θ1 = _arc_angle(arc, arc.p1)
    return APCircularArc2(arc.circle.center, arc.circle.r, θ1 - δ, θ1 - δ + total)
end
"""
    compass_trace(center::APPoint, p::APPoint; angle=nothing, length=nothing)

The short arc a compass leaves on paper: centered at `center`, of radius
`distance(center, p)`, and symmetric about `p` (`p` is the middle of the
arc). Give exactly one of `angle`, the total sweep in radians, or `length`,
the total arc length. The result is an [`APCircularArc2`](@ref), drawn with
`path` like any other. Throws an `ArgumentError` if both or neither are
given, or if `p == center`. To start the arc at `p` instead of centering it
there, see [`arc_with_angle`](@ref) and [`arc_with_length`](@ref).
"""
function compass_trace(center::APPoint, p::APPoint; angle::Union{Nothing,Real}=nothing, length::Union{Nothing,Real}=nothing)
    (angle === nothing) == (length === nothing) &&
        throw(ArgumentError("compass_trace: give exactly one of angle or length"))
    r = distance(center, p)
    r > 0 || throw(ArgumentError("compass_trace: p must differ from center"))
    total = angle === nothing ? length / r : angle
    0 < total < 2pi || throw(ArgumentError("compass_trace: the sweep must be strictly between 0 and 2π"))
    return arc_with_angle(center, rotate(p, -total / 2, center), total)
end
"""
    extend_line(l::APLine, before, after=before)
    extend_line(s::APSegment, before, after=before)

The segment obtained by lengthening the line through `l.p1` and `l.p2` (or
the segment `s`) by the fractions `before` and `after` of `distance(p1, p2)`
past `p1` and past `p2` respectively: `extend_line(l, 0.2)` adds 20% of the
length at each end. This is tkz-euclide's `add = a and b`, relative to the
two points that define the line, unlike the absolute `extend` of `path`. A
negative fraction shortens that end. Returns an [`APSegment`](@ref). Throws
an `ArgumentError` if the two points coincide or the result would be empty
(`1 + before + after <= 0`).
"""
function extend_line(l::APLine, before::Real, after::Real=before)
    d = l.p2 - l.p1
    norm(d) > 0 || throw(ArgumentError("extend_line: the two defining points coincide"))
    1 + before + after > 0 || throw(ArgumentError("extend_line: before + after must be greater than -1"))
    return APSegment(l.p1 - before * d, l.p2 + after * d)
end
extend_line(s::APSegment, before::Real, after::Real=before) = extend_line(APLine(s.p1, s.p2), before, after)
"""
    point_on_line(l, t)

The point `l.p1 + t * (l.p2 - l.p1)` of a line, a segment or a ray (for a
ray the two points are `origin` and `through`): `t = 0` is the first defining
point, `t = 1` the second, and `t` is measured in units of
`distance(l.p1, l.p2)`. It is not restricted to `[0, 1]`, so a value outside
that range gives a point on the line beyond a segment's ends.
"""
point_on_line(l::Union{APLine,APSegment}, t::Real) = l.p1 + t * (l.p2 - l.p1)
point_on_line(r::APRay, t::Real) = r.origin + t * (r.through - r.origin)
"""
    point_on_circle(c::APCircle2, angle)

The point of `c` at `angle` radians counterclockwise from the positive
x-axis, as seen from its center: `polar_point(c.r, angle, c.center)`.
"""
point_on_circle(c::APCircle2, angle::Real) = polar_point(c.r, angle, c.center)
