# Apollonius [![Build Status](https://github.com/gxono/Apollonius.jl/actions/workflows/CI.yml/badge.svg?branch=master)](https://github.com/gxono/Apollonius.jl/actions/workflows/CI.yml?query=branch%3Amaster) [![Stable](https://img.shields.io/badge/docs-stable-blue.svg)](https://gxono.github.io/Apollonius.jl/stable/) [![Dev](https://img.shields.io/badge/docs-dev-blue.svg)](https://gxono.github.io/Apollonius.jl/dev/) [![Coverage](https://codecov.io/gh/gxono/Apollonius.jl/branch/master/graph/badge.svg)](https://codecov.io/gh/gxono/Apollonius.jl)

A Julia toolkit for planar Euclidean geometry: points, segments, lines,
rays, circles, triangles, quadrilaterals, conics and circular arcs, plus
the constructions you build with them (midpoints, intersections,
projections, reflections, rotations, triangle centers...).

Every exported type is its own struct, prefixed `AP`, organized into a
real abstract type hierarchy instead of loose, unrelated structs. See the
[documentation](https://gxono.github.io/Apollonius.jl/dev/) for the full
type tree, the rationale behind it, and the complete function catalog
(vector algebra, predicates, constructions, tangency, triangle centers,
conics, affine maps, and the batch-transform macros).

Status: early, actively evolving. The core 2D constructions and the full
classical Apollonius tangency problem are covered; dozens of named
triangle centers are implemented, with plenty more in the literature
(Clark Kimberling's Encyclopedia of Triangle Centers alone catalogues
thousands).

## Example

```julia
using Apollonius

a, b, c = APPoint(0.0, 0.0), APPoint(4.0, 0.0), APPoint(0.0, 3.0)
t = APTriangle(a, b, c)

centroid(t)        # center of mass
circumcircle(t)     # circle through a, b, c
incenter(t)         # center of the inscribed circle

l = APLine(a, b)
perpendicular_through(l, c)   # altitude from c
intersection(l, circumcircle(t))
```
