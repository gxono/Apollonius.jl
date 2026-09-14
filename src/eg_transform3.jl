# -------------------------------------------------------------------------
# EGAffineMap3 (<: EGTransform), the 3D sibling of EGAffineMap: a 3x3
# linear part (a11..a33) + translation (tx,ty,tz), same "flat named
# scalars, no arrays/StaticArrays" style. Function names are unchanged
# from the 2D transform family (rotate/homothety/reflection/translate,
# rotation_map/homothety_map/reflection_map/translation_map, affine_map)
# -- every one of them already dispatches by the Dim of its point/line/
# plane argument, so the 3D methods here are new dispatches, not new names.
# -------------------------------------------------------------------------

"""
    EGAffineMap3(a11, a12, a13, a21, a22, a23, a31, a32, a33, tx, ty, tz)

The affine map `p -> A*p + (tx,ty,tz)` for the 3x3 matrix `A` (rows
`a11 a12 a13` / `a21 a22 a23` / `a31 a32 a33`) -- the 3D sibling of
[`EGAffineMap`](@ref). Instances are callable exactly like `EGAffineMap`.
"""
struct EGAffineMap3{T<:Real} <: EGTransform{T}
    a11::T
    a12::T
    a13::T
    a21::T
    a22::T
    a23::T
    a31::T
    a32::T
    a33::T
    tx::T
    ty::T
    tz::T
end
EGAffineMap3(a11::Real, a12::Real, a13::Real, a21::Real, a22::Real, a23::Real,
    a31::Real, a32::Real, a33::Real, tx::Real, ty::Real, tz::Real) =
    EGAffineMap3(promote(a11, a12, a13, a21, a22, a23, a31, a32, a33, tx, ty, tz)...)

Base.:(==)(x::EGAffineMap3, y::EGAffineMap3) =
    x.a11 == y.a11 && x.a12 == y.a12 && x.a13 == y.a13 &&
    x.a21 == y.a21 && x.a22 == y.a22 && x.a23 == y.a23 &&
    x.a31 == y.a31 && x.a32 == y.a32 && x.a33 == y.a33 &&
    x.tx == y.tx && x.ty == y.ty && x.tz == y.tz
Base.isapprox(x::EGAffineMap3, y::EGAffineMap3; kwargs...) =
    isapprox(x.a11, y.a11; kwargs...) && isapprox(x.a12, y.a12; kwargs...) && isapprox(x.a13, y.a13; kwargs...) &&
    isapprox(x.a21, y.a21; kwargs...) && isapprox(x.a22, y.a22; kwargs...) && isapprox(x.a23, y.a23; kwargs...) &&
    isapprox(x.a31, y.a31; kwargs...) && isapprox(x.a32, y.a32; kwargs...) && isapprox(x.a33, y.a33; kwargs...) &&
    isapprox(x.tx, y.tx; kwargs...) && isapprox(x.ty, y.ty; kwargs...) && isapprox(x.tz, y.tz; kwargs...)
Base.show(io::IO, m::EGAffineMap3) =
    print(io, "EGAffineMap3([", m.a11, " ", m.a12, " ", m.a13, "; ", m.a21, " ", m.a22, " ", m.a23,
        "; ", m.a31, " ", m.a32, " ", m.a33, "], t=(", m.tx, ", ", m.ty, ", ", m.tz, "))")

(m::EGAffineMap3)(p::EGPoint{3}) = EGPoint(
    m.a11 * p[1] + m.a12 * p[2] + m.a13 * p[3] + m.tx,
    m.a21 * p[1] + m.a22 * p[2] + m.a23 * p[3] + m.ty,
    m.a31 * p[1] + m.a32 * p[2] + m.a33 * p[3] + m.tz)

"""
    (m::EGAffineMap3)(v::EGVector{3})

The image of the free vector `v` under `m`'s *linear* part only (no
translation) -- same convention as `(m::EGAffineMap)(v::EGVector)`.
"""
(m::EGAffineMap3)(v::EGVector{3}) = EGVector(
    m.a11 * v[1] + m.a12 * v[2] + m.a13 * v[3],
    m.a21 * v[1] + m.a22 * v[2] + m.a23 * v[3],
    m.a31 * v[1] + m.a32 * v[2] + m.a33 * v[3])

(m::EGAffineMap3)(s::EGSegment{3}) = EGSegment(m(s.p1), m(s.p2))
(m::EGAffineMap3)(l::EGLine{3}) = EGLine(m(l.p1), m(l.p2))
(m::EGAffineMap3)(r::EGRay{3}) = EGRay(m(r.origin), m(r.through))

function Base.:∘(m2::EGAffineMap3, m1::EGAffineMap3)
    a11 = m2.a11 * m1.a11 + m2.a12 * m1.a21 + m2.a13 * m1.a31
    a12 = m2.a11 * m1.a12 + m2.a12 * m1.a22 + m2.a13 * m1.a32
    a13 = m2.a11 * m1.a13 + m2.a12 * m1.a23 + m2.a13 * m1.a33
    a21 = m2.a21 * m1.a11 + m2.a22 * m1.a21 + m2.a23 * m1.a31
    a22 = m2.a21 * m1.a12 + m2.a22 * m1.a22 + m2.a23 * m1.a32
    a23 = m2.a21 * m1.a13 + m2.a22 * m1.a23 + m2.a23 * m1.a33
    a31 = m2.a31 * m1.a11 + m2.a32 * m1.a21 + m2.a33 * m1.a31
    a32 = m2.a31 * m1.a12 + m2.a32 * m1.a22 + m2.a33 * m1.a32
    a33 = m2.a31 * m1.a13 + m2.a32 * m1.a23 + m2.a33 * m1.a33
    tx = m2.a11 * m1.tx + m2.a12 * m1.ty + m2.a13 * m1.tz + m2.tx
    ty = m2.a21 * m1.tx + m2.a22 * m1.ty + m2.a23 * m1.tz + m2.ty
    tz = m2.a31 * m1.tx + m2.a32 * m1.ty + m2.a33 * m1.tz + m2.tz
    return EGAffineMap3(a11, a12, a13, a21, a22, a23, a31, a32, a33, tx, ty, tz)
end

"""
    translation_map(v::EGVector{3})
    translation_map(v::EGPoint{3})

The affine map `p -> p + v` — the 3D sibling of
`translation_map(::EGPointOrVector{2})`, and likewise a deliberately
separate name from [`translate`](@ref) rather than an overload of it (see
that 2D docstring for why).
"""
translation_map(v::EGPointOrVector{3}) = EGAffineMap3(
    one(v[1]), zero(v[1]), zero(v[1]),
    zero(v[1]), one(v[1]), zero(v[1]),
    zero(v[1]), zero(v[1]), one(v[1]),
    v[1], v[2], v[3])

"""
    rotation_map(angle::Real, axis::EGLine{3})

The affine map rotating by `angle` radians about `axis` (right-hand
rule), via the Rodrigues rotation matrix `R = I*cosθ + sinθ*K +
(1-cosθ)*k kᵀ` (`k` the unit axis direction, `K` its cross-product
matrix) -- the 3D sibling of `rotation_map(::Real, ::EGPoint{2})`. The
translation term is fixed so that every point on `axis` maps to itself,
the same way the 2D version's is.
"""
function rotation_map(angle::Real, axis::EGLine{3})
    k = direction(axis) / norm(direction(axis))
    kx, ky, kz = k[1], k[2], k[3]
    c, s = cos(angle), sin(angle)
    ic = 1 - c

    a11, a12, a13 = c + kx^2 * ic, kx * ky * ic - kz * s, kx * kz * ic + ky * s
    a21, a22, a23 = ky * kx * ic + kz * s, c + ky^2 * ic, ky * kz * ic - kx * s
    a31, a32, a33 = kz * kx * ic - ky * s, kz * ky * ic + kx * s, c + kz^2 * ic

    p0 = axis.p1
    tx = p0[1] - (a11 * p0[1] + a12 * p0[2] + a13 * p0[3])
    ty = p0[2] - (a21 * p0[1] + a22 * p0[2] + a23 * p0[3])
    tz = p0[3] - (a31 * p0[1] + a32 * p0[2] + a33 * p0[3])
    return EGAffineMap3(a11, a12, a13, a21, a22, a23, a31, a32, a33, tx, ty, tz)
end

"""
    homothety_map(k::Real, center::EGPoint{3})

The affine map scaling by ratio `k` about `center` — the 3D sibling of
`homothety_map(::Real, ::EGPoint{2})`.
"""
function homothety_map(k::Real, center::EGPoint{3})
    z = zero(k)
    tx, ty, tz = center[1] * (1 - k), center[2] * (1 - k), center[3] * (1 - k)
    return EGAffineMap3(k, z, z, z, k, z, z, z, k, tx, ty, tz)
end

"""
    reflection_map(pl::EGPlane3)

The affine map reflecting across the plane `pl` — the 3D sibling of
`reflection_map(::EGLine{2})`, via `R = I - 2*n*nᵀ` for `pl`'s unit
normal `n`.
"""
function reflection_map(pl::EGPlane3)
    n = pl.normal
    nx, ny, nz = n[1], n[2], n[3]
    a11, a12, a13 = 1 - 2nx^2, -2nx * ny, -2nx * nz
    a21, a22, a23 = -2ny * nx, 1 - 2ny^2, -2ny * nz
    a31, a32, a33 = -2nz * nx, -2nz * ny, 1 - 2nz^2

    p0 = pl.point
    tx = p0[1] - (a11 * p0[1] + a12 * p0[2] + a13 * p0[3])
    ty = p0[2] - (a21 * p0[1] + a22 * p0[2] + a23 * p0[3])
    tz = p0[3] - (a31 * p0[1] + a32 * p0[2] + a33 * p0[3])
    return EGAffineMap3(a11, a12, a13, a21, a22, a23, a31, a32, a33, tx, ty, tz)
end

"""
    reflection_map(about::EGPoint{3})

The affine map point-reflecting through `about` (`p -> 2*about - p`) —
the 3D sibling of `reflection_map(::EGPoint{2})`.
"""
reflection_map(about::EGPoint{3}) = EGAffineMap3(
    -one(about[1]), zero(about[1]), zero(about[1]),
    zero(about[1]), -one(about[1]), zero(about[1]),
    zero(about[1]), zero(about[1]), -one(about[1]),
    2about[1], 2about[2], 2about[3])

"""
    translate(v::EGVector{3})

A reusable, one-argument function, `shape -> translate(shape, v)` — the
3D sibling of `translate(::EGVector{2})`; see that 2D docstring for the
full tradeoff against [`translation_map`](@ref).
"""
translate(v::EGVector{3}) = shape -> translate(shape, v)

"""
    rotate(angle::Real, axis::EGLine{3})

A reusable, one-argument function, `shape -> rotate(shape, angle, axis)`
— the 3D sibling of `rotate(::Real, ::EGPoint{2})`; see that 2D docstring
for the full tradeoff against [`rotation_map`](@ref).
"""
rotate(angle::Real, axis::EGLine{3}) = shape -> rotate(shape, angle, axis)

"""
    homothety(k::Real, center::EGPoint{3})

A reusable, one-argument function, `shape -> homothety(shape, k, center)`
— the 3D sibling of `homothety(::Real, ::EGPoint{2})`; see that 2D
docstring for the full tradeoff against [`homothety_map`](@ref).
"""
homothety(k::Real, center::EGPoint{3}) = shape -> homothety(shape, k, center)

"""
    reflection(about::EGPoint{3})
    reflection(about::EGPlane3)

A reusable, one-argument function, `shape -> reflection(shape, about)` —
the 3D sibling of `reflection(::EGPoint{2})`/`reflection(::EGLine{2})`;
see that 2D docstring for the full tradeoff against
[`reflection_map`](@ref). There is deliberately no
`reflection(::EGLine{3})` — see
[`reflection(::EGPoint{2}, ::EGLine{2})`](@ref) for why "reflecting
across a line" isn't a well-defined 3D isometry.
"""
reflection(about::EGPoint{3}) = shape -> reflection(shape, about)
reflection(about::EGPlane3) = shape -> reflection(shape, about)

"""
    affine_map(src::NTuple{4,EGPoint{3}}, dst::NTuple{4,EGPoint{3}})

The unique affine map sending `src[i]` to `dst[i]` for `i = 1, ..., 4` —
the 3D sibling of `affine_map(::NTuple{3,EGPoint{2}}, ::NTuple{3,EGPoint{2}})`.
`src` must not be coplanar (4 non-coplanar points pin down all 12 degrees
of freedom of a 3D affine map, the same way 3 non-collinear points do for
2D's 6).
"""
function affine_map(src::NTuple{4,<:EGPoint{3}}, dst::NTuple{4,<:EGPoint{3}}; atol=1e-9)
    p1, p2, p3, p4 = src
    q1, q2, q3, q4 = dst
    u, v, w = p2 - p1, p3 - p1, p4 - p1
    du, dv, dw = q2 - q1, q3 - q1, q4 - q1

    is_coplanar(p1, p2, p3, p4; atol=atol) &&
        throw(ArgumentError("affine_map: source points must not be coplanar"))

    M = [u[1] v[1] w[1]; u[2] v[2] w[2]; u[3] v[3] w[3]]
    Dm = [du[1] dv[1] dw[1]; du[2] dv[2] dw[2]; du[3] dv[3] dw[3]]
    A = Dm / M

    a11, a12, a13 = A[1, 1], A[1, 2], A[1, 3]
    a21, a22, a23 = A[2, 1], A[2, 2], A[2, 3]
    a31, a32, a33 = A[3, 1], A[3, 2], A[3, 3]
    tx = q1[1] - (a11 * p1[1] + a12 * p1[2] + a13 * p1[3])
    ty = q1[2] - (a21 * p1[1] + a22 * p1[2] + a23 * p1[3])
    tz = q1[3] - (a31 * p1[1] + a32 * p1[2] + a33 * p1[3])
    return EGAffineMap3(a11, a12, a13, a21, a22, a23, a31, a32, a33, tx, ty, tz)
end
