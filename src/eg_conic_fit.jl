# -------------------------------------------------------------------------
# Fitting an EGEllipse2/EGHyperbola2 through five points.
# -------------------------------------------------------------------------

"""
    conic_through_points(p1::EGPoint, p2::EGPoint, p3::EGPoint, p4::EGPoint, p5::EGPoint; atol=1e-9)

The ellipse or hyperbola (as an `EGEllipse2` or `EGHyperbola2`) passing
through the 5 given points, assumed to be in general position. Throws an
`ArgumentError` if the points don't determine a unique conic (a degenerate
configuration), or if that conic is a parabola (discriminant ≈ 0), which
isn't representable by this function.
"""
function conic_through_points(p1::EGPoint, p2::EGPoint, p3::EGPoint, p4::EGPoint, p5::EGPoint; atol=1e-9)
    pts = (p1, p2, p3, p4, p5)
    centroid = sum(pts) / 5
    scale = max(sum(distance(p, centroid) for p in pts) / 5, 1.0)

    M = zeros(Float64, 5, 6)
    for (i, p) in enumerate(pts)
        x, y = (Float64(p[1]) - centroid[1]) / scale, (Float64(p[2]) - centroid[2]) / scale
        M[i, :] = [x^2, x * y, y^2, x, y, 1.0]
    end
    ns = nullspace(M)
    size(ns, 2) != 1 && throw(ArgumentError(
        "conic_through_points: the 5 points don't determine a unique conic (degenerate configuration)"))
    A, B, C, D, E, F = ns[:, 1]

    disc = B^2 - 4A * C
    abs(disc) <= atol && throw(ArgumentError(
        "conic_through_points: the points lie on (or near) a parabola, which this function can't return"))

    x0, y0 = [2A B; B 2C] \ [-D, -E]
    center = centroid + scale * EGPoint(x0, y0)
    F0 = A * x0^2 + B * x0 * y0 + C * y0^2 + D * x0 + E * y0 + F

    lam1 = (A + C + sqrt((A - C)^2 + B^2)) / 2
    lam2 = (A + C - sqrt((A - C)^2 + B^2)) / 2
    theta = atan(B, A - C) / 2
    s1, s2 = -F0 / lam1, -F0 / lam2

    if disc < 0
        (s1 <= atol || s2 <= atol) && throw(ArgumentError("conic_through_points: no real ellipse fits these points"))
        return EGEllipse2(center, scale * sqrt(s1), scale * sqrt(s2), theta)
    else
        if s1 > 0 && s2 < 0
            return EGHyperbola2(center, scale * sqrt(s1), scale * sqrt(-s2), theta)
        elseif s2 > 0 && s1 < 0
            return EGHyperbola2(center, scale * sqrt(s2), scale * sqrt(-s1), theta + pi / 2)
        else
            throw(ArgumentError("conic_through_points: no real hyperbola fits these points"))
        end
    end
end
