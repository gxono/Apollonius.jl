"""
    APAffineMap(a11, a12, a21, a22, tx, ty)

The affine map `p -> [a11 a12; a21 a22] * p + (tx, ty)`. Instances are
callable: `m(p)` applies the map to a point, and pointwise to every
AP-typed curve/polygon.
"""
struct APAffineMap{T<:Real} <: APTransform{T}
    a11::T
    a12::T
    a21::T
    a22::T
    tx::T
    ty::T
end
APAffineMap(a11::Real, a12::Real, a21::Real, a22::Real, tx::Real, ty::Real) =
    APAffineMap(promote(a11, a12, a21, a22, tx, ty)...)
Base.:(==)(x::APAffineMap, y::APAffineMap) =
    x.a11 == y.a11 && x.a12 == y.a12 && x.a21 == y.a21 && x.a22 == y.a22 && x.tx == y.tx && x.ty == y.ty
Base.isapprox(x::APAffineMap, y::APAffineMap; kwargs...) =
    isapprox(x.a11, y.a11; kwargs...) && isapprox(x.a12, y.a12; kwargs...) &&
    isapprox(x.a21, y.a21; kwargs...) && isapprox(x.a22, y.a22; kwargs...) &&
    isapprox(x.tx, y.tx; kwargs...) && isapprox(x.ty, y.ty; kwargs...)
Base.show(io::IO, m::APAffineMap) =
    print(io, "APAffineMap([", m.a11, " ", m.a12, "; ", m.a21, " ", m.a22, "], t=(", m.tx, ", ", m.ty, "))")
(m::APAffineMap)(p::APPoint{2}) = APPoint(m.a11 * p[1] + m.a12 * p[2] + m.tx, m.a21 * p[1] + m.a22 * p[2] + m.ty)
"""
    (m::APAffineMap)(v::APVector)

The image of the free vector `v` under `m`'s *linear* part only: a
vector has no position, so the translation `(tx, ty)` is not applied.
"""
(m::APAffineMap)(v::APVector{2}) = APVector(m.a11 * v[1] + m.a12 * v[2], m.a21 * v[1] + m.a22 * v[2])
(m::APAffineMap)(s::APSegment) = APSegment(m(s.p1), m(s.p2))
(m::APAffineMap)(l::APLine) = APLine(m(l.p1), m(l.p2))
(m::APAffineMap)(r::APRay) = APRay(m(r.origin), m(r.through))
(m::APAffineMap)(t::APTriangle) = APTriangle(m(t.a), m(t.b), m(t.c))
(m::APAffineMap)(pg::APStraightNgon) = APStraightNgon([m(v) for v in pg.vertices])
(m::APAffineMap)(q::APQuadrilateral) = APQuadrilateral(m(q.a), m(q.b), m(q.c), m(q.d))
(m::APAffineMap)(ang::APAngle2) = APAngle2(m(ang.vertex), m(ang.a), m(ang.b))
"""
    (m::APAffineMap)(hp::APHalfPlane2)

The image of `hp` under `m`. Unlike [`rotate`](@ref)/[`homothety`](@ref)
(always orientation-preserving in 2D, so `side` never needs to change), a
general affine map can reverse orientation (`det(m) < 0`, like a
reflection), which would flip which side of the transformed boundary is
"inside": so `side` is recomputed fresh from a point already known to be
on the correct side, rather than carried over unchanged.
"""
function (m::APAffineMap)(hp::APHalfPlane2)
    new_boundary = m(hp.boundary)
    interior_pt = hp.boundary.p1 + hp.side * orthogonal(direction(hp.boundary))
    return APHalfPlane2(new_boundary, side_of_line(m(interior_pt), new_boundary))
end
"""
    (m::APAffineMap)(s::APStrip2)

The image of `s` under `m`. Affine maps preserve parallelism, so the two
transformed boundary lines are still parallel.
"""
(m::APAffineMap)(s::APStrip2) = APStrip2(m(s.line1), m(s.line2))
"""
    (m::APAffineMap)(s::APCircularSector2)
    (m::APAffineMap)(s::APCircularSegment2)
    (m::APAffineMap)(s::APAnnularSector2)
    (m::APAffineMap)(g::APInterstice2)

The image under `m` of a region built from circular arcs. None of these
four *types* are closed under a general affine map: their circular arcs
generically become elliptic ones (see `(m::APAffineMap)(arc::APCircularArc2)`
above), which no longer fits an
`APCircularSector2`/`APCircularSegment2`/`APAnnularSector2`/
`APInterstice2` (each holds a concrete `APCircularArc2` field, not any
conic arc): so, unless `m` is a similarity (see
`(m::APAffineMap)(c::APCircle2)`, which then keeps the original type), the
result is the more general
[`APCurvilinearTriangle2`](@ref)/[`APCurvilinearQuadrilateral2`](@ref)/
[`APCurvilinearNgon2`](@ref) with the same sides, each mapped through `m`
(reusing [`sides`](@ref) rather than each type's own fields, so this
automatically stays correct if those ever change).
"""
function (m::APAffineMap)(s::APCircularSector2)
    _affine_map_scale(m) === nothing || return APCircularSector2(m(s.arc))
    s1, s2, s3 = sides(s)
    return APCurvilinearTriangle2((m(s1), m(s2), m(s3)))
end
function (m::APAffineMap)(s::APCircularSegment2)
    _affine_map_scale(m) === nothing || return APCircularSegment2(m(s.arc))
    return APCurvilinearNgon2([m(side) for side in sides(s)])
end
function (m::APAffineMap)(s::APAnnularSector2)
    k = _affine_map_scale(m)
    k === nothing || return APAnnularSector2(m(s.outer), k * s.r_inner)
    s1, s2, s3, s4 = sides(s)
    return APCurvilinearQuadrilateral2((m(s1), m(s2), m(s3), m(s4)))
end
function (m::APAffineMap)(g::APInterstice2)
    _affine_map_scale(m) === nothing || return APInterstice2(m(g.arc1), m(g.arc2), m(g.arc3))
    return APCurvilinearTriangle2((m(g.arc1), m(g.arc2), m(g.arc3)))
end
"""
    (m::APAffineMap)(t::APCurvilinearTriangle2)
    (m::APAffineMap)(q::APCurvilinearQuadrilateral2)
    (m::APAffineMap)(pg::APCurvilinearNgon2)

The image under `m` of a general mixed-side region, the same type,
each side mapped through `m` (every side type, `APSegment` and all four
conic arcs: already knows how to transform itself under `m`).
"""
(m::APAffineMap)(t::APCurvilinearTriangle2) = APCurvilinearTriangle2(map(m, t.sides))
(m::APAffineMap)(q::APCurvilinearQuadrilateral2) = APCurvilinearQuadrilateral2(map(m, q.sides))
(m::APAffineMap)(pg::APCurvilinearNgon2) = APCurvilinearNgon2([m(side) for side in pg.sides])
# sqrt of the area scale if the linear part is a similarity (equal, orthogonal rows), else nothing
"""
    (m::APAffineMap)(c::APCircle2)

The image of `c` under `m`: an [`APCircle2`](@ref) when `m` is a
similarity (a rotation, translation, reflection or uniform scaling, or any
composition of them), otherwise an [`APEllipse2`](@ref). The type therefore
depends on the values of `m`, not only on its type.

The linear part of `m` maps the unit circle to an ellipse whose semi-axes
are its singular values and whose axes are its left singular vectors;
`c`'s own radius scales those semi-axes, and its center maps pointwise.
"""
function _affine_map_scale(m::APAffineMap; rtol=1e-12)
    a, b, cc, d = m.a11, m.a12, m.a21, m.a22
    p, s, q = a^2 + b^2, cc^2 + d^2, a * cc + b * d
    scale = max(p, s)
    return (abs(p - s) <= rtol * scale && abs(q) <= rtol * scale && scale > 0) ? sqrt((p + s) / 2) : nothing
end
function (m::APAffineMap)(c::APCircle2)
    k = _affine_map_scale(m)
    k === nothing || return APCircle2(m(c.center), k * c.r)
    a, b, cc, d = m.a11, m.a12, m.a21, m.a22
    p, s, q = a^2 + b^2, cc^2 + d^2, a * cc + b * d
    tr, det = p + s, p * s - q^2
    disc = sqrt(max(tr^2 / 4 - det, 0.0))
    λmax, λmin = tr / 2 + disc, tr / 2 - disc
    ang = 0.5 * atan(2q, p - s)
    return APEllipse2(m(c.center), c.r * sqrt(λmax), c.r * sqrt(λmin), ang)
end
function _affine_map_conic_quadratic_form(m::APAffineMap, a::Real, b::Real, angle::Real, ε::Real)
    c, s = cos(angle), sin(angle)
    Q11 = c^2 / a^2 + ε * s^2 / b^2
    Q12 = c * s * (1 / a^2 - ε / b^2)
    Q22 = s^2 / a^2 + ε * c^2 / b^2
    a11, a12, a21, a22 = m.a11, m.a12, m.a21, m.a22
    det = a11 * a22 - a12 * a21
    ia11, ia12, ia21, ia22 = a22 / det, -a12 / det, -a21 / det, a11 / det
    T11 = Q11 * ia11 + Q12 * ia21
    T12 = Q11 * ia12 + Q12 * ia22
    T21 = Q12 * ia11 + Q22 * ia21
    T22 = Q12 * ia12 + Q22 * ia22
    Qp11 = ia11 * T11 + ia21 * T21
    Qp12 = ia11 * T12 + ia21 * T22
    Qp22 = ia12 * T12 + ia22 * T22
    tr, dt = Qp11 + Qp22, Qp11 * Qp22 - Qp12^2
    disc = sqrt(max(tr^2 / 4 - dt, 0.0))
    λ1, λ2 = tr / 2 + disc, tr / 2 - disc
    θ = atan(2Qp12, Qp11 - Qp22) / 2
    return λ1, λ2, θ
end
"""
    (m::APAffineMap)(e::APEllipse2)

The image of `e` under `m`, always another `APEllipse2` (never a circle,
even if `e` happens to be one and `m` conformal, same convention as
`(m::APAffineMap)(c::APCircle2)` above).
"""
function (m::APAffineMap)(e::APEllipse2)
    λ1, λ2, θ = _affine_map_conic_quadratic_form(m, e.a, e.b, e.angle, 1.0)
    return APEllipse2(m(e.center), 1 / sqrt(λ1), 1 / sqrt(λ2), θ)
end
"""
    (m::APAffineMap)(h::APHyperbola2)

The image of `h` under `m`: always another `APHyperbola2`.
"""
function (m::APAffineMap)(h::APHyperbola2)
    λ1, λ2, θ = _affine_map_conic_quadratic_form(m, h.a, h.b, h.angle, -1.0)
    return APHyperbola2(m(h.center), 1 / sqrt(λ1), 1 / sqrt(-λ2), θ)
end
"""
    (m::APAffineMap)(par::APParabola2)

The image of `par` under `m`: always another `APParabola2`. Unlike
`(m::APAffineMap)(e::APEllipse2)`/`(m::APAffineMap)(h::APHyperbola2)`
above, `focus`/`directrix` are metric (not affine-invariant) constructs, so they
can't just be mapped pointwise like a segment's endpoints: `m` can shear
or scale non-uniformly, which moves the true focus/directrix off of
`m(par.focus)`/`m(par.directrix)`. Instead: `par`'s own parametrization
`point_on_parabola(par, y) = vertex + (y²/2pf)u + y·w` becomes, under `m`,
`q(y) = m(vertex) + y·m(w) + y²·(m(u)/2pf)`: a quadratic *vector*
function of `y` whose own vertex/axis/focal parameter are recovered by
rewriting it in the orthonormal frame aligned with its (generally skewed)
`y²` coefficient direction, then completing the square.
"""
function (m::APAffineMap)(par::APParabola2)
    V, u, w = _parabola_frame(par)
    pf = focal_parameter(par)
    A, B, C = m(V), m(w), m(u) / (2pf)
    κ = norm(C)
    u2 = C / κ
    w2 = orthogonal(u2)
    X0, Y0 = dot(APVector(A), u2), dot(APVector(A), w2)
    bu, bw = dot(B, u2), dot(B, w2)
    C2 = κ / bw^2
    slope = bu / bw
    Xvertex = X0 - slope^2 / (4C2)
    Yvertex = Y0 - slope / (2C2)
    pf2 = 1 / (2C2)
    vertex2 = _from_local_frame(Xvertex, Yvertex, APPoint(0.0, 0.0), u2, w2)
    focus2 = vertex2 + (pf2 / 2) * u2
    foot2 = vertex2 - (pf2 / 2) * u2
    return APParabola2(focus2, APLine(foot2, foot2 + w2))
end
_affine_map_det(m::APAffineMap) = m.a11 * m.a22 - m.a12 * m.a21
"""
    (m::APAffineMap)(arc::APCircularArc2)

The image of `arc` under `m`: an [`APCircularArc2`](@ref) when `m` is a
similarity, otherwise an [`APEllipticArc2`](@ref) (matching
`(m::APAffineMap)(c::APCircle2)`).

Like [`reflection(::APCircularArc2, ::APLine)`](@ref), this needs to know
whether `m` preserves or reverses orientation: for a *closed* conic, "the
arc from `p1` to `p2`" only picks out one of the two complementary arcs
because it's understood to sweep counterclockwise, and an
orientation-reversing map (`det(m) < 0`, like a reflection) turns that
sweep clockwise: so `p1`/`p2` are swapped in that case to reconstruct
the correct (not the complementary) arc.
"""
function (m::APAffineMap)(arc::APCircularArc2)
    e2 = m(arc.circle)
    if e2 isa APCircle2
        return _affine_map_det(m) >= 0 ? APCircularArc2(e2, m(arc.p1), m(arc.p2)) : APCircularArc2(e2, m(arc.p2), m(arc.p1))
    end
    return _affine_map_det(m) >= 0 ? APEllipticArc2(e2, m(arc.p1), m(arc.p2)) : APEllipticArc2(e2, m(arc.p2), m(arc.p1))
end
"""
    (m::APAffineMap)(arc::APEllipticArc2)

The image of `arc` under `m`: another `APEllipticArc2`, on the image of
its ellipse (an affine invariant, see `(m::APAffineMap)(e::APEllipse2)`
above). Swaps `p1`/`p2` when `m` is
orientation-reversing, for the same reason as
`(m::APAffineMap)(arc::APCircularArc2)` above.
"""
function (m::APAffineMap)(arc::APEllipticArc2)
    e2 = m(arc.ellipse)
    return _affine_map_det(m) >= 0 ? APEllipticArc2(e2, m(arc.p1), m(arc.p2)) : APEllipticArc2(e2, m(arc.p2), m(arc.p1))
end
"""
    (m::APAffineMap)(arc::APHyperbolicArc2)
    (m::APAffineMap)(arc::APParabolicArc2)

The image of `arc` under `m`: the same arc type, on the image of its
underlying conic. Unlike the closed-conic arcs above, a single hyperbola
branch/a parabola is open, so there's no complementary-arc ambiguity and
no swap is needed even when `m` reverses orientation (matching
[`reflection(::APHyperbolicArc2, _)`](@ref)/`reflection(::APParabolicArc2, _)`).
"""
(m::APAffineMap)(arc::APHyperbolicArc2) = APHyperbolicArc2(m(arc.hyperbola), m(arc.p1), m(arc.p2))
(m::APAffineMap)(arc::APParabolicArc2) = APParabolicArc2(m(arc.parabola), m(arc.p1), m(arc.p2))
"""
    (m::APAffineMap)(pl::APPolyline2)
    (m::APAffineMap)(pg::APCurvilinearPolyline2)
    (m::APAffineMap)(e::APEquipollentVector)
    (m::APAffineMap)(curve::APParametricCurve2)

The image under `m` of an open chain, an anchored vector or a parametric
curve, of the same type. The vector part of an `APEquipollentVector` goes
through the linear part of `m` alone. When `m` reverses orientation, a
curvilinear polyline comes back traversed the other way, as with
[`reflection`](@ref).
"""
(m::APAffineMap)(pl::APPolyline2) = APPolyline2([m(p) for p in pl.vertices])
(m::APAffineMap)(e::APEquipollentVector) = APEquipollentVector(m(e.vector), m(e.point))
(m::APAffineMap)(curve::APParametricCurve2) = APParametricCurve2(t -> m(curve.f(t)), curve.trange)
function (m::APAffineMap)(pg::APCurvilinearPolyline2)
    _affine_map_det(m) >= 0 && return APCurvilinearPolyline2([m(side) for side in pg.sides])
    return APCurvilinearPolyline2([side isa Union{APCircularArc2,APEllipticArc2} ? m(side) : reverse(m(side)) for side in Base.reverse(pg.sides)])
end
"""
    affine_map(src::NTuple{3,APPoint}, dst::NTuple{3,APPoint})
    affine_map(a => a2, b => b2, c => c2)

The unique affine map sending `src[i]` to `dst[i]` for `i = 1, 2, 3`, given
either as two tuples of points or as three `source => image` pairs (the
same map, with each correspondence written next to its own points).
`src` must be non-collinear.
"""
function affine_map(src::NTuple{3,<:APPoint{2}}, dst::NTuple{3,<:APPoint{2}}; atol=1e-9)
    p1, p2, p3 = src
    q1, q2, q3 = dst
    u, v = p2 - p1, p3 - p1
    du, dv = q2 - q1, q3 - q1
    det = cross2(u, v)
    abs(det) <= atol * norm(u) * norm(v) && throw(ArgumentError("affine_map: source points must not be collinear"))
    a11 = (du[1] * v[2] - dv[1] * u[2]) / det
    a12 = (dv[1] * u[1] - du[1] * v[1]) / det
    a21 = (du[2] * v[2] - dv[2] * u[2]) / det
    a22 = (dv[2] * u[1] - du[2] * v[1]) / det
    tx = q1[1] - (a11 * p1[1] + a12 * p1[2])
    ty = q1[2] - (a21 * p1[1] + a22 * p1[2])
    return APAffineMap(a11, a12, a21, a22, tx, ty)
end
function affine_map(p1::Pair{<:APPoint{2},<:APPoint{2}}, p2::Pair{<:APPoint{2},<:APPoint{2}}, p3::Pair{<:APPoint{2},<:APPoint{2}}; atol=1e-9)
    return affine_map((first(p1), first(p2), first(p3)), (last(p1), last(p2), last(p3)); atol=atol)
end
"""
    translation_map(v::APVector)
    translation_map(v::APPoint)

The affine map `p -> p + v`: equivalent to `p -> translate(p, v)`, as a
genuine, reusable `APAffineMap` value: composes with `∘`/other maps into
one *combined* map (computed once, applied as cheaply as any single map),
and works uniformly across every type this file already handles (see
[Affine Maps](@ref)).

The tradeoff for that generality: applying an `APAffineMap`, this one
included, can't preserve an exotic type the way `translate(shape, v)`
itself does (the type of the result of mapping a circle is decided at run time: an
`APCircle2` for a similarity, an `APEllipse2` otherwise, so the result of
`m(circle)` is not type-stable). [`translate`](@ref)'s own one-argument form
(`translate(v)`) is a plain function rather than an `APAffineMap`, so it
doesn't compose into one combined object, but it always preserves the type.
"""
translation_map(v::APPointOrVector{2}) = APAffineMap(one(v[1]), zero(v[1]), zero(v[1]), one(v[1]), v[1], v[2])
"""
    rotation_map(angle::Real, center::APPoint)

The affine map rotating by `angle` radians (counterclockwise) around
`center`: equivalent to `p -> rotate(p, angle, center)`, as a genuine,
composable `APAffineMap` value (see [`translation_map`](@ref) for the
tradeoff against [`rotate`](@ref)'s own type-preserving one-argument
form).

No default for `center` here (unlike `rotate`, which defaults to the
origin): a default would make `rotation_map(angle)` alone valid, silently
rotating about the origin with no `center` in sight at the call site:
pass `center` explicitly instead.
"""
function rotation_map(angle::Real, center::APPoint{2})
    c, s = cos(angle), sin(angle)
    tx = center[1] - (c * center[1] - s * center[2])
    ty = center[2] - (s * center[1] + c * center[2])
    return APAffineMap(c, -s, s, c, tx, ty)
end
"""
    homothety_map(k::Real, center::APPoint)

The affine map scaling by ratio `k` about `center`: equivalent to
`p -> homothety(p, k, center)`, as a genuine, composable `APAffineMap`
value (see [`translation_map`](@ref) for the tradeoff against
[`homothety`](@ref)'s own type-preserving one-argument form). See
[`rotation_map`](@ref) for why `center` has no zero-argument default here.
"""
function homothety_map(k::Real, center::APPoint{2})
    tx, ty = center[1] * (1 - k), center[2] * (1 - k)
    return APAffineMap(k, zero(k), zero(k), k, tx, ty)
end
"""
    reflection_map(l::APLine)

The affine map reflecting across `l`: equivalent to
`p -> reflection(p, l)`, as a genuine, composable `APAffineMap` value
(see [`translation_map`](@ref) for the tradeoff against
[`reflection`](@ref)'s own type-preserving one-argument form).
"""
function reflection_map(l::APLine{2})
    n = orthogonal(direction(l))
    return affine_map((l.p1, l.p2, l.p1 + n), (l.p1, l.p2, l.p1 - n))
end
"""
    reflection_map(about::APPoint)

The affine map point-reflecting through `about` (`p -> 2*about - p`):
equivalent to `p -> reflection(p, about)`, as a genuine, composable
`APAffineMap` value (see [`translation_map`](@ref) for the tradeoff
against [`reflection`](@ref)'s own type-preserving one-argument form).
"""
reflection_map(about::APPoint{2}) = APAffineMap(-one(about[1]), zero(about[1]), zero(about[1]), -one(about[1]), 2about[1], 2about[2])
"""
    translate(v::APVector)

A reusable, one-argument function, `shape -> translate(shape, v)`, for
`|>`/`∘`/`map`/`filter` composition without a shape already in hand yet,
same as [`translation_map`](@ref)`(v)`, but a plain function rather than
an `APAffineMap`, so it *preserves* whatever specific type
`translate(shape, v)` itself already returns (a circle stays a circle).
Composing two of these with `∘` builds a plain function too (a chain of
type-preserving calls, applied in sequence each time), not one combined,
reusable map object: reach for [`translation_map`](@ref) instead if
that's what's actually needed.

```julia
t |> translate(v)                      # same as translate(t, v)
(rotate(pi/2) ∘ translate(v))(t)       # rotate(translate(t, v), pi/2): each step exact
map(translate(v), [c1, c2])            # c1/c2 stay APCircle2, not APEllipse2
```
"""
translate(v::APVector{2}) = shape -> translate(shape, v)
"""
    rotate(angle::Real, center::APPoint=APPoint(0.0, 0.0))

A reusable, one-argument function, `shape -> rotate(shape, angle,
center)`, the type-preserving counterpart of
[`rotation_map`](@ref)`(angle, center)` (see [`translate`](@ref)`(v)` for
the full tradeoff). Unlike `rotation_map`, `center` here defaults to the
origin, same as the direct, shape-taking `rotate` itself.
"""
rotate(angle::Real, center::APPoint{2}=APPoint(0.0, 0.0)) = shape -> rotate(shape, angle, center)
"""
    homothety(k::Real, center::APPoint=APPoint(0.0, 0.0))

A reusable, one-argument function, `shape -> homothety(shape, k,
center)`, the type-preserving counterpart of
[`homothety_map`](@ref)`(k, center)` (see [`translate`](@ref)`(v)` for the
full tradeoff). Unlike `homothety_map`, `center` here defaults to the
origin, same as the direct, shape-taking `homothety` itself.
"""
homothety(k::Real, center::APPoint{2}=APPoint(0.0, 0.0)) = shape -> homothety(shape, k, center)
"""
    reflection(about::APPoint)
    reflection(about::APLine)

A reusable, one-argument function, `shape -> reflection(shape, about)`:
the type-preserving counterpart of [`reflection_map`](@ref)`(about)` (see
[`translate`](@ref)`(v)` for the full tradeoff).
"""
reflection(about::APPoint{2}) = shape -> reflection(shape, about)
reflection(about::APLine{2}) = shape -> reflection(shape, about)
function Base.:∘(m2::APAffineMap, m1::APAffineMap)
    a11 = m2.a11 * m1.a11 + m2.a12 * m1.a21
    a12 = m2.a11 * m1.a12 + m2.a12 * m1.a22
    a21 = m2.a21 * m1.a11 + m2.a22 * m1.a21
    a22 = m2.a21 * m1.a12 + m2.a22 * m1.a22
    tx = m2.a11 * m1.tx + m2.a12 * m1.ty + m2.tx
    ty = m2.a21 * m1.tx + m2.a22 * m1.ty + m2.ty
    return APAffineMap(a11, a12, a21, a22, tx, ty)
end
