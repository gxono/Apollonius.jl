_side_p1(s::APCircularArc2) = s.p1
_side_p2(s::APCircularArc2) = s.p2
_side_length(s::APCircularArc2) = arc_length(s)
_side_greens_term(s::APCircularArc2) = begin
    c = s.circle
    θ1 = atan(s.p1[2] - c.center[2], s.p1[1] - c.center[1])
    Δθ = measure(s)
    θ2 = θ1 + Δθ
    (c.r^2 * Δθ + c.r * c.center[1] * (sin(θ2) - sin(θ1)) + c.r * c.center[2] * (cos(θ1) - cos(θ2))) / 2
end
_side_scale(s::APCircularArc2) = max(s.circle.r, 1.0)
_side_p1(s::APEllipticArc2) = s.p1
_side_p2(s::APEllipticArc2) = s.p2
_side_length(s::APEllipticArc2) = arc_length(s)
function _side_greens_term(s::APEllipticArc2)
    e = s.ellipse
    θ1 = _ellipse_param(s, s.p1)
    Δθ = measure(s)
    θ2 = θ1 + Δθ
    P1, P2 = point_on(e, θ1) - e.center, point_on(e, θ2) - e.center
    return (e.a * e.b * Δθ + e.center[1] * (P2[2] - P1[2]) - e.center[2] * (P2[1] - P1[1])) / 2
end
_side_scale(s::APEllipticArc2) = max(s.ellipse.a, s.ellipse.b, 1.0)
_side_p1(s::APHyperbolicArc2) = s.p1
_side_p2(s::APHyperbolicArc2) = s.p2
_side_length(s::APHyperbolicArc2) = arc_length(s)
function _side_greens_term(s::APHyperbolicArc2)
    h = s.hyperbola
    t1, branch = _hyperbola_param(s, s.p1)
    t2, _ = _hyperbola_param(s, s.p2)
    P1, P2 = point_on(h, t1; branch=branch) - h.center, point_on(h, t2; branch=branch) - h.center
    return (branch * h.a * h.b * (t2 - t1) + h.center[1] * (P2[2] - P1[2]) - h.center[2] * (P2[1] - P1[1])) / 2
end
_side_scale(s::APHyperbolicArc2) = max(s.hyperbola.a, s.hyperbola.b, 1.0)
_side_p1(s::APParabolicArc2) = s.p1
_side_p2(s::APParabolicArc2) = s.p2
_side_length(s::APParabolicArc2) = arc_length(s)
function _side_greens_term(s::APParabolicArc2)
    par = s.parabola
    V, _, _ = _parabola_frame(par)
    pf = focal_parameter(par)
    s1, s2 = _parabola_param(s, s.p1), _parabola_param(s, s.p2)
    P1, P2 = point_on(par, s1) - V, point_on(par, s2) - V
    local_term = -(s2^3 - s1^3) / (6pf)
    return (local_term + V[1] * (P2[2] - P1[2]) - V[2] * (P2[1] - P1[1])) / 2
end
_side_scale(s::APParabolicArc2) = max(focal_parameter(s.parabola), distance(s.p1, s.p2), 1.0)
_map_sides(f, ss) = map(f, ss)
"""
    APCircularSector2(arc::APCircularArc2)
    APCircularSector2(circle::APCircle2, p1::APPoint, p2::APPoint)

The "pie slice" swept by `arc`: bounded by the two radii
`circle.center -> p1`, `circle.center -> p2`, and the arc itself.
"""
struct APCircularSector2{T<:Real} <: APPolygon{2,T}
    arc::APCircularArc2{T}
end
APCircularSector2(circle::APCircle2, p1, p2) = APCircularSector2(APCircularArc2(circle, p1, p2))
"""
    APCircularSector2(center::APPoint, r::Real, p1::APPoint, p2::APPoint)

Same as [`APCircularSector2(::APCircle2, ::APPoint, ::APPoint)`](@ref)
above, from the circle's raw center/radius instead of an [`APCircle2`](@ref)
directly.
"""
APCircularSector2(center::APPoint, r::Real, p1, p2) = APCircularSector2(APCircularArc2(center, r, p1, p2))
Base.:(==)(x::APCircularSector2, y::APCircularSector2) = x.arc == y.arc
Base.hash(x::APCircularSector2, h::UInt) = hash(x.arc, hash(:APCircularSector2, h))
Base.isapprox(x::APCircularSector2, y::APCircularSector2; kwargs...) = isapprox(x.arc, y.arc; kwargs...)
Base.show(io::IO, s::APCircularSector2) = print(io, "APCircularSector2(", s.arc, ")")
sides(s::APCircularSector2) = [APSegment(s.arc.circle.center, s.arc.p1), s.arc, APSegment(s.arc.p2, s.arc.circle.center)]
function Base.in(p::APPoint, s::APCircularSector2)
    c = s.arc.circle
    distance(p, c.center) > c.r && return false
    a1 = atan(s.arc.p1[2] - c.center[2], s.arc.p1[1] - c.center[1])
    ap = atan(p[2] - c.center[2], p[1] - c.center[1])
    return mod(ap - a1, 2π) <= measure(s.arc)
end
"""
    centroid(s::APCircularSector2)

The centroid of `s`, at distance `(4r·sin(θ/2))/(3θ)` from the circle's
center along the arc's own bisector (`θ = measure(s.arc)`, `r =
s.arc.circle.r`): the classical circular-sector centroid formula. Unlike
`area`/`perimeter` (which reuse the generic `APPolygon` machinery via
[`sides`](@ref)), this is a dedicated formula: the generic
`centroid(::APPolygon)` needs [`vertices`](@ref), which curved-sided
regions like this one don't implement.
"""
function centroid(s::APCircularSector2)
    c = s.arc.circle
    θ = measure(s.arc)
    a1 = atan(s.arc.p1[2] - c.center[2], s.arc.p1[1] - c.center[1])
    ψ = a1 + θ / 2
    d = (4 * c.r * sin(θ / 2)) / (3θ)
    return c.center + d * APVector(cos(ψ), sin(ψ))
end
rotate(s::APCircularSector2, angle::Real, center::APPoint=APPoint(0.0, 0.0)) = APCircularSector2(rotate(s.arc, angle, center))
homothety(s::APCircularSector2, k::Real, center::APPoint=APPoint(0.0, 0.0)) = APCircularSector2(homothety(s.arc, k, center))
reflection(s::APCircularSector2, about) = APCircularSector2(reflection(s.arc, about))
translate(s::APCircularSector2, v::APVector) = APCircularSector2(translate(s.arc, v))
"""
    APCircularSegment2(arc::APCircularArc2)
    APCircularSegment2(circle::APCircle2, p1::APPoint, p2::APPoint)

The "cap" bounded by `arc` and the straight chord `[p1, p2]`.
"""
struct APCircularSegment2{T<:Real} <: APPolygon{2,T}
    arc::APCircularArc2{T}
end
APCircularSegment2(circle::APCircle2, p1, p2) = APCircularSegment2(APCircularArc2(circle, p1, p2))
"""
    APCircularSegment2(center::APPoint, r::Real, p1::APPoint, p2::APPoint)

Same as [`APCircularSegment2(::APCircle2, ::APPoint, ::APPoint)`](@ref)
above, from the circle's raw center/radius instead of an [`APCircle2`](@ref)
directly.
"""
APCircularSegment2(center::APPoint, r::Real, p1, p2) = APCircularSegment2(APCircularArc2(center, r, p1, p2))
Base.:(==)(x::APCircularSegment2, y::APCircularSegment2) = x.arc == y.arc
Base.hash(x::APCircularSegment2, h::UInt) = hash(x.arc, hash(:APCircularSegment2, h))
Base.isapprox(x::APCircularSegment2, y::APCircularSegment2; kwargs...) = isapprox(x.arc, y.arc; kwargs...)
Base.show(io::IO, s::APCircularSegment2) = print(io, "APCircularSegment2(", s.arc, ")")
sides(s::APCircularSegment2) = [s.arc, APSegment(s.arc.p2, s.arc.p1)]
function Base.in(p::APPoint, s::APCircularSegment2)
    c = s.arc.circle
    distance(p, c.center) > c.r && return false
    chord = APLine(s.arc.p1, s.arc.p2)
    side_of_chord(q) = sign(cross2(direction(chord), q - chord.p1))
    return side_of_chord(p) == side_of_chord(midpoint(s.arc))
end
"""
    centroid(s::APCircularSegment2)

The centroid of `s`, at distance `(4r·sin³(θ/2))/(3(θ-sinθ))` from the
circle's center along the arc's own bisector: the classical
circular-segment centroid formula (see
[`centroid(::APCircularSector2)`](@ref) for why this is a dedicated
formula rather than the generic `APPolygon` one).
"""
function centroid(s::APCircularSegment2)
    c = s.arc.circle
    θ = measure(s.arc)
    a1 = atan(s.arc.p1[2] - c.center[2], s.arc.p1[1] - c.center[1])
    ψ = a1 + θ / 2
    d = (4 * c.r * sin(θ / 2)^3) / (3 * (θ - sin(θ)))
    return c.center + d * APVector(cos(ψ), sin(ψ))
end
rotate(s::APCircularSegment2, angle::Real, center::APPoint=APPoint(0.0, 0.0)) = APCircularSegment2(rotate(s.arc, angle, center))
homothety(s::APCircularSegment2, k::Real, center::APPoint=APPoint(0.0, 0.0)) = APCircularSegment2(homothety(s.arc, k, center))
reflection(s::APCircularSegment2, about) = APCircularSegment2(reflection(s.arc, about))
translate(s::APCircularSegment2, v::APVector) = APCircularSegment2(translate(s.arc, v))
"""
    APAnnularSector2(outer::APCircularArc2, r_inner::Real)

The region between two concentric arcs: `outer` (on the outer circle,
`outer.circle.r > r_inner`) and the corresponding arc of the concentric
circle of radius `r_inner`, closed by the two radial segments between
them: Luxor's own `sector(center, innerradius, outerradius, ...)` shape,
represented here as an [`APPolygon`](@ref).
"""
struct APAnnularSector2{T<:Real} <: APPolygon{2,T}
    outer::APCircularArc2{T}
    r_inner::T
    function APAnnularSector2{T}(outer::APCircularArc2{T}, r_inner::T) where {T<:Real}
        r_inner < outer.circle.r || throw(ArgumentError("APAnnularSector2: r_inner must be less than the outer radius"))
        return new{T}(outer, r_inner)
    end
end
function APAnnularSector2(outer::APCircularArc2{T1}, r_inner::T2) where {T1,T2}
    T = promote_type(T1, T2)
    return APAnnularSector2{T}(convert(APCircularArc2{T}, outer), T(r_inner))
end
"""
    APAnnularSector2(center::APPoint, r_outer::Real, p1::APPoint, p2::APPoint, r_inner::Real)

Same as [`APAnnularSector2(::APCircularArc2, ::Real)`](@ref) above, from
the outer arc's raw center/radius instead of an [`APCircularArc2`](@ref)
directly.
"""
APAnnularSector2(center::APPoint, r_outer::Real, p1, p2, r_inner::Real) =
    APAnnularSector2(APCircularArc2(center, r_outer, p1, p2), r_inner)
Base.:(==)(x::APAnnularSector2, y::APAnnularSector2) = x.outer == y.outer && x.r_inner == y.r_inner
Base.hash(x::APAnnularSector2, h::UInt) = hash((x.outer, x.r_inner), hash(:APAnnularSector2, h))
Base.isapprox(x::APAnnularSector2, y::APAnnularSector2; kwargs...) =
    isapprox(x.outer, y.outer; kwargs...) && isapprox(x.r_inner, y.r_inner; kwargs...)
Base.show(io::IO, s::APAnnularSector2) = print(io, "APAnnularSector2(", s.outer, ", r_inner=", s.r_inner, ")")
function _inner_arc(s::APAnnularSector2)
    c = s.outer.circle
    p1i = c.center + s.r_inner * (s.outer.p1 - c.center) / c.r
    p2i = c.center + s.r_inner * (s.outer.p2 - c.center) / c.r
    return APCircularArc2(APCircle2(c.center, s.r_inner), p1i, p2i)
end
function sides(s::APAnnularSector2)
    inner = _inner_arc(s)
    return [APSegment(inner.p1, s.outer.p1), s.outer, APSegment(s.outer.p2, inner.p2), inner]
end
"""
    centroid(s::APAnnularSector2)

The centroid of `s`, as the area-weighted difference of the outer and
inner sectors' own centroids (`(Aₒcₒ - Aᵢcᵢ)/(Aₒ-Aᵢ)`): both share the
same bisector by construction, so this reduces to the same closed form as
[`centroid(::APCircularSector2)`](@ref) applied twice.
"""
function centroid(s::APAnnularSector2)
    outer_sector = APCircularSector2(s.outer)
    inner_sector = APCircularSector2(_inner_arc(s))
    Ao, Ai = area(outer_sector), area(inner_sector)
    c_outer, c_inner = centroid(outer_sector), centroid(inner_sector)
    return c_outer - Ai * (c_inner - c_outer) / (Ao - Ai)
end
rotate(s::APAnnularSector2, angle::Real, center::APPoint=APPoint(0.0, 0.0)) = APAnnularSector2(rotate(s.outer, angle, center), s.r_inner)
homothety(s::APAnnularSector2, k::Real, center::APPoint=APPoint(0.0, 0.0)) = APAnnularSector2(homothety(s.outer, k, center), abs(k) * s.r_inner)
reflection(s::APAnnularSector2, about) = APAnnularSector2(reflection(s.outer, about), s.r_inner)
translate(s::APAnnularSector2, v::APVector) = APAnnularSector2(translate(s.outer, v), s.r_inner)
"""
    APInterstice2(arc1::APCircularArc2, arc2::APCircularArc2, arc3::APCircularArc2)

A curvilinear triangle bounded by three circular arcs, each from a
different circle, meeting end to end. Build with [`interstices`](@ref)
rather than directly, in the common case of 3 mutually tangent circles.
"""
struct APInterstice2{T<:Real} <: APPolygon{2,T}
    arc1::APCircularArc2{T}
    arc2::APCircularArc2{T}
    arc3::APCircularArc2{T}
end
function APInterstice2(arc1::APCircularArc2{T1}, arc2::APCircularArc2{T2}, arc3::APCircularArc2{T3}) where {T1,T2,T3}
    T = promote_type(T1, T2, T3)
    return APInterstice2{T}(convert(APCircularArc2{T}, arc1), convert(APCircularArc2{T}, arc2), convert(APCircularArc2{T}, arc3))
end
Base.getindex(g::APInterstice2, i::Integer) = (g.arc1, g.arc2, g.arc3)[i]
Base.length(::APInterstice2) = 3
Base.iterate(g::APInterstice2, i::Int=1) = i > 3 ? nothing : (g[i], i + 1)
Base.:(==)(x::APInterstice2, y::APInterstice2) = x.arc1 == y.arc1 && x.arc2 == y.arc2 && x.arc3 == y.arc3
Base.hash(x::APInterstice2, h::UInt) = hash((x.arc1, x.arc2, x.arc3), hash(:APInterstice2, h))
Base.isapprox(x::APInterstice2, y::APInterstice2; kwargs...) =
    isapprox(x.arc1, y.arc1; kwargs...) && isapprox(x.arc2, y.arc2; kwargs...) && isapprox(x.arc3, y.arc3; kwargs...)
Base.show(io::IO, g::APInterstice2) = print(io, "APInterstice2(", g.arc1, ", ", g.arc2, ", ", g.arc3, ")")
sides(g::APInterstice2) = [g.arc1, g.arc2, g.arc3]
rotate(g::APInterstice2, angle::Real, center::APPoint=APPoint(0.0, 0.0)) =
    APInterstice2(rotate(g.arc1, angle, center), rotate(g.arc2, angle, center), rotate(g.arc3, angle, center))
homothety(g::APInterstice2, k::Real, center::APPoint=APPoint(0.0, 0.0)) =
    APInterstice2(homothety(g.arc1, k, center), homothety(g.arc2, k, center), homothety(g.arc3, k, center))
reflection(g::APInterstice2, about) =
    APInterstice2(reflection(g.arc1, about), reflection(g.arc2, about), reflection(g.arc3, about))
translate(g::APInterstice2, v::APVector) =
    APInterstice2(translate(g.arc1, v), translate(g.arc2, v), translate(g.arc3, v))
const APSide{T} = Union{APSegment{2,T},APCircularArc2{T},APEllipticArc2{T},APParabolicArc2{T},APHyperbolicArc2{T}}
"""
    APCurvilinearTriangle2(side1, side2, side3)

A closed region bounded by 3 sides, each independently an [`APSegment`](@ref)
or a conic arc ([`APCircularArc2`](@ref), `APEllipticArc2`,
`APParabolicArc2`, `APHyperbolicArc2`): the general 3-sided analogue of
[`APTriangle`](@ref) (all straight) and [`APInterstice2`](@ref) (all
circular arcs). The wider arc coverage (beyond just circular) exists
mainly so that `APAffineMap`-transformed circular-arc regions, whose
arcs generically become elliptic under a non-conformal map, still fit.
"""
struct APCurvilinearTriangle2{T<:Real} <: APPolygon{2,T}
    sides::NTuple{3,APSide{T}}
end
function APCurvilinearTriangle2(s1, s2, s3)
    T = promote_type(_side_eltype(s1), _side_eltype(s2), _side_eltype(s3))
    return APCurvilinearTriangle2((_side_convert(s1, T), _side_convert(s2, T), _side_convert(s3, T)))
end
sides(t::APCurvilinearTriangle2) = t.sides
Base.:(==)(x::APCurvilinearTriangle2, y::APCurvilinearTriangle2) = x.sides == y.sides
Base.hash(x::APCurvilinearTriangle2, h::UInt) = hash(x.sides, hash(:APCurvilinearTriangle2, h))
Base.show(io::IO, t::APCurvilinearTriangle2) = print(io, "APCurvilinearTriangle2", t.sides)
_transform_side(f, s::APSegment) = f(s)
_transform_side(f, s::APCircularArc2) = f(s)
rotate(t::APCurvilinearTriangle2, angle::Real, center::APPoint=APPoint(0.0, 0.0)) =
    APCurvilinearTriangle2(map(s -> rotate(s, angle, center), t.sides))
homothety(t::APCurvilinearTriangle2, k::Real, center::APPoint=APPoint(0.0, 0.0)) =
    APCurvilinearTriangle2(map(s -> homothety(s, k, center), t.sides))
reflection(t::APCurvilinearTriangle2, about) = APCurvilinearTriangle2(map(s -> reflection(s, about), t.sides))
translate(t::APCurvilinearTriangle2, v::APVector) = APCurvilinearTriangle2(map(s -> translate(s, v), t.sides))
"""
    APCurvilinearQuadrilateral2(side1, side2, side3, side4)

The 4-sided analogue of [`APCurvilinearTriangle2`](@ref).
"""
struct APCurvilinearQuadrilateral2{T<:Real} <: APPolygon{2,T}
    sides::NTuple{4,APSide{T}}
end
function APCurvilinearQuadrilateral2(s1, s2, s3, s4)
    T = promote_type(_side_eltype(s1), _side_eltype(s2), _side_eltype(s3), _side_eltype(s4))
    return APCurvilinearQuadrilateral2((_side_convert(s1, T), _side_convert(s2, T), _side_convert(s3, T), _side_convert(s4, T)))
end
sides(q::APCurvilinearQuadrilateral2) = q.sides
Base.:(==)(x::APCurvilinearQuadrilateral2, y::APCurvilinearQuadrilateral2) = x.sides == y.sides
Base.hash(x::APCurvilinearQuadrilateral2, h::UInt) = hash(x.sides, hash(:APCurvilinearQuadrilateral2, h))
Base.show(io::IO, q::APCurvilinearQuadrilateral2) = print(io, "APCurvilinearQuadrilateral2", q.sides)
rotate(q::APCurvilinearQuadrilateral2, angle::Real, center::APPoint=APPoint(0.0, 0.0)) =
    APCurvilinearQuadrilateral2(map(s -> rotate(s, angle, center), q.sides))
homothety(q::APCurvilinearQuadrilateral2, k::Real, center::APPoint=APPoint(0.0, 0.0)) =
    APCurvilinearQuadrilateral2(map(s -> homothety(s, k, center), q.sides))
reflection(q::APCurvilinearQuadrilateral2, about) = APCurvilinearQuadrilateral2(map(s -> reflection(s, about), q.sides))
translate(q::APCurvilinearQuadrilateral2, v::APVector) = APCurvilinearQuadrilateral2(map(s -> translate(s, v), q.sides))
"""
    APCurvilinearNgon2(sides::AbstractVector)

A closed region bounded by any number of sides, each an [`APSegment`](@ref)
or an [`APCircularArc2`](@ref): the fully general case of the curved
[`APPolygon`](@ref) family.
"""
struct APCurvilinearNgon2{T<:Real} <: APPolygon{2,T}
    sides::Vector{APSide{T}}
end
_side_eltype(::APSegment{2,T}) where {T} = T
_side_eltype(::APCircularArc2{T}) where {T} = T
_side_eltype(::APEllipticArc2{T}) where {T} = T
_side_eltype(::APParabolicArc2{T}) where {T} = T
_side_eltype(::APHyperbolicArc2{T}) where {T} = T
_side_convert(s::APSegment, ::Type{T}) where {T} = convert(APSegment{2,T}, s)
_side_convert(s::APCircularArc2, ::Type{T}) where {T} = convert(APCircularArc2{T}, s)
_side_convert(s::APEllipticArc2, ::Type{T}) where {T} = convert(APEllipticArc2{T}, s)
_side_convert(s::APParabolicArc2, ::Type{T}) where {T} = convert(APParabolicArc2{T}, s)
_side_convert(s::APHyperbolicArc2, ::Type{T}) where {T} = convert(APHyperbolicArc2{T}, s)
function APCurvilinearNgon2(sides::AbstractVector)
    T = promote_type(_side_eltype.(sides)...)
    return APCurvilinearNgon2(APSide{T}[_side_convert(s, T) for s in sides])
end
"""
    APCurvilinearNgon2(sides...)

Same as [`APCurvilinearNgon2(::AbstractVector)`](@ref) above, one side per
argument instead of wrapped in a `Vector`: matching
[`APCurvilinearTriangle2`](@ref)/[`APCurvilinearQuadrilateral2`](@ref)'s
own fixed-count, one-argument-per-side style for the arbitrary-count case.
"""
APCurvilinearNgon2(sides...) = APCurvilinearNgon2(collect(sides))
sides(pg::APCurvilinearNgon2) = pg.sides
Base.getindex(pg::APCurvilinearNgon2, i::Integer) = pg.sides[i]
Base.length(pg::APCurvilinearNgon2) = length(pg.sides)
Base.iterate(pg::APCurvilinearNgon2, i::Int=1) = i > length(pg) ? nothing : (pg[i], i + 1)
Base.:(==)(x::APCurvilinearNgon2, y::APCurvilinearNgon2) = x.sides == y.sides
Base.hash(x::APCurvilinearNgon2, h::UInt) = hash(x.sides, hash(:APCurvilinearNgon2, h))
Base.show(io::IO, pg::APCurvilinearNgon2) = print(io, "APCurvilinearNgon2(", pg.sides, ")")
rotate(pg::APCurvilinearNgon2, angle::Real, center::APPoint=APPoint(0.0, 0.0)) =
    APCurvilinearNgon2([rotate(s, angle, center) for s in pg.sides])
homothety(pg::APCurvilinearNgon2, k::Real, center::APPoint=APPoint(0.0, 0.0)) =
    APCurvilinearNgon2([homothety(s, k, center) for s in pg.sides])
reflection(pg::APCurvilinearNgon2, about) = APCurvilinearNgon2([reflection(s, about) for s in pg.sides])
translate(pg::APCurvilinearNgon2, v::APVector) = APCurvilinearNgon2([translate(s, v) for s in pg.sides])
"""
    APBoundingBox(pg::APPolygon)

The axis-aligned bounding box of `pg`. The generic
[`APBoundingBox(::APPolygon)`](@ref) in ap_polygon.jl (via `vertices`)
doesn't apply to any curved-sided region, [`APCircularSector2`](@ref),
`APCircularSegment2`, `APAnnularSector2`, `APInterstice2`,
`APCurvilinearTriangle2`, `APCurvilinearQuadrilateral2`,
`APCurvilinearNgon2` don't implement `vertices`, so this instead unions
the bounding box of each of `pg`'s own [`sides`](@ref) (every side type,
straight or any conic arc, already knows its own bounding box).
"""
function APBoundingBox(pg::Union{APCircularSector2,APCircularSegment2,APAnnularSector2,
    APInterstice2,APCurvilinearTriangle2,APCurvilinearQuadrilateral2,APCurvilinearNgon2})
    boxes = [APBoundingBox(s) for s in sides(pg)]
    lo = APPoint(minimum(b.min[1] for b in boxes), minimum(b.min[2] for b in boxes))
    hi = APPoint(maximum(b.max[1] for b in boxes), maximum(b.max[2] for b in boxes))
    return APBoundingBox(lo, hi)
end
