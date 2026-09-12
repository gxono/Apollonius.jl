```@meta
CurrentModule = EuclideanGeometry
```

# EuclideanGeometry.jl

Documentation for [EuclideanGeometry.jl](https://github.com/gxono/EuclideanGeometry.jl), a Julia toolkit for planar Euclidean geometry — points, segments, lines, rays, circles and triangles, plus the constructions you build with them (midpoints, intersections, projections, reflections, rotations, triangle centers, tangency, conics...).

Every exported type is its own struct, prefixed `EG` (`EGPoint`, `EGCircle2`,
`EGTriangle`, ...) and organized into a real abstract type hierarchy — no
external geometry dependency, and genuine "is-a" relationships instead of
loose, unrelated structs:

```
EGObject{Dim,T}
├── EGLocus{Dim,T}
│   ├── EGCurve{Dim,T}          -- EGLine, EGRay, EGSegment, the conics, the conic arcs
│   └── EGSet{Dim,T}
│       ├── EGHalfPlane2, EGAngle2, EGStrip2      -- unbounded regions
│       └── EGRegion{Dim,T}
│           └── EGPolygon{Dim,T}                  -- closed regions, straight or curved sides
├── EGPoint{Dim,T}, EGVector{Dim,T}
└── EGBoundingBox{Dim,T}
EGTransform{T}
└── EGAffineMap{T}
```

The practical upshot: `EGTriangle`, `EGQuadrilateral`, `EGCircularSector2`
and every other closed shape genuinely *is* an [`EGPolygon`](@ref), so
`area`/`perimeter`/`centroid`/`is_convex`/`point_in_polygon` are defined
**once**, generically — not reimplemented per type. See each abstract
type's own docstring ([`EGObject`](@ref), [`EGLocus`](@ref),
[`EGCurve`](@ref), [`EGSet`](@ref), [`EGRegion`](@ref),
[`EGPolygon`](@ref), [`EGTransform`](@ref)) for what belongs where and why.

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

## Drawing with Luxor.jl (experimental)

This package doesn't depend on [Luxor.jl](https://github.com/JuliaGraphics/Luxor.jl),
but if you load both, a [`path`](@ref) function becomes available for
every type here, via a package extension — this is new and not yet a
stable, finished part of the API. See [Drawing with Luxor.jl](@ref) at
the end of this site for the full rundown.
