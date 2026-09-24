```@meta
CurrentModule = Apollonius
```

# Affine Maps

[`APAffineMap`](@ref) (`<: APTransform`, deliberately outside the
[`APObject`](@ref) tree; see its own docstring) is a general 2D affine
transformation, `p -> A*p + t` for a `2×2` matrix `A` (stored as four
scalars, `a11 a12 a21 a22`) and a translation `t = (tx, ty)`. It
generalizes [`rotate`](@ref), [`homothety`](@ref), [`reflection`](@ref) and
[`translate`](@ref) into a single reusable, *composable* object, rather
than a one-off function call: build one once, apply it to as many
points/shapes as you like, and combine several into one with plain
function composition (`∘`).

Unlike those four (each always orientation-preserving, or a
straightforward orientation flip for `reflection`), an `APAffineMap` can
be a genuine shear or non-uniform scale, so it's also the place where a
few subtleties specific to *general* affine transformations show up:
circles becoming ellipses, conic arcs sometimes needing their endpoints
swapped, and circular-arc regions becoming curvilinear. Each is covered
below.

## Creating one

The general constructor, [`affine_map`](@ref), builds the unique affine
map sending three given (non-collinear) source points to three chosen
destination points: the 2D affine analogue of "3 points determine a
transformation":

```@example geo
using Apollonius

src = (APPoint(0.0, 0.0), APPoint(1.0, 0.0), APPoint(0.0, 1.0))
dst = (APPoint(2.0, 3.0), APPoint(5.0, 3.0), APPoint(2.0, 7.0))
m = affine_map(src, dst)
```

The same map can be written as three `source => image` pairs, which keeps
each correspondence next to its own points and cannot mix up the order of
two separate tuples:

```@example geo
affine_map(src[1] => dst[1], src[2] => dst[2], src[3] => dst[3]) == m
```

```@raw html
<img src="../assets/img/affine/create.svg" alt="A triangle and its image under the affine map defined by three point pairs" style="width:100%; max-width: 700px;">
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
| [`reflection_map`](@ref) | `p -> reflection(p, l)` or `p -> reflection(p, about)` |

`rotation_map` and `homothety_map` both require `center` explicitly: there
is no zero-argument default here, unlike [`rotate`](@ref)/[`homothety`](@ref)
themselves (a default would let `rotation_map(angle)`/`homothety_map(k)`
alone silently rotate/scale about the origin with no `center` in sight at
the call site). `translation_map` takes either an `APVector` or an `APPoint`
for `v`; `reflection_map` takes either an `APLine` (mirror) or an `APPoint`
(point reflection).

```@example geo
tm = translation_map(APVector(3.0, -2.0))
rm = rotation_map(pi / 2, APPoint(1.0, 1.0))
hm = homothety_map(2.0, APPoint(1.0, 1.0))
refm = reflection_map(APLine(APPoint(0.0, 0.0), APPoint(1.0, 0.0)))
```

Each of these agrees exactly with its point-based counterpart
(`rotation_map(angle, center)(p) == rotate(p, angle, center)`, and likewise
for the other three); the map versions exist purely so the transformation
itself can be stored, composed and reused, rather than re-specifying
`angle`/`center` (or `k`/`center`, or `l`) on every call.

## Similarities, scalings and shears

Three functions build the maps that come up most often, without writing the six
numbers by hand.

| Function | Map |
|:---------|:----|
| [`similarity_map`](@ref)`(k, angle, center)` | scale by `k` and turn by `angle` about `center` (the origin by default) |
| [`similarity_map`](@ref)`(p1 => q1, p2 => q2)` | the unique similarity that sends `p1` to `q1` and `p2` to `q2` |
| [`scaling_map`](@ref)`(sx, sy, center)` | scale by `sx` along `x` and by `sy` along `y` |
| [`shear_map`](@ref)`(kx, ky, center)` | send `(x, y)` to `(x + kx·y, y + ky·x)`, relative to `center` |

A similarity keeps circles as circles; a scaling with `sx != sy` or a shear
turns them into ellipses (see below).

```@example geo
m_sim = similarity_map(APPoint(0.0, 0.0) => APPoint(1.0, 1.0), APPoint(1.0, 0.0) => APPoint(1.0, 2.0))
m_sim(APPoint(0.0, 1.0)), similarity_map(2.0, pi / 2)(APPoint(1.0, 0.0))
```

```@example geo
scaling_map(2.0, 3.0)(APCircle2(APPoint(0.0, 0.0), 1.0)) isa APEllipse2, shear_map(1.0)(APPoint(0.0, 2.0))
```

```@raw html
<img src="../assets/img/affine/similarity_shear.svg" alt="A square and its images under a similarity, a scaling and a shear" style="width:100%; max-width: 700px;">
```


## `rotate`/`homothety`/`translate`/`reflection`, called with one argument

`rotate`, `homothety`, `translate` and `reflection` also have a
single-argument form (`rotate(angle, center)`, `homothety(k, center)`,
`translate(v)`, `reflection(about)`) for `|>`/`∘`/`map`/`filter`
composition without a shape already in hand. Unlike
`rotation_map`/`homothety_map`/`translation_map`/`reflection_map` above,
these are **plain functions**, not `APAffineMap`s: each is just
`shape -> rotate(shape, angle, center)` (and likewise for the other
three), so they *preserve* whatever specific type the direct call already
returns, and they compose without building a matrix. A circle piped
through stays an `APCircle2`:

```@example geo
t = APTriangle(APPoint(0.0, 0.0), APPoint(1.0, 0.0), APPoint(0.0, 1.0))

rotate(pi / 2)(t)                              # rotate(t, pi/2, origin)
t |> translate(APVector(2.0, 0.0)) |> rotate(pi / 2)  # pipe several in a row, each step exact

# circumcircle(t) stays an APCircle2 all the way through, in contrast with
# map(homothety_map(2.0, APPoint(0.0,0.0)), ...) below, which widens it
map(homothety(2.0), [t, circumcircle(t)])
```

```@raw html
<img src="../assets/img/affine/one_argument.svg" alt="A triangle and its circumcircle, with the results of the one-argument rotate, translate and homothety" style="width:100%; max-width: 700px;">
```

The cost of that exactness: composing two of these with `∘` builds
*another plain function* (a chain of type-preserving calls applied one
after another each time), not a single, reusable, inspectable object the
way composing two `APAffineMap`s does:

```@example geo
chain = rotate(pi / 2) ∘ translate(APVector(2.0, 0.0))
chain isa APAffineMap   # false, it is just a Function
chain(circumcircle(t))  # still an APCircle2, computed via 2 exact calls in sequence
```

So the choice between the two families is a genuine tradeoff, not a
strict upgrade either way:

| | `rotate(angle)` etc. | `rotation_map(angle, center)` etc. |
|:--|:--|:--|
| Result type | always the type of the shape | an `APCircle2` stays one under a similarity, becomes an `APEllipse2` otherwise |
| `∘`/pipe result | a plain `Function` (chain of exact calls) | one combined, reusable `APAffineMap` |
| Reapplying many times | re-walks the chain every time | cheap: one precomputed matrix |

Reach for the plain-function form by default (most shapes here have a
type worth keeping exact); reach for the `*_map` form when the map itself
needs to be stored, inspected (`m.a11`, etc.), or reapplied many times as
one precomputed object, and the generic-conic tradeoff is acceptable.

[`invert`](@ref)/[`invert_neg`](@ref) have the same single-argument
convenience (`invert(center; k=1.0)`, see [Circles: Inversion](@ref)), also a plain
closure, circle inversion isn't an affine transformation at all, so
there's no `APAffineMap`-based alternative for it in the first place.

## Applying and composing

An `APAffineMap` is directly callable, and works pointwise on every other
straight-edged type in the package:

```@example geo
m(APPoint(1.0, 0.0))                 # a single point
t = APTriangle(APPoint(0.0, 0.0), APPoint(1.0, 0.0), APPoint(0.0, 1.0))
m(t)                                 # a whole APTriangle, vertex by vertex
```

The same works for `APSegment`, `APLine`, `APRay`, `APStraightNgon`,
`APQuadrilateral`, `APAngle2`, `APHalfPlane2` and `APStrip2`: all
pointwise, vertex by vertex (or endpoint by endpoint). It's also directly
callable on an [`APVector`](@ref), applying the linear part only (no
translation, since a vector has no position):

```@example geo
m(APVector(1.0, 0.0))
```

`APHalfPlane2` needs one extra piece of bookkeeping: unlike `rotate`/
`homothety` (always orientation-preserving in 2D), a general affine map
can reverse orientation, which would flip which side of the transformed
boundary is "inside", so its `side` field is recomputed fresh from an
interior point, rather than carried over unchanged.

## Conics: type is preserved, and a circle stays one under a similarity

An ellipse, hyperbola or parabola stays its *own* conic type under any
invertible affine map (a basic invariant: by Sylvester's law of inertia,
the map acts on a conic's defining quadratic form as a congruence, which
can't change how many of its eigenvalues are positive, negative or zero).
A circle is the one case that depends on the map. Concretely:

- `m(c::APCircle2)` returns an [`APCircle2`](@ref) when the linear part of
  `m` is a *similarity* (a rotation, homothety, reflection or translation,
  or a combination), and an [`APEllipse2`](@ref) otherwise. The same holds
  for circular arcs, sectors, segments, annular sectors and interstices,
  which keep their type under a similarity. The check is on the values of
  `m`, so the return type of `m(circle)` is not known from the type of `m`.
- `m(e::APEllipse2)` returns another `APEllipse2`, `m(h::APHyperbola2)`
  another `APHyperbola2`, `m(par::APParabola2)` another `APParabola2`,
  each computed exactly (no sampling or fitting): the conic's own
  quadratic form transforms as a congruence, which is diagonalized to
  recover the new semi-axes/angle directly (for the parabola, whose
  `focus`/`directrix` are metric rather than affine-invariant quantities,
  the new vertex/focal-parameter are instead recovered from its
  parametrization rewritten in the orthonormal frame aligned with the
  transformed axis direction).

```@example geo
c = APCircle2(APPoint(1.0, 2.0), 5.0)
skew = APAffineMap(2.0, 0.5, -0.3, 1.4, 3.0, -1.0)
skew(c)          # a genuine APEllipse2: the linear part isn't a similarity
rm(c)            # rm is a pure rotation: still an APCircle2
```

```@raw html
<img src="../assets/img/affine/conic_map.svg" alt="A circle and its image under a skewing affine map, an ellipse" style="width:100%; max-width: 700px;">
```

## Conic arcs: orientation-reversing maps need an endpoint swap

`m(arc::APCircularArc2)` returns an `APEllipticArc2` (same reasoning as
the circle case above); `APEllipticArc2`, `APHyperbolicArc2` and
`APParabolicArc2` each map to the same arc type, on the image of their
underlying conic.

For the two *closed*-conic arcs (circular, elliptic), "the arc from `p1`
to `p2`" only picks out one of two complementary arcs because it's
understood to sweep counterclockwise. An orientation-reversing map
(`det(m) < 0`, like a reflection) turns that sweep clockwise, so `p1`/`p2`
are swapped when reconstructing the transformed arc; otherwise it would
silently become the *complementary* arc instead. `APHyperbolicArc2`/
`APParabolicArc2` need no such swap: a single hyperbola branch or a
parabola is open, so two points on it always determine one unambiguous
arc regardless of orientation.

```@raw html
<img src="../assets/img/affine/arc_map.svg" alt="An elliptic arc and its mirror image, with the endpoints swapped so it is still the same piece of curve" style="width:100%; max-width: 700px;">
```

## Circular-arc regions become curvilinear

`APCircularSector2`, `APCircularSegment2`, `APAnnularSector2` and
`APInterstice2` each hold a concrete `APCircularArc2` (or two) as a field,
but under a general affine map, that arc generically becomes elliptic,
which no longer fits. So `m` applied to one of these returns the more
general [`APCurvilinearTriangle2`](@ref)/[`APCurvilinearQuadrilateral2`](@ref)/
[`APCurvilinearNgon2`](@ref) instead, built from the same sides, each
individually mapped through `m`:

```@example geo
c = APCircle2(APPoint(0.0, 0.0), 4.0)
arc = APCircularArc2(c, APPoint(4.0, 0.0), APPoint(0.0, 4.0))
sec = APCircularSector2(arc)
skew(sec)   # an APCurvilinearTriangle2: 2 straight sides + 1 elliptic arc
```

```@raw html
<img src="../assets/img/affine/regions.svg" alt="A circular sector and its image, a curvilinear triangle with an elliptic side" style="width:100%; max-width: 700px;">
```

`APCurvilinearTriangle2`/`APCurvilinearQuadrilateral2`/`APCurvilinearNgon2`
themselves are already general enough to be closed under this: `m` just
maps each of their sides through itself, whatever mix of segments and
conic arcs they are.

Maps compose with ordinary function composition, `∘`, right-to-left just
like any other Julia functions: `(m2 ∘ m1)(p) == m2(m1(p))`:

```@example geo
composed = rm ∘ tm     # first translate, then rotate
composed(APPoint(0.0, 0.0))
```

```@raw html
<img src="../assets/img/affine/composed.svg" alt="A triangle, its translation and the composition of the translation and a rotation" style="width:100%; max-width: 700px;">
```

This builds a single new `APAffineMap` (not a closure), so applying
`composed` to many points is exactly as cheap as applying any other single
map: the composition happens once, up front, not on every call.

## Applying one map to several shapes at once

[`@affinemap`](@ref) applies `m` to a whole `begin ... end` block of
shapes in one expression, returning the results as a tuple:

```@example geo
T1, C1 = @affinemap skew begin
    tri = APTriangle(APPoint(0.0, 0.0), APPoint(1.0, 0.0), APPoint(0.0, 1.0))
    circ = APCircle2(APPoint(1.0, 2.0), 5.0)
end
T1, C1
```

```@raw html
<img src="../assets/img/affine/several.svg" alt="A triangle and a circle with their images under the same affine map" style="width:100%; max-width: 700px;">
```

`tri`/`circ` themselves are untouched. [`@affinemap!`](@ref) is the
mutating counterpart, rebinding each named shape to its own image under
`m` instead of returning copies. See [Macros: Transforming Shapes](@ref)
for the full family this belongs to (`@translate`, `@rotate`,
`@homothety`, `@reflection`, `@invert`, `@invert_neg`) and every `!`
mutating counterpart, and [Macros: Sizing a Picture](@ref) for
[`@boundingbox`](@ref) and how a block is read.
