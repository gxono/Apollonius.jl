# -------------------------------------------------------------------------
# Phase 3 of the EG-prefixed type hierarchy rewrite (see
# .claude/plans/structured-wibbling-wigderson.md): EGTriangle,
# EGQuadrilateral, EGStraightNgon, all <: EGPolygon, with area/perimeter/
# centroid/is_convex/point_in_polygon implemented ONCE, generically, via a
# `vertices(p)` protocol — instead of once per concrete type. Coexists
# alongside the existing Point2-based Triangle/Quadrilateral/Polygon for
# now — nothing else in the package is migrated onto these yet.
#
# Deliberately out of scope here (deferred to when predicates.jl/
# intersections.jl themselves get migrated): `is_cyclic`, `is_degenerate`,
# `diagonal_intersection` — they need `is_concyclic`/`is_collinear`/
# `intersection(::EGLine, ::EGLine)`, none of which exist yet for EGPoint.
# -------------------------------------------------------------------------

# --- EGPolygon generic protocol -----------------------------------------
#
# Every concrete subtype implements EITHER `vertices(p)` (a straight-sided
# polygon: Triangle/Quadrilateral/StraightNgon) OR `sides(p)` directly (a
# region with at least one curved side, from Phase 5 onward — a Segment
# side, or an EGCircularArc2 side). `sides(p::EGPolygon)` below is the
# generic *default*, built from `vertices`, so straight-sided types don't
# need to define it themselves; `area`/`perimeter` are then written ONCE,
# purely in terms of `sides`, via the same Green's-theorem line-integral
# walk this package already used for `CurvilinearPolygon`/`Interstice`
# (mathematically identical to the plain shoelace formula when every side
# happens to be straight, so this is a compatible generalization, not a
# behavior change, for Triangle/Quadrilateral/StraightNgon).

"""
    sides(p::EGPolygon)

The sides of `p`, in order. Default: straight [`EGSegment`](@ref)s
between consecutive [`vertices`](@ref); concrete curved-region subtypes
(from Phase 5 on) override this directly instead of implementing
`vertices`.
"""
function sides(p::EGPolygon)
    v = vertices(p)
    n = length(v)
    return [EGSegment(v[i], v[mod1(i + 1, n)]) for i in 1:n]
end

_side_p1(s::EGSegment) = s.p1
_side_p2(s::EGSegment) = s.p2
_side_length(s::EGSegment) = distance(s.p1, s.p2)
_side_greens_term(s::EGSegment) = (s.p1[1] * s.p2[2] - s.p2[1] * s.p1[2]) / 2
_side_scale(s::EGSegment) = norm(s.p1)
# `_side_p1`/`_side_p2`/`_side_length`/`_side_greens_term`/`_side_scale`
# for EGCircularArc2 sides are added in eg_curved_region.jl (Phase 5),
# which is included after EGCircularArc2 itself is defined.

# Chains `sides` into a single closed walk, starting from `sides[1]`'s own
# p1->p2 direction, reporting for each whether it must be walked reversed
# to continue the chain — mirrors `Interstice`'s `_interstice_walk`/
# `CurvilinearPolygon`'s `_curvilinear_walk`, generalized to any polygon.
function _polygon_walk(theSides; atol=1e-9)
    n = length(theSides)
    scale = max(1.0, maximum(_side_scale, theSides))
    tol = sqrt(atol) * scale
    order = Tuple{eltype(theSides),Bool}[(theSides[1], false)]
    used, last_pt = Set(1), _side_p2(theSides[1])
    for _ in 1:n-1
        for i in setdiff(1:n, used)
            if isapprox(_side_p1(theSides[i]), last_pt; atol=tol)
                push!(order, (theSides[i], false))
                last_pt = _side_p2(theSides[i])
                push!(used, i)
                break
            elseif isapprox(_side_p2(theSides[i]), last_pt; atol=tol)
                push!(order, (theSides[i], true))
                last_pt = _side_p1(theSides[i])
                push!(used, i)
                break
            end
        end
    end
    return order
end

"""
    area(p::EGPolygon)

Unsigned area of `p`, via the Green's-theorem line integral `(1/2)|∮(x dy
- y dx)|` around [`sides`](@ref) — correct whether every side is straight
or some are [`EGCircularArc2`](@ref)s.
"""
function area(p::EGPolygon)
    total = sum(_polygon_walk(sides(p))) do (side, reversed)
        term = _side_greens_term(side)
        reversed ? -term : term
    end
    return abs(total)
end

"""
    perimeter(p::EGPolygon)
"""
perimeter(p::EGPolygon) = sum(_side_length, sides(p))

"""
    centroid(p::EGPolygon)

Area-weighted centroid of `p`. Falls back to the plain vertex average for
(near-)zero-area (degenerate) polygons. For a triangle this coincides
exactly with the plain vertex average (they're mathematically the same
thing at `n = 3`); [`EGQuadrilateral`](@ref) overrides this with the
plain average deliberately, since that's its own well-known convention.
"""
function centroid(p::EGPolygon)
    v = vertices(p)
    n = length(v)
    A = zero(v[1][1])
    cx = zero(v[1][1])
    cy = zero(v[1][1])
    for i in 1:n
        j = i == n ? 1 : i + 1
        cr = cross2(v[i], v[j])
        A += cr
        cx += (v[i][1] + v[j][1]) * cr
        cy += (v[i][2] + v[j][2]) * cr
    end
    A /= 2
    abs(A) <= 1e-12 && return sum(v) / n
    return EGPoint(cx / (6A), cy / (6A))
end

"""
    is_convex(p::EGPolygon; atol=1e-9)
"""
function is_convex(p::EGPolygon; atol=1e-9)
    v = vertices(p)
    n = length(v)
    n < 3 && return false
    got_sign = 0
    for i in 1:n
        a = v[i]
        b = v[mod1(i + 1, n)]
        c = v[mod1(i + 2, n)]
        cr = cross2(b - a, c - b)
        abs(cr) <= atol * norm(b - a) * norm(c - b) && continue
        s = cr > 0 ? 1 : -1
        if got_sign == 0
            got_sign = s
        elseif s != got_sign
            return false
        end
    end
    return true
end

"""
    point_in_polygon(p::EGPoint, pg::EGPolygon)

Whether `p` lies inside `pg`, via ray-casting (even-odd rule). Points
exactly on the boundary may return either `true` or `false`.
"""
function point_in_polygon(p::EGPoint, pg::EGPolygon)
    v = vertices(pg)
    n = length(v)
    inside = false
    j = n
    for i in 1:n
        xi, yi = v[i][1], v[i][2]
        xj, yj = v[j][1], v[j][2]
        if ((yi > p[2]) != (yj > p[2])) && (p[1] < (xj - xi) * (p[2] - yi) / (yj - yi) + xi)
            inside = !inside
        end
        j = i
    end
    return inside
end
Base.in(p::EGPoint, pg::EGPolygon) = point_in_polygon(p, pg)

EGBoundingBox(p::EGPolygon) = EGBoundingBox(collect(vertices(p)))

# --- EGTriangle -----------------------------------------------------------

"""
    EGTriangle(a, b, c)
"""
struct EGTriangle{Dim,T<:Real} <: EGPolygon{Dim,T}
    a::EGPoint{Dim,T}
    b::EGPoint{Dim,T}
    c::EGPoint{Dim,T}
end
EGTriangle(a::EGPoint{Dim,T1}, b::EGPoint{Dim,T2}, c::EGPoint{Dim,T3}) where {Dim,T1,T2,T3} =
    EGTriangle{Dim,promote_type(T1, T2, T3)}(a, b, c)

"""
    vertices(p)

The vertices of a straight-sided [`EGPolygon`](@ref) (`EGTriangle`,
`EGQuadrilateral`, `EGStraightNgon`), in order.
"""
vertices(t::EGTriangle) = (t.a, t.b, t.c)
Base.getindex(t::EGTriangle, i::Integer) = vertices(t)[i]
Base.length(::EGTriangle) = 3
Base.iterate(t::EGTriangle, i::Int=1) = i > 3 ? nothing : (t[i], i + 1)
Base.:(==)(x::EGTriangle, y::EGTriangle) = x.a == y.a && x.b == y.b && x.c == y.c
Base.isapprox(x::EGTriangle, y::EGTriangle; kwargs...) =
    isapprox(x.a, y.a; kwargs...) && isapprox(x.b, y.b; kwargs...) && isapprox(x.c, y.c; kwargs...)
Base.show(io::IO, t::EGTriangle) = print(io, "EGTriangle(", t.a, ", ", t.b, ", ", t.c, ")")

rotate(t::EGTriangle, angle::Real, center::EGPoint=EGPoint(0.0, 0.0)) =
    EGTriangle(rotate(t.a, angle, center), rotate(t.b, angle, center), rotate(t.c, angle, center))
reflection(t::EGTriangle, about) = EGTriangle(reflection(t.a, about), reflection(t.b, about), reflection(t.c, about))
homothety(t::EGTriangle, k::Real, center::EGPoint=EGPoint(0.0, 0.0)) =
    EGTriangle(homothety(t.a, k, center), homothety(t.b, k, center), homothety(t.c, k, center))

# --- EGQuadrilateral --------------------------------------------------------

"""
    EGQuadrilateral(a, b, c, d)

Consecutive vertices `a, b, c, d` — not assumed convex, cyclic, or of any
special kind.
"""
struct EGQuadrilateral{Dim,T<:Real} <: EGPolygon{Dim,T}
    a::EGPoint{Dim,T}
    b::EGPoint{Dim,T}
    c::EGPoint{Dim,T}
    d::EGPoint{Dim,T}
end
EGQuadrilateral(a::EGPoint{Dim,T1}, b::EGPoint{Dim,T2}, c::EGPoint{Dim,T3}, d::EGPoint{Dim,T4}) where {Dim,T1,T2,T3,T4} =
    EGQuadrilateral{Dim,promote_type(T1, T2, T3, T4)}(a, b, c, d)

vertices(q::EGQuadrilateral) = (q.a, q.b, q.c, q.d)
Base.getindex(q::EGQuadrilateral, i::Integer) = vertices(q)[i]
Base.length(::EGQuadrilateral) = 4
Base.iterate(q::EGQuadrilateral, i::Int=1) = i > 4 ? nothing : (q[i], i + 1)
Base.:(==)(x::EGQuadrilateral, y::EGQuadrilateral) = x.a == y.a && x.b == y.b && x.c == y.c && x.d == y.d
Base.isapprox(x::EGQuadrilateral, y::EGQuadrilateral; kwargs...) =
    isapprox(x.a, y.a; kwargs...) && isapprox(x.b, y.b; kwargs...) &&
    isapprox(x.c, y.c; kwargs...) && isapprox(x.d, y.d; kwargs...)
Base.show(io::IO, q::EGQuadrilateral) = print(io, "EGQuadrilateral(", q.a, ", ", q.b, ", ", q.c, ", ", q.d, ")")

"""
    sides(q::EGQuadrilateral)

The four side segments `[a,b]`, `[b,c]`, `[c,d]`, `[d,a]`.
"""
sides(q::EGQuadrilateral) = (EGSegment(q.a, q.b), EGSegment(q.b, q.c), EGSegment(q.c, q.d), EGSegment(q.d, q.a))

"""
    diagonals(q::EGQuadrilateral)

The two diagonal segments `[a,c]` and `[b,d]`.
"""
diagonals(q::EGQuadrilateral) = (EGSegment(q.a, q.c), EGSegment(q.b, q.d))

"""
    diagonal_intersection(q::EGQuadrilateral; atol=1e-9)

Where the two diagonals `[a,c]` and `[b,d]` cross, or `nothing` if
they're parallel (a degenerate quadrilateral).

Deferred from Phase 3 (needed `intersection(::EGLine, ::EGLine)`, not yet
ported then) — now available since `eg_intersections.jl` (Phase 7) is
included after this file.
"""
function diagonal_intersection(q::EGQuadrilateral; atol=1e-9)
    pts = intersection(EGLine(q.a, q.c), EGLine(q.b, q.d); atol=atol)
    isempty(pts) && return nothing
    return pts[1]
end

"""
    is_cyclic(q::EGQuadrilateral; atol=1e-9)

Whether the four vertices of `q` lie on a common circle. Also deferred
from Phase 3 (needed `is_concyclic`, itself needing
`circumcenter`/`circumradius(::EGTriangle)`, not ported until
eg_triangle.jl) — referenced here only inside a function body, so the
include order (this file comes well before eg_triangle.jl) doesn't matter.
"""
is_cyclic(q::EGQuadrilateral; atol=1e-9) = is_concyclic(q.a, q.b, q.c, q.d; atol=atol)

"""
    centroid(q::EGQuadrilateral)

The plain (equal-weight) average of the four vertices — *not*
area-weighted (that's [`centroid(::EGPolygon)`](@ref), which
`EGStraightNgon`/`EGTriangle` use instead).
"""
centroid(q::EGQuadrilateral) = (q.a + q.b + q.c + q.d) / 4

rotate(q::EGQuadrilateral, angle::Real, center::EGPoint=EGPoint(0.0, 0.0)) =
    EGQuadrilateral(rotate(q.a, angle, center), rotate(q.b, angle, center), rotate(q.c, angle, center), rotate(q.d, angle, center))
reflection(q::EGQuadrilateral, about) =
    EGQuadrilateral(reflection(q.a, about), reflection(q.b, about), reflection(q.c, about), reflection(q.d, about))
homothety(q::EGQuadrilateral, k::Real, center::EGPoint=EGPoint(0.0, 0.0)) =
    EGQuadrilateral(homothety(q.a, k, center), homothety(q.b, k, center), homothety(q.c, k, center), homothety(q.d, k, center))

# --- EGStraightNgon ---------------------------------------------------------

"""
    EGStraightNgon(vertices::AbstractVector{<:EGPoint})

A simple polygon with an arbitrary number of straight sides (assumed
simple — edges don't cross themselves), given as an ordered list of
vertices (no repeated closing point). The straight-sided analogue of
[`EGCurvilinearNgon2`](@ref).
"""
struct EGStraightNgon{Dim,T<:Real} <: EGPolygon{Dim,T}
    vertices::Vector{EGPoint{Dim,T}}
end

vertices(pg::EGStraightNgon) = pg.vertices
Base.getindex(pg::EGStraightNgon, i::Integer) = pg.vertices[i]
Base.length(pg::EGStraightNgon) = length(pg.vertices)
Base.iterate(pg::EGStraightNgon, i::Int=1) = i > length(pg) ? nothing : (pg[i], i + 1)
Base.:(==)(x::EGStraightNgon, y::EGStraightNgon) = x.vertices == y.vertices
Base.isapprox(x::EGStraightNgon, y::EGStraightNgon; kwargs...) =
    length(x) == length(y) && all(isapprox(a, b; kwargs...) for (a, b) in zip(x.vertices, y.vertices))
Base.show(io::IO, pg::EGStraightNgon) = print(io, "EGStraightNgon(", pg.vertices, ")")

rotate(pg::EGStraightNgon, angle::Real, center::EGPoint=EGPoint(0.0, 0.0)) =
    EGStraightNgon([rotate(v, angle, center) for v in pg.vertices])
reflection(pg::EGStraightNgon, about) = EGStraightNgon([reflection(v, about) for v in pg.vertices])
homothety(pg::EGStraightNgon, k::Real, center::EGPoint=EGPoint(0.0, 0.0)) =
    EGStraightNgon([homothety(v, k, center) for v in pg.vertices])

"""
    convex_hull(points::AbstractVector{<:EGPoint})

The convex hull of `points`, as an [`EGStraightNgon`](@ref) (Andrew's
monotone chain algorithm, `O(n log n)`).
"""
function convex_hull(points::AbstractVector{<:EGPoint})
    pts = sort(unique(points); by=p -> (p[1], p[2]))
    n = length(pts)
    n <= 2 && return EGStraightNgon(pts)

    cross3(o, a, b) = cross2(a - o, b - o)

    lower = eltype(pts)[]
    for p in pts
        while length(lower) >= 2 && cross3(lower[end-1], lower[end], p) <= 0
            pop!(lower)
        end
        push!(lower, p)
    end

    upper = eltype(pts)[]
    for p in Iterators.reverse(pts)
        while length(upper) >= 2 && cross3(upper[end-1], upper[end], p) <= 0
            pop!(upper)
        end
        push!(upper, p)
    end

    return EGStraightNgon(vcat(lower[1:end-1], upper[1:end-1]))
end
