# -------------------------------------------------------------------------
# EGCircularSector2, EGCircularSegment2, EGAnnularSector2, EGInterstice2,
# EGCurvilinearTriangle2, EGCurvilinearQuadrilateral2, EGCurvilinearNgon2 —
# all <: EGPolygon, all sharing the generic `sides`-based area/perimeter
# from eg_polygon.jl. Each just implements `sides(p)` (a mix of
# EGSegment/EGCircularArc2) and its own rotate/reflection/homothety
# (pointwise per side).
#
# `EGInterstice2` here is buildable directly from 3 arcs; the
# `interstices(c1, c2, c3)` convenience constructor (given 3 mutually
# tangent circles) lives in eg_apollonius.jl instead, since it needs
# `tangent_circles` (the CCC Apollonius solver).
# -------------------------------------------------------------------------

# `_side_p1`/`_side_p2`/`_side_length`/`_side_greens_term`/`_side_scale`
# for an EGCircularArc2 side (the EGSegment ones are in eg_polygon.jl).
_side_p1(s::EGCircularArc2) = s.p1
_side_p2(s::EGCircularArc2) = s.p2
_side_length(s::EGCircularArc2) = arc_length(s)
_side_greens_term(s::EGCircularArc2) = begin
    c = s.circle
    θ1 = atan(s.p1[2] - c.center[2], s.p1[1] - c.center[1])
    Δθ = measure(s)
    θ2 = θ1 + Δθ
    (c.r^2 * Δθ + c.r * c.center[1] * (sin(θ2) - sin(θ1)) + c.r * c.center[2] * (cos(θ1) - cos(θ2))) / 2
end
_side_scale(s::EGCircularArc2) = max(s.circle.r, norm(s.circle.center))

# The same 5-method protocol, for the three arc types an affine-mapped
# curved region can end up with as a side (a circle maps to an ellipse
# under a general `EGAffineMap`, so a region built from circular arcs can
# come back with elliptic ones — see eg_transform.jl). `_side_length` is
# just the already-verified `arc_length`; `_side_greens_term` is the
# closed-form Green's-theorem line integral for that arc (derived by hand
# for each — no closed form exists for arc *length* on these three, but
# the area integral ∮(x dy - y dx) still does).
_side_p1(s::EGEllipticArc2) = s.p1
_side_p2(s::EGEllipticArc2) = s.p2
_side_length(s::EGEllipticArc2) = arc_length(s)
function _side_greens_term(s::EGEllipticArc2)
    e = s.ellipse
    θ1 = _ellipse_param(s, s.p1)
    Δθ = measure(s)
    θ2 = θ1 + Δθ
    P1, P2 = point_on_ellipse(e, θ1) - e.center, point_on_ellipse(e, θ2) - e.center
    return (e.a * e.b * Δθ + e.center[1] * (P2[2] - P1[2]) - e.center[2] * (P2[1] - P1[1])) / 2
end
_side_scale(s::EGEllipticArc2) = max(s.ellipse.a, s.ellipse.b, norm(s.ellipse.center))

_side_p1(s::EGHyperbolicArc2) = s.p1
_side_p2(s::EGHyperbolicArc2) = s.p2
_side_length(s::EGHyperbolicArc2) = arc_length(s)
function _side_greens_term(s::EGHyperbolicArc2)
    h = s.hyperbola
    t1, branch = _hyperbola_param(s, s.p1)
    t2, _ = _hyperbola_param(s, s.p2)
    P1, P2 = point_on_hyperbola(h, t1; branch=branch) - h.center, point_on_hyperbola(h, t2; branch=branch) - h.center
    return (branch * h.a * h.b * (t2 - t1) + h.center[1] * (P2[2] - P1[2]) - h.center[2] * (P2[1] - P1[1])) / 2
end
_side_scale(s::EGHyperbolicArc2) = max(s.hyperbola.a, s.hyperbola.b, norm(s.hyperbola.center))

_side_p1(s::EGParabolicArc2) = s.p1
_side_p2(s::EGParabolicArc2) = s.p2
_side_length(s::EGParabolicArc2) = arc_length(s)
function _side_greens_term(s::EGParabolicArc2)
    par = s.parabola
    V, _, _ = _parabola_frame(par)
    pf = focal_parameter(par)
    s1, s2 = _parabola_param(s, s.p1), _parabola_param(s, s.p2)
    P1, P2 = point_on_parabola(par, s1) - V, point_on_parabola(par, s2) - V
    local_term = -(s2^3 - s1^3) / (6pf)
    return (local_term + V[1] * (P2[2] - P1[2]) - V[2] * (P2[1] - P1[1])) / 2
end
_side_scale(s::EGParabolicArc2) = max(focal_parameter(s.parabola), norm(vertex(s.parabola)), 1.0)

# Generic transform helper shared by every type below: transform each side
# (Segment/CircularArc2 already know how to transform themselves) and
# rebuild via the given constructor.
_map_sides(f, ss) = map(f, ss)

# --- EGCircularSector2 -----------------------------------------------------

"""
    EGCircularSector2(arc::EGCircularArc2)
    EGCircularSector2(circle::EGCircle2, p1::EGPoint, p2::EGPoint)

The "pie slice" swept by `arc`: bounded by the two radii
`circle.center -> p1`, `circle.center -> p2`, and the arc itself.
"""
struct EGCircularSector2{T<:Real} <: EGPolygon{2,T}
    arc::EGCircularArc2{T}
end
EGCircularSector2(circle::EGCircle2, p1, p2) = EGCircularSector2(EGCircularArc2(circle, p1, p2))

Base.:(==)(x::EGCircularSector2, y::EGCircularSector2) = x.arc == y.arc
Base.isapprox(x::EGCircularSector2, y::EGCircularSector2; kwargs...) = isapprox(x.arc, y.arc; kwargs...)
Base.show(io::IO, s::EGCircularSector2) = print(io, "EGCircularSector2(", s.arc, ")")

sides(s::EGCircularSector2) = [EGSegment(s.arc.circle.center, s.arc.p1), s.arc, EGSegment(s.arc.p2, s.arc.circle.center)]

function Base.in(p::EGPoint, s::EGCircularSector2)
    c = s.arc.circle
    distance(p, c.center) > c.r && return false
    a1 = atan(s.arc.p1[2] - c.center[2], s.arc.p1[1] - c.center[1])
    ap = atan(p[2] - c.center[2], p[1] - c.center[1])
    return mod(ap - a1, 2π) <= measure(s.arc)
end

"""
    centroid(s::EGCircularSector2)

The centroid of `s`, at distance `(4r·sin(θ/2))/(3θ)` from the circle's
center along the arc's own bisector (`θ = measure(s.arc)`, `r =
s.arc.circle.r`) — the classical circular-sector centroid formula. Unlike
`area`/`perimeter` (which reuse the generic `EGPolygon` machinery via
[`sides`](@ref)), this is a dedicated formula: the generic
`centroid(::EGPolygon)` needs [`vertices`](@ref), which curved-sided
regions like this one don't implement.
"""
function centroid(s::EGCircularSector2)
    c = s.arc.circle
    θ = measure(s.arc)
    a1 = atan(s.arc.p1[2] - c.center[2], s.arc.p1[1] - c.center[1])
    ψ = a1 + θ / 2
    d = (4 * c.r * sin(θ / 2)) / (3θ)
    return c.center + d * EGVector(cos(ψ), sin(ψ))
end

rotate(s::EGCircularSector2, angle::Real, center::EGPoint=EGPoint(0.0, 0.0)) = EGCircularSector2(rotate(s.arc, angle, center))
homothety(s::EGCircularSector2, k::Real, center::EGPoint=EGPoint(0.0, 0.0)) = EGCircularSector2(homothety(s.arc, k, center))
reflection(s::EGCircularSector2, about) = EGCircularSector2(reflection(s.arc, about))
translate(s::EGCircularSector2, v::EGVector) = EGCircularSector2(translate(s.arc, v))

# --- EGCircularSegment2 ----------------------------------------------------

"""
    EGCircularSegment2(arc::EGCircularArc2)
    EGCircularSegment2(circle::EGCircle2, p1::EGPoint, p2::EGPoint)

The "cap" bounded by `arc` and the straight chord `[p1, p2]`.
"""
struct EGCircularSegment2{T<:Real} <: EGPolygon{2,T}
    arc::EGCircularArc2{T}
end
EGCircularSegment2(circle::EGCircle2, p1, p2) = EGCircularSegment2(EGCircularArc2(circle, p1, p2))

Base.:(==)(x::EGCircularSegment2, y::EGCircularSegment2) = x.arc == y.arc
Base.isapprox(x::EGCircularSegment2, y::EGCircularSegment2; kwargs...) = isapprox(x.arc, y.arc; kwargs...)
Base.show(io::IO, s::EGCircularSegment2) = print(io, "EGCircularSegment2(", s.arc, ")")

sides(s::EGCircularSegment2) = [s.arc, EGSegment(s.arc.p2, s.arc.p1)]

function Base.in(p::EGPoint, s::EGCircularSegment2)
    c = s.arc.circle
    distance(p, c.center) > c.r && return false
    chord = EGLine(s.arc.p1, s.arc.p2)
    side_of_chord(q) = sign(cross2(direction(chord), q - chord.p1))
    return side_of_chord(p) == side_of_chord(midpoint(s.arc))
end

"""
    centroid(s::EGCircularSegment2)

The centroid of `s`, at distance `(4r·sin³(θ/2))/(3(θ-sinθ))` from the
circle's center along the arc's own bisector — the classical
circular-segment centroid formula (see
[`centroid(::EGCircularSector2)`](@ref) for why this is a dedicated
formula rather than the generic `EGPolygon` one).
"""
function centroid(s::EGCircularSegment2)
    c = s.arc.circle
    θ = measure(s.arc)
    a1 = atan(s.arc.p1[2] - c.center[2], s.arc.p1[1] - c.center[1])
    ψ = a1 + θ / 2
    d = (4 * c.r * sin(θ / 2)^3) / (3 * (θ - sin(θ)))
    return c.center + d * EGVector(cos(ψ), sin(ψ))
end

rotate(s::EGCircularSegment2, angle::Real, center::EGPoint=EGPoint(0.0, 0.0)) = EGCircularSegment2(rotate(s.arc, angle, center))
homothety(s::EGCircularSegment2, k::Real, center::EGPoint=EGPoint(0.0, 0.0)) = EGCircularSegment2(homothety(s.arc, k, center))
reflection(s::EGCircularSegment2, about) = EGCircularSegment2(reflection(s.arc, about))
translate(s::EGCircularSegment2, v::EGVector) = EGCircularSegment2(translate(s.arc, v))

# --- EGAnnularSector2 (new) -------------------------------------------------

"""
    EGAnnularSector2(outer::EGCircularArc2, r_inner::Real)

The region between two concentric arcs: `outer` (on the outer circle,
`outer.circle.r > r_inner`) and the corresponding arc of the concentric
circle of radius `r_inner`, closed by the two radial segments between
them — Luxor's own `sector(center, innerradius, outerradius, ...)` shape,
represented here as an [`EGPolygon`](@ref).
"""
struct EGAnnularSector2{T<:Real} <: EGPolygon{2,T}
    outer::EGCircularArc2{T}
    r_inner::T
    # An inner constructor is defined here specifically to suppress Julia's
    # auto-generated default outer constructor `EGAnnularSector2(outer::EGCircularArc2{T},
    # r_inner::T) where T` — without this, that unconstrained default is MORE
    # specific than (and silently wins over) the validating outer constructor
    # below whenever outer/r_inner already share the same T, letting an
    # invalid r_inner slip through with no ArgumentError.
    function EGAnnularSector2{T}(outer::EGCircularArc2{T}, r_inner::T) where {T<:Real}
        r_inner < outer.circle.r || throw(ArgumentError("EGAnnularSector2: r_inner must be less than the outer radius"))
        return new{T}(outer, r_inner)
    end
end
function EGAnnularSector2(outer::EGCircularArc2{T1}, r_inner::T2) where {T1,T2}
    T = promote_type(T1, T2)
    return EGAnnularSector2{T}(convert(EGCircularArc2{T}, outer), T(r_inner))
end

Base.:(==)(x::EGAnnularSector2, y::EGAnnularSector2) = x.outer == y.outer && x.r_inner == y.r_inner
Base.isapprox(x::EGAnnularSector2, y::EGAnnularSector2; kwargs...) =
    isapprox(x.outer, y.outer; kwargs...) && isapprox(x.r_inner, y.r_inner; kwargs...)
Base.show(io::IO, s::EGAnnularSector2) = print(io, "EGAnnularSector2(", s.outer, ", r_inner=", s.r_inner, ")")

function _inner_arc(s::EGAnnularSector2)
    c = s.outer.circle
    p1i = c.center + s.r_inner * (s.outer.p1 - c.center) / c.r
    p2i = c.center + s.r_inner * (s.outer.p2 - c.center) / c.r
    return EGCircularArc2(EGCircle2(c.center, s.r_inner), p1i, p2i)
end

function sides(s::EGAnnularSector2)
    inner = _inner_arc(s)
    return [EGSegment(inner.p1, s.outer.p1), s.outer, EGSegment(s.outer.p2, inner.p2), inner]
end

"""
    centroid(s::EGAnnularSector2)

The centroid of `s`, as the area-weighted difference of the outer and
inner sectors' own centroids (`(Aₒcₒ - Aᵢcᵢ)/(Aₒ-Aᵢ)`) — both share the
same bisector by construction, so this reduces to the same closed form as
[`centroid(::EGCircularSector2)`](@ref) applied twice.
"""
function centroid(s::EGAnnularSector2)
    outer_sector = EGCircularSector2(s.outer)
    inner_sector = EGCircularSector2(_inner_arc(s))
    Ao, Ai = area(outer_sector), area(inner_sector)
    c_outer, c_inner = centroid(outer_sector), centroid(inner_sector)
    return c_outer - Ai * (c_inner - c_outer) / (Ao - Ai)
end

rotate(s::EGAnnularSector2, angle::Real, center::EGPoint=EGPoint(0.0, 0.0)) = EGAnnularSector2(rotate(s.outer, angle, center), s.r_inner)
homothety(s::EGAnnularSector2, k::Real, center::EGPoint=EGPoint(0.0, 0.0)) = EGAnnularSector2(homothety(s.outer, k, center), abs(k) * s.r_inner)
reflection(s::EGAnnularSector2, about) = EGAnnularSector2(reflection(s.outer, about), s.r_inner)
translate(s::EGAnnularSector2, v::EGVector) = EGAnnularSector2(translate(s.outer, v), s.r_inner)

# --- EGInterstice2 ----------------------------------------------------------

"""
    EGInterstice2(arc1::EGCircularArc2, arc2::EGCircularArc2, arc3::EGCircularArc2)

A curvilinear triangle bounded by three circular arcs, each from a
different circle, meeting end to end. Build with [`interstices`](@ref)
rather than directly, in the common case of 3 mutually tangent circles.
"""
struct EGInterstice2{T<:Real} <: EGPolygon{2,T}
    arc1::EGCircularArc2{T}
    arc2::EGCircularArc2{T}
    arc3::EGCircularArc2{T}
end
function EGInterstice2(arc1::EGCircularArc2{T1}, arc2::EGCircularArc2{T2}, arc3::EGCircularArc2{T3}) where {T1,T2,T3}
    T = promote_type(T1, T2, T3)
    return EGInterstice2{T}(convert(EGCircularArc2{T}, arc1), convert(EGCircularArc2{T}, arc2), convert(EGCircularArc2{T}, arc3))
end

Base.getindex(g::EGInterstice2, i::Integer) = (g.arc1, g.arc2, g.arc3)[i]
Base.length(::EGInterstice2) = 3
Base.iterate(g::EGInterstice2, i::Int=1) = i > 3 ? nothing : (g[i], i + 1)
Base.:(==)(x::EGInterstice2, y::EGInterstice2) = x.arc1 == y.arc1 && x.arc2 == y.arc2 && x.arc3 == y.arc3
Base.isapprox(x::EGInterstice2, y::EGInterstice2; kwargs...) =
    isapprox(x.arc1, y.arc1; kwargs...) && isapprox(x.arc2, y.arc2; kwargs...) && isapprox(x.arc3, y.arc3; kwargs...)
Base.show(io::IO, g::EGInterstice2) = print(io, "EGInterstice2(", g.arc1, ", ", g.arc2, ", ", g.arc3, ")")

sides(g::EGInterstice2) = [g.arc1, g.arc2, g.arc3]

rotate(g::EGInterstice2, angle::Real, center::EGPoint=EGPoint(0.0, 0.0)) =
    EGInterstice2(rotate(g.arc1, angle, center), rotate(g.arc2, angle, center), rotate(g.arc3, angle, center))
homothety(g::EGInterstice2, k::Real, center::EGPoint=EGPoint(0.0, 0.0)) =
    EGInterstice2(homothety(g.arc1, k, center), homothety(g.arc2, k, center), homothety(g.arc3, k, center))
reflection(g::EGInterstice2, about) =
    EGInterstice2(reflection(g.arc1, about), reflection(g.arc2, about), reflection(g.arc3, about))
translate(g::EGInterstice2, v::EGVector) =
    EGInterstice2(translate(g.arc1, v), translate(g.arc2, v), translate(g.arc3, v))

# --- EGCurvilinearTriangle2 (new) -------------------------------------------

const EGSide{T} = Union{EGSegment{2,T},EGCircularArc2{T},EGEllipticArc2{T},EGParabolicArc2{T},EGHyperbolicArc2{T}}

"""
    EGCurvilinearTriangle2(side1, side2, side3)

A closed region bounded by 3 sides, each independently an [`EGSegment`](@ref)
or a conic arc ([`EGCircularArc2`](@ref), `EGEllipticArc2`,
`EGParabolicArc2`, `EGHyperbolicArc2`) — the general 3-sided analogue of
[`EGTriangle`](@ref) (all straight) and [`EGInterstice2`](@ref) (all
circular arcs). The wider arc coverage (beyond just circular) exists
mainly so that `EGAffineMap`-transformed circular-arc regions — whose
arcs generically become elliptic under a non-conformal map — still fit.
"""
struct EGCurvilinearTriangle2{T<:Real} <: EGPolygon{2,T}
    sides::NTuple{3,EGSide{T}}
end
function EGCurvilinearTriangle2(s1, s2, s3)
    T = promote_type(_side_eltype(s1), _side_eltype(s2), _side_eltype(s3))
    return EGCurvilinearTriangle2((_side_convert(s1, T), _side_convert(s2, T), _side_convert(s3, T)))
end

sides(t::EGCurvilinearTriangle2) = t.sides
Base.:(==)(x::EGCurvilinearTriangle2, y::EGCurvilinearTriangle2) = x.sides == y.sides
Base.show(io::IO, t::EGCurvilinearTriangle2) = print(io, "EGCurvilinearTriangle2", t.sides)

_transform_side(f, s::EGSegment) = f(s)
_transform_side(f, s::EGCircularArc2) = f(s)

rotate(t::EGCurvilinearTriangle2, angle::Real, center::EGPoint=EGPoint(0.0, 0.0)) =
    EGCurvilinearTriangle2(map(s -> rotate(s, angle, center), t.sides))
homothety(t::EGCurvilinearTriangle2, k::Real, center::EGPoint=EGPoint(0.0, 0.0)) =
    EGCurvilinearTriangle2(map(s -> homothety(s, k, center), t.sides))
reflection(t::EGCurvilinearTriangle2, about) = EGCurvilinearTriangle2(map(s -> reflection(s, about), t.sides))
translate(t::EGCurvilinearTriangle2, v::EGVector) = EGCurvilinearTriangle2(map(s -> translate(s, v), t.sides))

# --- EGCurvilinearQuadrilateral2 (new) --------------------------------------

"""
    EGCurvilinearQuadrilateral2(side1, side2, side3, side4)

The 4-sided analogue of [`EGCurvilinearTriangle2`](@ref).
"""
struct EGCurvilinearQuadrilateral2{T<:Real} <: EGPolygon{2,T}
    sides::NTuple{4,EGSide{T}}
end
function EGCurvilinearQuadrilateral2(s1, s2, s3, s4)
    T = promote_type(_side_eltype(s1), _side_eltype(s2), _side_eltype(s3), _side_eltype(s4))
    return EGCurvilinearQuadrilateral2((_side_convert(s1, T), _side_convert(s2, T), _side_convert(s3, T), _side_convert(s4, T)))
end

sides(q::EGCurvilinearQuadrilateral2) = q.sides
Base.:(==)(x::EGCurvilinearQuadrilateral2, y::EGCurvilinearQuadrilateral2) = x.sides == y.sides
Base.show(io::IO, q::EGCurvilinearQuadrilateral2) = print(io, "EGCurvilinearQuadrilateral2", q.sides)

rotate(q::EGCurvilinearQuadrilateral2, angle::Real, center::EGPoint=EGPoint(0.0, 0.0)) =
    EGCurvilinearQuadrilateral2(map(s -> rotate(s, angle, center), q.sides))
homothety(q::EGCurvilinearQuadrilateral2, k::Real, center::EGPoint=EGPoint(0.0, 0.0)) =
    EGCurvilinearQuadrilateral2(map(s -> homothety(s, k, center), q.sides))
reflection(q::EGCurvilinearQuadrilateral2, about) = EGCurvilinearQuadrilateral2(map(s -> reflection(s, about), q.sides))
translate(q::EGCurvilinearQuadrilateral2, v::EGVector) = EGCurvilinearQuadrilateral2(map(s -> translate(s, v), q.sides))

# --- EGCurvilinearNgon2 (n mixed sides, general case) -----------------------

"""
    EGCurvilinearNgon2(sides::AbstractVector)

A closed region bounded by any number of sides, each an [`EGSegment`](@ref)
or an [`EGCircularArc2`](@ref) — the fully general case of the curved
[`EGPolygon`](@ref) family.
"""
struct EGCurvilinearNgon2{T<:Real} <: EGPolygon{2,T}
    sides::Vector{EGSide{T}}
end

_side_eltype(::EGSegment{2,T}) where {T} = T
_side_eltype(::EGCircularArc2{T}) where {T} = T
_side_eltype(::EGEllipticArc2{T}) where {T} = T
_side_eltype(::EGParabolicArc2{T}) where {T} = T
_side_eltype(::EGHyperbolicArc2{T}) where {T} = T

# `convert(EGSide{T}, s)` doesn't work directly: `EGSide{T}` is a `Union`,
# and Julia's generic `convert` fallback only handles the case where `s`
# is already exactly one of the union's members, not "convert to whichever
# member matches `s`'s own type" — so each side type needs its own method
# here instead, dispatching on `s` and delegating to the concrete
# `convert(::Type{EGSegment{2,T}}, ...)`/etc. that already exists for it.
_side_convert(s::EGSegment, ::Type{T}) where {T} = convert(EGSegment{2,T}, s)
_side_convert(s::EGCircularArc2, ::Type{T}) where {T} = convert(EGCircularArc2{T}, s)
_side_convert(s::EGEllipticArc2, ::Type{T}) where {T} = convert(EGEllipticArc2{T}, s)
_side_convert(s::EGParabolicArc2, ::Type{T}) where {T} = convert(EGParabolicArc2{T}, s)
_side_convert(s::EGHyperbolicArc2, ::Type{T}) where {T} = convert(EGHyperbolicArc2{T}, s)

# A plain `[seg, arc, seg]` array literal infers as `Vector{EGCurve{2,T}}`
# (the common abstract supertype), which doesn't convert to
# `Vector{EGSide{T}}` (Julia containers are invariant) — so accept any
# AbstractVector of sides and re-narrow the element type here. Each side
# is explicitly `_side_convert`ed first (rather than relying on the
# `EGSide{T}[...]` literal to convert them itself), for the same
# Union-target reason `_side_convert` exists.
function EGCurvilinearNgon2(sides::AbstractVector)
    T = promote_type(_side_eltype.(sides)...)
    return EGCurvilinearNgon2(EGSide{T}[_side_convert(s, T) for s in sides])
end

sides(pg::EGCurvilinearNgon2) = pg.sides
Base.getindex(pg::EGCurvilinearNgon2, i::Integer) = pg.sides[i]
Base.length(pg::EGCurvilinearNgon2) = length(pg.sides)
Base.iterate(pg::EGCurvilinearNgon2, i::Int=1) = i > length(pg) ? nothing : (pg[i], i + 1)
Base.:(==)(x::EGCurvilinearNgon2, y::EGCurvilinearNgon2) = x.sides == y.sides
Base.show(io::IO, pg::EGCurvilinearNgon2) = print(io, "EGCurvilinearNgon2(", pg.sides, ")")

rotate(pg::EGCurvilinearNgon2, angle::Real, center::EGPoint=EGPoint(0.0, 0.0)) =
    EGCurvilinearNgon2([rotate(s, angle, center) for s in pg.sides])
homothety(pg::EGCurvilinearNgon2, k::Real, center::EGPoint=EGPoint(0.0, 0.0)) =
    EGCurvilinearNgon2([homothety(s, k, center) for s in pg.sides])
reflection(pg::EGCurvilinearNgon2, about) = EGCurvilinearNgon2([reflection(s, about) for s in pg.sides])
translate(pg::EGCurvilinearNgon2, v::EGVector) = EGCurvilinearNgon2([translate(s, v) for s in pg.sides])

"""
    EGBoundingBox(pg::EGPolygon)

The axis-aligned bounding box of `pg`. The generic
[`EGBoundingBox(::EGPolygon)`](@ref) in eg_polygon.jl (via `vertices`)
doesn't apply to any curved-sided region — [`EGCircularSector2`](@ref),
`EGCircularSegment2`, `EGAnnularSector2`, `EGInterstice2`,
`EGCurvilinearTriangle2`, `EGCurvilinearQuadrilateral2`,
`EGCurvilinearNgon2` don't implement `vertices` — so this instead unions
the bounding box of each of `pg`'s own [`sides`](@ref) (every side type,
straight or any conic arc, already knows its own bounding box).
"""
function EGBoundingBox(pg::Union{EGCircularSector2,EGCircularSegment2,EGAnnularSector2,
    EGInterstice2,EGCurvilinearTriangle2,EGCurvilinearQuadrilateral2,EGCurvilinearNgon2})
    boxes = [EGBoundingBox(s) for s in sides(pg)]
    lo = EGPoint(minimum(b.min[1] for b in boxes), minimum(b.min[2] for b in boxes))
    hi = EGPoint(maximum(b.max[1] for b in boxes), maximum(b.max[2] for b in boxes))
    return EGBoundingBox(lo, hi)
end
