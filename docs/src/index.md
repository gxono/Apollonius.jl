```@meta
CurrentModule = EuclideanGeometry
```

# EuclideanGeometry.jl

!!! note "Illustrations are still on their way"
    Several pages on this site have a placeholder image (labeled "TODO:
    diagram") standing in for a real illustration. The text and code
    examples around them are complete and verified; the actual diagrams
    will be filled in over time.

Documentation for [EuclideanGeometry.jl](https://github.com/gxono/EuclideanGeometry.jl), a Julia toolkit for planar Euclidean geometry — points, segments, lines, rays, circles and triangles, plus the constructions you build with them (midpoints, intersections, projections, reflections, rotations, triangle centers, tangency, conics...).

Every exported type is its own struct, prefixed `EG` (`EGPoint`, `EGCircle2`,
`EGTriangle`, ...) and organized into a real abstract type hierarchy — no
external geometry dependency, and genuine "is-a" relationships instead of
loose, unrelated structs:

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
and every other closed shape genuinely *is* an [`EGPolygon`](@ref), so
`area`/`perimeter`/`centroid`/`is_convex`/`point_in_polygon` are defined
**once**, generically — not reimplemented per type. See each abstract
type's own docstring ([`EGObject`](@ref), [`EGLocus`](@ref),
[`EGCurve`](@ref), [`EGSet`](@ref), [`EGRegion`](@ref),
[`EGPolygon`](@ref), [`EGTransform`](@ref)) for what belongs where and why.

```julia
t = EGTriangle(EGPoint(0.0, 0.0), EGPoint(1.0, 0.0), EGPoint(0.0, 1.0))
t isa EGPolygon, t isa EGRegion, t isa EGSet, t isa EGLocus, t isa EGObject   # (true, true, true, true, true)

s = EGSegment(EGPoint(0.0, 0.0), EGPoint(1.0, 1.0))
s isa EGCurve, s isa EGLocus                                                  # (true, true) -- not an EGRegion: a segment isn't a closed shape

ang = EGAngle2(EGPoint(0.0, 0.0), EGPoint(1.0, 0.0), EGPoint(0.0, 1.0))
ang isa EGSet, ang isa EGRegion   # (true, false) -- unbounded, so an EGSet but not an EGRegion

m = EGAffineMap(1.0, 0.0, 0.0, 1.0, 0.0, 0.0)
m isa EGTransform, m isa EGObject   # (true, false) -- EGTransform is its own separate hierarchy
```

See the [README](https://github.com/gxono/EuclideanGeometry.jl#readme) for the full feature overview, and the [API Reference](@ref) for every exported function and type. For a guided tour with explanations and worked examples, start with:

* [Points, Lines & Rays](@ref)
* [Circles](@ref)
* [Triangles & Triangle Centers](@ref)
* [Tangency & Apollonius Problems](@ref)
* [Polygons & Bounding Boxes](@ref)
* [Conics: Ellipse, Parabola & Hyperbola](@ref)
* [Affine Maps](@ref)

## Quick example

```julia
using EuclideanGeometry

a, b, c = EGPoint(0.0, 0.0), EGPoint(4.0, 0.0), EGPoint(0.0, 3.0)
t = EGTriangle(a, b, c)

centroid(t)        # center of mass
circumcircle(t)    # circle through a, b, c
incenter(t)        # center of the inscribed circle

l = EGLine(a, b)
perpendicular_through(l, c)   # altitude from c
intersection(l, circumcircle(t))
```

## Figures, via Luxor.jl

This package doesn't depend on [Luxor.jl](https://github.com/JuliaGraphics/Luxor.jl),
but if you load both, a [`path`](@ref) function becomes available for
every type here, via a package extension, plus [`@to_luxor_picture`](@ref)
and [`current_path_bbox`](@ref) for sizing/positioning a `Drawing`
automatically instead of guessing coordinates by hand. The point of all
of it is exactly what this documentation itself needs: it's the tool
this site's own illustrations (once filled in, see the note above) get
built with. See [Drawing with Luxor.jl](@ref) at the end of this site for
the full rundown.
