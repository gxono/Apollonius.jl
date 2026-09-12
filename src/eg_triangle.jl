# -------------------------------------------------------------------------
# Every named triangle center, axis, circle, derived triangle and
# inellipse/circumellipse/hyperbola/parabola.
# -------------------------------------------------------------------------

# Side lengths (a = |BC|, b = |CA|, c = |AB|), the standard triangle-center
# building block, computed once instead of re-derived at each call site.
_side_lengths(t::EGTriangle) = (distance(t[2], t[3]), distance(t[1], t[3]), distance(t[1], t[2]))

"""
    altitude(t::EGTriangle, i)

The altitude line from vertex `t[i]`, perpendicular to the opposite side.
"""
function altitude(t::EGTriangle, i::Integer)
    j, k = _other_two(i)
    return perpendicular_through(EGLine(t[j], t[k]), t[i])
end

"""
    median(t::EGTriangle, i)

The median line from vertex `t[i]` to the midpoint of the opposite side.
"""
function median(t::EGTriangle, i::Integer)
    j, k = _other_two(i)
    return EGLine(t[i], midpoint(t[j], t[k]))
end

"""
    bisector(t::EGTriangle, i)

The internal angle bisector line from vertex `t[i]` (passes through the
[`incenter`](@ref)).
"""
function bisector(t::EGTriangle, i::Integer)
    j, k = _other_two(i)
    u = normalize(t[j] - t[i])
    v = normalize(t[k] - t[i])
    return EGLine(t[i], t[i] + (u + v))
end

"""
    bisector_ext(t::EGTriangle, i)

The external angle bisector line from vertex `t[i]`, perpendicular to the
internal one ([`bisector`](@ref)) at that same vertex.
"""
bisector_ext(t::EGTriangle, i::Integer) = perpendicular_through(bisector(t, i), t[i])

"""
    mediator(t::EGTriangle, i)

The perpendicular bisector of the side opposite vertex `t[i]` (passes
through the [`circumcenter`](@ref)).
"""
function mediator(t::EGTriangle, i::Integer)
    j, k = _other_two(i)
    return perpendicular_bisector(t[j], t[k])
end

"""
    trisector(t::EGTriangle, i)

The two rays from vertex `t[i]` trisecting the interior angle there into
three equal parts (see [`angle_trisectors`](@ref); this is the
construction behind the [`morley_triangle`](@ref)).
"""
function trisector(t::EGTriangle, i::Integer)
    j, k = _other_two(i)
    return angle_trisectors(t[i], t[j], t[k])
end

"""
    circumcenter(t::EGTriangle)

Center of the circle passing through the three vertices of `t`.
"""
function circumcenter(t::EGTriangle)
    a, b, c = t[1], t[2], t[3]
    ax, ay = a[1], a[2]
    bx, by = b[1], b[2]
    cx, cy = c[1], c[2]

    d = 2 * (ax * (by - cy) + bx * (cy - ay) + cx * (ay - by))
    a2, b2, c2 = ax^2 + ay^2, bx^2 + by^2, cx^2 + cy^2

    ux = (a2 * (by - cy) + b2 * (cy - ay) + c2 * (ay - by)) / d
    uy = (a2 * (cx - bx) + b2 * (ax - cx) + c2 * (bx - ax)) / d
    return EGPoint(ux, uy)
end

"""
    circumradius(t::EGTriangle)

Radius of the circumscribed circle of `t`.
"""
circumradius(t::EGTriangle) = distance(circumcenter(t), t[1])

"""
    circumcircle(t::EGTriangle)

The circumscribed circle of `t`.
"""
circumcircle(t::EGTriangle) = EGCircle2(circumcenter(t), circumradius(t))

"""
    incenter(t::EGTriangle)

Center of the circle inscribed in `t`.
"""
function incenter(t::EGTriangle)
    a, b, c = t[1], t[2], t[3]
    la, lb, lc = distance(b, c), distance(a, c), distance(a, b)
    return (la * a + lb * b + lc * c) / (la + lb + lc)
end

"""
    inradius(t::EGTriangle)

Radius of the inscribed circle of `t`.
"""
inradius(t::EGTriangle) = 2 * area(t) / perimeter(t)

"""
    incircle(t::EGTriangle)

The inscribed circle of `t`.
"""
incircle(t::EGTriangle) = EGCircle2(incenter(t), inradius(t))

"""
    orthocenter(t::EGTriangle)

Intersection point of the three altitudes of `t`, obtained from the Euler
line relation `H = 3G - 2O`.
"""
orthocenter(t::EGTriangle) = 3 * centroid(t) - 2 * circumcenter(t)

"""
    excenters(t::EGTriangle)

The three excenters of `t`, as a `(A=..., B=..., C=...)` named tuple where
`A` is the excenter opposite vertex `t[1]`, etc.
"""
function excenters(t::EGTriangle)
    A, B, C = t[1], t[2], t[3]
    a, b, c = _side_lengths(t)
    return (A=(-a * A + b * B + c * C) / (-a + b + c),
        B=(a * A - b * B + c * C) / (a - b + c),
        C=(a * A + b * B - c * C) / (a + b - c))
end

"""
    exradii(t::EGTriangle)

The three exradii of `t`, as a `(A=..., B=..., C=...)` named tuple where
`A` is the radius of the excircle opposite vertex `t[1]`, etc.
"""
function exradii(t::EGTriangle)
    a, b, c = _side_lengths(t)
    s = (a + b + c) / 2
    K = area(t)
    return (A=K / (s - a), B=K / (s - b), C=K / (s - c))
end

"""
    excircles(t::EGTriangle)

The three excircles of `t`, as a `(A=..., B=..., C=...)` named tuple (see
[`excenters`](@ref) and [`exradii`](@ref)).
"""
function excircles(t::EGTriangle)
    ec, er = excenters(t), exradii(t)
    return (A=EGCircle2(ec.A, er.A), B=EGCircle2(ec.B, er.B), C=EGCircle2(ec.C, er.C))
end

"""
    euler_line(t::EGTriangle)

The Euler line of `t`, through its centroid, circumcenter and orthocenter.
"""
euler_line(t::EGTriangle) = EGLine(circumcenter(t), centroid(t))

"""
    nine_point_center(t::EGTriangle)

Center of the nine-point (Euler) circle of `t`: the midpoint of the segment
joining the circumcenter and the orthocenter.
"""
nine_point_center(t::EGTriangle) = midpoint(circumcenter(t), orthocenter(t))

"""
    nine_point_circle(t::EGTriangle)

The nine-point (Euler) circle of `t`, passing through the midpoints of the
three sides, the feet of the three altitudes, and the midpoints of the
segments from the orthocenter to each vertex. Its radius is half the
circumradius.
"""
nine_point_circle(t::EGTriangle) = EGCircle2(nine_point_center(t), circumradius(t) / 2)

"""
    euler_points(t::EGTriangle)

The three Euler points of `t`, as a 3-tuple: the midpoints of the segments
joining the orthocenter to each vertex. Together with the three edge
midpoints and the three altitude feet, these are the nine defining points
of the [`nine_point_circle`](@ref).
"""
function euler_points(t::EGTriangle)
    H = orthocenter(t)
    return (midpoint(H, t[1]), midpoint(H, t[2]), midpoint(H, t[3]))
end

"""
    orthic_axis(t::EGTriangle)

The orthic axis of `t`: the radical axis of its circumcircle and
[`nine_point_circle`](@ref). Always perpendicular to the [`euler_line`](@ref).
"""
orthic_axis(t::EGTriangle) = radical_axis(circumcircle(t), nine_point_circle(t))

"""
    brocard_axis(t::EGTriangle)

The Brocard axis of `t`: the line through the circumcenter and the
symmedian (Lemoine) point.
"""
brocard_axis(t::EGTriangle) = EGLine(circumcenter(t), symmedian_point(t))

"""
    lemoine_axis(t::EGTriangle)

The Lemoine axis of `t`: the polar line of the symmedian point with
respect to the circumcircle.
"""
lemoine_axis(t::EGTriangle) = polar_line(circumcircle(t), symmedian_point(t))

"""
    steiner_line(t::EGTriangle, p::EGPoint)

The Steiner line of `p` with respect to `t`: the line through the
reflections of `p` across the three side-lines of `t`. These reflections
are only guaranteed to be collinear (and the line only guaranteed to pass
through the orthocenter) when `p` lies on the circumcircle of `t` — compare
[`simson_line`](@ref), whose feet of perpendiculars are the midpoints of
`p` and each of these reflections.
"""
function steiner_line(t::EGTriangle, p::EGPoint)
    r1 = reflection(p, EGLine(t[1], t[2]))
    r2 = reflection(p, EGLine(t[2], t[3]))
    return EGLine(r1, r2)
end

"""
    barycentric_point(t::EGTriangle, wA, wB, wC)

The point with barycentric coordinates `(wA, wB, wC)` relative to `t`
(the weights need not be normalized).
"""
barycentric_point(t::EGTriangle, wA::Real, wB::Real, wC::Real) =
    (wA * t[1] + wB * t[2] + wC * t[3]) / (wA + wB + wC)

"""
    barycentric_coordinates(t::EGTriangle, p::EGPoint)

The normalized barycentric coordinates `(α, β, γ)` (summing to `1`) of `p`
relative to `t`, computed from signed sub-triangle areas.
"""
function barycentric_coordinates(t::EGTriangle, p::EGPoint)
    A, B, C = t[1], t[2], t[3]
    total = cross2(B - A, C - A)
    α = cross2(B - p, C - p) / total
    β = cross2(C - p, A - p) / total
    γ = cross2(A - p, B - p) / total
    return (α, β, γ)
end

"""
    trilinear_point(t::EGTriangle, x, y, z)

The point with trilinear coordinates `(x:y:z)` relative to `t` (the values
need not be normalized — trilinear coordinates are only meaningful up to a
common scale factor, unlike the actual distances [`trilinear_coordinates`](@ref)
returns). Converts to barycentric via `(a*x : b*y : c*z)`, `a`/`b`/`c`
being the side lengths opposite `t[1]`/`t[2]`/`t[3]`.
"""
function trilinear_point(t::EGTriangle, x::Real, y::Real, z::Real)
    a, b, c = _side_lengths(t)
    return barycentric_point(t, a * x, b * y, c * z)
end

"""
    trilinear_coordinates(t::EGTriangle, p::EGPoint)

The trilinear coordinates of `p` relative to `t`: the actual signed
perpendicular distances `(x, y, z)` from `p` to sides `a = [t[2],t[3]]`,
`b = [t[3],t[1]]`, `c = [t[1],t[2]]` (positive on the same side as the
opposite vertex). For `p` inside `t`, all three are positive; for `p` on a
side, the corresponding coordinate is `0`.
"""
function trilinear_coordinates(t::EGTriangle, p::EGPoint)
    A, B, C = t[1], t[2], t[3]
    a, b, c = _side_lengths(t)
    x = cross2(B - p, C - p) / a
    y = cross2(C - p, A - p) / b
    z = cross2(A - p, B - p) / c
    return (x, y, z)
end

"""
    kenmotu_point(t::EGTriangle)

The Kenmotu point of `t` (Kimberling center X(371)): the common vertex of
the three congruent squares inscribed in `t`, one per vertex, each with a
diagonal's endpoints on the two sides meeting at that vertex. Given here by
its trilinear coordinates `cos(A - π/4) : cos(B - π/4) : cos(C - π/4)`
(equivalently `cos A + sin A` etc.).
"""
function kenmotu_point(t::EGTriangle)
    A, B, C = t[1], t[2], t[3]
    angA, angB, angC = angle_at(A, B, C), angle_at(B, C, A), angle_at(C, A, B)
    return trilinear_point(t, cos(angA) + sin(angA), cos(angB) + sin(angB), cos(angC) + sin(angC))
end

"""
    kenmotu_circle(t::EGTriangle)

The Kenmotu circle of `t`: centered at the [`kenmotu_point`](@ref), with
radius `√2·a·b·c / (4·Area + a²+b²+c²)`. Passes through the 6 points where
the three equal inscribed squares of the Kenmotu configuration meet the
sides of `t`.
"""
function kenmotu_circle(t::EGTriangle)
    a, b, c = _side_lengths(t)
    rho = sqrt(2) * a * b * c / (4 * area(t) + (a^2 + b^2 + c^2))
    return EGCircle2(kenmotu_point(t), rho)
end

"""
    nagel_point(t::EGTriangle)

The Nagel point of `t` (barycentric coordinates `(s-a):(s-b):(s-c)`).
"""
function nagel_point(t::EGTriangle)
    a, b, c = _side_lengths(t)
    s = (a + b + c) / 2
    return barycentric_point(t, s - a, s - b, s - c)
end

"""
    gergonne_point(t::EGTriangle)

The Gergonne point of `t` (barycentric coordinates `1/(s-a) : 1/(s-b) : 1/(s-c)`).
"""
function gergonne_point(t::EGTriangle)
    a, b, c = _side_lengths(t)
    s = (a + b + c) / 2
    return barycentric_point(t, 1 / (s - a), 1 / (s - b), 1 / (s - c))
end

"""
    spieker_center(t::EGTriangle)

The Spieker center of `t` (the incenter of its medial triangle; barycentric
coordinates `(b+c) : (c+a) : (a+b)`). Equal to `midpoint(incenter(t), nagel_point(t))`.
"""
function spieker_center(t::EGTriangle)
    a, b, c = _side_lengths(t)
    return barycentric_point(t, b + c, c + a, a + b)
end

"""
    symmedian_point(t::EGTriangle)

The symmedian (Lemoine) point of `t` (barycentric coordinates `a² : b² : c²`).
"""
function symmedian_point(t::EGTriangle)
    a, b, c = _side_lengths(t)
    return barycentric_point(t, a^2, b^2, c^2)
end

"""
    mittenpunkt(t::EGTriangle)

The mittenpunkt of `t` (barycentric coordinates `a(s-a) : b(s-b) : c(s-c)`),
the point of concurrence of the lines from each excenter to the midpoint of
the corresponding side.
"""
function mittenpunkt(t::EGTriangle)
    a, b, c = _side_lengths(t)
    s = (a + b + c) / 2
    return barycentric_point(t, a * (s - a), b * (s - b), c * (s - c))
end

"""
    de_longchamps_point(t::EGTriangle)

The de Longchamps point of `t`: the reflection of the orthocenter across
the circumcenter (it lies on the Euler line).
"""
de_longchamps_point(t::EGTriangle) = 2 * circumcenter(t) - orthocenter(t)

"""
    bevan_point(t::EGTriangle)

The Bevan point of `t`: the circumcenter of its excentral triangle (the
triangle formed by the three excenters).
"""
bevan_point(t::EGTriangle) = circumcenter(excentral_triangle(t))

"""
    feuerbach_point(t::EGTriangle)

The Feuerbach point of `t`: the point where the incircle and the
nine-point circle are (internally) tangent.
"""
function feuerbach_point(t::EGTriangle)
    ic, npc = incenter(t), nine_point_center(t)
    return ic + inradius(t) * normalize(ic - npc)
end

"""
    feuerbach_points(t::EGTriangle)

The three points where the nine-point circle of `t` is (externally)
tangent to each of the three excircles, as an `(A=..., B=..., C=...)`
named tuple matching [`excircles`](@ref) — the excircle analogue of
[`feuerbach_point`](@ref) (which is the nine-point circle's tangency with
the *incircle*, an internal tangency instead).
"""
function feuerbach_points(t::EGTriangle)
    npc = nine_point_circle(t)
    exc = excircles(t)
    tangency(J::EGCircle2) = npc.center + npc.r * (J.center - npc.center) / distance(npc.center, J.center)
    return (A=tangency(exc.A), B=tangency(exc.B), C=tangency(exc.C))
end

"""
    _rotate_toward(p, vertex, angle, ref)
    _rotate_away(p, vertex, angle, ref)

Rotate `p` around `vertex` by `angle` (radians), choosing the sign
(`angle` or `-angle`) that lands on the same side of line `(vertex, p)` as
`ref` (`_rotate_toward`) or on the opposite side (`_rotate_away`).
"""
function _rotate_toward(p::EGPoint, vertex::EGPoint, angle::Real, ref::EGPoint)
    cand = rotate(p, angle, vertex)
    line = EGLine(vertex, p)
    return side_of_line(cand, line) == side_of_line(ref, line) ? cand : rotate(p, -angle, vertex)
end
function _rotate_away(p::EGPoint, vertex::EGPoint, angle::Real, ref::EGPoint)
    cand = rotate(p, angle, vertex)
    line = EGLine(vertex, p)
    return side_of_line(cand, line) == side_of_line(ref, line) ? rotate(p, -angle, vertex) : cand
end

"""
    fermat_point(t::EGTriangle)

The (first) Fermat point of `t`: the point minimizing the sum of distances
to the three vertices when every angle of `t` is below 120°. Constructed
as the common intersection of the segments joining each vertex to the apex
of the equilateral triangle erected outward on the opposite side.
"""
function fermat_point(t::EGTriangle)
    A, B, C = t[1], t[2], t[3]
    A2, B2 = _rotate_away(C, B, pi / 3, A), _rotate_away(A, C, pi / 3, B)
    return only(intersection(EGLine(A, A2), EGLine(B, B2)))
end

"""
    second_fermat_point(t::EGTriangle)

The second Fermat point of `t` (Kimberling center X(14), also called the
second isogonic center): constructed like [`fermat_point`](@ref) but with
the three equilateral triangles erected *inward* instead of outward. Equal
to the isogonal conjugate of one of the two [`isodynamic_points`](@ref) —
and, like them, degenerate for an equilateral triangle.
"""
function second_fermat_point(t::EGTriangle)
    A, B, C = t[1], t[2], t[3]
    A2, B2 = _rotate_toward(C, B, pi / 3, A), _rotate_toward(A, C, pi / 3, B)
    return only(intersection(EGLine(A, A2), EGLine(B, B2)))
end

"""
    fermat_axis(t::EGTriangle)

The line through the two [`fermat_point`](@ref)/[`second_fermat_point`](@ref).
"""
fermat_axis(t::EGTriangle) = EGLine(fermat_point(t), second_fermat_point(t))

"""
    napoleon_triangle(t::EGTriangle; outward::Bool=true)

The (outer, by default) Napoleon triangle of `t`: the triangle formed by
the centroids of the equilateral triangles erected on each side of `t`
(outward by default; inward if `outward=false`). Always equilateral
(Napoleon's theorem).
"""
function napoleon_triangle(t::EGTriangle; outward::Bool=true)
    A, B, C = t[1], t[2], t[3]
    rot = outward ? _rotate_away : _rotate_toward
    Aapex, Bapex, Capex = rot(C, B, pi / 3, A), rot(A, C, pi / 3, B), rot(B, A, pi / 3, C)
    return EGTriangle((B + C + Aapex) / 3, (C + A + Bapex) / 3, (A + B + Capex) / 3)
end

"""
    napoleon_point(t::EGTriangle; outward::Bool=true)

The center of the (outer, by default) Napoleon triangle of `t` — which, by
Napoleon's theorem, coincides with the centroid of `t` itself.
"""
napoleon_point(t::EGTriangle; outward::Bool=true) = centroid(napoleon_triangle(t; outward=outward))

"""
    square_inscribed(t::EGTriangle, i::Integer)

The square inscribed in `t` with one side on `[t[j], t[k]]` (the side
opposite `t[i]`) and its other two vertices on the sides through `t[i]`.
Returns an `EGQuadrilateral`, its 4 vertices in order starting from `t[j]`.
There are 3 such squares (one per side, hence the index `i ∈ 1:3`) —
their common side length is `a*h / (a+h)`, `a` the base length and `h` the
corresponding height, independent of how oblique the triangle is.
"""
function square_inscribed(t::EGTriangle, i::Integer)
    others = ((2, 3), (1, 3), (1, 2))
    j, k = others[i]
    apex, Bv, Cv = t[i], t[j], t[k]
    u = direction(EGLine(Bv, Cv)) / norm(direction(EGLine(Bv, Cv)))
    foot = projection(apex, EGLine(Bv, Cv))
    h = distance(apex, foot)
    a = distance(Bv, Cv)
    s = a * h / (a + h)
    x0 = dot(foot - Bv, u) * s / h
    w = (apex - foot) / h
    P1 = Bv + x0 * u
    P2 = Bv + (x0 + s) * u
    return EGQuadrilateral(P1, P2, P2 + s * w, P1 + s * w)
end

"""
    morley_triangle(t::EGTriangle)

The Morley triangle of `t`: formed by the intersections of adjacent
interior-angle trisectors. Always equilateral (Morley's trisector theorem).
"""
function morley_triangle(t::EGTriangle)
    A, B, C = t[1], t[2], t[3]
    trisector_point(vertex, from, ref) = angle_trisectors(vertex, from, ref)[1].through

    Ma = only(intersection(EGLine(B, trisector_point(B, C, A)), EGLine(C, trisector_point(C, B, A))))
    Mb = only(intersection(EGLine(C, trisector_point(C, A, B)), EGLine(A, trisector_point(A, C, B))))
    Mc = only(intersection(EGLine(A, trisector_point(A, B, C)), EGLine(B, trisector_point(B, A, C))))
    return EGTriangle(Ma, Mb, Mc)
end

"""
    spieker_circle(t::EGTriangle)

The Spieker circle of `t`: the incircle of its medial triangle.
"""
spieker_circle(t::EGTriangle) = incircle(medial_triangle(t))

# The circle through p1, p2, tangent to `tline` at `tpoint` (which must be
# p1 or p2): its center is on both the perpendicular to `tline` at `tpoint`
# (tangency) and the perpendicular bisector of [p1,p2] (equidistant from both).
function _circle_tangent_at(p1::EGPoint, p2::EGPoint, tpoint::EGPoint, tline::EGLine)
    center = only(intersection(perpendicular_through(tline, tpoint), perpendicular_bisector(p1, p2)))
    return EGCircle2(center, distance(center, p1))
end

_other_point(pts, known::EGPoint; atol=1e-9) = isapprox(pts[1], known; atol=atol) ? pts[2] : pts[1]

"""
    first_brocard_point(t::EGTriangle)

The first Brocard point of `t`: the point `Ω` such that `∠ΩAB = ∠ΩBC = ∠ΩCA`
(the Brocard angle). Constructed as the second intersection of the circles
`(A,B)` tangent to `BC` at `B` and `(B,C)` tangent to `CA` at `C` (both
pass through `B`).
"""
function first_brocard_point(t::EGTriangle)
    A, B, C = t[1], t[2], t[3]
    c1 = _circle_tangent_at(A, B, B, EGLine(B, C))
    c2 = _circle_tangent_at(B, C, C, EGLine(C, A))
    return _other_point(intersection(c1, c2), B)
end

"""
    second_brocard_point(t::EGTriangle)

The second Brocard point of `t`: the point `Ω'` such that
`∠Ω'BA = ∠Ω'CB = ∠Ω'AC` (the same Brocard angle as [`first_brocard_point`](@ref)).
Constructed analogously, tangent at the other endpoint of each pair.
"""
function second_brocard_point(t::EGTriangle)
    A, B, C = t[1], t[2], t[3]
    c1 = _circle_tangent_at(A, B, A, EGLine(A, C))  # through A, B
    c2 = _circle_tangent_at(B, C, B, EGLine(B, A))  # through B, C -- shared point with c1 is B
    return _other_point(intersection(c1, c2), B)
end

"""
    brocard_angle(t::EGTriangle)

The Brocard angle of `t`: the common value of `∠ΩAB = ∠ΩBC = ∠ΩCA` at the
first Brocard point.
"""
brocard_angle(t::EGTriangle) = angle_at(t[1], first_brocard_point(t), t[2])

"""
    brocard_circle(t::EGTriangle)

The Brocard circle of `t`: centered at the midpoint of the circumcenter and
the symmedian point, passing through both Brocard points (among others).
"""
function brocard_circle(t::EGTriangle)
    center = midpoint(circumcenter(t), symmedian_point(t))
    return EGCircle2(center, distance(center, first_brocard_point(t)))
end

"""
    brocard_midpoint(t::EGTriangle)

The Brocard midpoint of `t` (Kimberling center X(39)): the midpoint of the
two [`first_brocard_point`](@ref) and [`second_brocard_point`](@ref).
"""
brocard_midpoint(t::EGTriangle) = midpoint(first_brocard_point(t), second_brocard_point(t))

"""
    medial_triangle(t::EGTriangle)

The medial triangle of `t`: its vertices are the midpoints of the sides of `t`.
"""
medial_triangle(t::EGTriangle) = EGTriangle(midpoint(t[2], t[3]), midpoint(t[1], t[3]), midpoint(t[1], t[2]))

"""
    anticomplementary_triangle(t::EGTriangle)

The anticomplementary (antimedial) triangle of `t`: vertices `B+C-A`,
`C+A-B`, `A+B-C` — the inverse of [`medial_triangle`](@ref) (`t` is the
medial triangle of this one). Each vertex is the [`anticomplement`](@ref)
of the opposite one.
"""
anticomplementary_triangle(t::EGTriangle) = EGTriangle(t[2] + t[3] - t[1], t[3] + t[1] - t[2], t[1] + t[2] - t[3])

"""
    reflection_triangle(t::EGTriangle)

The reflection triangle of `t`: each vertex reflected across its *opposite
side line* (distinct from [`orthic_triangle`](@ref), which projects onto
the opposite side instead of reflecting across it).
"""
function reflection_triangle(t::EGTriangle)
    A, B, C = t[1], t[2], t[3]
    return EGTriangle(reflection(A, EGLine(B, C)), reflection(B, EGLine(A, C)), reflection(C, EGLine(A, B)))
end

"""
    orthic_triangle(t::EGTriangle)

The orthic triangle of `t`: its vertices are the feet of the altitudes of `t`.
"""
function orthic_triangle(t::EGTriangle)
    A, B, C = t[1], t[2], t[3]
    return EGTriangle(projection(A, EGLine(B, C)), projection(B, EGLine(C, A)), projection(C, EGLine(A, B)))
end

"""
    excentral_triangle(t::EGTriangle)

The excentral triangle of `t`: its vertices are the three excenters of `t`.
"""
excentral_triangle(t::EGTriangle) = (ec = excenters(t); EGTriangle(ec.A, ec.B, ec.C))

"""
    contact_triangle(t::EGTriangle)

The contact (intouch) triangle of `t`: its vertices are the points where
the incircle touches the sides of `t`.
"""
function contact_triangle(t::EGTriangle)
    A, B, C = t[1], t[2], t[3]
    ic = incenter(t)
    return EGTriangle(projection(ic, EGLine(B, C)), projection(ic, EGLine(C, A)), projection(ic, EGLine(A, B)))
end

"""
    extouch_triangle(t::EGTriangle)

The extouch triangle of `t`: its vertices are the points where each
excircle touches the corresponding side of `t`.
"""
function extouch_triangle(t::EGTriangle)
    A, B, C = t[1], t[2], t[3]
    ec = excenters(t)
    return EGTriangle(projection(ec.A, EGLine(B, C)), projection(ec.B, EGLine(C, A)), projection(ec.C, EGLine(A, B)))
end

"""
    tangential_triangle(t::EGTriangle)

The tangential triangle of `t`: its vertices are the pairwise intersections
of the lines tangent to the circumcircle of `t` at each vertex.
"""
function tangential_triangle(t::EGTriangle)
    A, B, C = t[1], t[2], t[3]
    O = circumcenter(t)
    tA = perpendicular_through(EGLine(O, A), A)
    tB = perpendicular_through(EGLine(O, B), B)
    tC = perpendicular_through(EGLine(O, C), C)
    return EGTriangle(only(intersection(tB, tC)), only(intersection(tC, tA)), only(intersection(tA, tB)))
end

"""
    isogonal_conjugate(t::EGTriangle, p::EGPoint)

The isogonal conjugate of `p` with respect to `t`: reflect each cevian
`vertex -> p` across the internal angle bisector at that vertex; the three
reflected lines concur at the isogonal conjugate. An involution
(`isogonal_conjugate(t, isogonal_conjugate(t, p)) == p`) that sends
orthocenter ↔ circumcenter, centroid ↔ symmedian point, and fixes the
incenter.
"""
function isogonal_conjugate(t::EGTriangle, p::EGPoint)
    A, B, C = t[1], t[2], t[3]
    reflect_cevian(vertex, s1, s2) = reflection(EGLine(vertex, p), angle_bisectors(EGLine(vertex, s1), EGLine(vertex, s2))[1])
    return only(intersection(reflect_cevian(A, B, C), reflect_cevian(B, C, A)))
end

"""
    isotomic_conjugate(t::EGTriangle, p::EGPoint)

The isotomic conjugate of `p` with respect to `t`: reflect, for each side,
the point where cevian `vertex -> p` meets that side across the side's
midpoint; the three cevians through the reflected points concur at the
isotomic conjugate. An involution that fixes the centroid.
"""
function isotomic_conjugate(t::EGTriangle, p::EGPoint)
    A, B, C = t[1], t[2], t[3]
    function reflected_cevian(vertex, s1, s2)
        foot = only(intersection(EGLine(s1, s2), EGLine(vertex, p)))
        return EGLine(vertex, reflection(foot, midpoint(s1, s2)))
    end
    return only(intersection(reflected_cevian(A, B, C), reflected_cevian(B, C, A)))
end

"""
    macbeath_point(t::EGTriangle)

The MacBeath point of `t` (Kimberling center X(264)): the isotomic
conjugate of the [`circumcenter`](@ref). It is the Brianchon point of the
MacBeath inconic (the inconic with foci at the circumcenter and the
orthocenter).
"""
macbeath_point(t::EGTriangle) = isotomic_conjugate(t, circumcenter(t))

"""
    complement(t::EGTriangle, p::EGPoint)

The complement of `p` with respect to `t`: `p` homothetically shrunk by
`-1/2` about the [`centroid`](@ref). Sends each vertex to the midpoint of
the opposite side (i.e. to the corresponding vertex of the
[`medial_triangle`](@ref)).
"""
complement(t::EGTriangle, p::EGPoint) = homothety(p, -0.5, centroid(t))

"""
    anticomplement(t::EGTriangle, p::EGPoint)

The anticomplement of `p` with respect to `t`: `p` homothetically expanded
by `-2` about the [`centroid`](@ref) — the inverse of [`complement`](@ref).
Sends each vertex to the corresponding vertex of the
[`anticomplementary_triangle`](@ref).
"""
anticomplement(t::EGTriangle, p::EGPoint) = homothety(p, -2.0, centroid(t))

"""
    pedal_triangle(t::EGTriangle, p::EGPoint)

The pedal triangle of `p` with respect to `t`: the feet of the
perpendiculars from `p` to the three side-lines of `t`. Generalizes
[`orthic_triangle`](@ref) (pedal triangle of the orthocenter) and
[`contact_triangle`](@ref) (pedal triangle of the incenter).
"""
function pedal_triangle(t::EGTriangle, p::EGPoint)
    A, B, C = t[1], t[2], t[3]
    return EGTriangle(projection(p, EGLine(B, C)), projection(p, EGLine(C, A)), projection(p, EGLine(A, B)))
end

"""
    cevian_triangle(t::EGTriangle, p::EGPoint)

The cevian triangle of `p` with respect to `t`: where each cevian
`vertex -> p` meets the opposite side. Generalizes [`medial_triangle`](@ref)
(cevian triangle of the centroid).
"""
function cevian_triangle(t::EGTriangle, p::EGPoint)
    A, B, C = t[1], t[2], t[3]
    return EGTriangle(only(intersection(EGLine(B, C), EGLine(A, p))),
        only(intersection(EGLine(C, A), EGLine(B, p))),
        only(intersection(EGLine(A, B), EGLine(C, p))))
end

"""
    circumcevian_triangle(t::EGTriangle, p::EGPoint)

The circumcevian triangle of `p` with respect to `t`: where each cevian
`vertex -> p`, extended, meets the circumcircle of `t` again.
"""
function circumcevian_triangle(t::EGTriangle, p::EGPoint)
    cc = circumcircle(t)
    second(vertex) = _other_point(intersection(EGLine(vertex, p), cc), vertex)
    return EGTriangle(second(t[1]), second(t[2]), second(t[3]))
end

"""
    mixtilinear_incircle(t::EGTriangle, i::Integer; atol=1e-9)

The mixtilinear incircle at vertex `t[i]` (`i` in `1:3`): the circle
tangent to the two sides of `t` through that vertex, and internally
tangent to the circumcircle of `t`. Built by reusing [`tangent_circles`](@ref)
(the `CLL` Apollonius case) and picking, among its up to 4 solutions, the
one nestled inside the vertex's angle with internal circumcircle tangency.
"""
function mixtilinear_incircle(t::EGTriangle, i::Integer; atol=1e-9)
    vertex, other1, other2 = t[i], t[mod1(i + 1, 3)], t[mod1(i + 2, 3)]
    l1, l2 = EGLine(vertex, other1), EGLine(vertex, other2)
    cc = circumcircle(t)
    for s in tangent_circles(l1, l2, cc; atol=atol)
        scale = max(s.r, cc.r, 1.0)
        side_of_line(s.center, l1) == side_of_line(other2, l1) &&
            side_of_line(s.center, l2) == side_of_line(other1, l2) &&
            abs(distance(s.center, cc.center) - (cc.r - s.r)) <= sqrt(atol) * scale &&
            return s
    end
    error("mixtilinear_incircle: no valid solution found")
end

"""
    thebault_circles(t::EGTriangle, p::EGPoint; atol=1e-9)

The two Thébault circles of `t` for a point `p` on side `[t[2], t[3]]`
(the side opposite `t[1]`): each is tangent to the cevian `t[1] -> p`, to
the side `[t[2], t[3]]`, and internally tangent to the circumcircle of
`t` — one nestled against `t[2]`, the other against `t[3]`. Returned as a
named tuple `(near_b=..., near_c=...)`. By the Sawayama–Thébault theorem,
the incenter of `t` always lies on the segment joining their two centers.
Built the same way as [`mixtilinear_incircle`](@ref), by reusing
[`tangent_circles`](@ref) (the `CLL` Apollonius case).
"""
function thebault_circles(t::EGTriangle, p::EGPoint; atol=1e-9)
    A, B, C = t[1], t[2], t[3]
    cevian, side_line = EGLine(A, p), EGLine(B, C)
    cc = circumcircle(t)
    near_b, near_c = nothing, nothing
    for s in tangent_circles(cevian, side_line, cc; atol=atol)
        scale = max(s.r, cc.r, 1.0)
        (side_of_line(s.center, side_line) == side_of_line(A, side_line) &&
         abs(distance(s.center, cc.center) - (cc.r - s.r)) <= sqrt(atol) * scale) || continue
        if side_of_line(s.center, cevian) == side_of_line(C, cevian)
            near_c = s
        elseif side_of_line(s.center, cevian) == side_of_line(B, cevian)
            near_b = s
        end
    end
    (near_b === nothing || near_c === nothing) &&
        error("thebault_circles: could not find both Thébault circles")
    return (near_b=near_b, near_c=near_c)
end

"""
    three_apollonius_circles(t::EGTriangle)

The three (vertex) Apollonius circles of `t`, as a 3-tuple `(circ_a, circ_b,
circ_c)`: `circ_a` is the locus of points whose distances to `B` and `C`
are in the ratio `AB:AC` (so it passes through `A`), and likewise for
`circ_b` (through `B`) and `circ_c` (through `C`). All three pass through
the two [`isodynamic_points`](@ref) of `t`. Throws an `ArgumentError` for
an equilateral triangle (each Apollonius circle then degenerates to a line).
"""
function three_apollonius_circles(t::EGTriangle)
    A, B, C = t[1], t[2], t[3]
    a, b, c = _side_lengths(t)
    return (apollonius_circle(B, C, c / b), apollonius_circle(C, A, a / c), apollonius_circle(A, B, b / a))
end

"""
    isodynamic_points(t::EGTriangle)

The two isodynamic points of `t`, as a 2-tuple: the common points of its
[`three_apollonius_circles`](@ref) (for each vertex, the locus of points
whose distances to the other two vertices are in the same ratio as the two
sides meeting at that vertex). Throws an `ArgumentError` for an equilateral
triangle (the Apollonius circles degenerate to lines).
"""
function isodynamic_points(t::EGTriangle)
    circ_a, circ_b, _ = three_apollonius_circles(t)
    pts = intersection(circ_a, circ_b)
    return (pts[1], pts[2])
end

"""
    orthopole(l::EGLine, t::EGTriangle)

The orthopole of `l` with respect to `t`: project each vertex of `t` onto
`l`, then draw through each projection the perpendicular to the side
opposite that vertex; the three perpendiculars concur at the orthopole.
"""
function orthopole(l::EGLine, t::EGTriangle)
    A, B, C = t[1], t[2], t[3]
    lA = perpendicular_through(EGLine(B, C), projection(A, l))
    lB = perpendicular_through(EGLine(C, A), projection(B, l))
    return only(intersection(lA, lB))
end

"""
    poncelet_point(t::EGTriangle, p::EGPoint; atol=1e-9)

The Poncelet point of `t` and a 4th point `p`: for any 4 points in general
position, the nine-point circles of the 4 triangles formed by leaving out
one of them always share a common point.
"""
function poncelet_point(t::EGTriangle, p::EGPoint; atol=1e-9)
    A, B, C = t[1], t[2], t[3]
    npc_a = nine_point_circle(EGTriangle(B, C, p))
    npc_b = nine_point_circle(EGTriangle(A, C, p))
    npc_c = nine_point_circle(EGTriangle(A, B, p))
    tol = sqrt(atol) * max(npc_a.r, npc_b.r, npc_c.r, 1.0)
    for cand in intersection(npc_a, npc_b; atol=atol)
        abs(distance(cand, npc_c.center) - npc_c.r) <= tol && return cand
    end
    error("poncelet_point: could not find a common point of the nine-point circles")
end

"""
    conway_points(t::EGTriangle)

The 6 Conway points of `t`, as a 6-tuple: at each vertex, extend both
sides meeting there beyond that vertex by the length of the side opposite
it. All 6 lie on the [`conway_circle`](@ref).
"""
function conway_points(t::EGTriangle)
    A, B, C = t[1], t[2], t[3]
    a, b, c = _side_lengths(t)
    ext(v, other, d) = v + (d / distance(v, other)) * (v - other)
    return (ext(A, B, a), ext(A, C, a), ext(B, A, b), ext(B, C, b), ext(C, B, c), ext(C, A, c))
end

"""
    conway_circle(t::EGTriangle)

The Conway circle of `t`: centered at the incenter, passing through the 6
[`conway_points`](@ref). Its radius is `sqrt(inradius(t)^2 + s^2)` where
`s` is the semiperimeter.
"""
conway_circle(t::EGTriangle) = EGCircle2(incenter(t), distance(incenter(t), conway_points(t)[1]))

"""
    taylor_points(t::EGTriangle)

The 6 points of the Taylor configuration, as a 6-tuple: project each
vertex of the [`orthic_triangle`](@ref) onto each of the two sides of `t`
*not* used to define it. All 6 are always concyclic, on the
[`taylor_circle`](@ref).
"""
function taylor_points(t::EGTriangle)
    A, B, C = t[1], t[2], t[3]
    oh = orthic_triangle(t)
    return (projection(oh[1], EGLine(A, B)), projection(oh[1], EGLine(C, A)),
        projection(oh[2], EGLine(B, C)), projection(oh[2], EGLine(A, B)),
        projection(oh[3], EGLine(C, A)), projection(oh[3], EGLine(B, C)))
end

"""
    taylor_circle(t::EGTriangle)

The Taylor circle of `t`: the common circle through the 6
[`taylor_points`](@ref) (any 3 of them already determine it).
"""
function taylor_circle(t::EGTriangle)
    d, _, e, _, f, _ = taylor_points(t)
    return circumcircle(EGTriangle(d, e, f))
end

"""
    first_lemoine_points(t::EGTriangle)

6 points, as a 6-tuple: through the symmedian point, draw the line
parallel to each side, and take its intersections with the *other* two
sides. All 6 lie on the [`first_lemoine_circle`](@ref).
"""
function first_lemoine_points(t::EGTriangle)
    A, B, C = t[1], t[2], t[3]
    lp = symmedian_point(t)
    p_ab = parallel_through(EGLine(A, B), lp)
    p_bc = parallel_through(EGLine(B, C), lp)
    p_ca = parallel_through(EGLine(C, A), lp)
    return (only(intersection(p_ab, EGLine(A, C))), only(intersection(p_ab, EGLine(B, C))),
        only(intersection(p_bc, EGLine(B, A))), only(intersection(p_bc, EGLine(C, A))),
        only(intersection(p_ca, EGLine(C, B))), only(intersection(p_ca, EGLine(A, B))))
end

"""
    first_lemoine_circle(t::EGTriangle)

The first Lemoine circle of `t`: centered at the midpoint of the
circumcenter and the symmedian point, passing through the 6
[`first_lemoine_points`](@ref).
"""
function first_lemoine_circle(t::EGTriangle)
    center = midpoint(circumcenter(t), symmedian_point(t))
    return EGCircle2(center, distance(center, first_lemoine_points(t)[1]))
end

"""
    van_lamoen_points(t::EGTriangle)

The 6 circumcenters of the sub-triangles that the three medians of `t` cut
it into (each an area formed by one vertex, one non-adjacent side midpoint,
and the [`centroid`](@ref)), as a 6-tuple. A classical theorem states these
6 points are always concyclic — see [`van_lamoen_circle`](@ref).
"""
function van_lamoen_points(t::EGTriangle)
    A, B, C = t[1], t[2], t[3]
    Ma, Mb, Mc = midpoint(B, C), midpoint(A, C), midpoint(A, B)
    G = centroid(t)
    return (circumcenter(EGTriangle(A, Mc, G)), circumcenter(EGTriangle(B, Ma, G)),
        circumcenter(EGTriangle(B, Mc, G)), circumcenter(EGTriangle(C, Mb, G)),
        circumcenter(EGTriangle(C, Ma, G)), circumcenter(EGTriangle(A, Mb, G)))
end

"""
    van_lamoen_circle(t::EGTriangle)

The Van Lamoen circle of `t`: the common circle through the 6
[`van_lamoen_points`](@ref).
"""
function van_lamoen_circle(t::EGTriangle)
    A, B, C = t[1], t[2], t[3]
    Ma, Mb, Mc = midpoint(B, C), midpoint(A, C), midpoint(A, B)
    G = centroid(t)
    p1 = circumcenter(EGTriangle(A, Mb, G))
    p2 = circumcenter(EGTriangle(B, Ma, G))
    p3 = circumcenter(EGTriangle(C, Ma, G))
    return circumcircle(EGTriangle(p1, p2, p3))
end

"""
    second_lemoine_circle(t::EGTriangle)

The second Lemoine (cosine) circle of `t`: centered at the symmedian
point, with radius `a*b*c / (a^2+b^2+c^2)`.
"""
function second_lemoine_circle(t::EGTriangle)
    a, b, c = _side_lengths(t)
    return EGCircle2(symmedian_point(t), a * b * c / (a^2 + b^2 + c^2))
end

"""
    three_tangent_circles(t::EGTriangle)

The three circles centered at the vertices of `t`, each with radius equal
to the tangent length from that vertex to the incircle (`s - a` at the
vertex opposite side `a`, etc., `s` the semiperimeter). Every pair is
externally tangent — e.g. `distance(A, B) == (s-a) + (s-b) == c` — meeting
exactly at the point where the incircle touches the side between them.
These are the starting configuration [`soddy_circles`](@ref) is built from.
"""
function three_tangent_circles(t::EGTriangle)
    A, B, C = t[1], t[2], t[3]
    a, b, c = _side_lengths(t)
    s = (a + b + c) / 2
    return (EGCircle2(A, s - a), EGCircle2(B, s - b), EGCircle2(C, s - c))
end

"""
    soddy_circles(t::EGTriangle; atol=1e-9)

The two Soddy circles of `t`, as `(inner=..., outer=...)`: build the three
mutually tangent circles centered at the vertices with radii `s-a`, `s-b`,
`s-c` (`s` the semiperimeter, see [`three_tangent_circles`](@ref)), then
find their common tangent circles (the classical Apollonius `CCC` problem,
[`tangent_circles`](@ref)) other than the three vertex circles themselves
— the smaller one nestled between them is `inner`, the larger one
enclosing them is `outer`.
"""
function soddy_circles(t::EGTriangle; atol=1e-9)
    base = three_tangent_circles(t)
    a, b, c = _side_lengths(t)
    s = (a + b + c) / 2
    sols = tangent_circles(base...; atol=atol)
    tol = sqrt(atol) * max(s, 1.0)
    genuine = filter(sol -> !any(bc -> isapprox(sol.center, bc.center; atol=tol) && isapprox(sol.r, bc.r; atol=tol), base), sols)
    length(genuine) != 2 && error("soddy_circles: expected exactly 2 non-trivial solutions, got $(length(genuine))")
    return genuine[1].r < genuine[2].r ? (inner=genuine[1], outer=genuine[2]) : (inner=genuine[2], outer=genuine[1])
end

"""
    soddy_line(t::EGTriangle; atol=1e-9)

The Soddy line of `t`: the line through the centers of its two
[`soddy_circles`](@ref) (inner and outer).
"""
function soddy_line(t::EGTriangle; atol=1e-9)
    sc = soddy_circles(t; atol=atol)
    return EGLine(sc.inner.center, sc.outer.center)
end

"""
    simson_line(t::EGTriangle, p::EGPoint)

The Simson line of `p` with respect to `t`: the line through the feet of
the perpendiculars from `p` to the three side-lines of `t`. These feet are
only guaranteed to be collinear when `p` lies on the circumcircle of `t`.
"""
function simson_line(t::EGTriangle, p::EGPoint)
    f1 = projection(p, EGLine(t[1], t[2]))
    f2 = projection(p, EGLine(t[2], t[3]))
    return EGLine(f1, f2)
end

"""
    steiner_inellipse(t::EGTriangle)

The Steiner inellipse of `t`: the unique ellipse centered at [`centroid`](@ref)
that is tangent to the three sides of `t` at their midpoints (it is the
ellipse of maximum area inscribed in `t`). Its foci are found via Marden's
theorem: representing the vertices of `t` as complex numbers `z1, z2, z3`,
the foci are the two roots of the derivative of `(z-z1)*(z-z2)*(z-z3)`.
"""
function steiner_inellipse(t::EGTriangle)
    A, B, C = t[1], t[2], t[3]
    z1, z2, z3 = complex(A[1], A[2]), complex(B[1], B[2]), complex(C[1], C[2])
    s, sp = z1 + z2 + z3, z1 * z2 + z1 * z3 + z2 * z3
    disc = sqrt(s^2 - 3sp)
    f1, f2 = (s + disc) / 3, (s - disc) / 3
    F1, F2 = EGPoint(real(f1), imag(f1)), EGPoint(real(f2), imag(f2))
    return EGEllipse2(F1, F2, midpoint(A, B))
end

"""
    steiner_circumellipse(t::EGTriangle)

The Steiner circumellipse of `t`: the unique ellipse centered at
[`centroid`](@ref) that passes through the three vertices of `t` (it is the
ellipse of minimum area circumscribing `t`). Constructed via
[`conic_through_points`](@ref) using the three vertices together with the
reflections of two of them across the centroid (also on the ellipse, since
it's centrally symmetric about its center).
"""
function steiner_circumellipse(t::EGTriangle)
    A, B, C = t[1], t[2], t[3]
    g = centroid(t)
    return conic_through_points(A, B, C, reflection(A, g), reflection(B, g))
end

"""
    kiepert_hyperbola(t::EGTriangle)

The Kiepert hyperbola of `t`: the unique **rectangular** hyperbola through
`t`'s three vertices, its [`centroid`](@ref) and its [`orthocenter`](@ref)
(centered at Kimberling center X(115)). Built via [`conic_through_points`](@ref)
on those 5 points directly, since a conic is uniquely determined by 5
points and this one is already known to pass through all 5 — no need to
construct its axes/asymptotes by hand first.
"""
kiepert_hyperbola(t::EGTriangle) = conic_through_points(t[1], t[2], t[3], centroid(t), orthocenter(t))

"""
    kiepert_parabola(t::EGTriangle)

The Kiepert parabola of `t`: focus at Kimberling center X(110)
(`trilinear(a/(b²-c²), b/(c²-a²), c/(a²-b²))`), directrix the
[`euler_line`](@ref). Throws an `ArgumentError` if `t` is isosceles (X(110)
is undefined then).
"""
function kiepert_parabola(t::EGTriangle)
    a, b, c = _side_lengths(t)
    any(isapprox.((a, b, c), (b, c, a))) &&
        throw(ArgumentError("kiepert_parabola: undefined for an isosceles triangle"))
    focus = trilinear_point(t, a / (b^2 - c^2), b / (c^2 - a^2), c / (a^2 - b^2))
    return EGParabola2(focus, euler_line(t))
end

"""
    lemoine_inellipse(t::EGTriangle)

The Lemoine inellipse of `t`: the bifocal ellipse with foci at the
[`centroid`](@ref) and [`symmedian_point`](@ref), passing through the
`t[1]`-side vertex of the cevian triangle of Kimberling center X(598).
"""
function lemoine_inellipse(t::EGTriangle)
    a, b, c = _side_lengths(t)
    x598 = trilinear_point(t, b * c / (a^2 - 2b^2 - 2c^2), c * a / (b^2 - 2c^2 - 2a^2), a * b / (c^2 - 2a^2 - 2b^2))
    through = cevian_triangle(t, x598)[1]
    return EGEllipse2(centroid(t), symmedian_point(t), through)
end

"""
    brocard_inellipse(t::EGTriangle)

The Brocard inellipse of `t`: the bifocal ellipse with foci at the second
and first [`first_brocard_point`](@ref)/[`second_brocard_point`](@ref) (in
that order), passing through the `t[1]`-side vertex of the cevian triangle
of the [`symmedian_point`](@ref).
"""
function brocard_inellipse(t::EGTriangle)
    through = cevian_triangle(t, symmedian_point(t))[1]
    return EGEllipse2(second_brocard_point(t), first_brocard_point(t), through)
end

"""
    macbeath_inellipse(t::EGTriangle)

The MacBeath inellipse of `t`: the bifocal ellipse with foci at the
[`circumcenter`](@ref) and [`orthocenter`](@ref), passing through the
`t[1]`-side vertex of the cevian triangle of the [`macbeath_point`](@ref).
Only defined (as a real ellipse) when `t` has no obtuse angle.
"""
function macbeath_inellipse(t::EGTriangle)
    through = cevian_triangle(t, macbeath_point(t))[1]
    return EGEllipse2(circumcenter(t), orthocenter(t), through)
end

"""
    mandart_inellipse(t::EGTriangle)

The Mandart inellipse of `t`: centered at the [`mittenpunkt`](@ref),
tangent to the three sides at the [`extouch_triangle`](@ref)'s vertices.
Built via [`conic_through_points`](@ref) on those 3 vertices together with
2 of their point-reflections through the mittenpunkt (also on the ellipse,
since it's centrally symmetric about its own center).
"""
function mandart_inellipse(t::EGTriangle)
    m = mittenpunkt(t)
    et = extouch_triangle(t)
    return conic_through_points(reflection(et[1], m), reflection(et[2], m), et[1], et[2], et[3])
end

"""
    orthic_inellipse(t::EGTriangle)

The orthic inellipse of `t`: centered at the [`symmedian_point`](@ref),
tangent to the three sides at the [`orthic_triangle`](@ref)'s vertices
(the altitude feet). Built the same way as [`mandart_inellipse`](@ref), via
[`conic_through_points`](@ref). Only defined (as a real ellipse) when `t`
has no obtuse angle.
"""
function orthic_inellipse(t::EGTriangle)
    k = symmedian_point(t)
    ot = orthic_triangle(t)
    return conic_through_points(reflection(ot[1], k), reflection(ot[2], k), ot[1], ot[2], ot[3])
end
