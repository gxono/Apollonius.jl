```@meta
CurrentModule = Apollonius
```

# Drawing: The Package Logo & Name Collisions

## Worked example: the package logo

![Apollonius.jl logo](assets/logo.svg)

The logo is a chain of circles, each one the answer to an Apollonius problem.
It starts from three equal circles centered at the vertices of an equilateral
triangle, so that each touches the other two. [`tangent_circles`](@ref) of the
three returns the circles tangent to all of them, and the largest is the outer
circle that encloses the three. Each new circle of the chain is then the
smallest one tangent to that outer circle, to the first of the three circles
and to the previous circle of the chain, another call to `tangent_circles`, and
the chain stops when the radius falls to `Δr`. Every circle then gives up `Δr`
of its radius, which opens the gaps between them, and drawing the chain three
times, [`rotate`](@ref)d by 120° each time and one color per copy, completes the
figure. For a more detailed explanation, see the Examples section.

```julia
begin
using Apollonius
using Luxor
import Apollonius: distance, rotate
import Luxor: julia_red, julia_blue, julia_green, julia_purple
end

colors = [julia_red, julia_purple, julia_green]

begin
Δr = 5
p1, p2 = polar_point_deg.(100, [30, 30+120])
t = equilateral_triangle_on_segment(p1, p2)
three_circles = APCircle2.(vertices(t), distance(p1, p2) / 2)
outer_circle = argmax(c -> c.r, tangent_circles(three_circles...))
circles = [three_circles[2]]

while true
    tc = argmin(c -> c.r, tangent_circles(outer_circle, three_circles[1], circles[end]))
    tc.r > Δr ? push!(circles, tc) : break
end

map!(c -> APCircle2(c.center, c.r - Δr), circles)

end

begin
Drawing(500, 500, :svg)
origin()

for (i, color) in enumerate(colors)
    sethue(color)
    path(rotate(circles, (1-i)*2pi/3), action=:fill)
end

finish()
end
```

## Passing an `APPoint` to a plain Luxor function

The `path` methods above take an `APPoint` directly, but Luxor's own
functions (`circle`, `line`, `text`, ...) take a `Point`. `Luxor.Point(p)`
converts one to the other, so `circle(Luxor.Point(p), 5, :fill)` works with
an `APPoint` `p` without writing out `Point(p[1], p[2])` by hand.

## Name collisions with Luxor

Every AP-prefixed *type* in this package (`APPoint`, `APCircle2`,
`APBoundingBox`, ...) is safe to use unqualified alongside Luxor, precisely
because the `AP` prefix keeps it out of Luxor's own namespace. What still
collides is a handful of *function* names both packages independently
export: `midpoint`, `distance` and `rotate`. Plain `using Apollonius,
Luxor` still works (that's exactly what every example on this page does),
but calling any of those three names *unqualified* is ambiguous and throws
an `UndefVarError` pointing out the clash, rather than silently picking
one:

```julia
julia> using Apollonius, Luxor

julia> midpoint(APPoint(0.0, 0.0), APPoint(4.0, 4.0))
ERROR: UndefVarError: `midpoint` not defined in `Main`
Hint: It looks like two or more modules export different bindings with this name, resulting in ambiguity. Try explicitly importing it from a particular module, or qualifying the name with the module it should come from.
Hint: a global variable of this name also exists in Apollonius.
Hint: a global variable of this name also exists in Luxor.
```

Two ways to resolve it, depending on which package's version you mean at
that call site:

* Qualify it explicitly: `Apollonius.midpoint(...)` or
  `Luxor.rotate(...)`.

* The recommended approach is to import both packages normally and explicitly import the conflicting bindings from Apollonius:
  ```julia
  using Apollonius
  using Luxor
  import Apollonius: midpoint, rotate, translate
  ```
  This makes the Apollonius versions available unqualified at the call site,
  while the corresponding Luxor functions remain available as
  `Luxor.midpoint`, `Luxor.rotate`, etc. For names that do not conflict,
  both packages can still be used normally.
