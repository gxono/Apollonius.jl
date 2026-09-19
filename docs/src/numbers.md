```@meta
CurrentModule = Apollonius
```

# Numbers & Tolerances

Geometry on a computer is arithmetic on floating-point numbers, and that has
consequences a figure never shows: two constructions of the same point can
differ in the last digit, a line that touches a circle can miss it by
`1e-16`, and a triangle very far from the origin loses digits. This page says
what to expect, and which knob to turn.

```@example geo
using Apollonius
```

## Coordinate types

An [`APPoint`](@ref) keeps the type of the numbers you give it. Mixed types
are promoted to a common one, as in Julia.

```@example geo
typeof(APPoint(1, 2)), typeof(APPoint(1, 2.5)), typeof(APPoint(1.0f0, 2.0f0)), typeof(APPoint(1 // 2, 1 // 3))
```

Operations that only add, subtract and multiply keep the type, so integer
coordinates stay integers under a translation, and rational coordinates give
exact results:

```@example geo
APPoint(1, 2) + APVector(1, 1), area(APTriangle(APPoint(0 // 1, 0 // 1), APPoint(4 // 1, 0 // 1), APPoint(0 // 1, 3 // 1)))
```

Anything that needs a square root or a division returns floating point:
[`distance`](@ref) and [`midpoint`](@ref) are `Float64` for integer points,
and constructions such as [`circumcircle`](@ref) follow the precision of the
input (`Float32` in, `Float32` out). Use `Float64` unless you have a reason
not to.

## Comparing

`==` compares coordinates exactly, so it is right for "is this the very
same point I built" and wrong for the result of a computation. `≈` compares
with a relative tolerance:

```@example geo
APPoint(0.1 + 0.2, 0.0) == APPoint(0.3, 0.0), APPoint(0.1 + 0.2, 0.0) ≈ APPoint(0.3, 0.0)
```

A relative tolerance cannot tell a number from `0`, because any error is
infinitely large next to it. When a coordinate can be zero, give an absolute
one:

```@example geo
APPoint(1e-12, 0.0) ≈ APPoint(0.0, 0.0), isapprox(APPoint(1e-12, 0.0), APPoint(0.0, 0.0); atol=1e-9)
```

## The `atol` of predicates and constructions

Predicates and constructions that have to decide whether two things
coincide take `atol`, `1e-9` by default. It does not mean the same thing in
every function, and the difference is the useful part:

| Scaled how | Where | Effect of `atol=1e-9` |
|:-----------|:------|:----------------------|
| Relative to the lengths involved | [`is_collinear`](@ref), [`is_parallel`](@ref), [`is_perpendicular`](@ref) | a sine or cosine below `1e-9` counts as zero, whatever the size of the figure |
| As a distance, `sqrt(atol)` | [`on_line`](@ref), [`line_circle_position`](@ref), [`circles_position`](@ref), and the tangency decisions inside [`intersection`](@ref) | distances below `3e-5` (times the radius, when there is one) count as zero |

The second row is why a line that misses a circle by a hair is still called
tangent. The gap below is `1e-6`, and the line is treated as touching:

```@example geo
c = APCircle2(APPoint(0.0, 0.0), 1.0)
l = APLine(APPoint(-1.0, 1.0 + 1e-6), APPoint(1.0, 1.0 + 1e-6))
line_circle_position(l, c), length(intersection(c, l))
```

Pass a smaller `atol` when your objects are small, or when you need a
stricter answer. Because the distance tolerance is `sqrt(atol)`, reaching
`1e-8` takes `atol=1e-16`:

```@example geo
line_circle_position(l, c; atol=1e-16), length(intersection(c, l; atol=1e-16))
```

For objects around `1e-6` in size, the default distance tolerance is larger
than the objects themselves. Either rescale the problem to a size near 1, or
lower `atol` to about `1e-24`.

## Far from the origin, and very large or small figures

A floating-point number has about 16 significant digits, and those digits
are spent on the whole coordinate. A triangle of side 5 at `x = 1e8` has
coordinates that differ in the eighth decimal, so anything computed from the
absolute coordinates loses most of its precision. The constructions of the
package are computed relative to one of the object's own points for this
reason, and stay accurate for [`circumcenter`](@ref), [`centroid`](@ref) and
[`area`](@ref) even at `1e10`:

```@example geo
b = 1e10
t = APTriangle(APPoint(b, b), APPoint(b + 3.0, b), APPoint(b, b + 4.0))
circumcenter(t) - APPoint(b, b), area(t)
```

The limit is the spacing of the numbers themselves: at `1e12` two adjacent
floats are `1e-4` apart, so no method can place a point better than that.
When the problem does not need those coordinates, move it near the origin,
build there, and translate back at the end.

## Nearly degenerate input

Three points that are almost collinear do not raise an error. They give a
circumcircle of enormous radius, which is the correct answer for the numbers
given:

```@example geo
t = APTriangle(APPoint(0.0, 0.0), APPoint(1.0, 0.0), APPoint(2.0, 1e-12))
is_degenerate(t), circumradius(t)
```

Check with [`is_degenerate`](@ref), [`is_collinear`](@ref) or
[`is_concyclic`](@ref) before you depend on a construction that needs a
non-degenerate input, and see the notes on each function for the cases that
do throw.

## Units of angles

Every angle is in radians, and every function that takes an angle takes
radians. Convert with `deg2rad` and `rad2deg`:

```@example geo
rad2deg(measure(APAngle2(APPoint(0.0, 0.0), APPoint(1.0, 0.0), APPoint(0.0, 1.0)))), rotate(APPoint(1.0, 0.0), deg2rad(90))
```

`rotate(p, pi / 2)` is not exactly `[0, 1]`: the `x` coordinate is about
`6e-17`, the rounding of `cos(pi / 2)`. Compare it with `≈` and an absolute
`atol`, as above.
