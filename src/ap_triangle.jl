_side_lengths(t::APTriangle) = (distance(t[2], t[3]), distance(t[1], t[3]), distance(t[1], t[2]))
"""
    altitude(t::APTriangle, i)

The altitude line from vertex `t[i]`, perpendicular to the opposite side.
"""
function altitude(t::APTriangle, i::Integer)
    j, k = _other_two(i)
    return perpendicular_through(APLine(t[j], t[k]), t[i])
end
"""
    median(t::APTriangle, i)

The median line from vertex `t[i]` to the midpoint of the opposite side.
"""
function median(t::APTriangle, i::Integer)
    j, k = _other_two(i)
    return APLine(t[i], midpoint(t[j], t[k]))
end
"""
    bisector(t::APTriangle, i)

The internal angle bisector line from vertex `t[i]` (passes through the
[`incenter`](@ref)).
"""
function bisector(t::APTriangle, i::Integer)
    j, k = _other_two(i)
    u = normalize(t[j] - t[i])
    v = normalize(t[k] - t[i])
    return APLine(t[i], t[i] + (u + v))
end
"""
    bisector_ext(t::APTriangle, i)

The external angle bisector line from vertex `t[i]`, perpendicular to the
internal one ([`bisector`](@ref)) at that same vertex.
"""
bisector_ext(t::APTriangle, i::Integer) = perpendicular_through(bisector(t, i), t[i])
"""
    mediator(t::APTriangle, i)

The perpendicular bisector of the side opposite vertex `t[i]` (passes
through the [`circumcenter`](@ref)).
"""
function mediator(t::APTriangle, i::Integer)
    j, k = _other_two(i)
    return perpendicular_bisector(t[j], t[k])
end
"""
    trisector(t::APTriangle, i)

The two rays from vertex `t[i]` trisecting the interior angle there into
three equal parts (see [`angle_trisectors`](@ref); this is the
construction behind the [`morley_triangle`](@ref)).
"""
function trisector(t::APTriangle, i::Integer)
    j, k = _other_two(i)
    return angle_trisectors(t[i], t[j], t[k])
end
"""
    circumcenter(t::APTriangle)

Center of the circle passing through the three vertices of `t`.
"""
function circumcenter(t::APTriangle)
    a, b, c = t[1], t[2], t[3]
    ax, ay = a[1], a[2]
    bx, by = b[1], b[2]
    cx, cy = c[1], c[2]
    d = 2 * (ax * (by - cy) + bx * (cy - ay) + cx * (ay - by))
    a2, b2, c2 = ax^2 + ay^2, bx^2 + by^2, cx^2 + cy^2
    ux = (a2 * (by - cy) + b2 * (cy - ay) + c2 * (ay - by)) / d
    uy = (a2 * (cx - bx) + b2 * (ax - cx) + c2 * (bx - ax)) / d
    return APPoint(ux, uy)
end
"""
    circumradius(t::APTriangle)

Radius of the circumscribed circle of `t`.
"""
circumradius(t::APTriangle) = distance(circumcenter(t), t[1])
"""
    circumcircle(t::APTriangle)

The circumscribed circle of `t`.
"""
circumcircle(t::APTriangle) = APCircle2(circumcenter(t), circumradius(t))
"""
    incenter(t::APTriangle)

Center of the circle inscribed in `t`.
"""
function incenter(t::APTriangle)
    a, b, c = t[1], t[2], t[3]
    la, lb, lc = distance(b, c), distance(a, c), distance(a, b)
    return a + (lb * (b - a) + lc * (c - a)) / (la + lb + lc)
end
"""
    inradius(t::APTriangle)

Radius of the inscribed circle of `t`.
"""
inradius(t::APTriangle) = 2 * area(t) / perimeter(t)
"""
    incircle(t::APTriangle)

The inscribed circle of `t`.
"""
incircle(t::APTriangle) = APCircle2(incenter(t), inradius(t))
"""
    orthocenter(t::APTriangle)

Intersection point of the three altitudes of `t`, obtained from the Euler
line relation `H = 3G - 2O`.
"""
orthocenter(t::APTriangle) = circumcenter(t) + 3 * (centroid(t) - circumcenter(t))
"""
    excenters(t::APTriangle)

The three excenters of `t`, as a `(A=..., B=..., C=...)` named tuple where
`A` is the excenter opposite vertex `t[1]`, etc.
"""
function excenters(t::APTriangle)
    A, B, C = t[1], t[2], t[3]
    a, b, c = _side_lengths(t)
    return (A=A + (b * (B - A) + c * (C - A)) / (-a + b + c),
        B=B + (a * (A - B) + c * (C - B)) / (a - b + c),
        C=C + (a * (A - C) + b * (B - C)) / (a + b - c))
end
"""
    exradii(t::APTriangle)

The three exradii of `t`, as a `(A=..., B=..., C=...)` named tuple where
`A` is the radius of the excircle opposite vertex `t[1]`, etc.
"""
function exradii(t::APTriangle)
    a, b, c = _side_lengths(t)
    s = (a + b + c) / 2
    K = area(t)
    return (A=K / (s - a), B=K / (s - b), C=K / (s - c))
end
"""
    excircles(t::APTriangle)

The three excircles of `t`, as a `(A=..., B=..., C=...)` named tuple (see
[`excenters`](@ref) and [`exradii`](@ref)).
"""
function excircles(t::APTriangle)
    ec, er = excenters(t), exradii(t)
    return (A=APCircle2(ec.A, er.A), B=APCircle2(ec.B, er.B), C=APCircle2(ec.C, er.C))
end
"""
    euler_line(t::APTriangle)

The Euler line of `t`, through its centroid, circumcenter and orthocenter.
"""
euler_line(t::APTriangle) = APLine(circumcenter(t), centroid(t))
"""
    nine_point_center(t::APTriangle)

Center of the nine-point (Euler) circle of `t`: the midpoint of the segment
joining the circumcenter and the orthocenter.
"""
nine_point_center(t::APTriangle) = midpoint(circumcenter(t), orthocenter(t))
"""
    nine_point_circle(t::APTriangle)

The nine-point (Euler) circle of `t`, passing through the midpoints of the
three sides, the feet of the three altitudes, and the midpoints of the
segments from the orthocenter to each vertex. Its radius is half the
circumradius.
"""
nine_point_circle(t::APTriangle) = APCircle2(nine_point_center(t), circumradius(t) / 2)
"""
    euler_points(t::APTriangle)

The three Euler points of `t`, as a 3-tuple: the midpoints of the segments
joining the orthocenter to each vertex. Together with the three edge
midpoints and the three altitude feet, these are the nine defining points
of the [`nine_point_circle`](@ref).
"""
function euler_points(t::APTriangle)
    H = orthocenter(t)
    return (midpoint(H, t[1]), midpoint(H, t[2]), midpoint(H, t[3]))
end
"""
    orthic_axis(t::APTriangle)

The orthic axis of `t`: the radical axis of its circumcircle and
[`nine_point_circle`](@ref). Always perpendicular to the [`euler_line`](@ref).
"""
orthic_axis(t::APTriangle) = radical_axis(circumcircle(t), nine_point_circle(t))
"""
    brocard_axis(t::APTriangle)

The Brocard axis of `t`: the line through the circumcenter and the
symmedian (Lemoine) point.
"""
brocard_axis(t::APTriangle) = APLine(circumcenter(t), symmedian_point(t))
"""
    lemoine_axis(t::APTriangle)

The Lemoine axis of `t`: the polar line of the symmedian point with
respect to the circumcircle.
"""
lemoine_axis(t::APTriangle) = polar_line(circumcircle(t), symmedian_point(t))
"""
    steiner_line(t::APTriangle, p::APPoint)

The Steiner line of `p` with respect to `t`: the line through the
reflections of `p` across the three side-lines of `t`. These reflections
are only guaranteed to be collinear (and the line only guaranteed to pass
through the orthocenter) when `p` lies on the circumcircle of `t` — compare
[`simson_line`](@ref), whose feet of perpendiculars are the midpoints of
`p` and each of these reflections.
"""
function steiner_line(t::APTriangle, p::APPoint)
    r1 = reflection(p, APLine(t[1], t[2]))
    r2 = reflection(p, APLine(t[2], t[3]))
    return APLine(r1, r2)
end
"""
    barycentric_point(t::APTriangle, wA, wB, wC)

The point with barycentric coordinates `(wA, wB, wC)` relative to `t`
(the weights need not be normalized).
"""
barycentric_point(t::APTriangle, wA::Real, wB::Real, wC::Real) =
    t[1] + (wB * (t[2] - t[1]) + wC * (t[3] - t[1])) / (wA + wB + wC)
"""
    barycentric_point(t::APTriangle)

[`barycentric_point`](@ref) with equal weights `(1, 1, 1)` — the centroid.
"""
barycentric_point(t::APTriangle) = barycentric_point(t, 1.0, 1.0, 1.0)
"""
    barycentric_coordinates(t::APTriangle, p::APPoint)

The normalized barycentric coordinates `(α, β, γ)` (summing to `1`) of `p`
relative to `t`, computed from signed sub-triangle areas.
"""
function barycentric_coordinates(t::APTriangle, p::APPoint)
    A, B, C = t[1], t[2], t[3]
    total = cross2(B - A, C - A)
    α = cross2(B - p, C - p) / total
    β = cross2(C - p, A - p) / total
    γ = cross2(A - p, B - p) / total
    return (α, β, γ)
end
"""
    trilinear_point(t::APTriangle, x, y, z)

The point with trilinear coordinates `(x:y:z)` relative to `t` (the values
need not be normalized — trilinear coordinates are only meaningful up to a
common scale factor, unlike the actual distances [`trilinear_coordinates`](@ref)
returns). Converts to barycentric via `(a*x : b*y : c*z)`, `a`/`b`/`c`
being the side lengths opposite `t[1]`/`t[2]`/`t[3]`.
"""
function trilinear_point(t::APTriangle, x::Real, y::Real, z::Real)
    a, b, c = _side_lengths(t)
    return barycentric_point(t, a * x, b * y, c * z)
end
"""
    trilinear_coordinates(t::APTriangle, p::APPoint)

The trilinear coordinates of `p` relative to `t`: the actual signed
perpendicular distances `(x, y, z)` from `p` to sides `a = [t[2],t[3]]`,
`b = [t[3],t[1]]`, `c = [t[1],t[2]]` (positive on the same side as the
opposite vertex). For `p` inside `t`, all three are positive; for `p` on a
side, the corresponding coordinate is `0`.
"""
function trilinear_coordinates(t::APTriangle, p::APPoint)
    A, B, C = t[1], t[2], t[3]
    a, b, c = _side_lengths(t)
    x = cross2(B - p, C - p) / a
    y = cross2(C - p, A - p) / b
    z = cross2(A - p, B - p) / c
    return (x, y, z)
end
"""
    kenmotu_point(t::APTriangle)

The Kenmotu point of `t` (Kimberling center X(371)): the common vertex of
the three congruent squares inscribed in `t`, one per vertex, each with a
diagonal's endpoints on the two sides meeting at that vertex. Given here by
its trilinear coordinates `cos(A - π/4) : cos(B - π/4) : cos(C - π/4)`
(equivalently `cos A + sin A` etc.).
"""
function kenmotu_point(t::APTriangle)
    A, B, C = t[1], t[2], t[3]
    angA, angB, angC = angle_at(A, B, C), angle_at(B, C, A), angle_at(C, A, B)
    return trilinear_point(t, cos(angA) + sin(angA), cos(angB) + sin(angB), cos(angC) + sin(angC))
end
"""
    kenmotu_circle(t::APTriangle)

The Kenmotu circle of `t`: centered at the [`kenmotu_point`](@ref), with
radius `√2·a·b·c / (4·Area + a²+b²+c²)`. Passes through the 6 points where
the three equal inscribed squares of the Kenmotu configuration meet the
sides of `t`.
"""
function kenmotu_circle(t::APTriangle)
    a, b, c = _side_lengths(t)
    rho = sqrt(2) * a * b * c / (4 * area(t) + (a^2 + b^2 + c^2))
    return APCircle2(kenmotu_point(t), rho)
end
"""
    nagel_point(t::APTriangle)

The Nagel point of `t` (barycentric coordinates `(s-a):(s-b):(s-c)`).
"""
function nagel_point(t::APTriangle)
    a, b, c = _side_lengths(t)
    s = (a + b + c) / 2
    return barycentric_point(t, s - a, s - b, s - c)
end
"""
    gergonne_point(t::APTriangle)

The Gergonne point of `t` (barycentric coordinates `1/(s-a) : 1/(s-b) : 1/(s-c)`).
"""
function gergonne_point(t::APTriangle)
    a, b, c = _side_lengths(t)
    s = (a + b + c) / 2
    return barycentric_point(t, 1 / (s - a), 1 / (s - b), 1 / (s - c))
end
"""
    spieker_center(t::APTriangle)

The Spieker center of `t` (the incenter of its medial triangle; barycentric
coordinates `(b+c) : (c+a) : (a+b)`). Equal to `midpoint(incenter(t), nagel_point(t))`.
"""
function spieker_center(t::APTriangle)
    a, b, c = _side_lengths(t)
    return barycentric_point(t, b + c, c + a, a + b)
end
"""
    symmedian_point(t::APTriangle)

The symmedian (Lemoine) point of `t` (barycentric coordinates `a² : b² : c²`).
"""
function symmedian_point(t::APTriangle)
    a, b, c = _side_lengths(t)
    return barycentric_point(t, a^2, b^2, c^2)
end
"""
    mittenpunkt(t::APTriangle)

The mittenpunkt of `t` (barycentric coordinates `a(s-a) : b(s-b) : c(s-c)`),
the point of concurrence of the lines from each excenter to the midpoint of
the corresponding side.
"""
function mittenpunkt(t::APTriangle)
    a, b, c = _side_lengths(t)
    s = (a + b + c) / 2
    return barycentric_point(t, a * (s - a), b * (s - b), c * (s - c))
end
"""
    clawson_point(t::APTriangle; atol=1e-9)

The Clawson point of `t` (Kimberling X(19)): trilinear coordinates
`tan(A) : tan(B) : tan(C)`, the angles of `t` at each vertex. Undefined
for a right triangle (`tan` of the right angle has no finite value, so
the point is genuinely at infinity, not just numerically awkward), which
throws an `ArgumentError` instead of silently returning a meaningless
finite point from a near-infinite weight.
"""
function clawson_point(t::APTriangle; atol=1e-9)
    A, B, C = angle_at(t[1], t[2], t[3]), angle_at(t[2], t[1], t[3]), angle_at(t[3], t[1], t[2])
    any(ang -> isapprox(ang, pi / 2; atol=atol), (A, B, C)) &&
        throw(ArgumentError("clawson_point: undefined for a right triangle (X(19) is a point at infinity here)"))
    return barycentric_point(t, tan(A), tan(B), tan(C))
end
"""
    de_longchamps_point(t::APTriangle)

The de Longchamps point of `t`: the reflection of the orthocenter across
the circumcenter (it lies on the Euler line).
"""
de_longchamps_point(t::APTriangle) = circumcenter(t) + (circumcenter(t) - orthocenter(t))
"""
    bevan_point(t::APTriangle)

The Bevan point of `t`: the circumcenter of its excentral triangle (the
triangle formed by the three excenters).
"""
bevan_point(t::APTriangle) = circumcenter(excentral_triangle(t))
"""
    feuerbach_point(t::APTriangle)

The Feuerbach point of `t`: the point where the incircle and the
nine-point circle are (internally) tangent.
"""
function feuerbach_point(t::APTriangle)
    ic, npc = incenter(t), nine_point_center(t)
    return ic + inradius(t) * normalize(ic - npc)
end
"""
    feuerbach_points(t::APTriangle)

The three points where the nine-point circle of `t` is (externally)
tangent to each of the three excircles, as an `(A=..., B=..., C=...)`
named tuple matching [`excircles`](@ref) — the excircle analogue of
[`feuerbach_point`](@ref) (which is the nine-point circle's tangency with
the *incircle*, an internal tangency instead).
"""
function feuerbach_points(t::APTriangle)
    npc = nine_point_circle(t)
    exc = excircles(t)
    tangency(J::APCircle2) = npc.center + npc.r * (J.center - npc.center) / distance(npc.center, J.center)
    return (A=tangency(exc.A), B=tangency(exc.B), C=tangency(exc.C))
end
"""
    _rotate_toward(p, vertex, angle, ref)
    _rotate_away(p, vertex, angle, ref)

Rotate `p` around `vertex` by `angle` (radians), choosing the sign
(`angle` or `-angle`) that lands on the same side of line `(vertex, p)` as
`ref` (`_rotate_toward`) or on the opposite side (`_rotate_away`).
"""
function _rotate_toward(p::APPoint, vertex::APPoint, angle::Real, ref::APPoint)
    cand = rotate(p, angle, vertex)
    line = APLine(vertex, p)
    return side_of_line(cand, line) == side_of_line(ref, line) ? cand : rotate(p, -angle, vertex)
end
function _rotate_away(p::APPoint, vertex::APPoint, angle::Real, ref::APPoint)
    cand = rotate(p, angle, vertex)
    line = APLine(vertex, p)
    return side_of_line(cand, line) == side_of_line(ref, line) ? rotate(p, -angle, vertex) : cand
end
"""
    fermat_point(t::APTriangle)

The (first) Fermat point of `t`: the point minimizing the sum of distances
to the three vertices when every angle of `t` is below 120°. Constructed
as the common intersection of the segments joining each vertex to the apex
of the equilateral triangle erected outward on the opposite side.
"""
function fermat_point(t::APTriangle)
    A, B, C = t[1], t[2], t[3]
    A2, B2 = _rotate_away(C, B, pi / 3, A), _rotate_away(A, C, pi / 3, B)
    return only(intersection(APLine(A, A2), APLine(B, B2)))
end
"""
    second_fermat_point(t::APTriangle)

The second Fermat point of `t` (Kimberling center X(14), also called the
second isogonic center): constructed like [`fermat_point`](@ref) but with
the three equilateral triangles erected *inward* instead of outward. Equal
to the isogonal conjugate of one of the two [`isodynamic_points`](@ref) —
and, like them, degenerate for an equilateral triangle.
"""
function second_fermat_point(t::APTriangle)
    A, B, C = t[1], t[2], t[3]
    A2, B2 = _rotate_toward(C, B, pi / 3, A), _rotate_toward(A, C, pi / 3, B)
    return only(intersection(APLine(A, A2), APLine(B, B2)))
end
"""
    fermat_axis(t::APTriangle)

The line through the two [`fermat_point`](@ref)/[`second_fermat_point`](@ref).
"""
fermat_axis(t::APTriangle) = APLine(fermat_point(t), second_fermat_point(t))
"""
    napoleon_triangle(t::APTriangle; outward::Bool=true)

The (outer, by default) Napoleon triangle of `t`: the triangle formed by
the centroids of the equilateral triangles erected on each side of `t`
(outward by default; inward if `outward=false`). Always equilateral
(Napoleon's theorem).
"""
function napoleon_triangle(t::APTriangle; outward::Bool=true)
    A, B, C = t[1], t[2], t[3]
    rot = outward ? _rotate_away : _rotate_toward
    Aapex, Bapex, Capex = rot(C, B, pi / 3, A), rot(A, C, pi / 3, B), rot(B, A, pi / 3, C)
    return APTriangle(B + ((C - B) + (Aapex - B)) / 3, C + ((A - C) + (Bapex - C)) / 3, A + ((B - A) + (Capex - A)) / 3)
end
"""
    napoleon_point(t::APTriangle; outward::Bool=true)

The center of the (outer, by default) Napoleon triangle of `t` — which, by
Napoleon's theorem, coincides with the centroid of `t` itself.
"""
napoleon_point(t::APTriangle; outward::Bool=true) = centroid(napoleon_triangle(t; outward=outward))
"""
    square_inscribed(t::APTriangle, i::Integer)

The square inscribed in `t` with one side on `[t[j], t[k]]` (the side
opposite `t[i]`) and its other two vertices on the sides through `t[i]`.
Returns an `APQuadrilateral`, its 4 vertices in order starting from `t[j]`.
There are 3 such squares (one per side, hence the index `i ∈ 1:3`) —
their common side length is `a*h / (a+h)`, `a` the base length and `h` the
corresponding height, independent of how oblique the triangle is.
"""
function square_inscribed(t::APTriangle, i::Integer)
    others = ((2, 3), (1, 3), (1, 2))
    j, k = others[i]
    apex, Bv, Cv = t[i], t[j], t[k]
    u = direction(APLine(Bv, Cv)) / norm(direction(APLine(Bv, Cv)))
    foot = projection(apex, APLine(Bv, Cv))
    h = distance(apex, foot)
    a = distance(Bv, Cv)
    s = a * h / (a + h)
    x0 = dot(foot - Bv, u) * s / h
    w = (apex - foot) / h
    P1 = Bv + x0 * u
    P2 = Bv + (x0 + s) * u
    return APQuadrilateral(P1, P2, P2 + s * w, P1 + s * w)
end
"""
    morley_triangle(t::APTriangle)

The Morley triangle of `t`: formed by the intersections of adjacent
interior-angle trisectors. Always equilateral (Morley's trisector theorem).
"""
function morley_triangle(t::APTriangle)
    A, B, C = t[1], t[2], t[3]
    trisector_point(vertex, from, ref) = angle_trisectors(vertex, from, ref)[1].through
    Ma = only(intersection(APLine(B, trisector_point(B, C, A)), APLine(C, trisector_point(C, B, A))))
    Mb = only(intersection(APLine(C, trisector_point(C, A, B)), APLine(A, trisector_point(A, C, B))))
    Mc = only(intersection(APLine(A, trisector_point(A, B, C)), APLine(B, trisector_point(B, A, C))))
    return APTriangle(Ma, Mb, Mc)
end
"""
    spieker_circle(t::APTriangle)

The Spieker circle of `t`: the incircle of its medial triangle.
"""
spieker_circle(t::APTriangle) = incircle(medial_triangle(t))
function _circle_tangent_at(p1::APPoint, p2::APPoint, tpoint::APPoint, tline::APLine)
    center = only(intersection(perpendicular_through(tline, tpoint), perpendicular_bisector(p1, p2)))
    return APCircle2(center, distance(center, p1))
end
_other_point(pts, known::APPoint; atol=1e-9) = isapprox(pts[1], known; atol=atol) ? pts[2] : pts[1]
"""
    first_brocard_point(t::APTriangle)

The first Brocard point of `t`: the point `Ω` such that `∠ΩAB = ∠ΩBC = ∠ΩCA`
(the Brocard angle). Constructed as the second intersection of the circles
`(A,B)` tangent to `BC` at `B` and `(B,C)` tangent to `CA` at `C` (both
pass through `B`).
"""
function first_brocard_point(t::APTriangle)
    A, B, C = t[1], t[2], t[3]
    c1 = _circle_tangent_at(A, B, B, APLine(B, C))
    c2 = _circle_tangent_at(B, C, C, APLine(C, A))
    return _other_point(intersection(c1, c2), B)
end
"""
    second_brocard_point(t::APTriangle)

The second Brocard point of `t`: the point `Ω'` such that
`∠Ω'BA = ∠Ω'CB = ∠Ω'AC` (the same Brocard angle as [`first_brocard_point`](@ref)).
Constructed analogously, tangent at the other endpoint of each pair.
"""
function second_brocard_point(t::APTriangle)
    A, B, C = t[1], t[2], t[3]
    c1 = _circle_tangent_at(A, B, A, APLine(A, C))
    c2 = _circle_tangent_at(B, C, B, APLine(B, A))
    return _other_point(intersection(c1, c2), B)
end
"""
    brocard_angle(t::APTriangle)

The Brocard angle of `t`: the common value of `∠ΩAB = ∠ΩBC = ∠ΩCA` at the
first Brocard point.
"""
brocard_angle(t::APTriangle) = angle_at(t[1], first_brocard_point(t), t[2])
"""
    brocard_circle(t::APTriangle)

The Brocard circle of `t`: centered at the midpoint of the circumcenter and
the symmedian point, passing through both Brocard points (among others).
"""
function brocard_circle(t::APTriangle)
    center = midpoint(circumcenter(t), symmedian_point(t))
    return APCircle2(center, distance(center, first_brocard_point(t)))
end
"""
    brocard_midpoint(t::APTriangle)

The Brocard midpoint of `t` (Kimberling center X(39)): the midpoint of the
two [`first_brocard_point`](@ref) and [`second_brocard_point`](@ref).
"""
brocard_midpoint(t::APTriangle) = midpoint(first_brocard_point(t), second_brocard_point(t))
"""
    medial_triangle(t::APTriangle)

The medial triangle of `t`: its vertices are the midpoints of the sides of `t`.
"""
medial_triangle(t::APTriangle) = APTriangle(midpoint(t[2], t[3]), midpoint(t[1], t[3]), midpoint(t[1], t[2]))
"""
    anticomplementary_triangle(t::APTriangle)

The anticomplementary (antimedial) triangle of `t`: vertices `B+C-A`,
`C+A-B`, `A+B-C` — the inverse of [`medial_triangle`](@ref) (`t` is the
medial triangle of this one). Each vertex is the [`anticomplement`](@ref)
of the opposite one.
"""
anticomplementary_triangle(t::APTriangle) = APTriangle(t[2] + (t[3] - t[1]), t[3] + (t[1] - t[2]), t[1] + (t[2] - t[3]))
"""
    reflection_triangle(t::APTriangle)

The reflection triangle of `t`: each vertex reflected across its *opposite
side line* (distinct from [`orthic_triangle`](@ref), which projects onto
the opposite side instead of reflecting across it).
"""
function reflection_triangle(t::APTriangle)
    A, B, C = t[1], t[2], t[3]
    return APTriangle(reflection(A, APLine(B, C)), reflection(B, APLine(A, C)), reflection(C, APLine(A, B)))
end
"""
    orthic_triangle(t::APTriangle)

The orthic triangle of `t`: its vertices are the feet of the altitudes of `t`.
"""
function orthic_triangle(t::APTriangle)
    A, B, C = t[1], t[2], t[3]
    return APTriangle(projection(A, APLine(B, C)), projection(B, APLine(C, A)), projection(C, APLine(A, B)))
end
"""
    excentral_triangle(t::APTriangle)

The excentral triangle of `t`: its vertices are the three excenters of `t`.
"""
excentral_triangle(t::APTriangle) = (ec = excenters(t); APTriangle(ec.A, ec.B, ec.C))
"""
    contact_triangle(t::APTriangle)

The contact (intouch) triangle of `t`: its vertices are the points where
the incircle touches the sides of `t`.
"""
function contact_triangle(t::APTriangle)
    A, B, C = t[1], t[2], t[3]
    ic = incenter(t)
    return APTriangle(projection(ic, APLine(B, C)), projection(ic, APLine(C, A)), projection(ic, APLine(A, B)))
end
"""
    extouch_triangle(t::APTriangle)

The extouch triangle of `t`: its vertices are the points where each
excircle touches the corresponding side of `t`.
"""
function extouch_triangle(t::APTriangle)
    A, B, C = t[1], t[2], t[3]
    ec = excenters(t)
    return APTriangle(projection(ec.A, APLine(B, C)), projection(ec.B, APLine(C, A)), projection(ec.C, APLine(A, B)))
end
"""
    tangential_triangle(t::APTriangle)

The tangential triangle of `t`: its vertices are the pairwise intersections
of the lines tangent to the circumcircle of `t` at each vertex.
"""
function tangential_triangle(t::APTriangle)
    A, B, C = t[1], t[2], t[3]
    O = circumcenter(t)
    tA = perpendicular_through(APLine(O, A), A)
    tB = perpendicular_through(APLine(O, B), B)
    tC = perpendicular_through(APLine(O, C), C)
    return APTriangle(only(intersection(tB, tC)), only(intersection(tC, tA)), only(intersection(tA, tB)))
end
"""
    isogonal_conjugate(t::APTriangle, p::APPoint)

The isogonal conjugate of `p` with respect to `t`: reflect each cevian
`vertex -> p` across the internal angle bisector at that vertex; the three
reflected lines concur at the isogonal conjugate. An involution
(`isogonal_conjugate(t, isogonal_conjugate(t, p)) == p`) that sends
orthocenter ↔ circumcenter, centroid ↔ symmedian point, and fixes the
incenter.
"""
function isogonal_conjugate(t::APTriangle, p::APPoint)
    A, B, C = t[1], t[2], t[3]
    reflect_cevian(vertex, s1, s2) = reflection(APLine(vertex, p), angle_bisectors(APLine(vertex, s1), APLine(vertex, s2))[1])
    return only(intersection(reflect_cevian(A, B, C), reflect_cevian(B, C, A)))
end
"""
    isotomic_conjugate(t::APTriangle, p::APPoint)

The isotomic conjugate of `p` with respect to `t`: reflect, for each side,
the point where cevian `vertex -> p` meets that side across the side's
midpoint; the three cevians through the reflected points concur at the
isotomic conjugate. An involution that fixes the centroid.
"""
function isotomic_conjugate(t::APTriangle, p::APPoint)
    A, B, C = t[1], t[2], t[3]
    function reflected_cevian(vertex, s1, s2)
        foot = only(intersection(APLine(s1, s2), APLine(vertex, p)))
        return APLine(vertex, reflection(foot, midpoint(s1, s2)))
    end
    return only(intersection(reflected_cevian(A, B, C), reflected_cevian(B, C, A)))
end
"""
    macbeath_point(t::APTriangle)

The MacBeath point of `t` (Kimberling center X(264)): the isotomic
conjugate of the [`circumcenter`](@ref). It is the Brianchon point of the
MacBeath inconic (the inconic with foci at the circumcenter and the
orthocenter).
"""
macbeath_point(t::APTriangle) = isotomic_conjugate(t, circumcenter(t))
"""
    complement(t::APTriangle, p::APPoint)

The complement of `p` with respect to `t`: `p` homothetically shrunk by
`-1/2` about the [`centroid`](@ref). Sends each vertex to the midpoint of
the opposite side (i.e. to the corresponding vertex of the
[`medial_triangle`](@ref)).
"""
complement(t::APTriangle, p::APPoint) = homothety(p, -0.5, centroid(t))
"""
    anticomplement(t::APTriangle, p::APPoint)

The anticomplement of `p` with respect to `t`: `p` homothetically expanded
by `-2` about the [`centroid`](@ref) — the inverse of [`complement`](@ref).
Sends each vertex to the corresponding vertex of the
[`anticomplementary_triangle`](@ref).
"""
anticomplement(t::APTriangle, p::APPoint) = homothety(p, -2.0, centroid(t))
"""
    pedal_triangle(t::APTriangle, p::APPoint)

The pedal triangle of `p` with respect to `t`: the feet of the
perpendiculars from `p` to the three side-lines of `t`. Generalizes
[`orthic_triangle`](@ref) (pedal triangle of the orthocenter) and
[`contact_triangle`](@ref) (pedal triangle of the incenter).
"""
function pedal_triangle(t::APTriangle, p::APPoint)
    A, B, C = t[1], t[2], t[3]
    return APTriangle(projection(p, APLine(B, C)), projection(p, APLine(C, A)), projection(p, APLine(A, B)))
end
"""
    pedal_circle(t::APTriangle, p::APPoint)

The pedal circle of `p` with respect to `t`: the circumcircle of
[`pedal_triangle`](@ref)`(t, p)`.
"""
pedal_circle(t::APTriangle, p::APPoint) = circumcircle(pedal_triangle(t, p))
"""
    cevian_triangle(t::APTriangle, p::APPoint)

The cevian triangle of `p` with respect to `t`: where each cevian
`vertex -> p` meets the opposite side. Generalizes [`medial_triangle`](@ref)
(cevian triangle of the centroid).
"""
function cevian_triangle(t::APTriangle, p::APPoint)
    A, B, C = t[1], t[2], t[3]
    return APTriangle(only(intersection(APLine(B, C), APLine(A, p))),
        only(intersection(APLine(C, A), APLine(B, p))),
        only(intersection(APLine(A, B), APLine(C, p))))
end
"""
    circumcevian_triangle(t::APTriangle, p::APPoint)

The circumcevian triangle of `p` with respect to `t`: where each cevian
`vertex -> p`, extended, meets the circumcircle of `t` again.
"""
function circumcevian_triangle(t::APTriangle, p::APPoint)
    cc = circumcircle(t)
    second(vertex) = _other_point(intersection(APLine(vertex, p), cc), vertex)
    return APTriangle(second(t[1]), second(t[2]), second(t[3]))
end
"""
    mixtilinear_incircle(t::APTriangle, i::Integer; atol=1e-9)

The mixtilinear incircle at vertex `t[i]` (`i` in `1:3`): the circle
tangent to the two sides of `t` through that vertex, and internally
tangent to the circumcircle of `t`. Built by reusing [`tangent_circles`](@ref)
(the `CLL` Apollonius case) and picking, among its up to 4 solutions, the
one nestled inside the vertex's angle with internal circumcircle tangency.
"""
function mixtilinear_incircle(t::APTriangle, i::Integer; atol=1e-9)
    vertex, other1, other2 = t[i], t[mod1(i + 1, 3)], t[mod1(i + 2, 3)]
    l1, l2 = APLine(vertex, other1), APLine(vertex, other2)
    cc = circumcircle(t)
    for s in tangent_circles(l1, l2, cc; atol=atol)
        side_of_line(s.center, l1) == side_of_line(other2, l1) &&
            side_of_line(s.center, l2) == side_of_line(other1, l2) &&
            _encloses(cc, s; atol=atol) &&
            return s
    end
    error("mixtilinear_incircle: no valid solution found")
end
"""
    thebault_circles(t::APTriangle, p::APPoint; atol=1e-9)

The two Thébault circles of `t` for a point `p` on side `[t[2], t[3]]`
(the side opposite `t[1]`): each is tangent to the cevian `t[1] -> p`, to
the side `[t[2], t[3]]`, and internally tangent to the circumcircle of
`t` — one nestled against `t[2]`, the other against `t[3]`. Returned as a
named tuple `(near_b=..., near_c=...)`. By the Sawayama–Thébault theorem,
the incenter of `t` always lies on the segment joining their two centers.
Built the same way as [`mixtilinear_incircle`](@ref), by reusing
[`tangent_circles`](@ref) (the `CLL` Apollonius case).
"""
function thebault_circles(t::APTriangle, p::APPoint; atol=1e-9)
    A, B, C = t[1], t[2], t[3]
    cevian, side_line = APLine(A, p), APLine(B, C)
    cc = circumcircle(t)
    near_b, near_c = nothing, nothing
    for s in tangent_circles(cevian, side_line, cc; atol=atol)
        (side_of_line(s.center, side_line) == side_of_line(A, side_line) &&
         _encloses(cc, s; atol=atol)) || continue
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
    three_apollonius_circles(t::APTriangle)

The three (vertex) Apollonius circles of `t`, as a 3-tuple `(circ_a, circ_b,
circ_c)`: `circ_a` is the locus of points whose distances to `B` and `C`
are in the ratio `AB:AC` (so it passes through `A`), and likewise for
`circ_b` (through `B`) and `circ_c` (through `C`). All three pass through
the two [`isodynamic_points`](@ref) of `t`. Throws an `ArgumentError` for
an equilateral triangle (each Apollonius circle then degenerates to a line).
"""
function three_apollonius_circles(t::APTriangle)
    A, B, C = t[1], t[2], t[3]
    a, b, c = _side_lengths(t)
    return (apollonius_circle(B, C, c / b), apollonius_circle(C, A, a / c), apollonius_circle(A, B, b / a))
end
"""
    isodynamic_points(t::APTriangle)

The two isodynamic points of `t`, as a 2-tuple: the common points of its
[`three_apollonius_circles`](@ref) (for each vertex, the locus of points
whose distances to the other two vertices are in the same ratio as the two
sides meeting at that vertex). Throws an `ArgumentError` for an equilateral
triangle (the Apollonius circles degenerate to lines).
"""
function isodynamic_points(t::APTriangle)
    circ_a, circ_b, _ = three_apollonius_circles(t)
    pts = intersection(circ_a, circ_b)
    return (pts[1], pts[2])
end
"""
    apollonius_circle_of_triangle(t::APTriangle; atol=1e-9)

The Apollonius circle of `t`: the circle tangent to and enclosing all
three [`excircles`](@ref) of `t` -- one of up to 8 solutions to the
classical Apollonius `CCC` problem ([`tangent_circles`](@ref)) applied to
the three excircles, picked out as the one with all three inside it.
Not to be confused with [`apollonius_circle`](@ref)/
[`three_apollonius_circles`](@ref) (the two-point/three-vertex Apollonius
*problem*, unrelated beyond sharing Apollonius' name).
"""
function apollonius_circle_of_triangle(t::APTriangle; atol=1e-9)
    ec = excircles(t)
    sols = tangent_circles(ec.A, ec.B, ec.C; atol=atol)
    idx = findfirst(s -> _encloses(s, ec.A; atol=atol) && _encloses(s, ec.B; atol=atol) && _encloses(s, ec.C; atol=atol), sols)
    idx === nothing && error("apollonius_circle_of_triangle: no circle enclosing all three excircles was found")
    return sols[idx]
end
"""
    apollonius_point_of_triangle(t::APTriangle; atol=1e-9)

The Apollonius point of `t` (Kimberling X(181)): let `E` be
[`apollonius_circle_of_triangle`](@ref)`(t)`. For each excircle, the line
from its *own* vertex (the one it's opposite, e.g. [`excircles`](@ref)`(t).A`
and `t[1]`) through its point of tangency with `E` -- all three such
lines meet at this point.
"""
function apollonius_point_of_triangle(t::APTriangle; atol=1e-9)
    ec = excircles(t)
    E = apollonius_circle_of_triangle(t; atol=atol)
    lA = APLine(t[1], _tangency_point(E, ec.A))
    lB = APLine(t[2], _tangency_point(E, ec.B))
    return only(intersection(lA, lB; atol=atol))
end
"""
    orthopole(l::APLine, t::APTriangle)

The orthopole of `l` with respect to `t`: project each vertex of `t` onto
`l`, then draw through each projection the perpendicular to the side
opposite that vertex; the three perpendiculars concur at the orthopole.
"""
function orthopole(l::APLine, t::APTriangle)
    A, B, C = t[1], t[2], t[3]
    lA = perpendicular_through(APLine(B, C), projection(A, l))
    lB = perpendicular_through(APLine(C, A), projection(B, l))
    return only(intersection(lA, lB))
end
"""
    poncelet_point(t::APTriangle, p::APPoint; atol=1e-9)

The Poncelet point of `t` and a 4th point `p`: for any 4 points in general
position, the nine-point circles of the 4 triangles formed by leaving out
one of them always share a common point.
"""
function poncelet_point(t::APTriangle, p::APPoint; atol=1e-9)
    A, B, C = t[1], t[2], t[3]
    npc_a = nine_point_circle(APTriangle(B, C, p))
    npc_b = nine_point_circle(APTriangle(A, C, p))
    npc_c = nine_point_circle(APTriangle(A, B, p))
    tol = sqrt(atol) * max(npc_a.r, npc_b.r, npc_c.r, 1.0)
    for cand in intersection(npc_a, npc_b; atol=atol)
        abs(distance(cand, npc_c.center) - npc_c.r) <= tol && return cand
    end
    error("poncelet_point: could not find a common point of the nine-point circles")
end
"""
    conway_points(t::APTriangle)

The 6 Conway points of `t`, as a 6-tuple: at each vertex, extend both
sides meeting there beyond that vertex by the length of the side opposite
it. All 6 lie on the [`conway_circle`](@ref).
"""
function conway_points(t::APTriangle)
    A, B, C = t[1], t[2], t[3]
    a, b, c = _side_lengths(t)
    ext(v, other, d) = v + (d / distance(v, other)) * (v - other)
    return (ext(A, B, a), ext(A, C, a), ext(B, A, b), ext(B, C, b), ext(C, B, c), ext(C, A, c))
end
"""
    conway_circle(t::APTriangle)

The Conway circle of `t`: centered at the incenter, passing through the 6
[`conway_points`](@ref). Its radius is `sqrt(inradius(t)^2 + s^2)` where
`s` is the semiperimeter.
"""
conway_circle(t::APTriangle) = APCircle2(incenter(t), distance(incenter(t), conway_points(t)[1]))
"""
    taylor_points(t::APTriangle)

The 6 points of the Taylor configuration, as a 6-tuple: project each
vertex of the [`orthic_triangle`](@ref) onto each of the two sides of `t`
*not* used to define it. All 6 are always concyclic, on the
[`taylor_circle`](@ref).
"""
function taylor_points(t::APTriangle)
    A, B, C = t[1], t[2], t[3]
    oh = orthic_triangle(t)
    return (projection(oh[1], APLine(A, B)), projection(oh[1], APLine(C, A)),
        projection(oh[2], APLine(B, C)), projection(oh[2], APLine(A, B)),
        projection(oh[3], APLine(C, A)), projection(oh[3], APLine(B, C)))
end
"""
    taylor_circle(t::APTriangle)

The Taylor circle of `t`: the common circle through the 6
[`taylor_points`](@ref) (any 3 of them already determine it).
"""
function taylor_circle(t::APTriangle)
    d, _, e, _, f, _ = taylor_points(t)
    return circumcircle(APTriangle(d, e, f))
end
"""
    first_lemoine_points(t::APTriangle)

6 points, as a 6-tuple: through the symmedian point, draw the line
parallel to each side, and take its intersections with the *other* two
sides. All 6 lie on the [`first_lemoine_circle`](@ref).
"""
function first_lemoine_points(t::APTriangle)
    A, B, C = t[1], t[2], t[3]
    lp = symmedian_point(t)
    p_ab = parallel_through(APLine(A, B), lp)
    p_bc = parallel_through(APLine(B, C), lp)
    p_ca = parallel_through(APLine(C, A), lp)
    return (only(intersection(p_ab, APLine(A, C))), only(intersection(p_ab, APLine(B, C))),
        only(intersection(p_bc, APLine(B, A))), only(intersection(p_bc, APLine(C, A))),
        only(intersection(p_ca, APLine(C, B))), only(intersection(p_ca, APLine(A, B))))
end
"""
    first_lemoine_circle(t::APTriangle)

The first Lemoine circle of `t`: centered at the midpoint of the
circumcenter and the symmedian point, passing through the 6
[`first_lemoine_points`](@ref).
"""
function first_lemoine_circle(t::APTriangle)
    center = midpoint(circumcenter(t), symmedian_point(t))
    return APCircle2(center, distance(center, first_lemoine_points(t)[1]))
end
"""
    adams_points(t::APTriangle)

6 points, as a 6-tuple: through the Gergonne point, draw the line
parallel to each side of [`contact_triangle`](@ref)`(t)`, and take its
intersections with the two sides of `t` adjacent to the corresponding
vertex. All 6 lie on the [`adams_circle`](@ref) (a classical theorem).
"""
function adams_points(t::APTriangle)
    A, B, C = t[1], t[2], t[3]
    g = gergonne_point(t)
    m, l, n = contact_triangle(t)   # touch points on BC, CA, AB
    lx = parallel_through(APLine(m, n), g)
    ly = parallel_through(APLine(n, l), g)
    lz = parallel_through(APLine(m, l), g)
    return (only(intersection(lx, APLine(A, B))), only(intersection(ly, APLine(A, B))),
        only(intersection(lz, APLine(B, C))), only(intersection(lx, APLine(B, C))),
        only(intersection(ly, APLine(A, C))), only(intersection(lz, APLine(A, C))))
end
"""
    adams_circle(t::APTriangle)

The Adams circle of `t`: centered at the incenter, passing through the 6
[`adams_points`](@ref).
"""
function adams_circle(t::APTriangle)
    ic = incenter(t)
    return APCircle2(ic, distance(ic, adams_points(t)[1]))
end
"""
    van_lamoen_points(t::APTriangle)

The 6 circumcenters of the sub-triangles that the three medians of `t` cut
it into (each an area formed by one vertex, one non-adjacent side midpoint,
and the [`centroid`](@ref)), as a 6-tuple. A classical theorem states these
6 points are always concyclic — see [`van_lamoen_circle`](@ref).
"""
function van_lamoen_points(t::APTriangle)
    A, B, C = t[1], t[2], t[3]
    Ma, Mb, Mc = midpoint(B, C), midpoint(A, C), midpoint(A, B)
    G = centroid(t)
    return (circumcenter(APTriangle(A, Mc, G)), circumcenter(APTriangle(B, Ma, G)),
        circumcenter(APTriangle(B, Mc, G)), circumcenter(APTriangle(C, Mb, G)),
        circumcenter(APTriangle(C, Ma, G)), circumcenter(APTriangle(A, Mb, G)))
end
"""
    van_lamoen_circle(t::APTriangle)

The Van Lamoen circle of `t`: the common circle through the 6
[`van_lamoen_points`](@ref).
"""
function van_lamoen_circle(t::APTriangle)
    A, B, C = t[1], t[2], t[3]
    Ma, Mb, Mc = midpoint(B, C), midpoint(A, C), midpoint(A, B)
    G = centroid(t)
    p1 = circumcenter(APTriangle(A, Mb, G))
    p2 = circumcenter(APTriangle(B, Ma, G))
    p3 = circumcenter(APTriangle(C, Ma, G))
    return circumcircle(APTriangle(p1, p2, p3))
end
"""
    second_lemoine_circle(t::APTriangle)

The second Lemoine (cosine) circle of `t`: centered at the symmedian
point, with radius `a*b*c / (a^2+b^2+c^2)`.
"""
function second_lemoine_circle(t::APTriangle)
    a, b, c = _side_lengths(t)
    return APCircle2(symmedian_point(t), a * b * c / (a^2 + b^2 + c^2))
end
"""
    symmedial_circle(t::APTriangle)

The symmedial circle of `t`: the circumcircle of
[`cevian_triangle`](@ref)`(t, symmedian_point(t))`.
"""
symmedial_circle(t::APTriangle) = circumcircle(cevian_triangle(t, symmedian_point(t)))
"""
    three_tangent_circles(t::APTriangle)

The three circles centered at the vertices of `t`, each with radius equal
to the tangent length from that vertex to the incircle (`s - a` at the
vertex opposite side `a`, etc., `s` the semiperimeter). Every pair is
externally tangent — e.g. `distance(A, B) == (s-a) + (s-b) == c` — meeting
exactly at the point where the incircle touches the side between them.
These are the starting configuration [`soddy_circles`](@ref) is built from.
"""
function three_tangent_circles(t::APTriangle)
    A, B, C = t[1], t[2], t[3]
    a, b, c = _side_lengths(t)
    s = (a + b + c) / 2
    return (APCircle2(A, s - a), APCircle2(B, s - b), APCircle2(C, s - c))
end
"""
    soddy_circles(t::APTriangle; atol=1e-9)

The two Soddy circles of `t`, as `(inner=..., outer=...)`: build the three
mutually tangent circles centered at the vertices with radii `s-a`, `s-b`,
`s-c` (`s` the semiperimeter, see [`three_tangent_circles`](@ref)), then
find their common tangent circles (the classical Apollonius `CCC` problem,
[`tangent_circles`](@ref)) other than the three vertex circles themselves
— the smaller one nestled between them is `inner`, the larger one
enclosing them is `outer`.
"""
function soddy_circles(t::APTriangle; atol=1e-9)
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
    soddy_line(t::APTriangle; atol=1e-9)

The Soddy line of `t`: the line through the centers of its two
[`soddy_circles`](@ref) (inner and outer).
"""
function soddy_line(t::APTriangle; atol=1e-9)
    sc = soddy_circles(t; atol=atol)
    return APLine(sc.inner.center, sc.outer.center)
end
"""
    soddy_center(t::APTriangle; outer::Bool=false, atol=1e-9)

The center of `t`'s inner (`outer=false`, the default) or outer
(`outer=true`) [`soddy_circles`](@ref) circle, as a point on its own
(Kimberling X(176) and X(175) respectively).
"""
function soddy_center(t::APTriangle; outer::Bool=false, atol=1e-9)
    sc = soddy_circles(t; atol=atol)
    return outer ? sc.outer.center : sc.inner.center
end
"""
    soddy_points(t::APTriangle; atol=1e-9)

Both Soddy centers of `t`, as `(inner=..., outer=...)`: the point-only
analogue of [`soddy_circles`](@ref).
"""
function soddy_points(t::APTriangle; atol=1e-9)
    sc = soddy_circles(t; atol=atol)
    return (inner=sc.inner.center, outer=sc.outer.center)
end
"""
    simson_line(t::APTriangle, p::APPoint)

The Simson line of `p` with respect to `t`: the line through the feet of
the perpendiculars from `p` to the three side-lines of `t`. These feet are
only guaranteed to be collinear when `p` lies on the circumcircle of `t`.
"""
function simson_line(t::APTriangle, p::APPoint)
    f1 = projection(p, APLine(t[1], t[2]))
    f2 = projection(p, APLine(t[2], t[3]))
    return APLine(f1, f2)
end
"""
    steiner_inellipse(t::APTriangle)

The Steiner inellipse of `t`: the unique ellipse centered at [`centroid`](@ref)
that is tangent to the three sides of `t` at their midpoints (it is the
ellipse of maximum area inscribed in `t`). Its foci are found via Marden's
theorem: representing the vertices of `t` as complex numbers `z1, z2, z3`,
the foci are the two roots of the derivative of `(z-z1)*(z-z2)*(z-z3)`.
"""
function steiner_inellipse(t::APTriangle)
    A, B, C = t[1], t[2], t[3]
    z1, z2, z3 = complex(A[1], A[2]), complex(B[1], B[2]), complex(C[1], C[2])
    s, sp = z1 + z2 + z3, z1 * z2 + z1 * z3 + z2 * z3
    disc = sqrt(s^2 - 3sp)
    f1, f2 = (s + disc) / 3, (s - disc) / 3
    F1, F2 = APPoint(real(f1), imag(f1)), APPoint(real(f2), imag(f2))
    return APEllipse2(F1, F2, midpoint(A, B))
end
"""
    steiner_circumellipse(t::APTriangle)

The Steiner circumellipse of `t`: the unique ellipse centered at
[`centroid`](@ref) that passes through the three vertices of `t` (it is the
ellipse of minimum area circumscribing `t`). Constructed via
[`conic_through_points`](@ref) using the three vertices together with the
reflections of two of them across the centroid (also on the ellipse, since
it's centrally symmetric about its center).
"""
function steiner_circumellipse(t::APTriangle)
    A, B, C = t[1], t[2], t[3]
    g = centroid(t)
    return conic_through_points(A, B, C, reflection(A, g), reflection(B, g))
end
"""
    kiepert_hyperbola(t::APTriangle)

The Kiepert hyperbola of `t`: the unique **rectangular** hyperbola through
`t`'s three vertices, its [`centroid`](@ref) and its [`orthocenter`](@ref)
(centered at Kimberling center X(115)). Built via [`conic_through_points`](@ref)
on those 5 points directly, since a conic is uniquely determined by 5
points and this one is already known to pass through all 5 — no need to
construct its axes/asymptotes by hand first.
"""
kiepert_hyperbola(t::APTriangle) = conic_through_points(t[1], t[2], t[3], centroid(t), orthocenter(t))
"""
    kiepert_parabola(t::APTriangle)

The Kiepert parabola of `t`: focus at Kimberling center X(110)
(`trilinear(a/(b²-c²), b/(c²-a²), c/(a²-b²))`), directrix the
[`euler_line`](@ref). Throws an `ArgumentError` if `t` is isosceles (X(110)
is undefined then).
"""
function kiepert_parabola(t::APTriangle)
    a, b, c = _side_lengths(t)
    any(isapprox.((a, b, c), (b, c, a))) &&
        throw(ArgumentError("kiepert_parabola: undefined for an isosceles triangle"))
    focus = trilinear_point(t, a / (b^2 - c^2), b / (c^2 - a^2), c / (a^2 - b^2))
    return APParabola2(focus, euler_line(t))
end
"""
    lemoine_inellipse(t::APTriangle)

The Lemoine inellipse of `t`: the bifocal ellipse with foci at the
[`centroid`](@ref) and [`symmedian_point`](@ref), passing through the
`t[1]`-side vertex of the cevian triangle of Kimberling center X(598).
"""
function lemoine_inellipse(t::APTriangle)
    a, b, c = _side_lengths(t)
    x598 = trilinear_point(t, b * c / (a^2 - 2b^2 - 2c^2), c * a / (b^2 - 2c^2 - 2a^2), a * b / (c^2 - 2a^2 - 2b^2))
    through = cevian_triangle(t, x598)[1]
    return APEllipse2(centroid(t), symmedian_point(t), through)
end
"""
    brocard_inellipse(t::APTriangle)

The Brocard inellipse of `t`: the bifocal ellipse with foci at the second
and first [`first_brocard_point`](@ref)/[`second_brocard_point`](@ref) (in
that order), passing through the `t[1]`-side vertex of the cevian triangle
of the [`symmedian_point`](@ref).
"""
function brocard_inellipse(t::APTriangle)
    through = cevian_triangle(t, symmedian_point(t))[1]
    return APEllipse2(second_brocard_point(t), first_brocard_point(t), through)
end
"""
    macbeath_inellipse(t::APTriangle)

The MacBeath inellipse of `t`: the bifocal ellipse with foci at the
[`circumcenter`](@ref) and [`orthocenter`](@ref), passing through the
`t[1]`-side vertex of the cevian triangle of the [`macbeath_point`](@ref).
Only defined (as a real ellipse) when `t` has no obtuse angle.
"""
function macbeath_inellipse(t::APTriangle)
    through = cevian_triangle(t, macbeath_point(t))[1]
    return APEllipse2(circumcenter(t), orthocenter(t), through)
end
"""
    mandart_inellipse(t::APTriangle)

The Mandart inellipse of `t`: centered at the [`mittenpunkt`](@ref),
tangent to the three sides at the [`extouch_triangle`](@ref)'s vertices.
Built via [`conic_through_points`](@ref) on those 3 vertices together with
2 of their point-reflections through the mittenpunkt (also on the ellipse,
since it's centrally symmetric about its own center).
"""
function mandart_inellipse(t::APTriangle)
    m = mittenpunkt(t)
    et = extouch_triangle(t)
    return conic_through_points(reflection(et[1], m), reflection(et[2], m), et[1], et[2], et[3])
end
"""
    orthic_inellipse(t::APTriangle)

The orthic inellipse of `t`: centered at the [`symmedian_point`](@ref),
tangent to the three sides at the [`orthic_triangle`](@ref)'s vertices
(the altitude feet). Built the same way as [`mandart_inellipse`](@ref), via
[`conic_through_points`](@ref). Only defined (as a real ellipse) when `t`
has no obtuse angle.
"""
function orthic_inellipse(t::APTriangle)
    k = symmedian_point(t)
    ot = orthic_triangle(t)
    return conic_through_points(reflection(ot[1], k), reflection(ot[2], k), ot[1], ot[2], ot[3])
end
