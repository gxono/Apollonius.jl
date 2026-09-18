"""
    angle_at(vertex, p1, p2)

Unsigned interior angle (in radians, in `[0, π]`) at `vertex` between the
rays `vertex -> p1` and `vertex -> p2`. See also [`angle_between`](@ref)
for the signed version, and [`APAngle2`](@ref) for a reusable object
carrying the three points around instead of just the number.
"""
angle_at(vertex::APPoint, p1::APPoint, p2::APPoint) =
    acos(clamp(dot(p1 - vertex, p2 - vertex) / (norm(p1 - vertex) * norm(p2 - vertex)), -1.0, 1.0))
"""
    APAngle2(vertex::APPoint, a::APPoint, b::APPoint)

The angle at `vertex` between the rays `vertex -> a` and `vertex -> b`,
plus (since it's an [`APSet`](@ref)) the infinite wedge they bound -- the
region swept counterclockwise from ray `vertex -> a` to ray `vertex -> b`
by [`normalized_measure`](@ref) radians. Unlike [`angle_at`](@ref)/
[`angle_between`](@ref), which just return a number, this keeps the three
defining points around.
"""
struct APAngle2{T<:Real} <: APSet{2,T}
    vertex::APPoint{2,T}
    a::APPoint{2,T}
    b::APPoint{2,T}
end
function APAngle2(vertex::APPoint, a::APPoint, b::APPoint)
    T = promote_type(eltype(vertex), eltype(a), eltype(b))
    return APAngle2{T}(vertex, a, b)
end
Base.:(==)(x::APAngle2, y::APAngle2) = x.vertex == y.vertex && x.a == y.a && x.b == y.b
Base.isapprox(x::APAngle2, y::APAngle2; kwargs...) =
    isapprox(x.vertex, y.vertex; kwargs...) && isapprox(x.a, y.a; kwargs...) && isapprox(x.b, y.b; kwargs...)
Base.show(io::IO, ang::APAngle2) = print(io, "APAngle2(vertex=", ang.vertex, ", a=", ang.a, ", b=", ang.b, ")")
"""
    reverse(ang::APAngle2)

The *complementary* wedge: same vertex, `a`/`b` swapped, so the sweep
runs the other way around the vertex. [`normalized_measure`](@ref) goes
from `θ` to `2π - θ` (0 stays 0) -- same rays, opposite orientation.

This is the fix for a common gotcha: [`APAngle2`](@ref)'s "counterclockwise
from `a` to `b`" is computed straight from the `(x, y)` values it's given,
with no idea whether those coordinates already live in a mirrored
coordinate space (e.g. after [`@to_luxor_picture`](@ref)'s default
`flip=true`, which reflects everything to match Luxor's `y`-down screen
convention). Building the angle *before* that reflection and letting the
whole object pass through the macro handles this automatically (see
[Drawing with Luxor.jl](@ref)); reconstructing it *after*, straight from
already-mirrored points, silently picks up the reversed sense instead --
`reverse` is the manual fix for that second case.
"""
Base.reverse(ang::APAngle2) = APAngle2(ang.vertex, ang.b, ang.a)
"""
    measure(ang::APAngle2)

The signed measure of `ang` (radians, in `(-π, π]`, counterclockwise from
ray `vertex -> a` to ray `vertex -> b`) -- see [`angle_between`](@ref).
"""
measure(ang::APAngle2) = angle_between(ang.a - ang.vertex, ang.b - ang.vertex)
"""
    rotate(obj::APObject, ang::APAngle2, args...; kwargs...)

Same as `rotate(obj, measure(ang), args...; kwargs...)` -- lets any
existing `rotate(obj, angle::Real, ...)` method (2D with a `center`, 3D
with an `axis`) be driven by an `APAngle2`'s own measure directly, without
unwrapping it by hand first. Not to be confused with
`rotate(ang::APAngle2, angle::Real, center)`, which rotates `ang` itself
*as a shape* -- here `ang` supplies the rotation amount for some other
`obj`, via its `measure`.
"""
rotate(obj::APObject, ang::APAngle2, args...; kwargs...) = rotate(obj, measure(ang), args...; kwargs...)
"""
    normalized_measure(ang::APAngle2)

The measure of `ang`, in `[0, 2π)` instead of `(-π, π]`.
"""
function normalized_measure(ang::APAngle2)
    m = measure(ang)
    return m < 0 ? m + 2 * pi : m
end
"""
    abs(ang::APAngle2)

The unsigned measure of `ang` (radians, in `[0, π]`) -- see [`angle_at`](@ref).
"""
Base.abs(ang::APAngle2) = angle_at(ang.vertex, ang.a, ang.b)
"""
    is_direct(ang::APAngle2)

Whether `ang` is oriented counterclockwise (its signed [`measure`](@ref) is positive).
"""
is_direct(ang::APAngle2) = measure(ang) > 0
"""
    p in ang::APAngle2

Whether `p` lies in the infinite wedge swept counterclockwise from ray
`vertex -> a` to ray `vertex -> b` (see [`APAngle2`](@ref)).
"""
function Base.in(p::APPoint, ang::APAngle2)
    p == ang.vertex && return true
    a1 = atan(ang.a[2] - ang.vertex[2], ang.a[1] - ang.vertex[1])
    ap = atan(p[2] - ang.vertex[2], p[1] - ang.vertex[1])
    return mod(ap - a1, 2 * pi) <= normalized_measure(ang)
end
"""
    rotate(ang::APAngle2, angle, center=APPoint(0.0, 0.0))
    homothety(ang::APAngle2, k, center=APPoint(0.0, 0.0))

Transform `ang` pointwise (`vertex`, `a` and `b`). [`measure`](@ref) is
preserved by both (a rotation or a homothety of any ratio, positive or
negative, is orientation-preserving in 2D and never changes an angle's
own signed measure).
"""
rotate(ang::APAngle2, angle::Real, center::APPoint=APPoint(0.0, 0.0)) =
    APAngle2(rotate(ang.vertex, angle, center), rotate(ang.a, angle, center), rotate(ang.b, angle, center))
homothety(ang::APAngle2, k::Real, center::APPoint=APPoint(0.0, 0.0)) =
    APAngle2(homothety(ang.vertex, k, center), homothety(ang.a, k, center), homothety(ang.b, k, center))
translate(ang::APAngle2, v::APVector) =
    APAngle2(translate(ang.vertex, v), translate(ang.a, v), translate(ang.b, v))
"""
    distance(p::APPoint, ang::APAngle2; mode::Symbol=:region)

Distance from `p` to the wedge `ang` (see [`APAngle2`](@ref)). The
wedge's boundary is exactly the union of the two rays `vertex -> a` and
`vertex -> b`, so `mode = :boundary` is `min` of the distances to each
ray -- this holds for any measure, reflex wedges included. With `mode =
:region` (the default), `0.0` whenever `p` lies inside the wedge, else
the same boundary distance (for a closed region, the nearest point to an
exterior point always lies on the boundary).
"""
function distance(p::APPoint, ang::APAngle2; mode::Symbol=:region)
    _check_distance_mode(mode)
    d = min(distance(p, APRay(ang.vertex, ang.a)), distance(p, APRay(ang.vertex, ang.b)))
    mode == :boundary && return d
    return p in ang ? zero(d) : d
end
distance(ang::APAngle2, p::APPoint; mode::Symbol=:region) = distance(p, ang; mode=mode)
"""
    reflection(ang::APAngle2, about::APPoint)
    reflection(ang::APAngle2, about::APLine)

Reflect `ang`. Since `APAngle2` is an [`APSet`](@ref) -- the infinite wedge
swept counterclockwise from `a` to `b`, not just a bare signed value --
reflecting about an `APLine` (a true mirror) swaps `a`/`b` so the result
is a genuine mirror image of the wedge (exactly the same swap convention
[`APCircularArc2`](@ref)/[`APEllipticArc2`](@ref) use to stay a true
mirror image rather than the complementary region); reflecting about an
`APPoint` (a point reflection) needs no swap. Consequently [`measure`](@ref)'s
sign is preserved by *both* -- a point reflection and a mirror are both
"apply the same swap-or-not rule uniformly across the AP hierarchy",
rather than the sign-flip-under-mirror convention a bare rotation
instruction would suggest.
"""
reflection(ang::APAngle2, about::APPoint) =
    APAngle2(reflection(ang.vertex, about), reflection(ang.a, about), reflection(ang.b, about))
reflection(ang::APAngle2, about::APLine) =
    APAngle2(reflection(ang.vertex, about), reflection(ang.b, about), reflection(ang.a, about))
APBoundingBox(::APAngle2) = APBoundingBox()
"""
    APHalfPlane2(boundary::APLine, side::Int)
    APHalfPlane2(boundary::APLine, interior_point::APPoint)

The closed half-plane bounded by `boundary`: `side = +1` means the side
left of `boundary` (oriented `p1 -> p2`), `side = -1` means the right
side -- see [`side_of_line`](@ref)'s convention, which this mirrors. The
second form is often easier to reason about: pass any point known to lie
inside instead of working out left/right by hand.
"""
struct APHalfPlane2{T<:Real} <: APSet{2,T}
    boundary::APLine{2,T}
    side::Int
end
function APHalfPlane2(boundary::APLine{2}, p::APPoint{2})
    s = side_of_line(p, boundary)
    s == 0 && throw(ArgumentError("APHalfPlane2: interior_point must not lie on boundary"))
    return APHalfPlane2(boundary, s)
end
Base.:(==)(x::APHalfPlane2, y::APHalfPlane2) = x.boundary == y.boundary && x.side == y.side
Base.isapprox(x::APHalfPlane2, y::APHalfPlane2; kwargs...) =
    isapprox(x.boundary, y.boundary; kwargs...) && x.side == y.side
Base.show(io::IO, hp::APHalfPlane2) = print(io, "APHalfPlane2(", hp.boundary, ", side=", hp.side, ")")
"""
    p in hp::APHalfPlane2

Whether `p` lies in the closed half-plane `hp` (on `hp.boundary` counts as inside).
"""
Base.in(p::APPoint, hp::APHalfPlane2) = side_of_line(p, hp.boundary) in (0, hp.side)
"""
    rotate(hp::APHalfPlane2, angle, center=APPoint(0.0, 0.0))
    homothety(hp::APHalfPlane2, k, center=APPoint(0.0, 0.0))

Transform `hp`'s boundary pointwise. `side` is unchanged by both: a
rotation or a homothety of any ratio (positive or negative) is
orientation-preserving in 2D, so "left of the transformed boundary" still
corresponds to the same physical half-plane.
"""
rotate(hp::APHalfPlane2, angle::Real, center::APPoint=APPoint(0.0, 0.0)) =
    APHalfPlane2(rotate(hp.boundary, angle, center), hp.side)
homothety(hp::APHalfPlane2, k::Real, center::APPoint=APPoint(0.0, 0.0)) =
    APHalfPlane2(homothety(hp.boundary, k, center), hp.side)
translate(hp::APHalfPlane2, v::APVector) = APHalfPlane2(translate(hp.boundary, v), hp.side)
"""
    reflection(hp::APHalfPlane2, about::APPoint)
    reflection(hp::APHalfPlane2, about::APLine)

Reflect `hp`'s boundary. Reflecting about an `APPoint` (a point
reflection) is orientation-preserving, so `side` is unchanged. Reflecting
about an `APLine` (a true mirror) reverses orientation, so `side` flips --
otherwise the reflected half-plane would represent the wrong side of its
own (also reflected) boundary.
"""
reflection(hp::APHalfPlane2, about::APPoint) = APHalfPlane2(reflection(hp.boundary, about), hp.side)
reflection(hp::APHalfPlane2, about::APLine) = APHalfPlane2(reflection(hp.boundary, about), -hp.side)
"""
    distance(p::APPoint, hp::APHalfPlane2; mode::Symbol=:region)

Distance from `p` to the half-plane `hp`. With `mode = :region` (the
default), `0.0` whenever `p in hp`, else the distance to `hp.boundary`.
With `mode = :boundary`, always the distance to `hp.boundary`, even from
inside.
"""
function distance(p::APPoint, hp::APHalfPlane2; mode::Symbol=:region)
    _check_distance_mode(mode)
    d = distance(p, hp.boundary)
    mode == :boundary && return d
    return p in hp ? zero(d) : d
end
distance(hp::APHalfPlane2, p::APPoint; mode::Symbol=:region) = distance(p, hp; mode=mode)
APBoundingBox(::APHalfPlane2) = APBoundingBox()
"""
    APStrip2(line1::APLine, line2::APLine; atol=1e-9)

The closed band between two parallel lines `line1`/`line2` (either
boundary counts as inside). Throws `ArgumentError` if the lines aren't
parallel.
"""
struct APStrip2{T<:Real} <: APSet{2,T}
    line1::APLine{2,T}
    line2::APLine{2,T}
    function APStrip2{T}(line1::APLine{2,T}, line2::APLine{2,T}; atol=1e-9) where {T<:Real}
        d1, d2 = direction(line1), direction(line2)
        abs(cross2(d1, d2)) <= atol * norm(d1) * norm(d2) ||
            throw(ArgumentError("APStrip2: line1 and line2 must be parallel"))
        return new{T}(line1, line2)
    end
end
function APStrip2(line1::APLine{2,T1}, line2::APLine{2,T2}; atol=1e-9) where {T1,T2}
    T = promote_type(T1, T2)
    return APStrip2{T}(convert(APLine{2,T}, line1), convert(APLine{2,T}, line2); atol=atol)
end
Base.:(==)(x::APStrip2, y::APStrip2) = x.line1 == y.line1 && x.line2 == y.line2
Base.isapprox(x::APStrip2, y::APStrip2; kwargs...) =
    isapprox(x.line1, y.line1; kwargs...) && isapprox(x.line2, y.line2; kwargs...)
Base.show(io::IO, s::APStrip2) = print(io, "APStrip2(", s.line1, ", ", s.line2, ")")
"""
    p in s::APStrip2

Whether `p` lies in the closed band between `s.line1` and `s.line2`.
"""
function Base.in(p::APPoint, s::APStrip2)
    side1, ref1 = side_of_line(p, s.line1), side_of_line(s.line2.p1, s.line1)
    side2, ref2 = side_of_line(p, s.line2), side_of_line(s.line1.p1, s.line2)
    return (side1 == 0 || side1 == ref1) && (side2 == 0 || side2 == ref2)
end
"""
    strip_width(s::APStrip2)

The perpendicular distance between `s`'s two boundary lines.
"""
strip_width(s::APStrip2) = distance(s.line2.p1, s.line1)
"""
    rotate(s::APStrip2, angle, center=APPoint(0.0, 0.0))
    homothety(s::APStrip2, k, center=APPoint(0.0, 0.0))
    reflection(s::APStrip2, about)

Transform both boundary lines pointwise. Since "the band between two
lines" doesn't depend on either line's own orientation, no
`side`-flipping bookkeeping is needed here (unlike [`APHalfPlane2`](@ref))
-- membership is recomputed fresh from the transformed lines every time.
"""
rotate(s::APStrip2, angle::Real, center::APPoint=APPoint(0.0, 0.0)) =
    APStrip2(rotate(s.line1, angle, center), rotate(s.line2, angle, center))
homothety(s::APStrip2, k::Real, center::APPoint=APPoint(0.0, 0.0)) =
    APStrip2(homothety(s.line1, k, center), homothety(s.line2, k, center))
reflection(s::APStrip2, about) = APStrip2(reflection(s.line1, about), reflection(s.line2, about))
translate(s::APStrip2, v::APVector) = APStrip2(translate(s.line1, v), translate(s.line2, v))
"""
    distance(p::APPoint, s::APStrip2; mode::Symbol=:region)

Distance from `p` to the strip `s`. With `mode = :region` (the default),
`0.0` whenever `p in s`, else `min` of the distances to `s.line1`/
`s.line2`. With `mode = :boundary`, always that `min`, even from inside.
"""
function distance(p::APPoint, s::APStrip2; mode::Symbol=:region)
    _check_distance_mode(mode)
    d = min(distance(p, s.line1), distance(p, s.line2))
    mode == :boundary && return d
    return p in s ? zero(d) : d
end
distance(s::APStrip2, p::APPoint; mode::Symbol=:region) = distance(p, s; mode=mode)
APBoundingBox(::APStrip2) = APBoundingBox()
