# EuclideanGeometry [![Build Status](https://github.com/gxono/EuclideanGeometry.jl/actions/workflows/CI.yml/badge.svg?branch=master)](https://github.com/gxono/EuclideanGeometry.jl/actions/workflows/CI.yml?query=branch%3Amaster) [![Docs](https://img.shields.io/badge/docs-dev-blue.svg)](https://gxono.github.io/EuclideanGeometry.jl/dev)

A Julia toolkit for planar Euclidean geometry — points, segments, lines,
rays, circles, triangles, quadrilaterals, conics and circular arcs, plus
the constructions you build with them (midpoints, intersections,
projections, reflections, rotations, triangle centers...).

Every exported type is its own struct, prefixed `EG` (`EGPoint`,
`EGCircle2`, `EGTriangle`, ...) and organized into a real abstract type
hierarchy — no external geometry dependency, and genuine "is-a"
relationships instead of loose, unrelated structs:

```
EGObject{Dim,T}
├── EGLocus{Dim,T}
│   ├── EGCurve{Dim,T}
│   │   ├── EGLine{Dim,T}
│   │   ├── EGRay{Dim,T}
│   │   ├── EGSegment{Dim,T}
│   │   ├── EGConic2{T}                       -- circle, ellipse, parabola, hyperbola
│   │   │   ├── EGCircle2{T}
│   │   │   ├── EGEllipse2{T}
│   │   │   ├── EGParabola2{T}
│   │   │   └── EGHyperbola2{T}
│   │   └── EGConicArc2{T}                    -- a bounded piece of one of the conics above
│   │       ├── EGCircularArc2{T}
│   │       ├── EGEllipticArc2{T}
│   │       ├── EGParabolicArc2{T}
│   │       └── EGHyperbolicArc2{T}
│   └── EGSet{Dim,T}
│       ├── EGHalfPlane2{T}
│       ├── EGAngle2{T}
│       ├── EGStrip2{T}
│       └── EGRegion{Dim,T}
│           └── EGPolygon{Dim,T}
│               ├── EGTriangle{Dim,T}
│               ├── EGQuadrilateral{Dim,T}
│               ├── EGStraightNgon{Dim,T}
│               ├── EGCircularSector2{T}
│               ├── EGCircularSegment2{T}
│               ├── EGAnnularSector2{T}
│               ├── EGInterstice2{T}
│               ├── EGCurvilinearTriangle2{T}
│               ├── EGCurvilinearQuadrilateral2{T}
│               └── EGCurvilinearNgon2{T}
├── EGPoint{Dim,T}
├── EGVector{Dim,T}
└── EGBoundingBox{Dim,T}

EGTransform{T}
└── EGAffineMap{T}
```

**Why a custom type hierarchy at all**, rather than building on an
existing geometry package: two concrete problems, both hit in practice
while this package still built on GeometryBasics.jl.

1. **Naming collisions.** GeometryBasics.jl exports `Point`, `Circle`,
   `Triangle`, `Polygon`, `BoundingBox`... — names that also collide with
   [Luxor.jl](https://github.com/JuliaGraphics/Luxor.jl)'s own `Point`,
   `Circle`, `BoundingBox`, etc. Since drawing (the main reason to load
   both packages together) needs exactly that combination, every call
   needed explicit qualification to say which package's type was meant.
   Every type here is prefixed `EG`, so it never collides with anything.
2. **No real "is-a" relationships.** With loose, unrelated structs, a
   `Triangle` couldn't be treated as a `Polygon` even though it obviously
   is one — so shared logic (`area`, `perimeter`, `centroid`, ...) had to
   be reimplemented separately per shape, and a function that legitimately
   wants "any closed region" had no single type to accept. With a genuine
   abstract hierarchy — every closed shape really `<: EGPolygon` — that
   logic is written **once**, generically, via `sides()` and a shared
   Green's-theorem line integral; a brand new shape (`EGCurvilinearNgon2`,
   `EGAnnularSector2`, ...) gets `area`/`perimeter`/`centroid`/`is_convex`/
   `point_in_polygon` for free just by implementing `sides()`.

The practical upshot: `EGTriangle`, `EGQuadrilateral`, `EGCircularSector2`
and every other closed shape genuinely *is* an `EGPolygon`, so
`area`/`perimeter`/`centroid`/`is_convex`/`point_in_polygon` are defined
**once**, generically, on `EGPolygon` itself — not reimplemented per type.

## Status

Early, actively evolving. All of the core constructions and the full
classical Apollonius tangency problem (see below) are covered; the main
open area is breadth of named triangle centers — dozens of the classical
ones are covered, with plenty more in the literature (Clark Kimberling's
Encyclopedia of Triangle Centers alone catalogues thousands). The current
core covers:

- **Types**: `EGPoint`, `EGVector`, `EGSegment`, `EGLine` (infinite),
  `EGRay`, `EGCircle2`, `EGTriangle`, `EGQuadrilateral`, `EGStraightNgon`,
  `EGBoundingBox`, `EGAngle2`, `EGHalfPlane2`, `EGStrip2`,
  `EGCircularArc2`, `EGEllipticArc2`, `EGParabolicArc2`,
  `EGHyperbolicArc2`, `EGCircularSector2`, `EGCircularSegment2`,
  `EGAnnularSector2`, `EGInterstice2`, `EGCurvilinearTriangle2`,
  `EGCurvilinearQuadrilateral2`, `EGCurvilinearNgon2`, `EGEllipse2`,
  `EGParabola2`, `EGHyperbola2`, `EGAffineMap`.
- **Vector algebra**: `EGVector` is a separate type from `EGPoint` (a free
  direction/displacement rather than a location), with `norm`, `dot`,
  `normalize`, `angle_between`, `angle_at`. Arithmetic between the two
  stays deliberately permissive — `EGPoint - EGPoint` still gives back an
  `EGPoint`, not a vector — so existing point-arithmetic formulas (like a
  reflection written as `2*about - p`) keep working exactly as they read.
- **Predicates**: `is_collinear`, `is_parallel`, `is_perpendicular`, `on_line`,
  `on_segment`, `side_of_line`, `is_degenerate`, `is_concyclic`.
- **Constructions**: `midpoint`, `distance`, `projection`, `reflection`,
  `rotate`, `homothety`, `translate`, `barycenter`, `parallel_through`,
  `perpendicular_through`, `perpendicular_bisector`, `angle_bisectors`,
  `angle_trisectors`, `golden_ratio_point`, `harmonic_conjugate`,
  `apollonius_circle`. `reflection`/`rotate`/`homothety`/`translate` work on
  every type in the package — `EGPoint`, `EGSegment`, `EGLine`, `EGRay`,
  every conic (`EGCircle2`, `EGEllipse2`, `EGParabola2`, `EGHyperbola2`) and
  conic arc (`EGCircularArc2` and the rest), the whole `EGPolygon` family
  (straight and curvilinear — `EGTriangle`, `EGStraightNgon`,
  `EGQuadrilateral`, `EGCircularSector2`, `EGInterstice2`, ...), and the
  unbounded sets `EGAngle2`/`EGHalfPlane2`/`EGStrip2` — except
  `EGBoundingBox`, which only supports the subset of transforms
  (`translate`, uniform scaling) that keep it axis-aligned, since
  `rotate`/`reflection` generally wouldn't. `EGVector` gets `rotate` and
  `reflection` only (a free vector has no position for `homothety`'s
  `center` or `translate` to act on).
- **Batch-transform macros**: `@translate`/`@rotate`/`@homothety`/
  `@reflection`/`@invert`/`@invert_neg`/`@affinemap` each take a
  `begin ... end` block (or a single expression) of shapes — freshly
  built, already defined, or a mix — and apply the same transform to all
  of them at once, returning the results as a tuple (or a bare value for
  a single item). Each has a mutating `!` counterpart (`@translate!`, ...)
  that rebinds the named shapes to their own transformed values instead
  of returning copies (the closest Julia gets to in-place mutation for
  these immutable structs). Also `@boundingbox begin ... end`, the same
  block pattern folded into one `EGBoundingBox` via `bbox_union` instead
  of transforming each shape.
- **Intersections**: `intersection` between any pair of `EGLine`/`EGCircle2`,
  between finite `EGSegment`s, and between an `EGLine` and any conic
  (`EGEllipse2`/`EGParabola2`/`EGHyperbola2`).
- **Tangency**: `tangent_points`/`tangent_lines` from a point to a circle
  (or any conic), `external_tangent_lines`/`internal_tangent_lines` between
  two circles, `external_similitude_center`/`internal_similitude_center`,
  `tangent_parallel` (the two tangents to a circle parallel to a line).
- **Relative position**: `line_circle_position` (`:disjoint`/`:tangent`/`:secant`)
  and `circles_position` (`:identical`/`:concentric`/`:disjoint_ext`/
  `:tangent_ext`/`:secant`/`:tangent_int`/`:disjoint_int`).
- **Power of a point / radical axis**: `power_of_point`, `radical_axis`,
  `radical_center` (the concurrency point of 3 pairwise radical axes),
  `radical_circle` (orthogonal to all three).
- **Pole/polar duality**: `polar_line`/`pole` with respect to a circle
  (also `polar_line` for `EGEllipse2`/`EGParabola2`/`EGHyperbola2`, which
  `tangent_points`/`tangent_lines` for those already use internally).
- **The polygon family** (`EGPolygon`): `area`, `perimeter`, `centroid`,
  `is_convex`, `point_in_polygon`, `convex_hull` — defined once,
  generically, via a Green's-theorem walk over each shape's `sides`, so
  the same formulas cover straight-sided shapes (`EGTriangle`,
  `EGQuadrilateral`, `EGStraightNgon`) and curved-sided regions
  (`EGCircularSector2`, `EGCircularSegment2`, `EGAnnularSector2`,
  `EGInterstice2`, the `EGCurvilinear*` family) alike.
- **Quadrilaterals**: `EGQuadrilateral` (a dedicated 4-vertex type,
  distinct from a general `EGStraightNgon`) — `sides`, `diagonals`,
  `diagonal_intersection`, `centroid` (plain vertex average, unlike the
  generic area-weighted one), `area`, `perimeter`, `is_convex`,
  `is_cyclic`, `EGBoundingBox`.
- **Bounding boxes**: `EGBoundingBox` can be built from any bounded shape
  in the package — `EGSegment`, every conic (`EGCircle2`/`EGEllipse2`) and
  every conic arc (bounded even when the full curve isn't, like a
  hyperbolic or parabolic arc), and the whole `EGPolygon` family (straight
  and curvilinear alike). Left out on purpose: `EGLine`/`EGRay`
  (infinite), `EGHyperbola2`/`EGParabola2` as full curves (also infinite),
  and the unbounded sets `EGHalfPlane2`/`EGStrip2`/`EGAngle2`. Also:
  `bbox_width`/`bbox_height`, `bbox_center`, `bbox_diagonal`,
  `bboxes_intersect`, `bbox_intersection` (`nothing` if disjoint),
  `bbox_union` (always exists), and `p in bbox` (`Base.in`) for point
  membership. `@boundingbox begin ... end` folds a whole block of shapes
  (freshly built, already defined, or a mix) into their combined
  `bbox_union` in one expression.
- **Angles as objects and regions**: `EGAngle2(vertex, a, b)` keeps the
  three defining points around instead of just a number — `measure`
  (signed), `normalized_measure`, `abs` (unsigned), `is_direct`, and (since
  it's a genuine `EGSet`) `p in ang` for the infinite wedge it sweeps.
- **Unbounded regions**: `EGHalfPlane2` (a boundary line plus a side),
  `EGStrip2` (the band between two parallel lines) — both support `p in s`,
  and the same `rotate`/`reflection`/`homothety` as everything else.
- **Circular (and conic) arcs, sectors and segments**: `EGCircularArc2`
  (the arc of a circle between two of its points, always traversed
  counterclockwise from the first to the second, with the same-shaped
  `EGEllipticArc2`/`EGParabolicArc2`/`EGHyperbolicArc2` for the other
  conics) — `measure`, `arc_length`, `point_on_arc`, `midpoint`.
  `EGCircularSector2` (the "pie slice"), `EGCircularSegment2` (the "cap")
  and `EGAnnularSector2` (the "ring slice", between two concentric arcs)
  each wrap an arc — `area`/`perimeter` come for free from the generic
  `EGPolygon` machinery, plus `p in shape`.
- **Interstices**: `interstices` — the curvilinear-triangle gap(s) between
  three mutually tangent circles (one gap for an externally tangent chain,
  two when one circle contains the other two), returned as
  `EGInterstice2`s bounded by three `EGCircularArc2`s.
- **Curvilinear polygons**: `EGCurvilinearTriangle2`/
  `EGCurvilinearQuadrilateral2`/`EGCurvilinearNgon2` — closed regions with
  any mix of straight (`EGSegment`) and curved (`EGCircularArc2`) sides,
  e.g. what inverting a straight-sided polygon through a circle produces.
- **Triangle centers**: `centroid`, `circumcenter`/`circumcircle`,
  `incenter`/`incircle`, `excenters`/`exradii`/`excircles`, `orthocenter`,
  `euler_line`, `nine_point_center`/`nine_point_circle`, `nagel_point`,
  `gergonne_point`, `spieker_center`, `symmedian_point`, `mittenpunkt`,
  `de_longchamps_point`, `bevan_point`, `feuerbach_point`, `feuerbach_points`
  (the excircle-tangency analogue), `fermat_point`,
  `second_fermat_point`, `napoleon_point`, `first_brocard_point`/
  `second_brocard_point`/`brocard_angle`/`brocard_circle`/
  `brocard_midpoint`, `isodynamic_points`, `orthopole`, `simson_line`,
  `spieker_circle`, `kenmotu_point`/`kenmotu_circle`, `macbeath_point`,
  `poncelet_point`, `euler_points`, `taylor_points`, `van_lamoen_points`,
  `square_inscribed`, `complement`, `anticomplement`,
  `barycentric_point`/`barycentric_coordinates`,
  `trilinear_point`/`trilinear_coordinates`, `area`, `perimeter`.
- **Triangle axes/lines**: `euler_line`, `simson_line`, `steiner_line`,
  `orthic_axis`, `brocard_axis`, `lemoine_axis`, `fermat_axis`, `soddy_line`.
- **More triangle circles**: `conway_points`/`conway_circle`,
  `taylor_circle`, `first_lemoine_points`/`first_lemoine_circle`,
  `second_lemoine_circle`, `van_lamoen_circle`, `soddy_circles` (the
  inner/outer circles tangent to the three mutually-tangent vertex circles
  of radii `s-a`, `s-b`, `s-c` — found by reusing the `CCC` Apollonius
  solver, `tangent_circles`, rather than a separate formula),
  `three_tangent_circles`, `three_apollonius_circles`, `thebault_circles`.
- **Triangle-inscribed conics**: `steiner_inellipse`, `steiner_circumellipse`,
  `lemoine_inellipse`, `brocard_inellipse`, `macbeath_inellipse`,
  `mandart_inellipse`, `orthic_inellipse`.
- **Triangle-associated hyperbola/parabola**: `kiepert_hyperbola` (the
  rectangular hyperbola through the 3 vertices, centroid and orthocenter),
  `kiepert_parabola`.
- **Derived triangles**, in addition to the ones below: `anticomplementary_triangle`,
  `reflection_triangle`.
- **Named triangles on a segment**: `equilateral_triangle_on_segment`,
  `isosceles_triangle_on_segment`, `triangle_30_60_90_on_segment`,
  `isosceles_right_triangle_on_segment` (via Thales' theorem),
  `golden_triangle_on_segment`, `golden_gnomon_on_segment`,
  `egyptian_triangle_on_segment` (the `3-4-5` right triangle) — each takes
  a base segment `[a, b]` and a `ccw::Bool=true` side keyword, the same
  convention as `square_on_segment`.
- **General point transformations relative to a triangle**:
  `isogonal_conjugate` (orthocenter ↔ circumcenter, centroid ↔ symmedian
  point, fixes the incenter) and `isotomic_conjugate` (fixes the
  centroid) — each an involution that turns any point into a whole family
  of related centers, rather than a one-off formula per center.
- **General point-parametrized derived triangles**: `pedal_triangle`
  (generalizes `orthic_triangle`/`contact_triangle`), `cevian_triangle`
  (generalizes `medial_triangle`), `circumcevian_triangle`.
- **Mixtilinear incircles**: `mixtilinear_incircle` — built by reusing the
  `CLL` Apollonius solver (`tangent_circles`) and picking out the one
  solution nestled in the vertex's angle, internally tangent to the
  circumcircle.
- **Derived triangles**: `medial_triangle`, `orthic_triangle`,
  `excentral_triangle`, `contact_triangle`, `extouch_triangle`,
  `tangential_triangle`, `napoleon_triangle` (Napoleon's theorem),
  `morley_triangle` (Morley's trisector theorem).
- **Named polygon constructors**: `parallelogram`, `square_on_segment`,
  `rectangle_on_segment`, `regular_polygon`.
- **Inversion**: `inversion` (points), `invert` (lines/circles to their
  image circle; an `EGSegment` to an `EGSegment` or `EGCircularArc2`; an
  `EGTriangle`/`EGStraightNgon` to an `EGCurvilinearNgon2`, since straight
  sides don't reliably stay straight), and their negative-ratio
  counterparts `inversion_neg`/`invert_neg` (the same image,
  point-reflected through the inversion circle's own center).
- **Affine transformations**: `EGAffineMap` (composable with `∘`), callable
  on every type `rotate`/`homothety`/`reflection` work on. Conic type is an
  affine invariant, so a circle/ellipse/hyperbola/parabola always maps to
  an ellipse/ellipse/hyperbola/parabola respectively (never crossing over,
  and never staying a circle unless the map happens to be a similarity);
  a region built from circular arcs (`EGCircularSector2`, `EGAnnularSector2`,
  `EGInterstice2`, ...) comes back as the more general
  `EGCurvilinearTriangle2`/`EGCurvilinearQuadrilateral2`/`EGCurvilinearNgon2`,
  since its arcs generically become elliptic. `affine_map` builds one from
  3 point correspondences; `translation_map`, `rotation_map`,
  `homothety_map`, `reflection_map` build one matching `translate`/`rotate`/
  `homothety`/`reflection` exactly, but composably.
- **Tangency with a given radius**: `tangent_circles_with_radius` between
  two lines, a line and a circle, or two circles; `offset_line`.
- **The full classical Apollonius tangency problem** (all 10 point/line/circle
  combinations, each internal/external tangency combination included):
  - `PPP` is `circumcircle`; `LLL` is `incircle`/`excircles`.
  - `tangent_circles_through_points` — circle(s) through two points tangent
    to a line (`LPP`) or to a circle (`CPP`).
  - `tangent_circles_through_point` — circle(s) tangent to two lines
    (`LLP`), two circles (`CCP`), or a line and a circle (`CLP`), through a
    given point.
  - `tangent_circles` — circle(s) tangent to two lines and a circle
    (`CLL`), two circles and a line (`CCL`), or three circles (`CCC`, the
    classical Apollonius problem, up to 8 solutions).

  `LPP`/`CPP`/`LLP` reduce directly to a quadratic; `CCP`/`CLP` invert the
  configuration about the required point (a line/circle through it becomes
  a line, reducing to `external_tangent_lines`/`internal_tangent_lines`,
  then inverting back); `CLL`/`CCL`/`CCC` use the classical
  difference-of-equations trick (subtracting two squared tangency
  conditions cancels their quadratic terms, leaving a linear equation) to
  pin the center down to a single remaining quadratic per sign choice.
- **Conics**: `EGEllipse2`, `EGParabola2` and `EGHyperbola2` — point-on-curve
  tests, parametric points, `area`/`perimeter`/`foci` (ellipse; `perimeter`
  via Ramanujan's approximation), `vertex`/`focal_parameter` (parabola),
  `foci`/`asymptotes` (hyperbola), `intersection` with an `EGLine`, and
  `tangent_points`/`tangent_lines` from an external point (via the polar
  line of the point, intersected with the conic). `EGEllipse2` and
  `EGHyperbola2` also have a bifocal constructor:
  `EGEllipse2(f1, f2, a_or_point)` / `EGHyperbola2(f1, f2, a_or_point)`.
  `conic_through_points` fits the ellipse or hyperbola through 5 given
  points (via `LinearAlgebra.nullspace` on the general conic equation,
  then diagonalizing to canonical form).

With Apollonius' problem now fully covered, tangent lines from a point to
any conic, a growing set of derived triangles, general point
transformations (isogonal/isotomic conjugate, pedal/cevian/circumcevian
triangle), named centers (Feuerbach, Fermat, Bevan, de Longchamps,
Napoleon, Morley, Brocard, Spieker, Kenmotu, MacBeath, Poncelet, Thébault,
mixtilinear incircles...), and every type's `rotate`/`reflection`/
`homothety` now filled in, what's left is mostly breadth: more of the many
named triangle centers/lines/circles in the classical literature, and
general conic-conic intersection.

### Julia idioms

- **`p in shape`** (`Base.in`) works for point-membership tests across the
  board: every `EGPolygon` (`EGTriangle`, `EGQuadrilateral`,
  `EGStraightNgon`, `EGCircularSector2`, `EGCircularSegment2`,
  `EGAnnularSector2`, and the rest) gets it for free from the one generic
  `point_in_polygon`, and `EGBoundingBox`, `EGEllipse2`, `EGParabola2`
  (region on the focus side), `EGHyperbola2` (on or beyond either branch),
  `EGAngle2` (its infinite wedge), `EGHalfPlane2` and `EGStrip2` each
  define their own.
- **`==`/`≈`** are defined for every type this package introduces.
- **`show`** is customized for the same set of types, so they print
  something readable at the REPL instead of a raw field dump.

## Example

```julia
using EuclideanGeometry

a, b, c = EGPoint(0.0, 0.0), EGPoint(4.0, 0.0), EGPoint(0.0, 3.0)
t = EGTriangle(a, b, c)

centroid(t)        # center of mass
circumcircle(t)     # circle through a, b, c
incenter(t)         # center of the inscribed circle

l = EGLine(a, b)
perpendicular_through(l, c)   # altitude from c
intersection(l, circumcircle(t))
```
