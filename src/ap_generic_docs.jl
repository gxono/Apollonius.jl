@doc """
    rotate(obj, angle, center=APPoint(0.0, 0.0))

Rotate `obj` counterclockwise by `angle` radians around `center`. Works on
every geometric type in the package: points and vectors, lines, rays,
segments, polylines, every conic and conic arc, angles, half-planes and
strips, every polygon and curved region, parametric curves, and vectors of
these (each element is rotated). One of the four transformations
([`rotate`](@ref), [`homothety`](@ref), [`reflection`](@ref),
[`translate`](@ref)) implemented uniformly across the whole package; see
[`APAffineMap`](@ref) for the general linear case.
""" rotate

@doc """
    homothety(obj, k, center=APPoint(0.0, 0.0))

Scale `obj` by the ratio `k` about `center` (`k = -1` is a point
reflection, `0 < k < 1` shrinks towards `center`). Defined for every
geometric type, exactly like [`rotate`](@ref). Radii and semi-axes scale by
`abs(k)`.
""" homothety

@doc """
    reflection(obj, about)

Reflect `obj` through `about`: a point (point symmetry) or an
[`APLine`](@ref) (mirror image across the line). Defined for every
geometric type, exactly like [`rotate`](@ref). Reflecting across a line
reverses orientation, so oriented objects ([`APAngle2`](@ref), circular
and elliptic arcs) swap their endpoints internally to stay a true mirror
image with the same `measure`.
""" reflection

@doc """
    translate(obj, v::APVector)

Shift `obj` by the vector `v`. Defined for every geometric type, exactly
like [`rotate`](@ref), but with no center: a translation has none.
""" translate

@doc """
    intersection(a, b; atol=1e-9)

The intersection points of two geometric objects, as a `Vector` of
[`APPoint`](@ref)s (empty when they don't meet). Defined for these
combinations, in both argument orders:

| First | Second |
|:------|:-------|
| [`APLine`](@ref), [`APSegment`](@ref), [`APRay`](@ref) | each other, and any [`APCircle2`](@ref), [`APEllipse2`](@ref), [`APHyperbola2`](@ref), [`APParabola2`](@ref) |
| any conic | any other conic (up to 4 points; two circles use their own exact method) |
| any conic arc | a line, segment, ray, full conic, or another arc of any type (only the points on the arc are kept) |
| a polyline, polygon, chain, bounding box, angle, half-plane or strip | anything above, and each other: the points where the curves (the sides, or the boundary) meet |
| an [`APParametricCurve2`](@ref) | a line, segment, ray, conic, conic arc, or any composite above (found by sampling) |
| an [`APPoint`](@ref) | any curve or boundary above, and another point: `[p]` if it lies on it |

Two coincident curves return an empty vector rather than infinitely many
points. Segments and rays keep only the points within their own extent.
""" intersection

@doc """
    distance(a, b)

The distance between two geometric objects: the plain Euclidean distance
for two points, and the shortest distance otherwise (`0` if they touch).
A point to a line, segment, ray, circle, conic, conic arc, polyline or
polygon boundary; two lines, segments or circles to each other. The
`APSet` types ([`APAngle2`](@ref), [`APHalfPlane2`](@ref),
[`APStrip2`](@ref)) accept `mode = :region` (default, `0` inside) or
`mode = :boundary`.
""" distance

@doc """
    area(obj)

The area enclosed by `obj`: any [`APPolygon`](@ref) (triangles,
quadrilaterals, straight or curvilinear n-gons, sectors, segments,
annular sectors, interstices), or a full [`APCircle2`](@ref) or
[`APEllipse2`](@ref).
""" area

@doc """
    perimeter(obj)

The length of the boundary of `obj`: any [`APPolygon`](@ref), or a full
[`APCircle2`](@ref) or [`APEllipse2`](@ref). For an open curve, see
[`arc_length`](@ref).
""" perimeter

@doc """
    normalize(v)

`v` scaled to unit length, for an [`APVector`](@ref) or [`APPoint`](@ref)
(taken as a vector from the origin), or an [`APEquipollentVector`](@ref)
(which keeps its point of application). Re-exported from `LinearAlgebra`
so `using Apollonius` alone is enough.
""" normalize

@doc """
    dot(u, v)

The dot product of two [`APVector`](@ref)s or [`APPoint`](@ref)s (taken as
vectors from the origin), also accepting an [`APEquipollentVector`](@ref)
in either position. Re-exported from `LinearAlgebra`.
""" dot

@doc """
    midpoint(a, b)
    midpoint(obj)

The midpoint of two points, or the middle of a single object: an
[`APSegment`](@ref), or a circular, elliptic, parabolic or hyperbolic arc
(the point halfway along its own parametrization, see [`point_on`](@ref)).
""" midpoint

@doc """
    direction(obj)

The non-normalized direction of an [`APLine`](@ref), [`APRay`](@ref) or
[`APSegment`](@ref) (`p2 - p1`), the vector of an
[`APEquipollentVector`](@ref), or an [`APVector`](@ref) itself, as an [`APVector`](@ref). Use
`normalize(direction(obj))` for the unit vector.
""" direction

@doc """
    point_on(arc, t)

The point at parameter `t` along `arc`, with `t = 0` at `arc.p1` and
`t = 1` at `arc.p2`. Defined for all four arc types
([`APCircularArc2`](@ref), [`APEllipticArc2`](@ref),
[`APParabolicArc2`](@ref), [`APHyperbolicArc2`](@ref)); for the last three
`t` follows the conic's own parametrization, not arc length.
""" point_on

@doc """
    vertices(obj)

The corner points of `obj`, in order: any polygon, a polyline, or the
single vertex of a parabola (as a 1-tuple, so the name works uniformly
across every conic that has one). For curved regions, the starting point of
each side.
""" vertices

@doc """
    sides(obj)

The sides of `obj`, in order: straight [`APSegment`](@ref)s for a polygon
or polyline, and a mix of segments and arcs for a curved region (sector,
segment, annular sector, interstice, curvilinear n-gon). Every generic
polygon function (`area`, `perimeter`, `centroid`...) is built on this.
""" sides

@doc """
    tangent_points(shape, p; atol=1e-9)

The points of tangency on `shape` of the lines through `p` tangent to it:
`0` points if `p` is strictly inside, `1` if `p` is on `shape`, `2` if
outside. `shape` is an [`APCircle2`](@ref), [`APEllipse2`](@ref),
[`APHyperbola2`](@ref) or [`APParabola2`](@ref), in either argument order.
""" tangent_points

@doc """
    tangent_lines(shape, p; atol=1e-9)

The line(s) through `p` tangent to `shape` (see [`tangent_points`](@ref)).
When `p` is on `shape`, this is the single tangent line at `p`. Defined for
the same four conics, in either argument order.
""" tangent_lines

@doc """
    tangent_circles(a, b, c; atol=1e-9)
    tangent_circles(a, b, p::APPoint; atol=1e-9)
    tangent_circles(p1::APPoint, p2::APPoint, x; atol=1e-9)

The circles tangent to `a`, `b`, `c` (each a line or [`APCircle2`](@ref)):
the classical Apollonius problem, up to 8 solutions, fewer for degenerate
configurations. Which of the three arguments are points, rather than a
line or a circle, decides which of the ten classical Apollonius problems
this solves, all under the one name: none (the plain tangency-to-three
case above), one (the circles tangent to the other two and passing
through that point), or two (the circles tangent to the remaining one and
passing through both points). See [`tangent_circles_with_radius`](@ref)
and [`tangent_circles_with_center`](@ref) for the cases where a radius or
a center is fixed instead of a tangency condition.
""" tangent_circles

@doc """
    tangent_circles_with_radius(a, b, r; atol=1e-9)

The circles of radius `r` tangent to both `a` and `b` (each a line or
[`APCircle2`](@ref)).
""" tangent_circles_with_radius
