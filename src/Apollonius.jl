module Apollonius
using LinearAlgebra: norm, dot, normalize, nullspace, eigvals
import LinearAlgebra
import Random
include("ap_point.jl")
export APObject, APLocus, APCurve, APSet, APRegion, APPolygon, APPolyhedron, APSurface, APTransform
export APPoint, APVector
include("ap_primitives.jl")
export APSegment, APLine, APRay, APBoundingBox
include("ap_equipollent_vector.jl")
export APEquipollentVector, tip
include("ap_polygon.jl")
export APTriangle, APQuadrilateral, APStraightNgon
include("ap_conic.jl")
export APCircle2, APEllipse2, APParabola2, APHyperbola2
export APCircularArc2, APEllipticArc2, APParabolicArc2, APHyperbolicArc2
include("ap_parametric_curve.jl")
export APParametricCurve2
include("ap_conic_tangency.jl")
include("ap_conic_intersection.jl")
include("ap_curved_region.jl")
export APCircularSector2, APCircularSegment2, APAnnularSector2, APInterstice2
export APCurvilinearTriangle2, APCurvilinearQuadrilateral2, APCurvilinearNgon2
include("ap_polyline.jl")
export APPolyline2, APCurvilinearPolyline2
include("ap_unbounded.jl")
export APAngle2, APHalfPlane2, APStrip2, strip_width
include("ap_transform.jl")
export APAffineMap
include("ap_predicates.jl")
include("ap_intersections.jl")
include("ap_intersections_composite.jl")
include("ap_unbounded_intersections.jl")
using Base.MathConstants: golden
include("ap_constructions.jl")
include("ap_marks.jl")
include("ap_show_constructions.jl")
include("ap_labels.jl")
include("ap_grid.jl")
include("ap_tangency.jl")
include("ap_radical_axis.jl")
include("ap_inversion.jl")
include("ap_apollonius.jl")
include("ap_named_polygons.jl")
include("ap_triangle_on_segment.jl")
include("ap_conic_fit.jl")
include("ap_triangle.jl")
include("ap_shape_constructors.jl")
include("ap_elementary.jl")
export polar_angle, center, radius, cross2, orthogonal
include("ap_metrics.jl")
export eccentricity, linear_eccentricity, semi_major, semi_minor, curvature, signed_curvature, chord_length, sagitta, side_lengths, semiperimeter, signed_area, interior_angles
export point_at_distance, divide_segment, equally_spaced_points, angle_with_measure, fillet, round_corners, tangent_line, normal_line
export regular_polygon_on_segment, rhombus_on_segment, square_from_diagonal, rectangle_from_diagonal, rectangle_with_center, square_with_center
export isosceles_trapezoid_on_segment, right_trapezoid_on_segment, kite_on_diagonal, star_polygon, offset_polygon, circumscribed_triangle
export offset_circle, chord, diameter, arc_through_points, arc_with_radius, tangent_circle_at_point, tangent_circles_at_point
export similarity_map, scaling_map, shear_map, conic_with_focus, ellipse_with_axis, hyperbola_with_asymptotes, parabola_through_points, inflate
include("utils.jl")
include("ap_rand.jl")
include("ap_generic_docs.jl")
export sides, diagonals, diagonal_intersection, is_cyclic
export direction, slope_angle, midpoint, distance, polar_point, polar_point_deg, antipode
export norm, dot, normalize, angle_measure_between, angle_measure_at
export measure, normalized_measure, is_direct
export arc_length, point_on, arc_with_measure, arc_with_length, tangent_at, marks, semicircle, circle_with_diameter, extend_arc, compass_trace
export mediator_construction, perpendicular_construction, parallel_construction, bisector_construction, label_anchor, extend_line
export projection_construction, reflection_construction, symmetry_construction, translation_construction
export grid_lines, axes_lines, clip_out, arrow_head, brace, brace_anchor, coordinate_guides
export interstices
export is_collinear, is_parallel, is_perpendicular, is_on_line, is_on_segment, is_on_ray, side_of_line, is_concyclic,
       line_circle_position, circles_position, is_coplanar, line_line_position
export projection, reflection, rotate, homothety, translate, barycenter
export parallel_through, perpendicular_through, perpendicular_bisector, angle_bisectors, angle_trisectors
export vertical_line, horizontal_line
export golden_ratio_point, harmonic_conjugate, apollonius_circle
export intersection
export centroid, circumcenter, circumradius, circumcircle,
       incenter, inradius, incircle, orthocenter, area, perimeter, is_degenerate
export excenters, exradii, excircles, euler_line, nine_point_center, nine_point_circle, euler_points
export orthic_axis, brocard_axis, lemoine_axis, steiner_line, apollonius_point_of_triangle, apollonius_circle_of_triangle
export barycentric_point, barycentric_coordinates, trilinear_point, trilinear_coordinates,
       altitude, median, bisector, bisector_ext, mediator, trisector,
       nagel_point, gergonne_point, spieker_center, symmedian_point, mittenpunkt, clawson_point, simson_line,
       de_longchamps_point, bevan_point, feuerbach_point, fermat_point, second_fermat_point, fermat_axis,
       napoleon_point, spieker_circle, kenmotu_point, kenmotu_circle, macbeath_point,
       steiner_inellipse, steiner_circumellipse,
       lemoine_inellipse, brocard_inellipse, macbeath_inellipse, mandart_inellipse, orthic_inellipse,
       kiepert_hyperbola, kiepert_parabola,
       first_brocard_point, second_brocard_point, angle_measure_brocard, brocard_circle, brocard_midpoint,
       isogonal_conjugate, isotomic_conjugate, mixtilinear_incircle, thebault_circles,
       isodynamic_points, three_apollonius_circles, orthopole, poncelet_point,
       conway_points, conway_circle, taylor_points, taylor_circle,
       first_lemoine_points, first_lemoine_circle, second_lemoine_circle,
       adams_points, adams_circle,
       van_lamoen_points, van_lamoen_circle,
       soddy_circles, soddy_line, soddy_center, soddy_points, three_tangent_circles,
       complement, anticomplement, feuerbach_points, symmedial_circle
export medial_triangle, orthic_triangle, excentral_triangle, contact_triangle,
       extouch_triangle, tangential_triangle, napoleon_triangle, morley_triangle,
       pedal_triangle, pedal_circle, cevian_triangle, circumcevian_triangle, square_inscribed,
       anticomplementary_triangle, reflection_triangle
export equilateral_triangle_on_segment, isosceles_triangle_on_segment, triangle_on_segment,
       triangle_on_segment_sss, triangle_on_segment_sas, triangle_on_segment_ssa, triangle_30_60_90_on_segment,
       isosceles_right_triangle_on_segment, golden_triangle_on_segment, golden_gnomon_on_segment,
       egyptian_triangle_on_segment, cheops_triangle_on_segment, golden_right_triangle_on_segment
export nearest_point, other_intersection, angle_measure_intersection, rand_inside
export tangent_length, tangent_points, tangent_lines, external_tangent_lines, internal_tangent_lines,
       tangent_parallel
export external_similitude_center, internal_similitude_center
export power_of_point, radical_axis, radical_center, radical_circle, orthogonal_circle, midcircle
export vertices, is_convex, point_in_polygon, convex_hull, is_planar
export bbox_width, bbox_height, bbox_center, bbox_diagonal, bbox_aspect_ratio,
       bboxes_intersect, bbox_intersection, bbox_union, @boundingbox
export @prepare_to_picture, @prepare_to_picture!, @unbounded
export @translate, @translate!, @rotate, @rotate!, @homothety, @homothety!, @reflection, @reflection!
export @invert, @invert!, @invert_neg, @invert_neg!, @affinemap, @affinemap!
export invert, invert_neg, polar_line, pole
export parallelogram, square_on_segment, rectangle_on_segment, regular_polygon
export offset_line, tangent_circles_with_radius, tangent_circles_with_center
export affine_map, translation_map, rotation_map, homothety_map, reflection_map
export is_on_ellipse, foci, orthoptic
export tangent_circles
export vertex, focal_parameter, is_on_parabola
export is_on_hyperbola, asymptotes
export conic_through_points
export path
"""
    path(obj; action=:path, kwargs...)

Add `obj` (an `APPoint`, `APVector`, `APSegment`, `APLine`, `APRay`,
`APCircle2`, `APBoundingBox`, `APEllipse2`, `APParabola2`, `APHyperbola2`,
`APParametricCurve2`, `APAngle2`, `APHalfPlane2`, `APStrip2`, any conic
arc (`APCircularArc2`, `APEllipticArc2`, `APParabolicArc2`,
`APHyperbolicArc2`), or any
`APPolygon`: `APTriangle`, `APQuadrilateral`, `APStraightNgon`,
`APCircularSector2`, `APCircularSegment2`, `APAnnularSector2`,
`APInterstice2`, `APCurvilinearTriangle2`, `APCurvilinearQuadrilateral2`,
`APCurvilinearNgon2`) to the current path of an active Luxor `Drawing`,
using [Luxor.jl](https://github.com/JuliaGraphics/Luxor.jl)'s own
primitives. This is a package extension: `Apollonius` doesn't
depend on Luxor, but methods for `path` become available as soon as both
packages are loaded (`using Apollonius, Luxor`).

Deliberately thin: `path` never touches color, fill, or labels: that's
already what Luxor's own `sethue`, `setopacity`, `label`, etc. do well.
Every method accepts `action` (`:path` by default, meaning "add to the
current path and do nothing else": pass `:stroke`, `:fill`, `:fillstroke`
or `:clip` to render/use it immediately, or `:fillpreserve` /
`:strokepreserve` to render it and keep the path, exactly as Luxor's own
shape functions do) plus whatever shape-specific keywords the curve needs:

| Keyword | Default | Applies to | Meaning |
|:--------|:--------|:-----------|:--------|
| `action` | `:path` | every method | `:path`, `:stroke`, `:fill`, `:fillstroke`, `:fillpreserve`, `:strokepreserve` or `:clip` |
| `reverse` | `false` | every curve | traverse the same points backwards |
| `extend` | `1000.0` | `APLine`, `APRay`, `APHalfPlane2`, `APStrip2` | how far past the defining points, or a 2-tuple `(before, after)` |
| `add` | `nothing` | same as `extend` | lengthen by fractions of `distance(p1, p2)`, replacing `extend` |
| `as` | `:plain` | `APSegment`, `APLine`, `APRay`, vectors | `:arrow` draws an arrow instead of a line; it draws immediately and ignores `action` |
| `as` | `:circle` | `APPoint` | `:circle`, `:square`, `:cross` or `:plus` |
| `as` | `:arc` | `APAngle2` | `:arc`, `:rays`, `:sector`, `:rarc` or `:rsector` |
| `radius` | `3` (`APPoint`) | `APPoint`, `APAngle2` | size of the mark, or of the arc or sector |
| `srange` | `(-100.0, 100.0)` | `APParabola2` | parameter range that is sampled |
| `trange` | `(-2.0, 2.0)` | `APHyperbola2` | parameter range that is sampled |
| `branch` | `1` | `APHyperbola2` | which branch, `1` or `-1` |
| `n` | `60` | sampled curves and polygons with such sides | number of sample points |

See [Drawing with Luxor.jl](@ref) for the full per-type reference.

Note: `APBoundingBox` is ambiguous when both packages are loaded with
`using` (Luxor has its own `BoundingBox` type): write
`Apollonius.APBoundingBox` explicitly when you mean this package's.
"""
function path end
export current_path_bbox
"""
    current_path_bbox()

The [`APBoundingBox`](@ref) of whatever is currently on the active Luxor
`Drawing`'s Cairo path (in the current user-space coordinates, i.e. after
any `origin`/`translate`/`scale`/`rotate` already applied): via
`Luxor.path_extents`. Unlike computing an `APBoundingBox` directly from
the AP shapes themselves (exact, needs no `Drawing` at all), this reflects
whatever Cairo itself actually measured, so it also picks up anything
drawn with plain Luxor calls, and only approximates the true extent of a
shape whose `path` method samples points (`APParabola2`, `APHyperbola2`,
the non-circular conic arcs) rather than using a native Cairo primitive.
Like [`path`](@ref), this is a package extension: only callable once
Luxor is also loaded.

Call it *before* a non-`:path` action (`:stroke`, `:fill`, ...): Cairo
clears the current path as a side effect of actually rendering it, same
as most of Luxor's own shape functions, so `current_path_bbox()` reads as
an empty (all-zero) box afterward.
"""
function current_path_bbox end
end
