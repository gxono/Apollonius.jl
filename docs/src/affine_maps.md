```@meta
CurrentModule = EuclideanGeometry
```

# Affine Maps

[`EGAffineMap`](@ref) (`<: EGTransform`, deliberately outside the
[`EGObject`](@ref) tree — see its own docstring) is a general 2D affine
transformation, `p -> A*p + t` for a `2×2` matrix `A` (stored as four
scalars, `a11 a12 a21 a22`) and a translation `t = (tx, ty)`. It
generalizes [`rotate`](@ref), [`homothety`](@ref), [`reflection`](@ref) and
[`translate`](@ref) into a single reusable, *composable* object, rather
than a one-off function call: build one once, apply it to as many
points/shapes as you like, and combine several into one with plain
function composition (`∘`).

Unlike those four (each always orientation-preserving, or a
straightforward orientation flip for `reflection`), an `EGAffineMap` can
be a genuine shear or non-uniform scale — so it's also the place where a
few subtleties specific to *general* affine transformations show up:
circles becoming ellipses, conic arcs sometimes needing their endpoints
swapped, and circular-arc regions becoming curvilinear. Each is covered
below.

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
themselves (a default would let `rotation_map(angle)`/`homothety_map(k)`
alone silently rotate/scale about the origin with no `center` in sight at
the call site).

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
straight-edged type in the package:

```@example geo
m(EGPoint(1.0, 0.0))                 # a single point
t = EGTriangle(EGPoint(0.0, 0.0), EGPoint(1.0, 0.0), EGPoint(0.0, 1.0))
m(t)                                 # a whole EGTriangle, vertex by vertex
```

The same works for `EGSegment`, `EGLine`, `EGRay`, `EGStraightNgon`,
`EGQuadrilateral`, `EGAngle2`, `EGHalfPlane2` and `EGStrip2` — all
pointwise, vertex by vertex (or endpoint by endpoint). It's also directly
callable on an [`EGVector`](@ref), applying the linear part only (no
translation, since a vector has no position):

```@example geo
m(EGVector(1.0, 0.0))
```

`EGHalfPlane2` needs one extra piece of bookkeeping: unlike `rotate`/
`homothety` (always orientation-preserving in 2D), a general affine map
can reverse orientation, which would flip which side of the transformed
boundary is "inside" — so its `side` field is recomputed fresh from an
interior point, rather than carried over unchanged.

## Conics: type is preserved, but never a circle

A circle, ellipse, hyperbola or parabola all stay their *own* conic
type under any invertible affine map — this is a basic invariant (by
Sylvester's law of inertia, the map acts on a conic's defining quadratic
form as a congruence, which can't change how many of its eigenvalues are
positive/negative/zero). Concretely:

- `m(c::EGCircle2)` always returns an [`EGEllipse2`](@ref), never another
  `EGCircle2` — only a *similarity* (rotation/homothety/reflection/
  translation, or a combination) sends a circle to a circle, and this
  covers every affine map, so the return type doesn't special-case that.
- `m(e::EGEllipse2)` returns another `EGEllipse2`, `m(h::EGHyperbola2)`
  another `EGHyperbola2`, `m(par::EGParabola2)` another `EGParabola2` —
  each computed exactly (no sampling or fitting): the conic's own
  quadratic form transforms as a congruence, which is diagonalized to
  recover the new semi-axes/angle directly (for the parabola, whose
  `focus`/`directrix` are metric rather than affine-invariant quantities,
  the new vertex/focal-parameter are instead recovered from its
  parametrization rewritten in the orthonormal frame aligned with the
  transformed axis direction).

```@example geo
c = EGCircle2(EGPoint(1.0, 2.0), 5.0)
skew = EGAffineMap(2.0, 0.5, -0.3, 1.4, 3.0, -1.0)
skew(c)          # a genuine EGEllipse2: the linear part isn't a similarity
rm(c)            # rm is a pure rotation, so this EGEllipse2 has a == b
```

## Conic arcs: orientation-reversing maps need an endpoint swap

`m(arc::EGCircularArc2)` returns an `EGEllipticArc2` (same reasoning as
the circle case above); `EGEllipticArc2`, `EGHyperbolicArc2` and
`EGParabolicArc2` each map to the same arc type, on the image of their
underlying conic.

For the two *closed*-conic arcs (circular, elliptic), "the arc from `p1`
to `p2`" only picks out one of two complementary arcs because it's
understood to sweep counterclockwise. An orientation-reversing map
(`det(m) < 0`, like a reflection) turns that sweep clockwise, so `p1`/`p2`
are swapped when reconstructing the transformed arc — otherwise it would
silently become the *complementary* arc instead. `EGHyperbolicArc2`/
`EGParabolicArc2` need no such swap: a single hyperbola branch or a
parabola is open, so two points on it always determine one unambiguous
arc regardless of orientation.

## Circular-arc regions become curvilinear

`EGCircularSector2`, `EGCircularSegment2`, `EGAnnularSector2` and
`EGInterstice2` each hold a concrete `EGCircularArc2` (or two) as a field
— but under a general affine map, that arc generically becomes elliptic,
which no longer fits. So `m` applied to one of these returns the more
general [`EGCurvilinearTriangle2`](@ref)/[`EGCurvilinearQuadrilateral2`](@ref)/
[`EGCurvilinearNgon2`](@ref) instead, built from the same sides, each
individually mapped through `m`:

```@example geo
c = EGCircle2(EGPoint(0.0, 0.0), 4.0)
arc = EGCircularArc2(c, EGPoint(4.0, 0.0), EGPoint(0.0, 4.0))
sec = EGCircularSector2(arc)
skew(sec)   # an EGCurvilinearTriangle2: 2 straight sides + 1 elliptic arc
```

`EGCurvilinearTriangle2`/`EGCurvilinearQuadrilateral2`/`EGCurvilinearNgon2`
themselves are already general enough to be closed under this: `m` just
maps each of their sides through itself, whatever mix of segments and
conic arcs they are.

Maps compose with ordinary function composition, `∘`, right-to-left just
like any other Julia functions — `(m2 ∘ m1)(p) == m2(m1(p))`:

```@example geo
composed = rm ∘ tm     # first translate, then rotate
composed(EGPoint(0.0, 0.0))
```

This builds a single new `EGAffineMap` (not a closure), so applying
`composed` to many points is exactly as cheap as applying any other single
map — the composition happens once, up front, not on every call.

## Applying one map to several shapes at once

[`@affinemap`](@ref) applies `m` to a whole `begin ... end` block of
shapes in one expression, returning the results as a tuple:

```@example geo
T1, C1 = @affinemap skew begin
    tri = EGTriangle(EGPoint(0.0, 0.0), EGPoint(1.0, 0.0), EGPoint(0.0, 1.0))
    circ = EGCircle2(EGPoint(1.0, 2.0), 5.0)
end
T1, C1
```

`tri`/`circ` themselves are untouched — [`@affinemap!`](@ref) is the
mutating counterpart, rebinding each named shape to its own image under
`m` instead of returning copies. See
[Transforming in Bulk: Macros](@ref) for the full family this belongs to
(`@translate`, `@rotate`, `@homothety`, `@reflection`, `@invert`,
`@invert_neg`, `@boundingbox`), every `!` mutating counterpart, and how
the block itself is read.
