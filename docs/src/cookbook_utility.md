```@meta
CurrentModule = Apollonius
```

# Cookbook: Checking & Drawing Recipes

## Checking recipes

### Are these points on a circle? On a line?

```@example geo
using Apollonius

a, b, c = APPoint(0.0, 0.0), APPoint(6.0, 0.0), APPoint(5.0, 4.0)
d = point_on(circumcircle(APTriangle(a, b, c)), 2.0)
is_concyclic(a, b, c, d), is_collinear(a, b, c)
```

```@raw html
<img src="../assets/img/predicates/concyclic.svg" alt="Three points, their circumcircle dashed, a fourth point on it in purple and a fifth point off it in gray" style="width:100%; max-width: 700px;">
```

### Which side of a line, and is a point in a region?

```@example geo
l = APLine(APPoint(0.0, 0.0), APPoint(4.0, 2.0))
side_of_line(APPoint(1.0, 3.0), l), APPoint(1.0, 1.0) in APHalfPlane2(l, APPoint(1.0, 3.0))
```

```@raw html
<img src="../assets/img/predicates/side.svg" alt="A line oriented by an arrow, with a point on its left marked +1, a point on its right marked -1 and a point on it marked 0" style="width:100%; max-width: 700px;">
```

See [Predicates](@ref).

## Drawing recipes

### Fit a construction to a canvas

```julia
using Apollonius, Luxor

t = APTriangle(APPoint(0.0, 0.0), APPoint(6.0, 0.0), APPoint(1.5, 4.0))
cc = circumcircle(t)

lxm, lxo = @prepare_to_picture width=500 margin=30 begin
    t
    cc
end
```

```@raw html
<img src="../assets/img/getting_started/first_figure.svg" alt="A triangle with its circumcircle and incircle, the two centers and the labels" style="width:100%; max-width: 700px;">
```

`lxm` holds the canvas size, and `lxo` the objects in canvas coordinates, under the
names they had in the block. Every name in the block must be an object with a size. See
[Workflow: From Construction to Figure](@ref).

### Put a label outside a vertex

```julia
A2, B2, C2 = vertices(lxo.t)
G = centroid(lxo.t)
for (v, name) in zip((A2, B2, C2), ("A", "B", "C"))
    label(name, label_anchor(v, G)...)
end
```

```@raw html
<img src="../assets/img/workflow/decorate.svg" alt="Equal tangent segments marked with ticks and vertex labels placed outside the triangle" style="width:100%; max-width: 700px;">
```

### Mark equal sides and a right angle

On the fitted vertices `A2`, `B2` and `C2` of the previous recipe:

```julia
path(marks(APSegment(A2, B2); count=2); action=:stroke)             # two ticks
path(APAngle2(A2, B2, C2); as=:rarc, radius=12, action=:stroke)     # the right-angle square
```

```@raw html
<img src="../assets/img/decorations/full_figure.svg" alt="A triangle with equal-side marks, angle marks, an arrowhead, a brace and labels" style="width:100%; max-width: 700px;">
```

Marks, braces, arrowheads and their styles are in
[Marks, Labels & Decorations](@ref).

### Draw a curve that goes on forever

Infinite lines and conics have no size, so name them with
[`@unbounded`](@ref) inside the fitting block and draw them with `extend`:

```julia
lxm, lxo = @prepare_to_picture width=500 begin
    t
    l = APLine(t[1], t[2])
end
path(lxo.l, action=:stroke, extend=500)
```

```@raw html
<img src="../assets/img/cookbook/unbounded_line.svg" alt="A triangle and the line through two of its vertices, drawn without end" style="width:100%; max-width: 700px;">
```
