```@meta
CurrentModule = Apollonius
```

# Getting Started

This page takes you from installing the package to a first figure. It uses
one triangle throughout, and ends with a table that says which page to read
for what you want to do.

## Installing

Apollonius needs Julia 1.10 or later. From the Julia REPL:

```julia
using Pkg
Pkg.add(url="https://github.com/gxono/Apollonius.jl")
```

The geometry needs nothing else. To draw figures, also install
[Luxor.jl](https://github.com/JuliaGraphics/Luxor.jl) (`Pkg.add("Luxor")`) and
load it after Apollonius. Drawing is the only part that depends on it.

## A first construction

Points are made from two coordinates, and shapes from points. Use
`Float64` coordinates (`0.0`, not `0`) until you have a reason not to.

```@example geo
using Apollonius

A, B, C = APPoint(0.0, 0.0), APPoint(6.0, 0.0), APPoint(1.5, 4.0)
t = APTriangle(A, B, C)
area(t), perimeter(t)
```

Named constructions take a shape and return another one. The circle through
the three vertices, and the circle that touches the three sides:

```@example geo
cc = circumcircle(t)
inc = incircle(t)
cc.center, cc.r
```

Every object is an ordinary value with fields you can read (`cc.center` is
an [`APPoint`](@ref), `cc.r` a number), and none of them can be changed after
it is built. To change one, build a new one, for instance with
[`translate`](@ref), [`rotate`](@ref) or [`reflection`](@ref).

## Checking the result

A construction gives a number you can test, which is how to know it is
right before drawing anything. The three vertices are all at the radius
from the center, and the incircle touches a side at exactly one point:

```@example geo
distance(cc.center, A) ≈ cc.r, distance(cc.center, B) ≈ cc.r, distance(cc.center, C) ≈ cc.r
```

```@example geo
length(intersection(APLine(A, B), inc)), length(intersection(APLine(A, B), cc))
```

Use `≈`, not `==`, to compare results of a computation: two ways of getting
the same point can differ in the last digit. When a function can have
several answers, such as [`intersection`](@ref), it returns a `Vector`, empty
if there are none.

## A first figure

With Luxor loaded, every object has a [`path`](@ref) method. The macro
[`@to_luxor_picture`](@ref) scales and centers a set of objects to fit a
canvas and returns them in canvas coordinates, ready to draw:

```julia
using Apollonius, Luxor

lxm, lxo = @to_luxor_picture width=500 height=300 margin=30 begin
    t
    cc
    inc
end

@svg begin
    sethue(julia_blue)
    path(lxo.t, action=:stroke)
    sethue(julia_purple)
    path([lxo.cc, lxo.inc], action=:stroke)
end lxm.width lxm.height
```

The full version of this figure, with the vertices, the two centers and their labels:

```@raw html
<img src="../assets/img/getting_started/first_figure.svg" alt="A triangle with its circumcircle and incircle, the two centers and the labels A, B, C, O and I" style="width:100%; max-width: 700px;">
```

The order of the steps (construct, check, fit, decorate, draw) is what makes
a figure easy to change. [Workflow: From Construction to Figure](@ref) walks
through it and lists the usual mistakes.

## Three habits

1. **Compare with `≈`.** `==` compares coordinates exactly. See
   [Conventions & FAQ](@ref).
2. **Build in your own coordinates.** Do not think in pixels while you
   construct. The macro converts at the end, and the screen has `y`
   pointing down, which the drawing functions take care of.
3. **Test before you draw.** A wrong figure is nearly always a wrong
   construction. [Predicates](@ref) and [Measurements & Queries](@ref) are
   the tools for that.

## Where to go next

| I want to | Read |
|:----------|:-----|
| Understand the types and how they relate | [The type hierarchy](@ref) on the Home page |
| Make points, lines, segments and rays | [Points, Lines & Rays](@ref) |
| Know if something is true (on a line, parallel, inside) | [Predicates](@ref) |
| Get a distance, area, angle or center | [Measurements & Queries](@ref) |
| Find where two objects meet | [Intersections](@ref) |
| Work with circles, inversion, radical axes | [Circles](@ref) |
| Find triangle centers and derived triangles | [Triangles & Triangle Centers](@ref) |
| Find circles tangent to given objects | [Tangency & Apollonius Problems](@ref) |
| Work with polygons and bounding boxes | [Polygons & Bounding Boxes](@ref) |
| Work with ellipses, parabolas and hyperbolas | [Conics: Ellipse, Parabola & Hyperbola](@ref) |
| Draw a compass and ruler construction step by step | [Compass & Ruler Constructions](@ref) |
| Draw figures, add marks, labels and braces | [Drawing with Luxor.jl](@ref), [Marks, Labels & Decorations](@ref) |
| Move or scale a whole figure at once | [Affine Maps](@ref), [Transforming in Bulk: Macros](@ref) |
| Find a ready-made recipe | [Cookbook](@ref) |
| Look up a function | [API Reference](@ref) |
