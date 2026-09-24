"""
    tangent_circles(a::APPoint, b::APPoint, l::APLine; atol=1e-9)

Circle(s) passing through `a` and `b` and tangent to line `l`. Returns a
`Vector{APCircle2{Float64}}` with 0, 1 or 2 solutions.
"""
function tangent_circles(a::APPoint, b::APPoint, l::APLine; atol=1e-9)
    m = midpoint(a, b)
    d = orthogonal(b - a)
    ld = direction(l)
    dn = norm(ld)
    dn <= atol && return APCircle2{Float64}[]
    s0 = cross2(ld, m - l.p1) / dn
    s1 = cross2(ld, d) / dn
    A0, A1, A2 = dot(m - a, m - a), 2 * dot(d, m - a), dot(d, d)
    ts = _solve_quadratic(s1^2 - A2, 2s0 * s1 - A1, s0^2 - A0; atol=atol)
    circles = APCircle2{Float64}[]
    for t in ts
        o = m + t * d
        r = distance(o, a)
        sol = APCircle2(APPoint(o[1], o[2]), Float64(r))
        _tangent_ok(sol, l; atol=atol, scale=max(r, 1.0)) && push!(circles, sol)
    end
    return circles
end
tangent_circles(l::APLine, a::APPoint, b::APPoint; atol=1e-9) =
    tangent_circles(a, b, l; atol=atol)
"""
    tangent_circles(a::APPoint, b::APPoint, c::APCircle2; atol=1e-9)

Circle(s) passing through `a` and `b` and tangent (internally or
externally) to circle `c`. Returns a `Vector{APCircle2{Float64}}` with 0,
1 or 2 solutions.
"""
function tangent_circles(a::APPoint, b::APPoint, c::APCircle2; atol=1e-9)
    m = midpoint(a, b)
    d = orthogonal(b - a)
    Cc, R = c.center, c.r
    A0, A1, A2 = dot(m - a, m - a), 2 * dot(d, m - a), dot(d, d)
    C0, C1 = dot(m - Cc, m - Cc), 2 * dot(d, m - Cc)
    g0, g1 = (C0 - A0) - R^2, C1 - A1
    ts = _solve_quadratic(g1^2 - 4R^2 * A2, 2g0 * g1 - 4R^2 * A1, g0^2 - 4R^2 * A0; atol=atol)
    circles = APCircle2{Float64}[]
    for t in ts
        o = m + t * d
        r = distance(o, a)
        sol = APCircle2(APPoint(o[1], o[2]), Float64(r))
        _tangent_ok(sol, c; atol=atol, scale=max(r, R, 1.0)) && push!(circles, sol)
    end
    return circles
end
tangent_circles(c::APCircle2, a::APPoint, b::APPoint; atol=1e-9) =
    tangent_circles(a, b, c; atol=atol)
"""
    tangent_circles(l1::APLine, l2::APLine, p::APPoint; atol=1e-9)

Circle(s) tangent to both `l1` and `l2`, passing through `p`. Returns a
`Vector{APCircle2{Float64}}` with up to 4 solutions (2 per bisector).
"""
function tangent_circles(l1::APLine, l2::APLine, p::APPoint; atol=1e-9)
    circles = APCircle2{Float64}[]
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
            sol = APCircle2(APPoint(o[1], o[2]), Float64(r))
            scale = max(r, 1.0)
            _tangent_ok(sol, l1; atol=atol, scale=scale) && _tangent_ok(sol, l2; atol=atol, scale=scale) &&
                push!(circles, sol)
        end
    end
    return circles
end
function _tangent_circles_through_point_via_inversion(obj1, obj2, p::APPoint; atol=1e-9)
    i1 = invert(obj1, p; atol=atol)
    i2 = invert(obj2, p; atol=atol)
    tls = vcat(external_tangent_lines(i1, i2; atol=atol), internal_tangent_lines(i1, i2; atol=atol))
    circles = APCircle2{Float64}[]
    for tl in tls
        is_on_line(p, tl; atol=atol) && continue
        sol = invert(tl, p; atol=atol)
        scale = max(sol.r, 1.0)
        _tangent_ok(sol, obj1; atol=atol, scale=scale) && _tangent_ok(sol, obj2; atol=atol, scale=scale) &&
            push!(circles, APCircle2(APPoint(sol.center[1], sol.center[2]), Float64(sol.r)))
    end
    return circles
end
_tangent_ok(sol::APCircle2, l::APLine; atol=1e-9, scale=1.0) = abs(distance(sol.center, l) - sol.r) <= sqrt(atol) * scale
function _tangent_ok(sol::APCircle2, c::APCircle2; atol=1e-9, scale=1.0)
    d = distance(sol.center, c.center)
    tol = sqrt(atol) * max(scale, c.r)
    abs(d - (c.r + sol.r)) <= tol || abs(d - abs(c.r - sol.r)) <= tol
end
"""
    tangent_circles(c1::APCircle2, c2::APCircle2, p::APPoint; atol=1e-9)
    tangent_circles(l::APLine, c::APCircle2, p::APPoint; atol=1e-9)

Circle(s) tangent to `c1`/`c2` (or to `l`/`c`), passing through `p`: the
`CCP`/`CLP` Apollonius cases, solved by inverting about `p`. `p` must not
lie on `c1`/`c2` (or `l`/`c`). Returns a `Vector{APCircle2{Float64}}`
with up to 4 solutions.
"""
tangent_circles(c1::APCircle2, c2::APCircle2, p::APPoint; atol=1e-9) =
    _tangent_circles_through_point_via_inversion(c1, c2, p; atol=atol)
tangent_circles(l::APLine, c::APCircle2, p::APPoint; atol=1e-9) =
    _tangent_circles_through_point_via_inversion(l, c, p; atol=atol)
tangent_circles(c::APCircle2, l::APLine, p::APPoint; atol=1e-9) =
    tangent_circles(l, c, p; atol=atol)
_line_coeffs(l::APLine) = begin
    d = direction(l) / norm(direction(l))
    (-d[2], d[1], d[2] * l.p1[1] - d[1] * l.p1[2])
end
function _push_valid!(circles, ox0, ox1, oy0, oy1, target_center::APPoint, target_r, eps3, others...; atol=1e-9)
    px, py = ox0 - target_center[1], oy0 - target_center[2]
    qa = ox1^2 + oy1^2 - 1
    qb = 2 * (px * ox1 + py * oy1) - 2 * eps3 * target_r
    qc = px^2 + py^2 - target_r^2
    for r in _solve_quadratic(qa, qb, qc; atol=atol)
        r <= atol && continue
        o = APPoint(ox0 + ox1 * r, oy0 + oy1 * r)
        sol = APCircle2(o, r)
        scale = max(r, 1.0)
        all(obj -> _tangent_ok(sol, obj; atol=atol, scale=scale), others) || continue
        push!(circles, APCircle2(APPoint(o[1], o[2]), Float64(r)))
    end
end
"""
    tangent_circles(l1::APLine, l2::APLine, c::APCircle2; atol=1e-9)

Circle(s) tangent to `l1`, `l2` and `c` (the `CLL` Apollonius case).
`l1` and `l2` must not be parallel. Returns a `Vector{APCircle2{Float64}}`
with up to 4 solutions.
"""
function tangent_circles(l1::APLine, l2::APLine, c::APCircle2; atol=1e-9)
    A1, B1, K1 = _line_coeffs(l1)
    A2, B2, K2 = _line_coeffs(l2)
    det = A1 * B2 - A2 * B1
    circles = APCircle2{Float64}[]
    abs(det) <= atol && return circles
    for δ1 in (1, -1), δ2 in (1, -1), ε in (1, -1)
        ox0, ox1 = (-K1 * B2 + K2 * B1) / det, (δ1 * B2 - δ2 * B1) / det
        oy0, oy1 = (A1 * (-K2) - A2 * (-K1)) / det, (A1 * δ2 - A2 * δ1) / det
        _push_valid!(circles, ox0, ox1, oy0, oy1, c.center, c.r, ε, l1, l2, c; atol=atol)
    end
    return _exclude_given(_dedupe_circles(circles; atol=atol), c; atol=atol)
end
tangent_circles(c::APCircle2, l1::APLine, l2::APLine; atol=1e-9) = tangent_circles(l1, l2, c; atol=atol)
"""
    tangent_circles(c1::APCircle2, c2::APCircle2, l::APLine; atol=1e-9)

Circle(s) tangent to `c1`, `c2` and `l` (the `CCL` Apollonius case).
Returns a `Vector{APCircle2{Float64}}` with up to 8 solutions.
"""
function tangent_circles(c1::APCircle2, c2::APCircle2, l::APLine; atol=1e-9)
    Cc1, R1 = c1.center, c1.r
    Cc2, R2 = c2.center, c2.r
    A, B, K = _line_coeffs(l)
    P, Q = 2 * (Cc2[1] - Cc1[1]), 2 * (Cc2[2] - Cc1[2])
    M = (R1^2 - R2^2) - (dot(Cc1, Cc1) - dot(Cc2, Cc2))
    circles = APCircle2{Float64}[]
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
tangent_circles(l::APLine, c1::APCircle2, c2::APCircle2; atol=1e-9) = tangent_circles(c1, c2, l; atol=atol)
"""
    tangent_circles(c1::APCircle2, c2::APCircle2, c3::APCircle2; atol=1e-9)

Circle(s) tangent to `c1`, `c2` and `c3`: the classical Apollonius
problem. Returns a `Vector{APCircle2{Float64}}` with up to 8 solutions.
"""
function tangent_circles(c1::APCircle2, c2::APCircle2, c3::APCircle2; atol=1e-9)
    # solve relative to c3's center, so the result does not degrade far from the origin
    o = c3.center
    local_circle(c) = APCircle2(APPoint(zero(o[1]), zero(o[2])) + (c.center - o), c.r)
    sols = _tangent_circles_ccc(local_circle(c1), local_circle(c2), local_circle(c3); atol=atol)
    # a radius a million times the size of the problem is a line in disguise, produced by rounding
    size = max(c1.r, c2.r, c3.r, distance(c1.center, c3.center), distance(c2.center, c3.center))
    filter!(s -> s.r <= 1e6 * size, sols)
    return [APCircle2(s.center + APVector(o[1], o[2]), s.r) for s in sols]
end
function _tangent_circles_ccc(c1::APCircle2, c2::APCircle2, c3::APCircle2; atol=1e-9)
    Cc1, R1 = c1.center, c1.r
    Cc2, R2 = c2.center, c2.r
    Cc3, R3 = c3.center, c3.r
    circles = APCircle2{Float64}[]
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
function _tangency_point(A::APCircle2, B::APCircle2)
    d = distance(A.center, B.center)
    return A.r >= B.r ? A.center + (A.r / d) * (B.center - A.center) : B.center + (B.r / d) * (A.center - B.center)
end
function _encloses(s::APCircle2, c::APCircle2; atol=1e-9)
    s.r <= c.r && return false
    return abs(distance(s.center, c.center) - (s.r - c.r)) <= sqrt(atol) * max(s.r, c.r, 1.0)
end
function _facing_arc(circle::APCircle2, p1::APPoint, p2::APPoint, seed::APPoint)
    a1 = atan(p1[2] - circle.center[2], p1[1] - circle.center[1])
    a2 = atan(p2[2] - circle.center[2], p2[1] - circle.center[1])
    aseed = atan(seed[2] - circle.center[2], seed[1] - circle.center[1])
    ccw_contains = 0 < mod(aseed - a1, 2π) < mod(a2 - a1, 2π)
    return ccw_contains ? APCircularArc2(circle, p1, p2) : APCircularArc2(circle, p2, p1)
end
function _build_interstice(c1::APCircle2, c2::APCircle2, c3::APCircle2, seed::APPoint)
    circles = (c1, c2, c3)
    others = ((2, 3), (1, 3), (1, 2))
    arcs = ntuple(3) do i
        ci = circles[i]
        j, k = others[i]
        _facing_arc(ci, _tangency_point(ci, circles[j]), _tangency_point(ci, circles[k]), seed)
    end
    return APInterstice2(arcs[1], arcs[2], arcs[3])
end
"""
    interstices(c1::APCircle2, c2::APCircle2, c3::APCircle2; atol=1e-9)

The curvilinear-triangle gap(s) of three mutually tangent circles, as a
`Vector{APInterstice2}`: length `1` when the three are an externally
tangent chain (none contains another), or `2` when one contains the other
two (each internally tangent to it, and externally tangent to each
other). Independent of the order `c1`, `c2`, `c3` are given in.

Built by reusing [`tangent_circles`](@ref) (the `CCC` Apollonius problem):
every genuine interstice has an inscribed circle tangent to all three
(never enclosing any of them), and each such solution's center pins down
exactly one interstice. Throws an `ArgumentError` if the three circles
aren't all pairwise tangent.
"""
function interstices(c1::APCircle2, c2::APCircle2, c3::APCircle2; atol=1e-9)
    scale = max(c1.r, c2.r, c3.r, 1.0)
    for (a, b) in ((c1, c2), (c1, c3), (c2, c3))
        _tangent_ok(a, b; atol=atol, scale=scale) ||
            throw(ArgumentError("interstices: c1, c2 and c3 must be pairwise tangent"))
    end
    seeds = filter(s -> !_encloses(s, c1; atol=atol) && !_encloses(s, c2; atol=atol) && !_encloses(s, c3; atol=atol),
        tangent_circles(c1, c2, c3; atol=atol))
    isempty(seeds) &&
        error("interstices: found no interstice-filling circle: is this a genuine mutually tangent triple?")
    return [_build_interstice(c1, c2, c3, s.center) for s in seeds]
end
