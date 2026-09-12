```@meta
CurrentModule = EuclideanGeometry
```

# Affine Maps

[`EGAffineMap`](@ref) (`<: EGTransform`, deliberately outside the
[`EGObject`](@ref) tree — see its own docstring) is a general 2D affine
transformation, `p -> A*p + t` for a `2×2` matrix `A` (stored as four
scalars, `a11 a12 a21 a22`) and a translation `t = (tx, ty)`. It
generalizes [`rotate`](@ref), [`homothety`](@ref) and [`reflection`](@ref)
into a single reusable, *composable* object, rather than a one-off
function call: build one once, apply it to as many points/shapes as you
like, and combine several into one with plain function composition (`∘`).

## Creating one

The general constructor, [`affine_map`](@ref), builds the unique affine
map sending three given (non-collinear) source points to three chosen
destination points — the 2D affine analogue of "3 points determine a
transformation":

```@example geo
using EuclideanGeometry

src = (EGPoint(0.0, 0.0), EGPoint(1.0, 0.0), EGPoint(0.0, 1.0))
dst = (EGPoint(2.0, 3.0), EGPoint(5.0, 3.0), EGPoint(2.0, 7.0))
m = affine_map(src, dst)
```

It throws an `ArgumentError` if the three source points are (or are too
close to) collinear, since then no unique affine map is determined (there
are either none or infinitely many, depending on `dst`).

More often, though, one of the specific named constructors below is more
direct than describing the map via three point correspondences:

| Function | Builds the affine map for... |
|:---------|:------------------------------|
| [`translation_map`](@ref) | `p -> p + v` |
| [`rotation_map`](@ref) | `p -> rotate(p, angle, center)` |
| [`homothety_map`](@ref) | `p -> homothety(p, k, center)` |
| [`reflection_map`](@ref) | `p -> reflection(p, l)` |

`rotation_map` and `homothety_map` both require `center` explicitly — there
is no zero-argument default here, unlike [`rotate`](@ref)/[`homothety`](@ref)
themselves (a default would collide with the single-argument form these
two functions would otherwise auto-generate).

```@example geo
tm = translation_map(EGPoint(3.0, -2.0))
rm = rotation_map(pi / 2, EGPoint(1.0, 1.0))
hm = homothety_map(2.0, EGPoint(1.0, 1.0))
refm = reflection_map(EGLine(EGPoint(0.0, 0.0), EGPoint(1.0, 0.0)))
```

Each of these agrees exactly with its point-based counterpart —
`rotation_map(angle, center)(p) == rotate(p, angle, center)`, and likewise
for the other three — the map versions exist purely so the transformation
itself can be stored, composed and reused, rather than re-specifying
`angle`/`center` (or `k`/`center`, or `l`) on every call.

## Applying and composing

An `EGAffineMap` is directly callable, and works pointwise on every other
type in the package:

```@example geo
m(EGPoint(1.0, 0.0))                 # a single point
t = EGTriangle(EGPoint(0.0, 0.0), EGPoint(1.0, 0.0), EGPoint(0.0, 1.0))
m(t)                                 # a whole EGTriangle, vertex by vertex
```

The same works for `EGSegment`, `EGLine`, `EGRay`, `EGStraightNgon`,
`EGQuadrilateral` and `EGAngle2` — all pointwise, vertex by vertex. It's
also directly callable on an [`EGVector`](@ref), applying the linear part
only (no translation, since a vector has no position):

```@example geo
m(EGVector(1.0, 0.0))
```

`EGCircle2` is different: a general affine map doesn't send a circle to
another circle (only similarity maps — rotation, homothety, reflection,
translation, and combinations of those — do), so `m(c::EGCircle2)` returns
an [`EGEllipse2`](@ref) instead, never an `EGCircle2`, even when `m`
happens to be a similarity:

```@example geo
c = EGCircle2(EGPoint(1.0, 2.0), 5.0)
skew = EGAffineMap(2.0, 0.5, -0.3, 1.4, 3.0, -1.0)
skew(c)          # a genuine EGEllipse2: the linear part isn't a similarity
rm(c)            # rm is a pure rotation, so this EGEllipse2 has a == b
```

Its center transforms pointwise like everything else; the semi-axes and
angle come from the singular values and left singular vectors of `m`'s
linear part (scaled by `c.r`) — the standard fact that a linear map always
sends a circle to an ellipse aligned with those directions.

Maps compose with ordinary function composition, `∘`, right-to-left just
like any other Julia functions — `(m2 ∘ m1)(p) == m2(m1(p))`:

```@example geo
composed = rm ∘ tm     # first translate, then rotate
composed(EGPoint(0.0, 0.0))
```

This builds a single new `EGAffineMap` (not a closure), so applying
`composed` to many points is exactly as cheap as applying any other single
map — the composition happens once, up front, not on every call.
