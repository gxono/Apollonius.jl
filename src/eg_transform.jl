# -------------------------------------------------------------------------
# Phase 7 of the EG-prefixed type hierarchy rewrite (see
# .claude/plans/structured-wibbling-wigderson.md): EGAffineMap (<: EGTransform),
# built on EGPoint/EGVector and callable on every EG-typed shape defined so
# far. Coexists with the existing Point2-based AffineMap for now.
# -------------------------------------------------------------------------

"""
    EGAffineMap(a11, a12, a21, a22, tx, ty)

The affine map `p -> [a11 a12; a21 a22] * p + (tx, ty)`. Instances are
callable: `m(p)` applies the map to a point, and pointwise to every
EG-typed curve/polygon defined so far.
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
    translation_map(v::EGPoint)

The affine map `p -> p + v`.
"""
translation_map(v::EGPoint{2}) = EGAffineMap(one(v[1]), zero(v[1]), zero(v[1]), one(v[1]), v[1], v[2])

"""
    rotation_map(angle::Real, center::EGPoint)

The affine map rotating by `angle` radians (counterclockwise) around
`center`. Equivalent to `p -> rotate(p, angle, center)`, but composable.

No zero-argument default for `center` here (unlike [`rotate`](@ref)): a
`rotation_map(angle::Real)` single-argument fallback already exists for
the old `Point2`-based `AffineMap` family, and since `center`'s type
never appears in *that* auto-generated method's signature, an EG-typed
default would collide with it — pass `center` explicitly instead.
"""
function rotation_map(angle::Real, center::EGPoint{2})
    c, s = cos(angle), sin(angle)
    tx = center[1] - (c * center[1] - s * center[2])
    ty = center[2] - (s * center[1] + c * center[2])
    return EGAffineMap(c, -s, s, c, tx, ty)
end

"""
    homothety_map(k::Real, center::EGPoint)

The affine map scaling by ratio `k` about `center`. Equivalent to
`p -> homothety(p, k, center)`, but composable. See [`rotation_map`](@ref)
for why `center` has no zero-argument default here.
"""
function homothety_map(k::Real, center::EGPoint{2})
    tx, ty = center[1] * (1 - k), center[2] * (1 - k)
    return EGAffineMap(k, zero(k), zero(k), k, tx, ty)
end

"""
    reflection_map(l::EGLine)

The affine map reflecting across `l`. Equivalent to `p -> reflection(p, l)`,
but composable.
"""
function reflection_map(l::EGLine{2})
    n = orthogonal(direction(l))
    return affine_map((l.p1, l.p2, l.p1 + n), (l.p1, l.p2, l.p1 - n))
end

function Base.:∘(m2::EGAffineMap, m1::EGAffineMap)
    a11 = m2.a11 * m1.a11 + m2.a12 * m1.a21
    a12 = m2.a11 * m1.a12 + m2.a12 * m1.a22
    a21 = m2.a21 * m1.a11 + m2.a22 * m1.a21
    a22 = m2.a21 * m1.a12 + m2.a22 * m1.a22
    tx = m2.a11 * m1.tx + m2.a12 * m1.ty + m2.tx
    ty = m2.a21 * m1.tx + m2.a22 * m1.ty + m2.ty
    return EGAffineMap(a11, a12, a21, a22, tx, ty)
end
