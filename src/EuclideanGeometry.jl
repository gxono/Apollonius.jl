module EuclideanGeometry

using LinearAlgebra: norm, dot, normalize, nullspace
import LinearAlgebra

# The EGPoint/EGVector primitives and the abstract type hierarchy
# (EGObject/EGLocus/EGCurve/EGSet/EGRegion/EGPolygon/EGTransform) that
# everything else in the package builds on.
include("eg_point.jl")
export EGObject, EGLocus, EGCurve, EGSet, EGRegion, EGPolygon, EGTransform
export EGPoint, EGVector

include("eg_primitives.jl")
export EGSegment, EGLine, EGRay, EGBoundingBox

include("eg_polygon.jl")
export EGTriangle, EGQuadrilateral, EGStraightNgon

include("eg_conic.jl")
export EGCircle2, EGEllipse2, EGParabola2, EGHyperbola2
export EGCircularArc2, EGEllipticArc2, EGParabolicArc2, EGHyperbolicArc2

# intersection/polar_line/tangent_points/tangent_lines for
# EGEllipse2/EGHyperbola2/EGParabola2 — split out from eg_conic.jl since
# they need `intersection` on lines/circles, defined later in this file.
include("eg_conic_tangency.jl")

include("eg_curved_region.jl")
export EGCircularSector2, EGCircularSegment2, EGAnnularSector2, EGInterstice2
export EGCurvilinearTriangle2, EGCurvilinearQuadrilateral2, EGCurvilinearNgon2

include("eg_unbounded.jl")
export EGAngle2, EGHalfPlane2, EGStrip2, strip_width

include("eg_transform.jl")
export EGAffineMap

include("eg_predicates.jl")
include("eg_intersections.jl")

using Base.MathConstants: golden

include("eg_constructions.jl")
include("eg_tangency.jl")
include("eg_radical_axis.jl")
include("eg_inversion.jl")
include("eg_apollonius.jl")
include("eg_named_polygons.jl")
include("eg_triangle_on_segment.jl")
include("eg_conic_fit.jl")

# Every named triangle center, axis, circle and derived
# triangle/inellipse/circumellipse.
include("eg_triangle.jl")

include("utils.jl")

export sides, diagonals, diagonal_intersection, is_cyclic
export direction, slope_angle, midpoint, distance, polar_point, polar_point_deg
export norm, dot, normalize, angle_between, angle_at
export measure, normalized_measure, is_direct
export arc_length, point_on_arc
export interstices
export is_collinear, is_parallel, is_perpendicular, on_line, on_segment, on_ray, side_of_line, is_concyclic,
       line_circle_position, circles_position
export projection, reflection, rotate, homothety, translate, barycenter
export parallel_through, perpendicular_through, perpendicular_bisector, angle_bisectors, angle_trisectors
export golden_ratio_point, harmonic_conjugate, apollonius_circle
export intersection
export centroid, circumcenter, circumradius, circumcircle,
       incenter, inradius, incircle, orthocenter, area, perimeter, is_degenerate
export excenters, exradii, excircles, euler_line, nine_point_center, nine_point_circle, euler_points
export orthic_axis, brocard_axis, lemoine_axis, steiner_line
export barycentric_point, barycentric_coordinates, trilinear_point, trilinear_coordinates,
       altitude, median, bisector, bisector_ext, mediator, trisector,
       nagel_point, gergonne_point, spieker_center, symmedian_point, mittenpunkt, simson_line,
       de_longchamps_point, bevan_point, feuerbach_point, fermat_point, second_fermat_point, fermat_axis,
       napoleon_point, spieker_circle, kenmotu_point, kenmotu_circle, macbeath_point,
       steiner_inellipse, steiner_circumellipse,
       lemoine_inellipse, brocard_inellipse, macbeath_inellipse, mandart_inellipse, orthic_inellipse,
       kiepert_hyperbola, kiepert_parabola,
       first_brocard_point, second_brocard_point, brocard_angle, brocard_circle, brocard_midpoint,
       isogonal_conjugate, isotomic_conjugate, mixtilinear_incircle, thebault_circles,
       isodynamic_points, three_apollonius_circles, orthopole, poncelet_point,
       conway_points, conway_circle, taylor_points, taylor_circle,
       first_lemoine_points, first_lemoine_circle, second_lemoine_circle,
       van_lamoen_points, van_lamoen_circle,
       soddy_circles, soddy_line, three_tangent_circles,
       complement, anticomplement, feuerbach_points
export medial_triangle, orthic_triangle, excentral_triangle, contact_triangle,
       extouch_triangle, tangential_triangle, napoleon_triangle, morley_triangle,
       pedal_triangle, cevian_triangle, circumcevian_triangle, square_inscribed,
       anticomplementary_triangle, reflection_triangle
export equilateral_triangle_on_segment, isosceles_triangle_on_segment, triangle_30_60_90_on_segment,
       isosceles_right_triangle_on_segment, golden_triangle_on_segment, golden_gnomon_on_segment,
       egyptian_triangle_on_segment
export tangent_length, tangent_points, tangent_lines, external_tangent_lines, internal_tangent_lines,
       tangent_parallel
export external_similitude_center, internal_similitude_center
export power_of_point, radical_axis, radical_center, radical_circle
export vertices, is_convex, point_in_polygon, convex_hull
export bbox_width, bbox_height, bbox_center, bbox_diagonal, bbox_aspect_ratio,
       bboxes_intersect, bbox_intersection, bbox_union, @boundingbox
export @to_luxor_picture, @to_luxor_picture!
export @translate, @translate!, @rotate, @rotate!, @homothety, @homothety!, @reflection, @reflection!
export @invert, @invert!, @invert_neg, @invert_neg!, @affinemap, @affinemap!
export inversion, invert, inversion_neg, invert_neg, polar_line, pole
export parallelogram, square_on_segment, rectangle_on_segment, regular_polygon
export offset_line, tangent_circles_with_radius
export affine_map, translation_map, rotation_map, homothety_map, reflection_map
export point_on_ellipse, is_on_ellipse, foci, orthoptic
export tangent_circles_through_points, tangent_circles_through_point, tangent_circles
export vertex, focal_parameter, point_on_parabola, is_on_parabola
export point_on_hyperbola, is_on_hyperbola, asymptotes
export conic_through_points
export path

"""
    path(obj; action=:path, kwargs...)

Add `obj` (an `EGPoint`, `EGVector`, `EGSegment`, `EGLine`, `EGRay`,
`EGCircle2`, `EGBoundingBox`, `EGEllipse2`, `EGParabola2`, `EGHyperbola2`,
`EGAngle2`, `EGHalfPlane2`, `EGStrip2`, any conic arc (`EGCircularArc2`,
`EGEllipticArc2`, `EGParabolicArc2`, `EGHyperbolicArc2`), or any
`EGPolygon` — `EGTriangle`, `EGQuadrilateral`, `EGStraightNgon`,
`EGCircularSector2`, `EGCircularSegment2`, `EGAnnularSector2`,
`EGInterstice2`, `EGCurvilinearTriangle2`, `EGCurvilinearQuadrilateral2`,
`EGCurvilinearNgon2`) to the current path of an active Luxor `Drawing`,
using [Luxor.jl](https://github.com/JuliaGraphics/Luxor.jl)'s own
primitives. This is a package extension: `EuclideanGeometry` doesn't
depend on Luxor, but methods for `path` become available as soon as both
packages are loaded (`using EuclideanGeometry, Luxor`).

Deliberately thin: `path` never touches color, fill, or labels — that's
already what Luxor's own `sethue`, `setopacity`, `label`, etc. do well.
Every method accepts `action` (`:path` by default, meaning "add to the
current path and do nothing else" — pass `:stroke`, `:fill`, `:fillstroke`
or `:clip` to render/use it immediately, exactly as Luxor's own shape
functions do) plus whatever shape-specific keywords the curve needs
(`extend` for the unbounded `EGLine`/`EGRay`, `srange`/`n` for
`EGParabola2`, `trange`/`n`/`branch` for `EGHyperbola2`, `as`/`radius` for
`EGAngle2`, `n` for `EGEllipticArc2`/`EGParabolicArc2`/`EGHyperbolicArc2`
and for any `EGPolygon` with such a side). `EGSegment`/`EGLine`/`EGRay`
also take `as=:arrow` to draw as an arrow instead of a plain line — the
one exception to the "just adds to the path" rule, since it draws
immediately (`action` is ignored in that case). See
[Drawing with Luxor.jl](@ref) for the full per-type reference.

Note: `EGBoundingBox` is ambiguous when both packages are loaded with
`using` (Luxor has its own `BoundingBox` type) — write
`EuclideanGeometry.EGBoundingBox` explicitly when you mean this package's.
"""
function path end

export current_path_bbox

"""
    current_path_bbox()

The [`EGBoundingBox`](@ref) of whatever is currently on the active Luxor
`Drawing`'s Cairo path (in the current user-space coordinates, i.e. after
any `origin`/`translate`/`scale`/`rotate` already applied) — via
`Luxor.path_extents`. Unlike computing an `EGBoundingBox` directly from
the EG shapes themselves (exact, needs no `Drawing` at all), this reflects
whatever Cairo itself actually measured, so it also picks up anything
drawn with plain Luxor calls, and only approximates the true extent of a
shape whose `path` method samples points (`EGParabola2`, `EGHyperbola2`,
the non-circular conic arcs) rather than using a native Cairo primitive.
Like [`path`](@ref), this is a package extension: only callable once
Luxor is also loaded.

Call it *before* a non-`:path` action (`:stroke`, `:fill`, ...) — Cairo
clears the current path as a side effect of actually rendering it, same
as most of Luxor's own shape functions, so `current_path_bbox()` reads as
an empty (all-zero) box afterward.
"""
function current_path_bbox end

end # module EuclideanGeometry
