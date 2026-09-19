"""
    grid_lines(bb::APBoundingBox; step=1.0, xstep=step, ystep=step)

The lines of a grid over `bb`, as a `Vector` of [`APSegment`](@ref)s ready
for `path`: the vertical lines `x = k * xstep` and then the horizontal lines
`y = k * ystep` (`k` an integer, so the grid is anchored at the origin, not
at the corner of `bb`) that fall inside `bb`, each running the full height
or width of `bb`. For a finer subgrid call it again with a smaller step and
draw it thinner. Empty for an empty box. Throws an `ArgumentError` for a
step that is not positive.

| Keyword | Default | Meaning |
|:--------|:--------|:--------|
| `step` | `1.0` | spacing of the vertical and the horizontal lines |
| `xstep` | `step` | spacing of the vertical lines |
| `ystep` | `step` | spacing of the horizontal lines |
"""
function grid_lines(bb::APBoundingBox; step::Real=1.0, xstep::Real=step, ystep::Real=step)
    (xstep > 0 && ystep > 0) || throw(ArgumentError("grid_lines: the steps must be positive"))
    isempty(bb) && return APSegment{2,Float64}[]
    x0, y0, x1, y1 = Float64.((bb.min[1], bb.min[2], bb.max[1], bb.max[2]))
    ks(lo, hi, s) = ceil(Int, lo / s - 1e-9):floor(Int, hi / s + 1e-9)
    vertical = [APSegment(APPoint(k * Float64(xstep), y0), APPoint(k * Float64(xstep), y1)) for k in ks(x0, x1, xstep)]
    horizontal = [APSegment(APPoint(x0, k * Float64(ystep)), APPoint(x1, k * Float64(ystep))) for k in ks(y0, y1, ystep)]
    return vcat(vertical, horizontal)
end
"""
    axes_lines(bb::APBoundingBox)

The coordinate axes that cross `bb`, as a `Vector` of [`APSegment`](@ref)s:
the x axis (`y = 0`, from the left to the right edge of `bb`) first, then the
y axis (`x = 0`), each only if `bb` contains it. For the ticks and numbers
along an axis, see `tickline` (from Luxor, with the method the Luxor
extension adds for [`APPoint`](@ref)s).
"""
function axes_lines(bb::APBoundingBox)
    out = APSegment{2,Float64}[]
    isempty(bb) && return out
    x0, y0, x1, y1 = Float64.((bb.min[1], bb.min[2], bb.max[1], bb.max[2]))
    y0 <= 0 <= y1 && push!(out, APSegment(APPoint(x0, 0.0), APPoint(x1, 0.0)))
    x0 <= 0 <= x1 && push!(out, APSegment(APPoint(0.0, y0), APPoint(0.0, y1)))
    return out
end
"""
    clip_out(obj; bound=1e5, kwargs...)

Restrict all further drawing to the *outside* of `obj`: the counterpart of
`path(obj; action=:clip)`, which keeps the inside. `obj` is anything
[`path`](@ref) draws as a closed shape (a circle, an ellipse, a polygon or
curved region, a bounding box), or a `Vector` of them (drawing is then kept
outside all of them at once); `kwargs` go to `path`. Built with Luxor's
even-odd fill rule: a box of half-side `bound` (in the current coordinates,
centered on the origin) with `obj` cut out of it becomes the clip region.

Like any Luxor clip it lasts until `clipreset()` or the end of the enclosing
`@layer`/`gsave`, and calling it again narrows the region further (two
calls keep only what is outside both shapes). This is what makes lunes,
arbelos and "circles minus circles" figures possible without approximating
the arcs. Like [`path`](@ref), this is a package extension: only callable
once Luxor is also loaded.

| Keyword | Default | Meaning |
|:--------|:--------|:--------|
| `bound` | `1e5` | half-side of the box that `obj` is cut out of, in the current coordinates |
| other keywords | | passed to [`path`](@ref) |
"""
function clip_out end
