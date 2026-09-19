```@meta
CurrentModule = Apollonius
```

# Types & Operations

This page explains how the types are named and grouped, and shows which
operations each one supports. The tree itself is on the
[Home](@ref The-type-hierarchy) page.

## Reading a name

* Every type starts with `AP`.
* A `2` at the end means the formulas only make sense in the plane
  (`APCircle2`, `APAngle2`). A type without it is written for any
  dimension (`APPoint`, `APSegment`), and carries its dimension as a type
  parameter: `APPoint{2,Float64}` is a point in the plane with `Float64`
  coordinates.
* The two type parameters are always the same: `Dim`, the dimension, and
  `T`, the number type. See [Numbers & Tolerances](@ref).

## What each level of the tree means

The abstract types say what a shape is, and each one brings functions that
work for every type below it.

| Type | What it is | Brings |
|:-----|:-----------|:-------|
| [`APObject`](@ref) | anything in the package | the transformations, `≈`, `show` |
| [`APLocus`](@ref) | the set of points that satisfy a condition | |
| [`APCurve`](@ref) | a locus with no interior: lines, rays, segments, conics, arcs, chains | `distance`, `arc_length` where it applies |
| [`APSet`](@ref) | a locus with an inside, bounded or not | `in` |
| [`APRegion`](@ref) | a set with finite extent | |
| [`APPolygon`](@ref) | a closed region bounded by straight or curved sides | [`area`](@ref), [`perimeter`](@ref), [`centroid`](@ref), [`is_convex`](@ref), [`point_in_polygon`](@ref) |
| [`APTransform`](@ref) | a function between objects, such as [`APAffineMap`](@ref) | it is not an `APObject` |

[`APPoint`](@ref), [`APVector`](@ref) and [`APBoundingBox`](@ref) are
`APObject`s outside the locus branch: a point is a position, a vector a
direction, and a bounding box an axis-aligned convenience.

Two things are worth knowing. An [`APCircle2`](@ref) is a curve (the
circumference), yet it has an [`area`](@ref) and `p in circle` means "inside
the disk", as for an ellipse. And an unbounded set such as an
[`APAngle2`](@ref) has `in` but no `area`.

## What each type supports

Each row is a type, each column an operation, and a check means that the
operation is defined for that type. The table is computed when the
documentation is built, so it is always what the code does.

```@example geo
using Apollonius, InteractiveUtils, Markdown # hide
A = Apollonius # hide
P, V, L = A.APPoint{2,Float64}, A.APVector{2,Float64}, A.APLine{2,Float64} # hide
M = A.APAffineMap(1.0, 0.0, 0.0, 1.0, 0.0, 0.0) # hide
concrete(T, acc=Any[]) = (for S in subtypes(T); isabstracttype(S) ? concrete(S, acc) : push!(acc, S); end; acc) # hide
function filled(S) # hide
    b, vars = S, [] # hide
    while b isa UnionAll; push!(vars, b.var); b = b.body; end # hide
    isempty(vars) && return S # hide
    try return S{[v.name == :Dim ? 2 : Float64 for v in vars]...} catch; return nothing end # hide
end # hide
specific_in(T) = hasmethod(Base.in, Tuple{P,T}) && Base.unwrap_unionall(which(Base.in, Tuple{P,T}).sig).parameters[3] <: A.APObject # hide
ops = [ # hide
    "translate" => T -> hasmethod(A.translate, Tuple{T,V}), # hide
    "rotate" => T -> hasmethod(A.rotate, Tuple{T,Float64,P}) || hasmethod(A.rotate, Tuple{T,Float64}), # hide
    "homothety" => T -> hasmethod(A.homothety, Tuple{T,Float64,P}) || hasmethod(A.homothety, Tuple{T,Float64}), # hide
    "reflection" => T -> hasmethod(A.reflection, Tuple{T,L}), # hide
    "affine map" => T -> hasmethod(M, Tuple{T}), # hide
    "invert" => T -> hasmethod(A.invert, Tuple{T,P}), # hide
    "distance" => T -> hasmethod(A.distance, Tuple{P,T}) || hasmethod(A.distance, Tuple{T,P}), # hide
    "in" => specific_in, # hide
    "area" => T -> hasmethod(A.area, Tuple{T}), # hide
    "bounding box" => T -> hasmethod(A.APBoundingBox, Tuple{T}), # hide
] # hide
rows = sort([(string(nameof(S)), filled(S)) for S in unique(concrete(A.APObject)) if !occursin("3", string(nameof(S)))]; by=first) # hide
lines = ["| Type | " * join(first.(ops), " | ") * " |", "|:-----|" * join(fill(":-:", length(ops)), "|") * "|"] # hide
for (n, T) in rows # hide
    T === nothing && continue # hide
    push!(lines, "| `$n` | " * join([last(o)(T) ? "✓" : "" for o in ops], " | ") * " |") # hide
end # hide
Markdown.parse(join(lines, "\n")) # hide
```

The blank cells are, with a few exceptions, deliberate:

* **`invert`.** Inversion sends a line or a circle to a line or a circle, and
  a polygon to a shape with curved sides, but it does not keep an ellipse, a
  conic arc or an angle inside their own type, so it is not defined for them.
* **`bounding box`.** A parabola and a hyperbola are unbounded, and have
  none.
* **`area`.** Only closed shapes have one.
* **`APBoundingBox`.** It stays axis-aligned, so it has no `rotate`,
  `reflection` or affine map. Transform the object and take its box again.
* **`APVector`.** A vector is a direction, so it has no `translate`, and it
  rotates without a center: `rotate(v, angle)`.
* **`distance`.** It is not defined for a vector, an anchored vector or a
  parametric curve.

`rotate` and `homothety` take a center, and `reflection` takes a line or a
point. Their one-argument forms (`rotate(angle)`) return a function of the
object, ready for `map` and `|>`; see [Affine Maps](@ref).

## Finding what a type supports

The table answers "does it exist". To see how a function treats a type, ask
Julia:

```@example geo
hasmethod(area, Tuple{APEllipse2{Float64}}), hasmethod(area, Tuple{APSegment{2,Float64}})
```

`methods(distance)` lists every pair of types `distance` accepts, and
`?distance` in the REPL shows the documentation of the function. The pages
of this manual say how each function behaves for each type:
[Measurements & Queries](@ref) for numbers, [Predicates](@ref) for yes/no
questions and [Intersections](@ref) for where two objects meet.
