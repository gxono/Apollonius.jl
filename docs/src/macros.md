```@meta
CurrentModule = Apollonius
```

# Transforming in Bulk: Macros

Applying the same transform to several shapes one at a time is repetitive:
`c2 = rotate(c, angle); s2 = rotate(s, angle); t2 = rotate(t, angle)`. Every
transform in the package ([`translate`](@ref), [`rotate`](@ref),
[`homothety`](@ref), [`reflection`](@ref), [`invert`](@ref)/
[`invert_neg`](@ref), and [`APAffineMap`](@ref) application) has a matching
macro that instead takes a whole `begin ... end` block naming several
shapes at once, applies the transform to each, and returns the results
together as a tuple, plus a mutating `!` counterpart that rebinds each
shape's own variable instead of returning a copy. [`@boundingbox`](@ref)
follows the same block syntax to build the one box around everything
listed, rather than applying a transform.

| Macro | Transform applied | Mutating form |
|:------|:-------------------|:--------------|
| [`@boundingbox`](@ref) | (builds one [`APBoundingBox`](@ref) around everything) | (none) |
| [`@translate`](@ref) | [`translate`](@ref) | [`@translate!`](@ref) |
| [`@rotate`](@ref) | [`rotate`](@ref) | [`@rotate!`](@ref) |
| [`@homothety`](@ref) | [`homothety`](@ref) | [`@homothety!`](@ref) |
| [`@reflection`](@ref) | [`reflection`](@ref) | [`@reflection!`](@ref) |
| [`@invert`](@ref) | [`invert`](@ref) | [`@invert!`](@ref) |
| [`@invert_neg`](@ref) | [`invert_neg`](@ref) | [`@invert_neg!`](@ref) |
| [`@affinemap`](@ref) | any [`APAffineMap`](@ref) | [`@affinemap!`](@ref) |

## Reading the block

Every one of these macros reads its `begin ... end` block the same way,
top to bottom, as ordinary code (not a new scope, there's no `let`):

* an **assignment** `name = expr` runs as written, and `name`'s value is
  the one transformed;
* a **destructuring assignment** `name1, name2, ... = expr` (what
  functions returning several shapes at once naturally look like, e.g.
  [`external_tangent_lines`](@ref)) runs the same way, and *each* name is
  transformed individually, exactly as if it had its own `name = ...` line;
* a **bare expression** (most often the name of a shape defined earlier,
  outside the block or on an earlier line inside it) has its value
  transformed directly, with nothing (re)assigned.

A single shape/expression instead of a full block also works
(`@rotate angle c`), treated as a one-line block; with only one item, the
result is returned bare rather than wrapped in a 1-tuple.

```@example geo
using Apollonius

c = APCircle2(APPoint(1.0, 2.0), 3.0)
s = APSegment(APPoint(0.0, 0.0), APPoint(4.0, 0.0))

C2, S2 = @rotate (pi / 2) begin
    c
    s
end
C2, S2
```

```@example geo
c1, c2 = APCircle2(APPoint(0.0, 0.0), 2.0), APCircle2(APPoint(10.0, 0.0), 1.0)

L1, L2 = @rotate (pi / 2) begin
    l1, l2 = external_tangent_lines(c1, c2)   # destructuring assignment
end
L1, L2
```

A named item can even be a plain `Vector` of shapes (what
[`intersection`](@ref)/[`tangent_points`](@ref) return, since they can
give 0, 1 or 2 points depending on the geometry), and it's transformed
element-wise, via [`translate`](@ref)/[`rotate`](@ref)/[`homothety`](@ref)/
[`reflection`](@ref)/[`invert`](@ref)/[`invert_neg`](@ref)'s own
`AbstractVector{<:APObject}` methods (plain broadcasting under the hood):

```@example geo
P1, P2 = intersection.(l1, [c1, c2])   # each a Vector{APPoint} (l1 is tangent to both)

Q1, Q2 = @rotate (pi / 2) begin
    P1
    P2
end
Q1, Q2
```

## `@boundingbox`

Builds one [`APBoundingBox`](@ref) around every shape listed: shorthand
for `reduce(bbox_union, APBoundingBox.(shapes))`, [`bbox_union`](@ref)
itself being the box around two boxes:

```@example geo
t = APTriangle(APPoint(0.0, 0.0), APPoint(5.0, 1.0), APPoint(2.0, 4.0))
circ = APCircle2(APPoint(-1.0, -1.0), 1.5)

@boundingbox begin
    t
    circ
end
```

```@example geo
bbox_union(APBoundingBox(t), APBoundingBox(circ))   # exactly what @boundingbox computed above
```

Blocks like this often mix in plain construction helpers alongside the
actual shapes: a center point, a radius, a scalar computed along the
way. `APBoundingBox` handles every one of those without erroring:

  - a bare [`APPoint`](@ref) gets its own degenerate (zero-size) box at
    its own location: a point *is* a position, so it grows a
    [`bbox_union`](@ref) exactly like any other shape;
  - a plain number, an [`APVector`](@ref) (a direction, not a location),
    or an unbounded curve/region (`APLine`, `APRay`, `APAngle2`,
    `APHalfPlane2`, `APStrip2`) has no position of its own to report, so
    `APBoundingBox` returns the *empty* box for these instead: the
    identity element for `bbox_union`, so combining it with anything else
    just returns that other box unchanged:

```@example geo
centro = APPoint(2.0, 1.0)
radio = 5.0

@boundingbox begin
    centro
    radio
end
```

```@example geo
isempty(APBoundingBox(radio)), bbox_union(APBoundingBox(radio), APBoundingBox(centro)) == APBoundingBox(centro)
```

An empty block is an `ArgumentError`: there's no box to build:

```@example geo
try
    @boundingbox begin end
catch e
    e
end
```

## `@to_luxor_picture` / `@to_luxor_picture!`

Preparing a set of shapes to actually *draw* usually means answering three
fiddly questions by hand: how big is this thing, how far do I need to
shift it so it isn't half off-canvas, and what canvas size do I even pass
to `Drawing`? [`@to_luxor_picture`](@ref) answers all three in one call:
it translates and uniformly scales every shape in the block so their
combined [`APBoundingBox`](@ref) fits centered on `(0, 0)`, and returns
two `NamedTuple`s: the first has the canvas size and the fitting function
(`width`, `height`, `fct`, `bb`), and the second has the transformed shapes,
one field per name in the block. Throughout this documentation they are called
`lxm` (the "Luxor meta") and `lxo` (the "Luxor objects"). Centering on `(0, 0)` matches Luxor's own
`origin()` convention, so the result is ready to draw right after
`origin()`, which `@png`/`@svg`/`@pdf` already call for you. Despite the
name, this macro is plain geometry: it has no Luxor dependency at all;
see [Drawing with Luxor.jl](@ref) for the full `Drawing`/`path`/`finish`
workflow this is designed to feed directly.

It also reflects everything across the x-axis by default (`flip=true`):
this package's own geometry follows the standard math convention (`y` up,
counterclockwise angles positive), but Luxor (like most 2D graphics
APIs) draws with `y` increasing *downward*, so left uncorrected,
everything would render as a vertical mirror image of how it reads on
paper. Pass `flip=false` to get the raw, un-mirrored coordinates instead:

```@example geo
t = APTriangle(APPoint(0.0, 0.0), APPoint(80.0, 0.0), APPoint(0.0, 80.0))

lxm, lxo = @to_luxor_picture width = 200.0 begin
    t
end
lxo.t.c   # (0, 80) in t's own coordinates ends up with a *negative* y here
```

```@example geo
lxm_noflip, lxo_noflip = @to_luxor_picture width = 200.0 flip = false begin
    t
end
lxo_noflip.t.c   # flip=false: the raw, un-mirrored coordinates
```

```@example geo
lxm, lxo = @to_luxor_picture begin
    c = APCircle2(APPoint(3.0, -1.0), 5.0)
    s = APSegment(APPoint(-2.0, 4.0), APPoint(6.0, -3.0))
end
lxm.width, lxm.height   # the combined bbox is already 10x10, so this is its natural size
```

The shapes are built inside the block, and the second value has them back
under the same names, so nothing has to be written twice:

```@example geo
lxo.c, lxo.s   # translated so the combined bbox is centered on (0, 0)
```

```@example geo
(; c, s) = lxo    # or bring them all into scope at once, under their own names
c
```

Being a `NamedTuple`, `lxm` supports `lxm.width`/`lxm.height`, and it still
destructures positionally like a plain tuple, so `(w, h), lxo =
@to_luxor_picture begin ... end` works if that is all you need. `lxo`
destructures by position too, in the order of the block.

Every line of the block has a name, which is what it is returned under: an
assignment `name = expr`, a destructuring assignment `p, q = expr` (`p` and
`q` become two fields), or the name of a shape defined earlier written on its
own line. A name assigned twice keeps its last value. Any other bare
expression is an `ArgumentError`, since it would have nothing to be returned
as. The originals (`c` and `s` above) are untouched: see
[`@to_luxor_picture!`](@ref) below for the mutating form.

This includes how construction helpers are handled: a bare
[`APPoint`](@ref) is repositioned along with everything else (it's a real
position), while a plain number or an [`APVector`](@ref) is left
completely untouched (there's no position to move, and a number in
particular isn't the kind of value `translate`/`homothety` know how to
transform):

```@example geo
centro = APPoint(2.0, 1.0)
radio = 5.0
circ2 = APCircle2(centro, radio)

lxm, lxo = @to_luxor_picture width = 400.0 begin
    centro
    radio
    circ2
end
lxo.radio == radio, lxo.centro   # radio untouched; centro repositioned like circ2
```

An unbounded shape (`APLine`, `APRay`, `APAngle2`, `APHalfPlane2`,
`APStrip2`) is a third case: it doesn't contribute to the canvas size
(no finite extent to report; see [`APBoundingBox()`](@ref)), but it *is*
still repositioned along with everything else, since (unlike a number or
a vector) it does have a position and does support `translate`/
`homothety` like any other shape:

```@example geo
c1, c2 = APCircle2(APPoint(0.0, 0.0), 3.0), APCircle2(APPoint(10.0, 0.0), 3.0)

lxm, lxo = @to_luxor_picture width = 200.0 begin
    c1
    c2
    ext1, ext2 = external_tangent_lines(c1, c2)  # destructuring assignment
end
lxo.ext1   # repositioned exactly like lxo.c1 and lxo.c2, even though its own bbox is empty
```

A block with nothing but non-positional values (numbers/vectors, with no
shape carrying a real position at all) is an `ArgumentError`: there's no
finite content to size a canvas around.

A named item can also be a plain `Vector` of shapes (see the same
capability under [Reading the block](@ref) above), e.g. the result of
`intersection.(ext1, [c1, c2])`, and it's repositioned element-wise right
alongside everything else.

### Sizing options

| Option | Effect |
|:-------|:-------|
| *(none)* | scale factor `1.0`: the shapes' own coordinate units become output units directly |
| `scale` | a literal, uniform multiplier |
| `width` (alone) | scaled so the content's width comes out exactly `width` minus `margin`; height follows to preserve the aspect ratio |
| `height` (alone) | symmetric |
| `width` *and* `height` | a "contain" fit: scaled by whichever of the two is more restrictive, so the content fits inside *both* without distortion |
| `margin` | blank space guaranteed around the content on every side (default `0.0`) |

`scale` and `width`/`height` are mutually exclusive: combining them is an
error. The scale factor is **always** the same in `x` and `y`: a circle
passed through `@to_luxor_picture` is always still a circle, never
distorted into an ellipse, no matter which sizing option is used.

```@example geo
c, s = APCircle2(APPoint(3.0, -1.0), 5.0), APSegment(APPoint(-2.0, 4.0), APPoint(6.0, -3.0))
lxm, _ = @to_luxor_picture width=400.0 begin
    c
    s
end
lxm.width, lxm.height   # height follows to keep the (here already square) aspect ratio
```

```@example geo
c, s = APCircle2(APPoint(3.0, -1.0), 5.0), APSegment(APPoint(-2.0, 4.0), APPoint(6.0, -3.0))
lxm, _ = @to_luxor_picture scale=2.0 begin
    c
    s
end
lxm.width, lxm.height   # canvas size is derived from the scaled content, not requested
```

When `width` and `height` are given together and don't match the
content's own aspect ratio, the content is scaled by whichever bound is
more restrictive and *centered* in the requested canvas: extra blank
space (beyond `margin`) lands on whichever axis has slack, rather than
stretching the content to fill it:

```@example geo
t = APTriangle(APPoint(0.0, 0.0), APPoint(6.0, 0.0), APPoint(3.0, 5.0))
circ = APCircle2(APPoint(3.0, 2.0), 1.5)

lxm, lxo = @to_luxor_picture width=400.0 height=200.0 margin=10.0 begin
    t
    circ
end
(lxm.width, lxm.height), lxo.circ   # the circle is still an APCircle2, never distorted
```

`margin` works the same way whether or not `width`/`height` are given:
with neither, it simply pads the content's own natural size on every side:

```@example geo
c, s = APCircle2(APPoint(3.0, -1.0), 5.0), APSegment(APPoint(-2.0, 4.0), APPoint(6.0, -3.0))
lxm, _ = @to_luxor_picture margin=3.0 begin
    c
    s
end
lxm.width, lxm.height   # the natural 10x10 size, padded by 3 on every side
```

Combining `scale` with `width`/`height` is an error: raised as soon as
the macro call itself is expanded, before any of the block even runs:

```@example geo
try
    eval(:(@to_luxor_picture scale=2.0 width=10.0 c))
catch e
    e
end
```

### `@to_luxor_picture!`

The mutating counterpart: rebinds each *named* shape (an assignment, or a
bare reference to a shape defined earlier) to its own translated/scaled
image, instead of returning copies, the same relationship
[`@translate!`](@ref) has to [`@translate`](@ref). Since the shapes are
already accessible under their own names afterward, it returns just the
first `NamedTuple` (`lxm`). The non-mutating form does the same job explicitly
with `(; c3, s3) = lxo`, and leaves the originals alone, so it is the one used
in this documentation:

```@example geo
c3 = APCircle2(APPoint(3.0, -1.0), 5.0)
s3 = APSegment(APPoint(-2.0, 4.0), APPoint(6.0, -3.0))

lxm = @to_luxor_picture! width=50.0 begin
    c3
    s3
end
(lxm.width, lxm.height), c3, s3   # c3/s3 themselves now refer to the translated/scaled shapes
```

A bare, unnamed expression has nothing to rebind, so this form rejects it
(same as `@translate!` and the rest of that family); see
[Drawing with Luxor.jl](@ref) for the complete pipeline, from a bare set
of `APPoint`/`APTriangle`/etc. all the way to a finished PNG.

## `@translate` / `@translate!`

```@example geo
v = APVector(2.0, -1.0)

T1, S1 = @translate v begin
    t
    s
end
T1
```

`t`/`s` themselves are untouched by `@translate`; `@translate!` instead
rebinds each *named* shape's own variable to its translated image (the
object itself never mutates, since these are all immutable structs; only
the variable is repointed, the same trick `Setfield.jl`'s `@set!` uses):

```@example geo
t3 = APTriangle(APPoint(0.0, 0.0), APPoint(1.0, 0.0), APPoint(0.0, 1.0))
@translate! v t3
t3   # t3 itself now refers to the translated triangle
```

A bare, unnamed expression has nothing to rebind, so the mutating forms
reject it:

```@example geo
try
    @translate! v begin
        APPoint(0.0, 0.0)   # not assigned to a name
    end
catch e
    e
end
```

## `@rotate` / `@rotate!`

Takes an optional `center` (defaults to the origin, exactly like
[`rotate`](@ref) itself):

```@example geo
R1, R2 = @rotate (pi / 2) APPoint(1.0, 1.0) begin
    t
    circ
end
R1
```

```@example geo
t4 = APTriangle(APPoint(0.0, 0.0), APPoint(1.0, 0.0), APPoint(0.0, 1.0))
@rotate! (pi / 2) t4
t4
```

## `@homothety` / `@homothety!`

Also takes an optional `center` (default: the origin):

```@example geo
H1, H2 = @homothety 2.0 begin
    t
    circ
end
H1
```

```@example geo
t5 = APTriangle(APPoint(0.0, 0.0), APPoint(1.0, 0.0), APPoint(0.0, 1.0))
@homothety! (-1.0) APPoint(0.5, 0.5) t5   # a point reflection through (0.5, 0.5)
t5
```

## `@reflection` / `@reflection!`

`about` a point or a line, same as [`reflection`](@ref) itself:

```@example geo
mirror = APLine(APPoint(0.0, 0.0), APPoint(1.0, 1.0))

M1, M2 = @reflection mirror begin
    t
    circ
end
M1
```

```@example geo
t6 = APTriangle(APPoint(0.0, 0.0), APPoint(1.0, 0.0), APPoint(0.0, 1.0))
@reflection! APPoint(2.0, 2.0) t6
t6
```

## `@invert` / `@invert!` and `@invert_neg` / `@invert_neg!`

[`invert`](@ref)/[`invert_neg`](@ref) with respect to the circle centered
at `center` (radius `k`, defaulting to `1.0`); note that inversion can
change a shape's own *type* (an `APLine` not through `center` inverts to
an `APCircle2`, and vice versa), no different here:

```@example geo
center = APPoint(0.0, 0.0)
far_line = APLine(APPoint(2.0, 0.0), APPoint(2.0, 1.0))

I1, I2 = @invert center 3.0 begin
    far_line
    circ
end
I1   # an APCircle2: far_line doesn't pass through center
```

`@invert!` is the mutating form, exactly like every other macro's `!`
counterpart:

```@example geo
near_line = APLine(APPoint(0.5, 0.0), APPoint(0.5, 1.0))
@invert! center 3.0 near_line
near_line   # rebound to its own inverted image
```

`@invert_neg` is the negative-ratio counterpart, used the same way:

```@example geo
far_line2 = APLine(APPoint(2.0, 0.0), APPoint(2.0, 1.0))
@invert_neg! center far_line2
far_line2
```

## `@affinemap` / `@affinemap!`

Applies any [`APAffineMap`](@ref) `m`, exactly like calling `m(shape)`
by hand; see [Affine Maps](@ref) for how `m` itself is built:

```@example geo
m = APAffineMap(1.3, 0.4, -0.2, 0.9, 0.0, 0.0)

T7, C7 = @affinemap m begin
    t
    circ
end
T7   # circ, being non-similarity-mapped, would come back as an APEllipse2, see Affine Maps
```

```@example geo
t8 = APTriangle(APPoint(0.0, 0.0), APPoint(1.0, 0.0), APPoint(0.0, 1.0))
@affinemap! m t8
t8
```

## Embedding a macro call inside another expression

When a call to any of these (besides `@boundingbox`, which only takes one
argument before the block) appears as an *argument* to something else,
rather than its own statement, wrap it in parentheses:

```julia
f((@rotate angle p), other_arg)    # correct
f(@rotate angle p, other_arg)      # wrong: swallows other_arg into the macro call
```

This is a general rule for any multi-argument macro call in Julia (a bare
`@macro arg1 arg2` swallows comma-separated arguments that follow), not
specific to this package: a plain statement like `x = @rotate angle p`
never runs into it.
