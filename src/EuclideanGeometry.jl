module EuclideanGeometry

using LinearAlgebra: norm, dot, normalize, nullspace
import LinearAlgebra

# Phase 1 of the EG-prefixed type hierarchy rewrite (see
# .claude/plans/structured-wibbling-wigderson.md): the foundational
# EGPoint/EGVector primitives and the abstract skeleton the rest of the
# hierarchy will build on. Not yet used by anything else in this module —
# later phases migrate the existing Point2-based code onto it.
include("eg_point.jl")
export EGObject, EGLocus, EGCurve, EGSet, EGRegion, EGPolygon, EGTransform
export EGPoint, EGVector

# Phase 2: EGSegment/EGLine/EGRay/EGBoundingBox, built on EGPoint/EGVector.
# Coexists with the existing Point2-based Segment/Line/Ray/BoundingBox for
# now (not yet used by the rest of the package).
include("eg_primitives.jl")
export EGSegment, EGLine, EGRay, EGBoundingBox

# Phase 3: EGTriangle/EGQuadrilateral/EGStraightNgon, all <: EGPolygon,
# with area/perimeter/centroid/is_convex/point_in_polygon defined once,
# generically, on EGPolygon. Coexists with the existing Point2-based
# Triangle/Quadrilateral/Polygon for now.
include("eg_polygon.jl")
export EGTriangle, EGQuadrilateral, EGStraightNgon

# Phase 4: EGCircle2/EGEllipse2/EGParabola2/EGHyperbola2 (<: EGConic2) and
# EGCircularArc2/EGEllipticArc2/EGParabolicArc2/EGHyperbolicArc2
# (<: EGConicArc2). Coexists with the existing Point2-based
# Circle/Ellipse/Parabola/Hyperbola/CircularArc for now.
include("eg_conic.jl")
export EGCircle2, EGEllipse2, EGParabola2, EGHyperbola2
export EGCircularArc2, EGEllipticArc2, EGParabolicArc2, EGHyperbolicArc2

# Phase 7 (finishing a gap left by Phase 4): intersection(::EGLine, _)/
# polar_line/tangent_points/tangent_lines for EGEllipse2/EGHyperbola2/
# EGParabola2 — deferred in Phase 4's own comment to "Phase 7" but missed
# by the Phase 7 sweep (which only covered the files the plan explicitly
# listed), caught here before the old Point2-based conic files are
# deleted in Phase 8.
include("eg_conic_tangency.jl")

# Phase 5: curved-region family, all <: EGPolygon, sharing the generic
# sides-based area/perimeter from Phase 3.
include("eg_curved_region.jl")
export EGCircularSector2, EGCircularSegment2, EGAnnularSector2, EGInterstice2
export EGCurvilinearTriangle2, EGCurvilinearQuadrilateral2, EGCurvilinearNgon2

# Phase 6: EGAngle2/EGHalfPlane2/EGStrip2, all <: EGSet (unbounded regions
# of the plane). Coexists with the existing Point2-based Angle for now.
include("eg_unbounded.jl")
export EGAngle2, EGHalfPlane2, EGStrip2, strip_width

# Phase 7 (start): EGAffineMap (<: EGTransform), callable on every EG-typed
# shape defined so far. Coexists with the existing Point2-based AffineMap.
include("eg_transform.jl")
export EGAffineMap

# Phase 7 (continued): mechanical port of predicates.jl's boolean/
# classification predicates onto EGPoint/EGLine/EGSegment/EGCircle2/
# EGTriangle. `is_concyclic` deferred until triangle.jl's own
# circumcenter/circumradius are ported.
include("eg_predicates.jl")

# Phase 7 (continued): mechanical port of intersections.jl onto
# EGLine/EGSegment/EGCircle2.
include("eg_intersections.jl")

using Base.MathConstants: golden

# Phase 7 (continued): mechanical port of constructions.jl,
# tangency.jl, radical_axis.jl and inversion.jl onto
# EGPoint/EGLine/EGSegment/EGCircle2/EGCircularArc2.
include("eg_constructions.jl")
include("eg_tangency.jl")
include("eg_radical_axis.jl")
include("eg_inversion.jl")

# Phase 7 (continued): mechanical port of apollonius.jl onto
# EGPoint/EGLine/EGCircle2, plus interstices(::EGCircle2...) (deferred
# from Phase 5 — needed exactly this file's CCC Apollonius solver).
include("eg_apollonius.jl")

# Phase 7 (continued): mechanical port of named_polygons.jl,
# triangle_on_segment.jl and conic_fit.jl.
include("eg_named_polygons.jl")
include("eg_triangle_on_segment.jl")
include("eg_conic_fit.jl")

# Phase 7 (continued, largest single file): mechanical port of
# triangle.jl onto EGPoint/EGLine/EGCircle2/EGTriangle/EGQuadrilateral/
# EGEllipse2/EGParabola2 — every named triangle center, axis, circle and
# derived triangle/inellipse/circumellipse/hyperbola/parabola.
include("eg_triangle.jl")

# Phase 8: the small numeric helper (`_solve_quadratic`) shared across
# construction algorithms — everything else `utils.jl` used to hold
# (Point2-typed local-frame helpers) is now redundant with eg_conic.jl's
# own EGPoint-typed versions and was dropped along with the old types.
include("utils.jl")

export sides, diagonals, diagonal_intersection, is_cyclic
export direction, slope_angle, midpoint, distance, polar_point, polar_point_deg
export norm, dot, normalize, angle_between, angle_at
export measure, normalized_measure, is_direct
export arc_length, point_on_arc
export interstices
export is_collinear, is_parallel, is_perpendicular, on_line, on_segment, side_of_line, is_concyclic,
       line_circle_position, circles_position
export projection, reflection, rotate, homothety, barycenter
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
       bboxes_intersect, bbox_intersection
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

Experimental, not yet stable — names and behavior may still change.

Add `obj` (an `EGPoint`, `EGSegment`, `EGLine`, `EGRay`, `EGCircle2`,
`EGBoundingBox`, `EGEllipse2`, `EGParabola2`, `EGHyperbola2`, `EGAngle2`,
`EGCircularArc2`, or any `EGPolygon` — `EGTriangle`, `EGQuadrilateral`,
`EGStraightNgon`, `EGCircularSector2`, `EGCircularSegment2`,
`EGAnnularSector2`, `EGInterstice2`, `EGCurvilinearTriangle2`,
`EGCurvilinearQuadrilateral2`, `EGCurvilinearNgon2`) to the current path of
an active Luxor `Drawing`, using [Luxor.jl](https://github.com/JuliaGraphics/Luxor.jl)'s
own primitives. This is a package extension: `EuclideanGeometry` doesn't
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
`EGAngle2`). See [Drawing with Luxor.jl](@ref) for the full per-type
reference.

Note: `EGBoundingBox` is ambiguous when both packages are loaded with
`using` (Luxor has its own `BoundingBox` type) — write
`EuclideanGeometry.EGBoundingBox` explicitly when you mean this package's.
"""
function path end

end # module EuclideanGeometry
