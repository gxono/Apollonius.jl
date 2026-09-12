# -------------------------------------------------------------------------
# The classical Apollonius problem (tangent_circles/_through_point(s)) for
# EGPoint/EGLine/EGCircle2. `_solve_quadratic` is untyped (utils.jl) and
# works for free; `_dedupe_circles`/`_exclude_given` have EGCircle2 methods
# in eg_tangency.jl.
# -------------------------------------------------------------------------

"""
    tangent_circles_through_points(a::EGPoint, b::EGPoint, l::EGLine; atol=1e-9)

Circle(s) passing through `a` and `b` and tangent to line `l`. Returns a
`Vector{EGCircle2{Float64}}` with 0, 1 or 2 solutions.
"""
function tangent_circles_through_points(a::EGPoint, b::EGPoint, l::EGLine; atol=1e-9)
    m = midpoint(a, b)
    d = orthogonal(b - a)
    ld = direction(l)
    dn = norm(ld)
    dn <= atol && return EGCircle2{Float64}[]

    s0 = cross2(ld, m - l.p1) / dn
    s1 = cross2(ld, d) / dn
    A0, A1, A2 = dot(m - a, m - a), 2 * dot(d, m - a), dot(d, d)

    ts = _solve_quadratic(s1^2 - A2, 2s0 * s1 - A1, s0^2 - A0; atol=atol)

    circles = EGCircle2{Float64}[]
    for t in ts
        o = m + t * d
        r = distance(o, a)
        sol = EGCircle2(EGPoint(o[1], o[2]), Float64(r))
        _tangent_ok(sol, l; atol=atol, scale=max(r, 1.0)) && push!(circles, sol)
    end
    return circles
end
tangent_circles_through_points(l::EGLine, a::EGPoint, b::EGPoint; atol=1e-9) =
    tangent_circles_through_points(a, b, l; atol=atol)

"""
    tangent_circles_through_points(a::EGPoint, b::EGPoint, c::EGCircle2; atol=1e-9)

Circle(s) passing through `a` and `b` and tangent (internally or
externally) to circle `c`. Returns a `Vector{EGCircle2{Float64}}` with 0,
1 or 2 solutions.
"""
function tangent_circles_through_points(a::EGPoint, b::EGPoint, c::EGCircle2; atol=1e-9)
    m = midpoint(a, b)
    d = orthogonal(b - a)
    Cc, R = c.center, c.r

    A0, A1, A2 = dot(m - a, m - a), 2 * dot(d, m - a), dot(d, d)
    C0, C1 = dot(m - Cc, m - Cc), 2 * dot(d, m - Cc)

    g0, g1 = (C0 - A0) - R^2, C1 - A1

    ts = _solve_quadratic(g1^2 - 4R^2 * A2, 2g0 * g1 - 4R^2 * A1, g0^2 - 4R^2 * A0; atol=atol)

    circles = EGCircle2{Float64}[]
    for t in ts
        o = m + t * d
        r = distance(o, a)
        sol = EGCircle2(EGPoint(o[1], o[2]), Float64(r))
        _tangent_ok(sol, c; atol=atol, scale=max(r, R, 1.0)) && push!(circles, sol)
    end
    return circles
end
tangent_circles_through_points(c::EGCircle2, a::EGPoint, b::EGPoint; atol=1e-9) =
    tangent_circles_through_points(a, b, c; atol=atol)

"""
    tangent_circles_through_point(l1::EGLine, l2::EGLine, p::EGPoint; atol=1e-9)

Circle(s) tangent to both `l1` and `l2`, passing through `p`. Returns a
`Vector{EGCircle2{Float64}}` with up to 4 solutions (2 per bisector).
"""
function tangent_circles_through_point(l1::EGLine, l2::EGLine, p::EGPoint; atol=1e-9)
    circles = EGCircle2{Float64}[]
    for bis in angle_bisectors(l1, l2; atol=atol)
        m, d = bis.p1, direction(bis)
        ld = direction(l1)
        dn = norm(ld)
        s0 = cross2(ld, m - l1.p1) / dn
        s1 = cross2(ld, d) / dn
        A0, A1, A2 = dot(m - p, m - p), 2 * dot(d, m - p), dot(d, d)

        ts = _solve_quadratic(s1^2 - A2, 2s0 * s1 - A1, s0^2 - A0; atol=atol)
        for t in ts
            o = m + t * d
            r = distance(o, p)
            sol = EGCircle2(EGPoint(o[1], o[2]), Float64(r))
            scale = max(r, 1.0)
            _tangent_ok(sol, l1; atol=atol, scale=scale) && _tangent_ok(sol, l2; atol=atol, scale=scale) &&
                push!(circles, sol)
        end
    end
    return circles
end

function _tangent_circles_through_point_via_inversion(obj1, obj2, p::EGPoint; atol=1e-9)
    i1 = invert(obj1, p; atol=atol)
    i2 = invert(obj2, p; atol=atol)
    tls = vcat(external_tangent_lines(i1, i2; atol=atol), internal_tangent_lines(i1, i2; atol=atol))

    circles = EGCircle2{Float64}[]
    for tl in tls
        on_line(p, tl; atol=atol) && continue
        sol = invert(tl, p; atol=atol)
        scale = max(sol.r, 1.0)
        _tangent_ok(sol, obj1; atol=atol, scale=scale) && _tangent_ok(sol, obj2; atol=atol, scale=scale) &&
            push!(circles, EGCircle2(EGPoint(sol.center[1], sol.center[2]), Float64(sol.r)))
    end
    return circles
end

_tangent_ok(sol::EGCircle2, l::EGLine; atol=1e-9, scale=1.0) = abs(distance(sol.center, l) - sol.r) <= sqrt(atol) * scale
function _tangent_ok(sol::EGCircle2, c::EGCircle2; atol=1e-9, scale=1.0)
    d = distance(sol.center, c.center)
    tol = sqrt(atol) * max(scale, c.r)
    abs(d - (c.r + sol.r)) <= tol || abs(d - abs(c.r - sol.r)) <= tol
end

"""
    tangent_circles_through_point(c1::EGCircle2, c2::EGCircle2, p::EGPoint; atol=1e-9)
    tangent_circles_through_point(l::EGLine, c::EGCircle2, p::EGPoint; atol=1e-9)

Circle(s) tangent to `c1`/`c2` (or to `l`/`c`), passing through `p` — the
`CCP`/`CLP` Apollonius cases, solved by inverting about `p`. `p` must not
lie on `c1`/`c2` (or `l`/`c`). Returns a `Vector{EGCircle2{Float64}}`
with up to 4 solutions.
"""
tangent_circles_through_point(c1::EGCircle2, c2::EGCircle2, p::EGPoint; atol=1e-9) =
    _tangent_circles_through_point_via_inversion(c1, c2, p; atol=atol)
tangent_circles_through_point(l::EGLine, c::EGCircle2, p::EGPoint; atol=1e-9) =
    _tangent_circles_through_point_via_inversion(l, c, p; atol=atol)
tangent_circles_through_point(c::EGCircle2, l::EGLine, p::EGPoint; atol=1e-9) =
    tangent_circles_through_point(l, c, p; atol=atol)

_line_coeffs(l::EGLine) = begin
    d = direction(l) / norm(direction(l))
    (-d[2], d[1], d[2] * l.p1[1] - d[1] * l.p1[2])
end

function _push_valid!(circles, ox0, ox1, oy0, oy1, target_center::EGPoint, target_r, eps3, others...; atol=1e-9)
    px, py = ox0 - target_center[1], oy0 - target_center[2]
    qa = ox1^2 + oy1^2 - 1
    qb = 2 * (px * ox1 + py * oy1) - 2 * eps3 * target_r
    qc = px^2 + py^2 - target_r^2
    for r in _solve_quadratic(qa, qb, qc; atol=atol)
        r <= atol && continue
        o = EGPoint(ox0 + ox1 * r, oy0 + oy1 * r)
        sol = EGCircle2(o, r)
        scale = max(r, 1.0)
        all(obj -> _tangent_ok(sol, obj; atol=atol, scale=scale), others) || continue
        push!(circles, EGCircle2(EGPoint(o[1], o[2]), Float64(r)))
    end
end

"""
    tangent_circles(l1::EGLine, l2::EGLine, c::EGCircle2; atol=1e-9)

Circle(s) tangent to `l1`, `l2` and `c` (the `CLL` Apollonius case).
`l1` and `l2` must not be parallel. Returns a `Vector{EGCircle2{Float64}}`
with up to 4 solutions.
"""
function tangent_circles(l1::EGLine, l2::EGLine, c::EGCircle2; atol=1e-9)
    A1, B1, K1 = _line_coeffs(l1)
    A2, B2, K2 = _line_coeffs(l2)
    det = A1 * B2 - A2 * B1
    circles = EGCircle2{Float64}[]
    abs(det) <= atol && return circles

    for δ1 in (1, -1), δ2 in (1, -1), ε in (1, -1)
        ox0, ox1 = (-K1 * B2 + K2 * B1) / det, (δ1 * B2 - δ2 * B1) / det
        oy0, oy1 = (A1 * (-K2) - A2 * (-K1)) / det, (A1 * δ2 - A2 * δ1) / det
        _push_valid!(circles, ox0, ox1, oy0, oy1, c.center, c.r, ε, l1, l2, c; atol=atol)
    end
    return _exclude_given(_dedupe_circles(circles; atol=atol), c; atol=atol)
end
tangent_circles(c::EGCircle2, l1::EGLine, l2::EGLine; atol=1e-9) = tangent_circles(l1, l2, c; atol=atol)

"""
    tangent_circles(c1::EGCircle2, c2::EGCircle2, l::EGLine; atol=1e-9)

Circle(s) tangent to `c1`, `c2` and `l` (the `CCL` Apollonius case).
Returns a `Vector{EGCircle2{Float64}}` with up to 8 solutions.
"""
function tangent_circles(c1::EGCircle2, c2::EGCircle2, l::EGLine; atol=1e-9)
    Cc1, R1 = c1.center, c1.r
    Cc2, R2 = c2.center, c2.r
    A, B, K = _line_coeffs(l)
    P, Q = 2 * (Cc2[1] - Cc1[1]), 2 * (Cc2[2] - Cc1[2])
    M = (R1^2 - R2^2) - (dot(Cc1, Cc1) - dot(Cc2, Cc2))

    circles = EGCircle2{Float64}[]
    for ε1 in (1, -1), ε2 in (1, -1), δ in (1, -1)
        N = 2 * (ε1 * R1 - ε2 * R2)
        det2 = P * B - A * Q
        abs(det2) <= atol && continue
        ox0, ox1 = (M * B + K * Q) / det2, (N * B - δ * Q) / det2
        oy0, oy1 = (-P * K - A * M) / det2, (P * δ - A * N) / det2
        _push_valid!(circles, ox0, ox1, oy0, oy1, Cc1, R1, ε1, c1, c2, l; atol=atol)
    end
    return _exclude_given(_dedupe_circles(circles; atol=atol), c1, c2; atol=atol)
end
tangent_circles(l::EGLine, c1::EGCircle2, c2::EGCircle2; atol=1e-9) = tangent_circles(c1, c2, l; atol=atol)

"""
    tangent_circles(c1::EGCircle2, c2::EGCircle2, c3::EGCircle2; atol=1e-9)

Circle(s) tangent to `c1`, `c2` and `c3` — the classical Apollonius
problem. Returns a `Vector{EGCircle2{Float64}}` with up to 8 solutions.
"""
function tangent_circles(c1::EGCircle2, c2::EGCircle2, c3::EGCircle2; atol=1e-9)
    Cc1, R1 = c1.center, c1.r
    Cc2, R2 = c2.center, c2.r
    Cc3, R3 = c3.center, c3.r

    circles = EGCircle2{Float64}[]
    for ε1 in (1, -1), ε2 in (1, -1), ε3 in (1, -1)
        P1, Q1 = 2 * (Cc3[1] - Cc1[1]), 2 * (Cc3[2] - Cc1[2])
        M1 = (R1^2 - R3^2) - (dot(Cc1, Cc1) - dot(Cc3, Cc3))
        N1 = 2 * (ε1 * R1 - ε3 * R3)

        P2, Q2 = 2 * (Cc3[1] - Cc2[1]), 2 * (Cc3[2] - Cc2[2])
        M2 = (R2^2 - R3^2) - (dot(Cc2, Cc2) - dot(Cc3, Cc3))
        N2 = 2 * (ε2 * R2 - ε3 * R3)

        det2 = P1 * Q2 - P2 * Q1
        abs(det2) <= atol && continue
        ox0, ox1 = (M1 * Q2 - M2 * Q1) / det2, (N1 * Q2 - N2 * Q1) / det2
        oy0, oy1 = (P1 * M2 - P2 * M1) / det2, (P1 * N2 - P2 * N1) / det2
        _push_valid!(circles, ox0, ox1, oy0, oy1, Cc3, R3, ε3, c1, c2, c3; atol=atol)
    end
    return _exclude_given(_dedupe_circles(circles; atol=atol), c1, c2, c3; atol=atol)
end

# -------------------------------------------------------------------------
# `interstices(c1, c2, c3)`: builds an `EGInterstice2` from 3 mutually
# tangent circles, using the `tangent_circles` (CCC Apollonius) solver
# just above.
# -------------------------------------------------------------------------

# The tangency point of two tangent circles, valid for both external and
# internal tangency — but only when called with the *larger* circle first
# (for internal tangency, going from the smaller circle's center towards
# the bigger one lands short of the actual touching point).
function _tangency_point(A::EGCircle2, B::EGCircle2)
    d = distance(A.center, B.center)
    return A.r >= B.r ? A.center + (A.r / d) * (B.center - A.center) : B.center + (B.r / d) * (A.center - B.center)
end

# Does circle `s` properly contain (and touch internally) circle `c`? Used
# to tell apart the two kinds of `tangent_circles(c1, c2, c3)` solutions:
# a genuine interstice-filling circle never encloses any of the three
# given circles, while the "outer Soddy"-type solution (relevant only when
# c1, c2, c3 are an externally-tangent chain) encloses all three.
function _encloses(s::EGCircle2, c::EGCircle2; atol=1e-9)
    s.r <= c.r && return false
    return abs(distance(s.center, c.center) - (s.r - c.r)) <= sqrt(atol) * max(s.r, c.r, 1.0)
end

# The arc of `circle` between `p1` and `p2` that faces `seed` (a point
# known to be strictly inside the interstice, e.g. the center of its
# inscribed tangent circle) — i.e. whichever of the two candidate arcs'
# counterclockwise sweep passes through `seed`'s angular direction.
function _facing_arc(circle::EGCircle2, p1::EGPoint, p2::EGPoint, seed::EGPoint)
    a1 = atan(p1[2] - circle.center[2], p1[1] - circle.center[1])
    a2 = atan(p2[2] - circle.center[2], p2[1] - circle.center[1])
    aseed = atan(seed[2] - circle.center[2], seed[1] - circle.center[1])
    ccw_contains = 0 < mod(aseed - a1, 2π) < mod(a2 - a1, 2π)
    return ccw_contains ? EGCircularArc2(circle, p1, p2) : EGCircularArc2(circle, p2, p1)
end

function _build_interstice(c1::EGCircle2, c2::EGCircle2, c3::EGCircle2, seed::EGPoint)
    circles = (c1, c2, c3)
    others = ((2, 3), (1, 3), (1, 2))
    arcs = ntuple(3) do i
        ci = circles[i]
        j, k = others[i]
        _facing_arc(ci, _tangency_point(ci, circles[j]), _tangency_point(ci, circles[k]), seed)
    end
    return EGInterstice2(arcs[1], arcs[2], arcs[3])
end

"""
    interstices(c1::EGCircle2, c2::EGCircle2, c3::EGCircle2; atol=1e-9)

The curvilinear-triangle gap(s) of three mutually tangent circles, as a
`Vector{EGInterstice2}` — length `1` when the three are an externally
tangent chain (none contains another), or `2` when one contains the other
two (each internally tangent to it, and externally tangent to each
other). Independent of the order `c1`, `c2`, `c3` are given in.

Built by reusing [`tangent_circles`](@ref) (the `CCC` Apollonius problem):
every genuine interstice has an inscribed circle tangent to all three
(never enclosing any of them), and each such solution's center pins down
exactly one interstice. Throws an `ArgumentError` if the three circles
aren't all pairwise tangent.
"""
function interstices(c1::EGCircle2, c2::EGCircle2, c3::EGCircle2; atol=1e-9)
    scale = max(c1.r, c2.r, c3.r, 1.0)
    for (a, b) in ((c1, c2), (c1, c3), (c2, c3))
        _tangent_ok(a, b; atol=atol, scale=scale) ||
            throw(ArgumentError("interstices: c1, c2 and c3 must be pairwise tangent"))
    end
    seeds = filter(s -> !_encloses(s, c1; atol=atol) && !_encloses(s, c2; atol=atol) && !_encloses(s, c3; atol=atol),
        tangent_circles(c1, c2, c3; atol=atol))
    isempty(seeds) &&
        error("interstices: found no interstice-filling circle — is this a genuine mutually tangent triple?")
    return [_build_interstice(c1, c2, c3, s.center) for s in seeds]
end
