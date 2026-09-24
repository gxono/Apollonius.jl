```@meta
CurrentModule = Apollonius
```

# Macros: Transforming Shapes

The triangle, circle and segment left over from [Macros: Sizing a Picture](@ref):

```@example geo
using Apollonius

t = APTriangle(APPoint(0.0, 0.0), APPoint(80.0, 0.0), APPoint(0.0, 80.0))
circ = APCircle2(APPoint(-1.0, -1.0), 1.5)
s = APSegment(APPoint(-2.0, 4.0), APPoint(6.0, -3.0))
nothing # hide
```

## `@translate` / `@translate!`

```@example geo
v = APVector(2.0, -1.0)

T1, S1 = @translate v begin
    t
    s
end
T1
```

```@raw html
<img src="../assets/img/macros/translate.svg" alt="A triangle and a segment with their translated images" style="width:100%; max-width: 700px;">
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

```@raw html
<img src="../assets/img/macros/rotate.svg" alt="A triangle and a circle rotated a quarter turn about a point" style="width:100%; max-width: 700px;">
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

```@raw html
<img src="../assets/img/macros/homothety.svg" alt="A triangle and a circle scaled by 2 about the origin" style="width:100%; max-width: 700px;">
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

```@raw html
<img src="../assets/img/macros/reflection.svg" alt="A triangle and a circle reflected across a line" style="width:100%; max-width: 700px;">
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

```@raw html
<img src="../assets/img/macros/invert.svg" alt="A line and a circle inverted with respect to a circle centered at the origin" style="width:100%; max-width: 700px;">
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

```@raw html
<img src="../assets/img/macros/invert_neg.svg" alt="A line and a circle inverted with negative ratio with respect to a circle centered at the origin" style="width:100%; max-width: 700px;">
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

```@raw html
<img src="../assets/img/macros/affinemap.svg" alt="A triangle and a circle under an affine map: the circle becomes an ellipse" style="width:100%; max-width: 700px;">
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

