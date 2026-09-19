function _implicit_from_local(origin::APPoint, u::APVector, w::APVector, Al::Real, Bl::Real, Cl::Real, Dl::Real, El::Real, Fl::Real)
    ox, oy = origin[1], origin[2]
    ux, uy = u[1], u[2]
    wx, wy = w[1], w[2]
    p1, p2, p0 = ux, uy, -(ux * ox + uy * oy)
    q1, q2, q0 = wx, wy, -(wx * ox + wy * oy)
    A = Al * p1^2 + Bl * p1 * q1 + Cl * q1^2
    B = Al * 2p1 * p2 + Bl * (p1 * q2 + p2 * q1) + Cl * 2q1 * q2
    C = Al * p2^2 + Bl * p2 * q2 + Cl * q2^2
    D = Al * 2p1 * p0 + Bl * (p1 * q0 + p0 * q1) + Cl * 2q1 * q0 + Dl * p1 + El * q1
    E = Al * 2p2 * p0 + Bl * (p2 * q0 + p0 * q2) + Cl * 2q2 * q0 + Dl * p2 + El * q2
    F = Al * p0^2 + Bl * p0 * q0 + Cl * q0^2 + Dl * p0 + El * q0 + Fl
    return (A, B, C, D, E, F)
end
_implicit_form(c::APCircle2) = _implicit_from_local(c.center, APVector(1.0, 0.0), APVector(0.0, 1.0), 1.0, 0.0, 1.0, 0.0, 0.0, -c.r^2)
function _implicit_form(e::APEllipse2)
    ca, sa = cos(e.angle), sin(e.angle)
    return _implicit_from_local(e.center, APVector(ca, sa), APVector(-sa, ca), 1 / e.a^2, 0.0, 1 / e.b^2, 0.0, 0.0, -1.0)
end
function _implicit_form(h::APHyperbola2)
    ca, sa = cos(h.angle), sin(h.angle)
    return _implicit_from_local(h.center, APVector(ca, sa), APVector(-sa, ca), 1 / h.a^2, 0.0, -1 / h.b^2, 0.0, 0.0, -1.0)
end
function _implicit_form(par::APParabola2)
    V, u, w = _parabola_frame(par)
    p = focal_parameter(par)
    return _implicit_from_local(V, u, w, 0.0, 0.0, 1.0, -2p, 0.0, 0.0)
end
_conic_center(c::APCircle2) = c.center
_conic_center(e::APEllipse2) = e.center
_conic_center(h::APHyperbola2) = h.center
_conic_center(par::APParabola2) = par.focus
_conic_scale(c::APCircle2) = c.r
_conic_scale(e::APEllipse2) = max(e.a, e.b)
_conic_scale(h::APHyperbola2) = max(h.a, h.b)
_conic_scale(par::APParabola2) = max(focal_parameter(par), 1.0)
function _resultant_at_y(y::Real, A1, B1, C1, D1, E1, F1, A2, B2, C2, D2, E2, F2)
    a1, b1, c1 = A1, B1 * y + D1, C1 * y^2 + E1 * y + F1
    a2, b2, c2 = A2, B2 * y + D2, C2 * y^2 + E2 * y + F2
    return (a1 * c2 - a2 * c1)^2 - (a1 * b2 - a2 * b1) * (b1 * c2 - b2 * c1)
end
function _real_roots_poly(coeffs::Vector{Float64}; atol=1e-9)
    n = length(coeffs) - 1
    tol = atol * max(maximum(abs, coeffs; init=1.0), 1.0)
    while n > 0 && abs(coeffs[n+1]) <= tol
        n -= 1
    end
    n <= 0 && return Float64[]
    n == 1 && return [-coeffs[1] / coeffs[2]]
    n == 2 && return _solve_quadratic(coeffs[3], coeffs[2], coeffs[1]; atol=atol)
    mono = coeffs[1:n] ./ coeffs[n+1]
    M = zeros(n, n)
    for i in 1:n
        M[1, i] = -mono[n+1-i]
    end
    for i in 2:n
        M[i, i-1] = 1.0
    end
    return [real(z) for z in eigvals(M) if abs(imag(z)) <= 1e-4 * max(abs(real(z)), 1.0)]
end
function _dedupe_points(pts::Vector{APPoint{2,Float64}}; atol=1e-9)
    out = APPoint{2,Float64}[]
    for p in pts
        any(o -> isapprox(o, p; atol=sqrt(atol)), out) || push!(out, p)
    end
    return out
end
"""
    intersection(c1::APConic2, c2::APConic2; atol=1e-9)

The intersection points of two conics, up to 4 real points (Bézout's
theorem for two degree-2 curves): covers every pair *except* two
circles, which already has its own direct method
([`intersection`](@ref)`(::APCircle2, ::APCircle2)`, picked automatically
since it's more specific).

Built via the classical elimination method: write each conic as a general
quadratic `Ax² + Bxy + Cy² + Dx + Ey + F = 0` (found once per type via a
rotation/translation of the conic's own local equation into the ambient
frame). Eliminating `x` between the two
equations gives their Sylvester resultant, a polynomial in `y` of degree
at most 4: found here by evaluating it at 5 points and fitting the
quartic through them (exact in principle, since the resultant *is* a
polynomial of that degree; far less error-prone than expanding it
symbolically) and solving via a companion-matrix eigendecomposition. Each
real root `y` is substituted back to solve for `x` as a quadratic
([`_solve_quadratic`](@ref)), and every `(x, y)` candidate is checked
against *both* original equations (and against a generous, geometry-based
distance bound from the two conics) before being kept, which is what
makes this robust to the numerical instability the companion-matrix
approach has right at a repeated root (a tangency, or the doubled root a
symmetric configuration like two concentric axis-aligned conics
produces).

The whole computation runs in coordinates shifted so `c1`'s own center
sits at the origin, then shifts the results back. Without this, the
implicit coefficients (built from the conics' *absolute* position) grow
with the distance from the global origin, and the elimination step
squares them, so two conics far from `(0, 0)` (coordinates in the tens of
thousands or beyond) lost enough precision to return points that don't
actually lie on either curve.
"""
function intersection(c1::APConic2, c2::APConic2; atol=1e-9)
    shift = APVector(_conic_center(c1)[1], _conic_center(c1)[2])
    c1s, c2s = translate(c1, -shift), translate(c2, -shift)
    coeffs1, coeffs2 = _implicit_form(c1s), _implicit_form(c2s)
    A1, B1, C1, D1, E1, F1 = coeffs1
    A2, B2, C2, D2, E2, F2 = coeffs2
    y0 = (_conic_center(c1s)[2] + _conic_center(c2s)[2]) / 2
    yscale = max(_conic_scale(c1s) + _conic_scale(c2s), sqrt(atol))
    ys = y0 .+ yscale .* (-2.0:1.0:2.0)
    resvals = [_resultant_at_y(y, coeffs1..., coeffs2...) for y in ys]
    V = [(y - y0)^k for y in ys, k in 0:4]
    yroots = y0 .+ _real_roots_poly(collect(V \ resvals); atol=atol)
    pts = APPoint{2,Float64}[]
    for y in yroots
        a1, b1, cc1 = A1, B1 * y + D1, C1 * y^2 + E1 * y + F1
        a2, b2, cc2 = A2, B2 * y + D2, C2 * y^2 + E2 * y + F2
        for x in _solve_quadratic(a1, b1, cc1; atol=atol)
            r2 = a2 * x^2 + b2 * x + cc2
            abs(r2) <= sqrt(atol) * max(abs(a2), abs(b2), abs(cc2), 1.0) && push!(pts, APPoint(x, y))
        end
    end
    sanity_center = midpoint(_conic_center(c1s), _conic_center(c2s))
    sanity_radius = 200 * (_conic_scale(c1s) + _conic_scale(c2s)) + distance(_conic_center(c1s), _conic_center(c2s))
    pts = filter(p -> distance(p, sanity_center) <= sanity_radius, pts)
    return translate.(_dedupe_points(pts; atol=atol), shift)
end
"""
    intersection(c::APConic2, arc::APConicArc2; atol=1e-9)
    intersection(arc::APConicArc2, c::APConic2; atol=1e-9)

Intersection of a full conic with an arc cut from *any* conic, not just a
matching type (e.g. an elliptic arc against a circle): intersect the two
full underlying conics ([`intersection`](@ref)`(::APConic2, ::APConic2)`),
then keep only the points within the arc's own sweep. Picked automatically
over this method whenever a more specific one exists (e.g.
[`intersection`](@ref)`(::APCircle2, ::APCircularArc2)`).
"""
intersection(c::APConic2, arc::APConicArc2; atol=1e-9) = filter(p -> in(p, arc; atol=atol), intersection(c, _conic(arc); atol=atol))
intersection(arc::APConicArc2, c::APConic2; atol=1e-9) = intersection(c, arc; atol=atol)
"""
    intersection(a1::APConicArc2, a2::APConicArc2; atol=1e-9)

Intersection of two arcs cut from any conics, same type or not: intersect
the two full underlying conics, then keep only the points within *both*
arcs' own sweeps.
"""
function intersection(a1::APConicArc2, a2::APConicArc2; atol=1e-9)
    return filter(p -> in(p, a1; atol=atol) && in(p, a2; atol=atol), intersection(_conic(a1), _conic(a2); atol=atol))
end
