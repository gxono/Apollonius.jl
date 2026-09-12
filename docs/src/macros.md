```@meta
CurrentModule = EuclideanGeometry
```

# Transforming in Bulk: Macros

Applying the same transform to several shapes one at a time is repetitive:
`c2 = rotate(c, angle); s2 = rotate(s, angle); t2 = rotate(t, angle)`. Every
transform in the package ([`translate`](@ref), [`rotate`](@ref),
[`homothety`](@ref), [`reflection`](@ref), [`invert`](@ref)/
[`invert_neg`](@ref), and [`EGAffineMap`](@ref) application) has a matching
macro that instead takes a whole `begin ... end` block naming several
shapes at once, applies the transform to each, and returns the results
together as a tuple — plus a mutating `!` counterpart that rebinds each
shape's own variable instead of returning a copy. [`@boundingbox`](@ref)
follows the same block syntax to build the one box around everything
listed, rather than applying a transform.

| Macro | Transform applied | Mutating form |
|:------|:-------------------|:--------------|
| [`@boundingbox`](@ref) | — (builds one [`EGBoundingBox`](@ref) around everything) | — |
| [`@translate`](@ref) | [`translate`](@ref) | [`@translate!`](@ref) |
| [`@rotate`](@ref) | [`rotate`](@ref) | [`@rotate!`](@ref) |
| [`@homothety`](@ref) | [`homothety`](@ref) | [`@homothety!`](@ref) |
| [`@reflection`](@ref) | [`reflection`](@ref) | [`@reflection!`](@ref) |
| [`@invert`](@ref) | [`invert`](@ref) | [`@invert!`](@ref) |
| [`@invert_neg`](@ref) | [`invert_neg`](@ref) | [`@invert_neg!`](@ref) |
| [`@affinemap`](@ref) | any [`EGAffineMap`](@ref) | [`@affinemap!`](@ref) |

![Several shapes rotated together by one @rotate block](assets/img/placeholder.png)

## Reading the block

Every one of these macros reads its `begin ... end` block the same way,
top to bottom, as ordinary code (not a new scope — there's no `let`):

* an **assignment** `name = expr` runs as written, and `name`'s value is
  the one transformed;
* a **bare expression** — most often the name of a shape defined earlier,
  outside the block or on an earlier line inside it — has its value
  transformed directly, with nothing (re)assigned.

A single shape/expression instead of a full block also works
(`@rotate angle c`), treated as a one-line block; with only one item, the
result is returned bare rather than wrapped in a 1-tuple.

```@example geo
using EuclideanGeometry

c = EGCircle2(EGPoint(1.0, 2.0), 3.0)
s = EGSegment(EGPoint(0.0, 0.0), EGPoint(4.0, 0.0))

C2, S2 = @rotate (pi / 2) begin
    c
    s
end
C2, S2
```

## `@boundingbox`

Builds one [`EGBoundingBox`](@ref) around every shape listed — shorthand
for `reduce(bbox_union, EGBoundingBox.(shapes))`, [`bbox_union`](@ref)
itself being the box around two boxes:

```@example geo
t = EGTriangle(EGPoint(0.0, 0.0), EGPoint(5.0, 1.0), EGPoint(2.0, 4.0))
circ = EGCircle2(EGPoint(-1.0, -1.0), 1.5)

@boundingbox begin
    t
    circ
end
```

```@example geo
bbox_union(EGBoundingBox(t), EGBoundingBox(circ))   # exactly what @boundingbox computed above
```

An empty block is an `ArgumentError` — there's no box to build:

```@example geo
try
    @boundingbox begin end
catch e
    e
end
```

## `@translate` / `@translate!`

```@example geo
v = EGVector(2.0, -1.0)

T1, S1 = @translate v begin
    t
    s
end
T1
```

`t`/`s` themselves are untouched by `@translate` — `@translate!` instead
rebinds each *named* shape's own variable to its translated image (the
object itself never mutates, since these are all immutable structs; only
the variable is repointed, the same trick `Setfield.jl`'s `@set!` uses):

```@example geo
t3 = EGTriangle(EGPoint(0.0, 0.0), EGPoint(1.0, 0.0), EGPoint(0.0, 1.0))
@translate! v t3
t3   # t3 itself now refers to the translated triangle
```

A bare, unnamed expression has nothing to rebind, so the mutating forms
reject it:

```@example geo
try
    @translate! v begin
        EGPoint(0.0, 0.0)   # not assigned to a name
    end
catch e
    e
end
```

## `@rotate` / `@rotate!`

Takes an optional `center` (defaults to the origin, exactly like
[`rotate`](@ref) itself):

```@example geo
R1, R2 = @rotate (pi / 2) EGPoint(1.0, 1.0) begin
    t
    circ
end
R1
```

```@example geo
t4 = EGTriangle(EGPoint(0.0, 0.0), EGPoint(1.0, 0.0), EGPoint(0.0, 1.0))
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
t5 = EGTriangle(EGPoint(0.0, 0.0), EGPoint(1.0, 0.0), EGPoint(0.0, 1.0))
@homothety! (-1.0) EGPoint(0.5, 0.5) t5   # a point reflection through (0.5, 0.5)
t5
```

## `@reflection` / `@reflection!`

`about` a point or a line, same as [`reflection`](@ref) itself:

```@example geo
mirror = EGLine(EGPoint(0.0, 0.0), EGPoint(1.0, 1.0))

M1, M2 = @reflection mirror begin
    t
    circ
end
M1
```

```@example geo
t6 = EGTriangle(EGPoint(0.0, 0.0), EGPoint(1.0, 0.0), EGPoint(0.0, 1.0))
@reflection! EGPoint(2.0, 2.0) t6
t6
```

## `@invert` / `@invert!` and `@invert_neg` / `@invert_neg!`

[`invert`](@ref)/[`invert_neg`](@ref) with respect to the circle centered
at `center` (radius `k`, defaulting to `1.0`) — note that inversion can
change a shape's own *type* (an `EGLine` not through `center` inverts to
an `EGCircle2`, and vice versa), no different here:

```@example geo
center = EGPoint(0.0, 0.0)
far_line = EGLine(EGPoint(2.0, 0.0), EGPoint(2.0, 1.0))

I1, I2 = @invert center 3.0 begin
    far_line
    circ
end
I1   # an EGCircle2: far_line doesn't pass through center
```

`@invert!` is the mutating form, exactly like every other macro's `!`
counterpart:

```@example geo
near_line = EGLine(EGPoint(0.5, 0.0), EGPoint(0.5, 1.0))
@invert! center 3.0 near_line
near_line   # rebound to its own inverted image
```

`@invert_neg` is the negative-ratio counterpart, used the same way:

```@example geo
far_line2 = EGLine(EGPoint(2.0, 0.0), EGPoint(2.0, 1.0))
@invert_neg! center far_line2
far_line2
```

## `@affinemap` / `@affinemap!`

Applies any [`EGAffineMap`](@ref) `m`, exactly like calling `m(shape)`
by hand — see [Affine Maps](@ref) for how `m` itself is built:

```@example geo
m = EGAffineMap(1.3, 0.4, -0.2, 0.9, 0.0, 0.0)

T7, C7 = @affinemap m begin
    t
    circ
end
T7   # circ, being non-similarity-mapped, would come back as an EGEllipse2 — see Affine Maps
```

```@example geo
t8 = EGTriangle(EGPoint(0.0, 0.0), EGPoint(1.0, 0.0), EGPoint(0.0, 1.0))
@affinemap! m t8
t8
```

## Embedding a macro call inside another expression

When a call to any of these (besides `@boundingbox`, which only takes one
argument before the block) appears as an *argument* to something else —
not its own statement — wrap it in parentheses:

```julia
f((@rotate angle p), other_arg)    # correct
f(@rotate angle p, other_arg)      # wrong: swallows other_arg into the macro call
```

This is a general rule for any multi-argument macro call in Julia (a bare
`@macro arg1 arg2` swallows comma-separated arguments that follow), not
specific to this package — a plain statement like `x = @rotate angle p`
never runs into it.
