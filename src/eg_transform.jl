# -------------------------------------------------------------------------
# EGAffineMap (<: EGTransform), built on EGPoint/EGVector and callable on
# every EG-typed curve/polygon.
# -------------------------------------------------------------------------

"""
    EGAffineMap(a11, a12, a21, a22, tx, ty)

The affine map `p -> [a11 a12; a21 a22] * p + (tx, ty)`. Instances are
callable: `m(p)` applies the map to a point, and pointwise to every
EG-typed curve/polygon.
"""
struct EGAffineMap{T<:Real} <: EGTransform{T}
    a11::T
    a12::T
    a21::T
    a22::T
    tx::T
    ty::T
end
EGAffineMap(a11::Real, a12::Real, a21::Real, a22::Real, tx::Real, ty::Real) =
    EGAffineMap(promote(a11, a12, a21, a22, tx, ty)...)

Base.:(==)(x::EGAffineMap, y::EGAffineMap) =
    x.a11 == y.a11 && x.a12 == y.a12 && x.a21 == y.a21 && x.a22 == y.a22 && x.tx == y.tx && x.ty == y.ty
Base.isapprox(x::EGAffineMap, y::EGAffineMap; kwargs...) =
    isapprox(x.a11, y.a11; kwargs...) && isapprox(x.a12, y.a12; kwargs...) &&
    isapprox(x.a21, y.a21; kwargs...) && isapprox(x.a22, y.a22; kwargs...) &&
    isapprox(x.tx, y.tx; kwargs...) && isapprox(x.ty, y.ty; kwargs...)
Base.show(io::IO, m::EGAffineMap) =
    print(io, "EGAffineMap([", m.a11, " ", m.a12, "; ", m.a21, " ", m.a22, "], t=(", m.tx, ", ", m.ty, "))")

(m::EGAffineMap)(p::EGPoint{2}) = EGPoint(m.a11 * p[1] + m.a12 * p[2] + m.tx, m.a21 * p[1] + m.a22 * p[2] + m.ty)

"""
    (m::EGAffineMap)(v::EGVector)

The image of the free vector `v` under `m`'s *linear* part only — a
vector has no position, so the translation `(tx, ty)` is not applied.
"""
(m::EGAffineMap)(v::EGVector{2}) = EGVector(m.a11 * v[1] + m.a12 * v[2], m.a21 * v[1] + m.a22 * v[2])

(m::EGAffineMap)(s::EGSegment) = EGSegment(m(s.p1), m(s.p2))
(m::EGAffineMap)(l::EGLine) = EGLine(m(l.p1), m(l.p2))
(m::EGAffineMap)(r::EGRay) = EGRay(m(r.origin), m(r.through))
(m::EGAffineMap)(t::EGTriangle) = EGTriangle(m(t.a), m(t.b), m(t.c))
(m::EGAffineMap)(pg::EGStraightNgon) = EGStraightNgon([m(v) for v in pg.vertices])
(m::EGAffineMap)(q::EGQuadrilateral) = EGQuadrilateral(m(q.a), m(q.b), m(q.c), m(q.d))
(m::EGAffineMap)(ang::EGAngle2) = EGAngle2(m(ang.vertex), m(ang.a), m(ang.b))

"""
    (m::EGAffineMap)(hp::EGHalfPlane2)

The image of `hp` under `m`. Unlike [`rotate`](@ref)/[`homothety`](@ref)
(always orientation-preserving in 2D, so `side` never needs to change), a
general affine map can reverse orientation (`det(m) < 0`, like a
reflection), which would flip which side of the transformed boundary is
"inside" — so `side` is recomputed fresh from a point already known to be
on the correct side, rather than carried over unchanged.
"""
function (m::EGAffineMap)(hp::EGHalfPlane2)
    new_boundary = m(hp.boundary)
    interior_pt = hp.boundary.p1 + hp.side * orthogonal(direction(hp.boundary))
    return EGHalfPlane2(new_boundary, side_of_line(m(interior_pt), new_boundary))
end

"""
    (m::EGAffineMap)(s::EGStrip2)

The image of `s` under `m`. Affine maps preserve parallelism, so the two
transformed boundary lines are still parallel.
"""
(m::EGAffineMap)(s::EGStrip2) = EGStrip2(m(s.line1), m(s.line2))

"""
    (m::EGAffineMap)(s::EGCircularSector2)
    (m::EGAffineMap)(s::EGCircularSegment2)
    (m::EGAffineMap)(s::EGAnnularSector2)
    (m::EGAffineMap)(g::EGInterstice2)

The image under `m` of a region built from circular arcs. None of these
four *types* are closed under a general affine map — their circular arcs
generically become elliptic ones (see `(m::EGAffineMap)(arc::EGCircularArc2)`
above), which no longer fits an
`EGCircularSector2`/`EGCircularSegment2`/`EGAnnularSector2`/
`EGInterstice2` (each holds a concrete `EGCircularArc2` field, not any
conic arc) — so the result is the more general
[`EGCurvilinearTriangle2`](@ref)/[`EGCurvilinearQuadrilateral2`](@ref)/
[`EGCurvilinearNgon2`](@ref) with the same sides, each mapped through `m`
(reusing [`sides`](@ref) rather than each type's own fields, so this
automatically stays correct if those ever change).
"""
function (m::EGAffineMap)(s::EGCircularSector2)
    s1, s2, s3 = sides(s)
    return EGCurvilinearTriangle2((m(s1), m(s2), m(s3)))
end
function (m::EGAffineMap)(s::EGCircularSegment2)
    return EGCurvilinearNgon2([m(side) for side in sides(s)])
end
function (m::EGAffineMap)(s::EGAnnularSector2)
    s1, s2, s3, s4 = sides(s)
    return EGCurvilinearQuadrilateral2((m(s1), m(s2), m(s3), m(s4)))
end
function (m::EGAffineMap)(g::EGInterstice2)
    return EGCurvilinearTriangle2((m(g.arc1), m(g.arc2), m(g.arc3)))
end

"""
    (m::EGAffineMap)(t::EGCurvilinearTriangle2)
    (m::EGAffineMap)(q::EGCurvilinearQuadrilateral2)
    (m::EGAffineMap)(pg::EGCurvilinearNgon2)

The image under `m` of a general mixed-side region — the same type,
each side mapped through `m` (every side type — `EGSegment` and all four
conic arcs — already knows how to transform itself under `m`).
"""
(m::EGAffineMap)(t::EGCurvilinearTriangle2) = EGCurvilinearTriangle2(map(m, t.sides))
(m::EGAffineMap)(q::EGCurvilinearQuadrilateral2) = EGCurvilinearQuadrilateral2(map(m, q.sides))
(m::EGAffineMap)(pg::EGCurvilinearNgon2) = EGCurvilinearNgon2([m(side) for side in pg.sides])

"""
    (m::EGAffineMap)(c::EGCircle2)

The image of `c` under `m`: in general an [`EGEllipse2`](@ref) (a circle
is only mapped to another circle by the *conformal* affine maps — a
rotation, translation, or uniform scaling — and this covers all affine
maps, so it always returns an `EGEllipse2`, never an `EGCircle2`, even
when `m` happens to be conformal).

The linear part of `m` maps the unit circle to an ellipse whose semi-axes
are its singular values and whose axes are its left singular vectors;
`c`'s own radius scales those semi-axes, and its center maps pointwise.
"""
function (m::EGAffineMap)(c::EGCircle2)
    a, b, cc, d = m.a11, m.a12, m.a21, m.a22
    p, s, q = a^2 + b^2, cc^2 + d^2, a * cc + b * d
    tr, det = p + s, p * s - q^2
    disc = sqrt(max(tr^2 / 4 - det, 0.0))
    λmax, λmin = tr / 2 + disc, tr / 2 - disc
    ang = 0.5 * atan(2q, p - s)
    return EGEllipse2(m(c.center), c.r * sqrt(λmax), c.r * sqrt(λmin), ang)
end

# The affine image of an EGEllipse2/EGHyperbola2's quadratic form. Conic
# TYPE is an affine invariant: an ellipse always maps to an ellipse, a
# hyperbola always to a hyperbola (never to each other, or to a
# parabola), by Sylvester's law of inertia — the map acts on the conic's
# quadratic form Q (relative to its own center, so (p-center)ᵀQ(p-center)
# = 1) as the congruence Q' = M⁻ᵀ Q M⁻¹, which preserves how many of Q's
# eigenvalues are positive/negative/zero. `ε` is +1 for an ellipse's form
# diag(1/a², 1/b²), -1 for a hyperbola's diag(1/a², -1/b²); for either,
# the larger eigenvalue of Q' always ends up on the "a" (1/a²) axis (for
# a hyperbola, Sylvester's law guarantees it's the positive one).
function _affine_map_conic_quadratic_form(m::EGAffineMap, a::Real, b::Real, angle::Real, ε::Real)
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
    (m::EGAffineMap)(e::EGEllipse2)

The image of `e` under `m` — always another `EGEllipse2` (never a circle,
even if `e` happens to be one and `m` conformal — same convention as
`(m::EGAffineMap)(c::EGCircle2)` above).
"""
function (m::EGAffineMap)(e::EGEllipse2)
    λ1, λ2, θ = _affine_map_conic_quadratic_form(m, e.a, e.b, e.angle, 1.0)
    return EGEllipse2(m(e.center), 1 / sqrt(λ1), 1 / sqrt(λ2), θ)
end

"""
    (m::EGAffineMap)(h::EGHyperbola2)

The image of `h` under `m` — always another `EGHyperbola2`.
"""
function (m::EGAffineMap)(h::EGHyperbola2)
    λ1, λ2, θ = _affine_map_conic_quadratic_form(m, h.a, h.b, h.angle, -1.0)
    return EGHyperbola2(m(h.center), 1 / sqrt(λ1), 1 / sqrt(-λ2), θ)
end

"""
    (m::EGAffineMap)(par::EGParabola2)

The image of `par` under `m` — always another `EGParabola2`. Unlike
`(m::EGAffineMap)(e::EGEllipse2)`/`(m::EGAffineMap)(h::EGHyperbola2)`
above, `focus`/`directrix` are metric (not affine-invariant) constructs, so they
can't just be mapped pointwise like a segment's endpoints — `m` can shear
or scale non-uniformly, which moves the true focus/directrix off of
`m(par.focus)`/`m(par.directrix)`. Instead: `par`'s own parametrization
`point_on_parabola(par, y) = vertex + (y²/2pf)u + y·w` becomes, under `m`,
`q(y) = m(vertex) + y·m(w) + y²·(m(u)/2pf)` — a quadratic *vector*
function of `y` whose own vertex/axis/focal parameter are recovered by
rewriting it in the orthonormal frame aligned with its (generally skewed)
`y²` coefficient direction, then completing the square.
"""
function (m::EGAffineMap)(par::EGParabola2)
    V, u, w = _parabola_frame(par)
    pf = focal_parameter(par)
    A, B, C = m(V), m(w), m(u) / (2pf)

    κ = norm(C)
    u2 = C / κ
    w2 = orthogonal(u2)
    X0, Y0 = dot(EGVector(A), u2), dot(EGVector(A), w2)
    bu, bw = dot(B, u2), dot(B, w2)

    C2 = κ / bw^2
    slope = bu / bw
    Xvertex = X0 - slope^2 / (4C2)
    Yvertex = Y0 - slope / (2C2)
    pf2 = 1 / (2C2)

    vertex2 = _from_local_frame(Xvertex, Yvertex, EGPoint(0.0, 0.0), u2, w2)
    focus2 = vertex2 + (pf2 / 2) * u2
    foot2 = vertex2 - (pf2 / 2) * u2
    return EGParabola2(focus2, EGLine(foot2, foot2 + w2))
end

_affine_map_det(m::EGAffineMap) = m.a11 * m.a22 - m.a12 * m.a21

"""
    (m::EGAffineMap)(arc::EGCircularArc2)

The image of `arc` under `m` — an [`EGEllipticArc2`](@ref), not another
`EGCircularArc2` (matching `(m::EGAffineMap)(c::EGCircle2)`'s convention:
a general affine map turns a circle into an ellipse).

Like [`reflection(::EGCircularArc2, ::EGLine)`](@ref), this needs to know
whether `m` preserves or reverses orientation: for a *closed* conic, "the
arc from `p1` to `p2`" only picks out one of the two complementary arcs
because it's understood to sweep counterclockwise, and an
orientation-reversing map (`det(m) < 0`, like a reflection) turns that
sweep clockwise — so `p1`/`p2` are swapped in that case to reconstruct
the correct (not the complementary) arc.
"""
function (m::EGAffineMap)(arc::EGCircularArc2)
    e2 = m(arc.circle)
    return _affine_map_det(m) >= 0 ? EGEllipticArc2(e2, m(arc.p1), m(arc.p2)) : EGEllipticArc2(e2, m(arc.p2), m(arc.p1))
end

"""
    (m::EGAffineMap)(arc::EGEllipticArc2)

The image of `arc` under `m` — another `EGEllipticArc2`, on the image of
its ellipse (an affine invariant, see `(m::EGAffineMap)(e::EGEllipse2)`
above). Swaps `p1`/`p2` when `m` is
orientation-reversing, for the same reason as
`(m::EGAffineMap)(arc::EGCircularArc2)` above.
"""
function (m::EGAffineMap)(arc::EGEllipticArc2)
    e2 = m(arc.ellipse)
    return _affine_map_det(m) >= 0 ? EGEllipticArc2(e2, m(arc.p1), m(arc.p2)) : EGEllipticArc2(e2, m(arc.p2), m(arc.p1))
end

"""
    (m::EGAffineMap)(arc::EGHyperbolicArc2)
    (m::EGAffineMap)(arc::EGParabolicArc2)

The image of `arc` under `m` — the same arc type, on the image of its
underlying conic. Unlike the closed-conic arcs above, a single hyperbola
branch/a parabola is open, so there's no complementary-arc ambiguity and
no swap is needed even when `m` reverses orientation (matching
[`reflection(::EGHyperbolicArc2, _)`](@ref)/`reflection(::EGParabolicArc2, _)`).
"""
(m::EGAffineMap)(arc::EGHyperbolicArc2) = EGHyperbolicArc2(m(arc.hyperbola), m(arc.p1), m(arc.p2))
(m::EGAffineMap)(arc::EGParabolicArc2) = EGParabolicArc2(m(arc.parabola), m(arc.p1), m(arc.p2))

"""
    affine_map(src::NTuple{3,EGPoint}, dst::NTuple{3,EGPoint})

The unique affine map sending `src[i]` to `dst[i]` for `i = 1, 2, 3`.
`src` must be non-collinear.
"""
function affine_map(src::NTuple{3,<:EGPoint{2}}, dst::NTuple{3,<:EGPoint{2}}; atol=1e-9)
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
    return EGAffineMap(a11, a12, a21, a22, tx, ty)
end

"""
    translation_map(v::EGVector)
    translation_map(v::EGPoint)

The affine map `p -> p + v` — equivalent to `p -> translate(p, v)`, as a
genuine, reusable `EGAffineMap` value: composes with `∘`/other maps into
one *combined* map (computed once, applied as cheaply as any single map),
and works uniformly across every type this file already handles (see
[Affine Maps](@ref)).

The tradeoff for that generality: applying an `EGAffineMap` — this one
included — can't preserve an exotic type the way `translate(shape, v)`
itself does (a circle piped through here comes back as an `EGEllipse2`,
never `EGCircle2`, since nothing in the map's own type says it happens to
be conformal). [`translate`](@ref)'s own one-argument form
(`translate(v)`) is the type-preserving alternative — a plain function
rather than an `EGAffineMap`, so it doesn't compose into one combined
object, but chains of direct, exact `translate(shape, v)` calls instead.
Reach for whichever tradeoff the situation calls for.
"""
translation_map(v::EGPointOrVector{2}) = EGAffineMap(one(v[1]), zero(v[1]), zero(v[1]), one(v[1]), v[1], v[2])

"""
    rotation_map(angle::Real, center::EGPoint)

The affine map rotating by `angle` radians (counterclockwise) around
`center` — equivalent to `p -> rotate(p, angle, center)`, as a genuine,
composable `EGAffineMap` value (see [`translation_map`](@ref) for the
tradeoff against [`rotate`](@ref)'s own type-preserving one-argument
form).

No default for `center` here (unlike `rotate`, which defaults to the
origin): a default would make `rotation_map(angle)` alone valid, silently
rotating about the origin with no `center` in sight at the call site —
pass `center` explicitly instead.
"""
function rotation_map(angle::Real, center::EGPoint{2})
    c, s = cos(angle), sin(angle)
    tx = center[1] - (c * center[1] - s * center[2])
    ty = center[2] - (s * center[1] + c * center[2])
    return EGAffineMap(c, -s, s, c, tx, ty)
end

"""
    homothety_map(k::Real, center::EGPoint)

The affine map scaling by ratio `k` about `center` — equivalent to
`p -> homothety(p, k, center)`, as a genuine, composable `EGAffineMap`
value (see [`translation_map`](@ref) for the tradeoff against
[`homothety`](@ref)'s own type-preserving one-argument form). See
[`rotation_map`](@ref) for why `center` has no zero-argument default here.
"""
function homothety_map(k::Real, center::EGPoint{2})
    tx, ty = center[1] * (1 - k), center[2] * (1 - k)
    return EGAffineMap(k, zero(k), zero(k), k, tx, ty)
end

"""
    reflection_map(l::EGLine)

The affine map reflecting across `l` — equivalent to
`p -> reflection(p, l)`, as a genuine, composable `EGAffineMap` value
(see [`translation_map`](@ref) for the tradeoff against
[`reflection`](@ref)'s own type-preserving one-argument form).
"""
function reflection_map(l::EGLine{2})
    n = orthogonal(direction(l))
    return affine_map((l.p1, l.p2, l.p1 + n), (l.p1, l.p2, l.p1 - n))
end

"""
    reflection_map(about::EGPoint)

The affine map point-reflecting through `about` (`p -> 2*about - p`) —
equivalent to `p -> reflection(p, about)`, as a genuine, composable
`EGAffineMap` value (see [`translation_map`](@ref) for the tradeoff
against [`reflection`](@ref)'s own type-preserving one-argument form).
"""
reflection_map(about::EGPoint{2}) = EGAffineMap(-one(about[1]), zero(about[1]), zero(about[1]), -one(about[1]), 2about[1], 2about[2])

"""
    translate(v::EGVector)

A reusable, one-argument function, `shape -> translate(shape, v)` — for
`|>`/`∘`/`map`/`filter` composition without a shape already in hand yet,
same as [`translation_map`](@ref)`(v)` — but a plain function rather than
an `EGAffineMap`, so it *preserves* whatever specific type
`translate(shape, v)` itself already returns (a circle stays a circle).
Composing two of these with `∘` builds a plain function too (a chain of
type-preserving calls, applied in sequence each time), not one combined,
reusable map object — reach for [`translation_map`](@ref) instead if
that's what's actually needed.

```julia
t |> translate(v)                      # same as translate(t, v)
(rotate(pi/2) ∘ translate(v))(t)       # rotate(translate(t, v), pi/2) -- each step exact
map(translate(v), [c1, c2])            # c1/c2 stay EGCircle2, not EGEllipse2
```
"""
translate(v::EGVector{2}) = shape -> translate(shape, v)

"""
    rotate(angle::Real, center::EGPoint=EGPoint(0.0, 0.0))

A reusable, one-argument function, `shape -> rotate(shape, angle,
center)` — the type-preserving counterpart of
[`rotation_map`](@ref)`(angle, center)` (see [`translate`](@ref)`(v)` for
the full tradeoff). Unlike `rotation_map`, `center` here defaults to the
origin, same as the direct, shape-taking `rotate` itself.
"""
rotate(angle::Real, center::EGPoint{2}=EGPoint(0.0, 0.0)) = shape -> rotate(shape, angle, center)

"""
    homothety(k::Real, center::EGPoint=EGPoint(0.0, 0.0))

A reusable, one-argument function, `shape -> homothety(shape, k,
center)` — the type-preserving counterpart of
[`homothety_map`](@ref)`(k, center)` (see [`translate`](@ref)`(v)` for the
full tradeoff). Unlike `homothety_map`, `center` here defaults to the
origin, same as the direct, shape-taking `homothety` itself.
"""
homothety(k::Real, center::EGPoint{2}=EGPoint(0.0, 0.0)) = shape -> homothety(shape, k, center)

"""
    reflection(about::EGPoint)
    reflection(about::EGLine)

A reusable, one-argument function, `shape -> reflection(shape, about)` —
the type-preserving counterpart of [`reflection_map`](@ref)`(about)` (see
[`translate`](@ref)`(v)` for the full tradeoff).
"""
reflection(about::EGPoint{2}) = shape -> reflection(shape, about)
reflection(about::EGLine{2}) = shape -> reflection(shape, about)

function Base.:∘(m2::EGAffineMap, m1::EGAffineMap)
    a11 = m2.a11 * m1.a11 + m2.a12 * m1.a21
    a12 = m2.a11 * m1.a12 + m2.a12 * m1.a22
    a21 = m2.a21 * m1.a11 + m2.a22 * m1.a21
    a22 = m2.a21 * m1.a12 + m2.a22 * m1.a22
    tx = m2.a11 * m1.tx + m2.a12 * m1.ty + m2.tx
    ty = m2.a21 * m1.tx + m2.a22 * m1.ty + m2.ty
    return EGAffineMap(a11, a12, a21, a22, tx, ty)
end
