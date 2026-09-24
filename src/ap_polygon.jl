"""
    sides(p::APPolygon)

The sides of `p`, in order. Default: straight [`APSegment`](@ref)s
between consecutive [`vertices`](@ref); curved-region subtypes override
this directly instead of implementing `vertices`.
"""
function sides(p::APPolygon)
    v = vertices(p)
    n = length(v)
    return [APSegment(v[i], v[mod1(i + 1, n)]) for i in 1:n]
end
"""
    vertices(p::APPolygon)

The corner points of `p`, in order. Default: the starting point of each of
`p`'s [`sides`](@ref): the counterpart of `sides`'s own default above, for
any curved-region subtype that defines `sides` directly instead of
`vertices` (see the protocol note above).
"""
vertices(pg::APPolygon) = [_side_p1(s) for s in sides(pg)]
_side_p1(s::APSegment) = s.p1
_side_p2(s::APSegment) = s.p2
_side_length(s::APSegment) = distance(s.p1, s.p2)
_side_greens_term(s::APSegment) = (s.p1[1] * s.p2[2] - s.p2[1] * s.p1[2]) / 2
_side_scale(s::APSegment) = distance(s.p1, s.p2)
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
    area(p::APPolygon)

Unsigned area of `p`, via the Green's-theorem line integral `(1/2)|∮(x dy
- y dx)|` around [`sides`](@ref): correct whether every side is straight
or some are [`APCircularArc2`](@ref)s.
"""
function area(p::APPolygon)
    o = vertices(p)[1]
    # translate the first vertex to the origin, so the result does not degrade far from it
    q = translate(p, APVector(-o[1], -o[2]))
    total = sum(_polygon_walk(sides(q))) do (side, reversed)
        term = _side_greens_term(side)
        reversed ? -term : term
    end
    return abs(total)
end
"""
    area(p::APPolygon{3})

Area of the (assumed planar) 3D-embedded polygon `p`: [`APTriangle`](@ref)/
[`APQuadrilateral`](@ref)/[`APStraightNgon`](@ref) built from `APPoint{3}`
vertices, as `APPolyhedron` faces typically are. Via **Newell's method**,
`(1/2)|Σᵢ vᵢ × vᵢ₊₁|` using the true 3D cross product: the direct
generalization of the 2D shoelace formula above (which only reads 2 of a
3D vertex's 3 coordinates, silently projecting onto the xy-plane instead
of computing the true planar area: a dedicated `Dim`-specific method is
needed here, not a fallback, for exactly that reason).
"""
function area(p::APPolygon{3})
    vs = vertices(p)
    n = length(vs)
    s = sum(cross3(vs[i], vs[mod1(i + 1, n)]) for i in 1:n)
    return norm(s) / 2
end
"""
    is_planar(pg::APPolygon{3}; atol=1e-9)

Whether all of `pg`'s vertices lie in a common plane: worth checking
before trusting `area`/`centroid`/`is_convex`/`point_in_polygon` on a
hand-built `APStraightNgon{3}`/`APQuadrilateral{3}` (all four assume
planarity; none of them validate it, the same "assumed correct"
convention as `APStraightNgon`'s "assumed simple").
"""
function is_planar(pg::APPolygon{3}; atol=1e-9)
    vs = vertices(pg)
    length(vs) <= 3 && return true
    for i in 4:length(vs)
        is_coplanar(vs[1], vs[2], vs[3], vs[i]; atol=atol) || return false
    end
    return true
end
"""
    centroid(p::APPolygon{3})

Area-weighted centroid of the (assumed planar) 3D-embedded polygon `p`,
via the same fan-triangulation (from `p`'s own first vertex, weighted by
each triangle's signed area relative to `p`'s own Newell normal) that
[`area(::APPolygon{3})`](@ref) is built on: the 3D generalization of
`centroid(::APPolygon)`'s shoelace-based formula above.
"""
function centroid(p::APPolygon{3})
    vs = vertices(p)
    n = length(vs)
    v1 = vs[1]
    nrm = sum(cross3(vs[i], vs[mod1(i + 1, n)]) for i in 1:n)
    nn = norm(nrm)
    nn <= eps(Float64) && return v1 + sum(vi - v1 for vi in vs) / n
    n_hat = nrm / nn
    T = eltype(v1)
    A, cx, cy, cz = zero(T), zero(T), zero(T), zero(T)
    for i in 2:n-1
        vi, vi1 = vs[i], vs[i+1]
        tri_area = dot(cross3(vi - v1, vi1 - v1), n_hat) / 2
        A += tri_area
        cx += tri_area * (v1[1] + vi[1] + vi1[1]) / 3
        cy += tri_area * (v1[2] + vi[2] + vi1[2]) / 3
        cz += tri_area * (v1[3] + vi[3] + vi1[3]) / 3
    end
    abs(A) <= sqrt(eps(Float64)) * max(nn, 1.0) && return v1 + sum(vi - v1 for vi in vs) / n
    return APPoint(cx / A, cy / A, cz / A)
end
"""
    is_convex(p::APPolygon{3}; atol=1e-9)

Whether the (assumed planar) 3D-embedded polygon `p` is convex, via the
same "consistent turning sign" test as `is_convex(::APPolygon)`, with
each turn measured relative to `p`'s own Newell normal instead of the 2D
scalar cross product.
"""
function is_convex(p::APPolygon{3}; atol=1e-9)
    vs = vertices(p)
    n = length(vs)
    n < 3 && return false
    nrm = sum(cross3(vs[i], vs[mod1(i + 1, n)]) for i in 1:n)
    nn = norm(nrm)
    nn <= atol && return false
    n_hat = nrm / nn
    got_sign = 0
    for i in 1:n
        a, b, c = vs[i], vs[mod1(i + 1, n)], vs[mod1(i + 2, n)]
        turn = dot(cross3(b - a, c - b), n_hat)
        abs(turn) <= atol * norm(b - a) * norm(c - b) && continue
        s = turn > 0 ? 1 : -1
        if got_sign == 0
            got_sign = s
        elseif s != got_sign
            return false
        end
    end
    return true
end
"""
    point_in_polygon(p::APPoint{3}, pg::APPolygon{3})

Whether `p` (assumed to lie in `pg`'s own plane) is inside `pg`, via the
same even-odd ray-casting rule as `point_in_polygon(::APPoint,
::APPolygon)`, applied after projecting `p` and `pg`'s vertices into a 2D
frame local to `pg`'s own plane (any in-plane orthonormal basis works;
the ray-casting result doesn't depend on which one is chosen).
"""
function point_in_polygon(p::APPoint{3}, pg::APPolygon{3})
    vs = vertices(pg)
    n = length(vs)
    nrm = sum(cross3(vs[i], vs[mod1(i + 1, n)]) for i in 1:n)
    n_hat = nrm / norm(nrm)
    ref = abs(n_hat[1]) < 0.9 ? APVector(1.0, 0.0, 0.0) : APVector(0.0, 1.0, 0.0)
    u = cross3(n_hat, ref)
    u = u / norm(u)
    w = cross3(n_hat, u)
    v1 = vs[1]
    to2d(q) = APPoint(dot(q - v1, u), dot(q - v1, w))
    pg2 = APStraightNgon([to2d(v) for v in vs])
    return point_in_polygon(to2d(p), pg2)
end
"""
    perimeter(p::APPolygon)
"""
perimeter(p::APPolygon) = sum(_side_length, sides(p))
"""
    centroid(p::APPolygon)

Area-weighted centroid of `p`. Falls back to the plain vertex average for
(near-)zero-area (degenerate) polygons. For a triangle this coincides
exactly with the plain vertex average (they're mathematically the same
thing at `n = 3`); [`APQuadrilateral`](@ref) overrides this with the
plain average deliberately, since that's its own well-known convention.
"""
function centroid(p::APPolygon)
    v = vertices(p)
    n = length(v)
    o = v[1]   # work relative to the first vertex, so the result does not degrade far from the origin
    A = zero(o[1])
    cx = zero(o[1])
    cy = zero(o[1])
    for i in 1:n
        j = i == n ? 1 : i + 1
        vi, vj = v[i] - o, v[j] - o
        cr = cross2(vi, vj)
        A += cr
        cx += (vi[1] + vj[1]) * cr
        cy += (vi[2] + vj[2]) * cr
    end
    A /= 2
    abs(A) <= sqrt(eps(Float64)) * max(maximum(vi -> norm(vi - o), v), 1.0)^2 && return o + sum(vi - o for vi in v) / n
    return o + APVector(cx / (6A), cy / (6A))
end
"""
    is_convex(p::APPolygon; atol=1e-9)
"""
function is_convex(p::APPolygon; atol=1e-9)
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
    _ray_crossings(p::APPoint, s::APSegment)

How many times the rightward horizontal ray from `p` (fixed height
`p[2]`, heading toward `+∞` in `x`) crosses `s` transversally: `0` or
`1`. The building block [`point_in_polygon`](@ref) sums over every side
of [`sides`](@ref)`(pg)` to apply the even-odd rule generically, whether
those sides are straight or (see `ap_conic.jl`) conic arcs.
"""
function _ray_crossings(p::APPoint, s::APSegment)
    x1, y1 = s.p1[1], s.p1[2]
    x2, y2 = s.p2[1], s.p2[2]
    (y1 > p[2]) == (y2 > p[2]) && return 0
    xcross = (x2 - x1) * (p[2] - y1) / (y2 - y1) + x1
    return xcross > p[1] ? 1 : 0
end
"""
    point_in_polygon(p::APPoint, pg::APPolygon)

Whether `p` lies inside `pg`, via ray-casting (even-odd rule) along
[`sides`](@ref)`(pg)`: works uniformly whether every side is straight or
some are conic arcs, so it needs no separate case for curved regions.
Points exactly on the boundary may return either `true` or `false`.
"""
function point_in_polygon(p::APPoint, pg::APPolygon)
    return isodd(sum(s -> _ray_crossings(p, s), sides(pg)))
end
Base.in(p::APPoint, pg::APPolygon) = point_in_polygon(p, pg)
"""
    distance(p::APPoint, pg::APPolygon; mode::Symbol=:region)

Distance from `p` to `pg`, defined once for the whole [`APPolygon`](@ref)
family via [`sides`](@ref): straight or curved alike. With `mode =
:region` (the default), `0.0` whenever `p` lies inside or on the boundary
of `pg`, otherwise the distance to the nearest point on `sides(pg)`. With
`mode = :boundary`, always the distance to the boundary itself, even from
inside `pg`.

```julia
t = APTriangle(APPoint(0.0, 0.0), APPoint(4.0, 0.0), APPoint(0.0, 3.0))
distance(APPoint(1.0, 1.0), t)                    # 0.0: p is inside t
distance(APPoint(1.0, 1.0), t; mode=:boundary)    # > 0.0: distance to the nearest side instead
```

| Keyword | Default | Meaning |
|:--------|:--------|:--------|
| `mode` | `:region` | for regions and sets: `:region` gives `0` for a point inside or on it, `:boundary` the distance to the boundary even from inside |
"""
function distance(p::APPoint, pg::APPolygon; mode::Symbol=:region)
    _check_distance_mode(mode)
    d = minimum(distance(p, s) for s in sides(pg))
    mode == :boundary && return d
    return p in pg ? zero(d) : d
end
distance(pg::APPolygon, p::APPoint; mode::Symbol=:region) = distance(p, pg; mode=mode)
APBoundingBox(p::APPolygon) = APBoundingBox(collect(vertices(p)))
"""
    APTriangle(a, b, c)
"""
struct APTriangle{Dim,T<:Real} <: APPolygon{Dim,T}
    a::APPoint{Dim,T}
    b::APPoint{Dim,T}
    c::APPoint{Dim,T}
end
function APTriangle(a::APPoint, b::APPoint, c::APPoint)
    return APTriangle{length(a),promote_type(eltype(a), eltype(b), eltype(c))}(a, b, c)
end
"""
    vertices(p)

The vertices of a straight-sided [`APPolygon`](@ref) (`APTriangle`,
`APQuadrilateral`, `APStraightNgon`), in order.
"""
vertices(t::APTriangle) = (t.a, t.b, t.c)
Base.getindex(t::APTriangle, i::Integer) = vertices(t)[i]
Base.length(::APTriangle) = 3
Base.iterate(t::APTriangle, i::Int=1) = i > 3 ? nothing : (t[i], i + 1)
Base.:(==)(x::APTriangle, y::APTriangle) = x.a == y.a && x.b == y.b && x.c == y.c
Base.isapprox(x::APTriangle, y::APTriangle; kwargs...) =
    isapprox(x.a, y.a; kwargs...) && isapprox(x.b, y.b; kwargs...) && isapprox(x.c, y.c; kwargs...)
Base.show(io::IO, t::APTriangle) = print(io, "APTriangle(", t.a, ", ", t.b, ", ", t.c, ")")
rotate(t::APTriangle{2}, angle::Real, center::APPoint{2}=APPoint(0.0, 0.0)) =
    APTriangle(rotate(t.a, angle, center), rotate(t.b, angle, center), rotate(t.c, angle, center))
rotate(t::APTriangle{3}, angle::Real, axis::APLine{3}) =
    APTriangle(rotate(t.a, angle, axis), rotate(t.b, angle, axis), rotate(t.c, angle, axis))
reflection(t::APTriangle, about) = APTriangle(reflection(t.a, about), reflection(t.b, about), reflection(t.c, about))
homothety(t::APTriangle, k::Real, center::APPoint=APPoint(0.0, 0.0)) =
    APTriangle(homothety(t.a, k, center), homothety(t.b, k, center), homothety(t.c, k, center))
translate(t::APTriangle, v::APVector) = APTriangle(translate(t.a, v), translate(t.b, v), translate(t.c, v))
"""
    APQuadrilateral(a, b, c, d)

Consecutive vertices `a, b, c, d`: not assumed convex, cyclic, or of any
special kind.
"""
struct APQuadrilateral{Dim,T<:Real} <: APPolygon{Dim,T}
    a::APPoint{Dim,T}
    b::APPoint{Dim,T}
    c::APPoint{Dim,T}
    d::APPoint{Dim,T}
end
function APQuadrilateral(a::APPoint, b::APPoint, c::APPoint, d::APPoint)
    return APQuadrilateral{length(a),promote_type(eltype(a), eltype(b), eltype(c), eltype(d))}(a, b, c, d)
end
function APQuadrilateral(bb::APBoundingBox)
    return APQuadrilateral(
        bb.min, APPoint(bb.max[1],bb.min[2]),
        bb.max, APPoint(bb.min[1],bb.max[2])
    )
end
vertices(q::APQuadrilateral) = (q.a, q.b, q.c, q.d)
Base.getindex(q::APQuadrilateral, i::Integer) = vertices(q)[i]
Base.length(::APQuadrilateral) = 4
Base.iterate(q::APQuadrilateral, i::Int=1) = i > 4 ? nothing : (q[i], i + 1)
Base.:(==)(x::APQuadrilateral, y::APQuadrilateral) = x.a == y.a && x.b == y.b && x.c == y.c && x.d == y.d
Base.isapprox(x::APQuadrilateral, y::APQuadrilateral; kwargs...) =
    isapprox(x.a, y.a; kwargs...) && isapprox(x.b, y.b; kwargs...) &&
    isapprox(x.c, y.c; kwargs...) && isapprox(x.d, y.d; kwargs...)
Base.show(io::IO, q::APQuadrilateral) = print(io, "APQuadrilateral(", q.a, ", ", q.b, ", ", q.c, ", ", q.d, ")")
"""
    sides(q::APQuadrilateral)

The four side segments `[a,b]`, `[b,c]`, `[c,d]`, `[d,a]`.
"""
sides(q::APQuadrilateral) = (APSegment(q.a, q.b), APSegment(q.b, q.c), APSegment(q.c, q.d), APSegment(q.d, q.a))
"""
    diagonals(q::APQuadrilateral)

The two diagonal segments `[a,c]` and `[b,d]`.
"""
diagonals(q::APQuadrilateral) = (APSegment(q.a, q.c), APSegment(q.b, q.d))
"""
    diagonal_intersection(q::APQuadrilateral; atol=1e-9)

Where the two diagonals `[a,c]` and `[b,d]` cross, or `nothing` if
they're parallel (a degenerate quadrilateral).

Uses `intersection(::APLine, ::APLine)`, defined later in
`ap_intersections.jl`: referenced here only inside a function body, so
the include order doesn't matter.
"""
function diagonal_intersection(q::APQuadrilateral; atol=1e-9)
    pts = intersection(APLine(q.a, q.c), APLine(q.b, q.d); atol=atol)
    isempty(pts) && return nothing
    return pts[1]
end
"""
    is_cyclic(q::APQuadrilateral; atol=1e-9)

Whether the four vertices of `q` lie on a common circle. Uses
`is_concyclic`, which in turn needs `circumcenter`/`circumradius(::APTriangle)`
from `ap_triangle.jl`: referenced here only inside a function body, so
the include order (this file comes well before `ap_triangle.jl`) doesn't
matter.
"""
is_cyclic(q::APQuadrilateral; atol=1e-9) = is_concyclic(q.a, q.b, q.c, q.d; atol=atol)
"""
    centroid(q::APQuadrilateral)

The plain (equal-weight) average of the four vertices: *not*
area-weighted (that's [`centroid(::APPolygon)`](@ref), which
`APStraightNgon`/`APTriangle` use instead).
"""
centroid(q::APQuadrilateral) = q.a + ((q.b - q.a) + (q.c - q.a) + (q.d - q.a)) / 4
rotate(q::APQuadrilateral{2}, angle::Real, center::APPoint{2}=APPoint(0.0, 0.0)) =
    APQuadrilateral(rotate(q.a, angle, center), rotate(q.b, angle, center), rotate(q.c, angle, center), rotate(q.d, angle, center))
rotate(q::APQuadrilateral{3}, angle::Real, axis::APLine{3}) =
    APQuadrilateral(rotate(q.a, angle, axis), rotate(q.b, angle, axis), rotate(q.c, angle, axis), rotate(q.d, angle, axis))
reflection(q::APQuadrilateral, about) =
    APQuadrilateral(reflection(q.a, about), reflection(q.b, about), reflection(q.c, about), reflection(q.d, about))
homothety(q::APQuadrilateral, k::Real, center::APPoint=APPoint(0.0, 0.0)) =
    APQuadrilateral(homothety(q.a, k, center), homothety(q.b, k, center), homothety(q.c, k, center), homothety(q.d, k, center))
translate(q::APQuadrilateral, v::APVector) =
    APQuadrilateral(translate(q.a, v), translate(q.b, v), translate(q.c, v), translate(q.d, v))
"""
    APStraightNgon(vertices::AbstractVector{<:APPoint})

A simple polygon with an arbitrary number of straight sides (assumed
simple: edges don't cross themselves), given as an ordered list of
vertices (no repeated closing point). The straight-sided analogue of
[`APCurvilinearNgon2`](@ref).
"""
struct APStraightNgon{Dim,T<:Real} <: APPolygon{Dim,T}
    vertices::Vector{APPoint{Dim,T}}
end
function APStraightNgon(vs::AbstractVector{<:APPoint{Dim}}) where {Dim}
    T = promote_type(eltype.(vs)...)
    return APStraightNgon(APPoint{Dim,T}[convert(APPoint{Dim,T}, v) for v in vs])
end
APStraightNgon(vs::AbstractVector) = APStraightNgon([v for v in vs])
"""
    APStraightNgon(vertices::APPoint...)

Same as [`APStraightNgon(::AbstractVector{<:APPoint})`](@ref) above, one
vertex per argument instead of wrapped in a `Vector`: matching
[`APPolyline2`](@ref)'s own vector/varargs pair.
"""
APStraightNgon(vs::APPoint...) = APStraightNgon(collect(vs))
function APStraightNgon(bb::APBoundingBox)
    return APStraightNgon([
        bb.min, APPoint(bb.max[1],bb.min[2]),
        bb.max, APPoint(bb.min[1],bb.max[2])
    ])
end
vertices(pg::APStraightNgon) = pg.vertices
Base.getindex(pg::APStraightNgon, i::Integer) = pg.vertices[i]
Base.length(pg::APStraightNgon) = length(pg.vertices)
Base.iterate(pg::APStraightNgon, i::Int=1) = i > length(pg) ? nothing : (pg[i], i + 1)
Base.:(==)(x::APStraightNgon, y::APStraightNgon) = x.vertices == y.vertices
Base.isapprox(x::APStraightNgon, y::APStraightNgon; kwargs...) =
    length(x) == length(y) && all(isapprox(a, b; kwargs...) for (a, b) in zip(x.vertices, y.vertices))
Base.show(io::IO, pg::APStraightNgon) = print(io, "APStraightNgon(", pg.vertices, ")")
rotate(pg::APStraightNgon{2}, angle::Real, center::APPoint{2}=APPoint(0.0, 0.0)) =
    APStraightNgon([rotate(v, angle, center) for v in pg.vertices])
rotate(pg::APStraightNgon{3}, angle::Real, axis::APLine{3}) =
    APStraightNgon([rotate(v, angle, axis) for v in pg.vertices])
reflection(pg::APStraightNgon, about) = APStraightNgon([reflection(v, about) for v in pg.vertices])
homothety(pg::APStraightNgon, k::Real, center::APPoint=APPoint(0.0, 0.0)) =
    APStraightNgon([homothety(v, k, center) for v in pg.vertices])
translate(pg::APStraightNgon, v::APVector) = APStraightNgon([translate(vt, v) for vt in pg.vertices])
"""
    convex_hull(points::AbstractVector{<:APPoint})

The convex hull of `points`, as an [`APStraightNgon`](@ref) (Andrew's
monotone chain algorithm, `O(n log n)`).
"""
function convex_hull(points::AbstractVector{<:APPoint})
    pts = sort(unique(points); by=p -> (p[1], p[2]))
    n = length(pts)
    n <= 2 && return APStraightNgon(pts)
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
    return APStraightNgon(vcat(lower[1:end-1], upper[1:end-1]))
end
# ear-clipping triangulation of a simple polygon's vertices: a fan from one vertex only works when
# the polygon is convex, or at least star-shaped from that vertex; this handles any simple polygon.
function _ear_triangulate(vs::Vector{<:APPoint{2}})
    n = length(vs)
    n == 3 && return [(1, 2, 3)]
    idx = collect(1:n)
    o = vs[1]
    ccw = sum(cross2(vs[i] - o, vs[mod1(i + 1, n)] - o) for i in 1:n) >= 0
    tris = Tuple{Int,Int,Int}[]
    while length(idx) > 3
        m = length(idx)
        clipped = false
        for k in 1:m
            ip, ic, inx = idx[mod1(k - 1, m)], idx[k], idx[mod1(k + 1, m)]
            a, b, c = vs[ip], vs[ic], vs[inx]
            cr = cross2(b - a, c - a)
            (ccw ? cr > 0 : cr < 0) || continue
            tri = APTriangle(a, b, c)
            any(j -> idx[j] != ip && idx[j] != ic && idx[j] != inx && vs[idx[j]] in tri, 1:m) && continue
            push!(tris, (ip, ic, inx))
            deleteat!(idx, k)
            clipped = true
            break
        end
        clipped || break
    end
    length(idx) == 3 && push!(tris, (idx[1], idx[2], idx[3]))
    return tris
end
