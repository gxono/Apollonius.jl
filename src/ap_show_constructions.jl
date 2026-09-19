function _side_sign(a::APPoint, b::APPoint, x::APPoint)
    return sign(cross2(b - a, x - a))
end
"""
    mediator_construction(a::APPoint, b::APPoint; radius=nothing, sweep=π/6)

The ruler-and-compass construction of the perpendicular bisector of `[a, b]`,
with everything the figure needs to *show* it: two circles of the same
`radius` (default `0.75 * distance(a, b)`, it must exceed half of it) centered
at `a` and `b` cross at two points, and the line through them is the
bisector. Returns a `NamedTuple`:

  - `result`: the bisector, an [`APLine`](@ref);
  - `arcs`: the four compass traces around the two crossing points, each an
    [`APCircularArc2`](@ref) of total angle `sweep` (see
    [`compass_trace`](@ref)), ready for `path`;
  - `points`: the two crossing points, the one to the left of `a -> b`
    first.

Throws an `ArgumentError` if `a == b` or `radius` is too small to cross.
"""
function mediator_construction(a::APPoint, b::APPoint; radius::Union{Nothing,Real}=nothing, sweep::Real=pi / 6)
    d = distance(a, b)
    d > 0 || throw(ArgumentError("mediator_construction: a and b must differ"))
    r = radius === nothing ? 0.75d : radius
    r > d / 2 || throw(ArgumentError("mediator_construction: radius must exceed half the distance between a and b"))
    crossings = intersection(APCircle2(a, r), APCircle2(b, r))
    length(crossings) == 2 || throw(ArgumentError("mediator_construction: the two circles do not cross in two points"))
    p, q = _side_sign(a, b, crossings[1]) > 0 ? (crossings[1], crossings[2]) : (crossings[2], crossings[1])
    arcs = [compass_trace(c, x; angle=sweep) for c in (a, b) for x in (p, q)]
    return (result=APLine(p, q), arcs=arcs, points=[p, q])
end
"""
    perpendicular_construction(l::APLine, p::APPoint; radius=nothing, radius2=nothing, sweep=π/6)

The ruler-and-compass construction of the perpendicular to `l` through `p`,
with everything the figure needs to show it. Returns a `NamedTuple` like
[`mediator_construction`](@ref): `result` (the perpendicular), `arcs` (the
compass traces) and `points` (the auxiliary points in construction order).

If `p` is off `l`: a circle centered at `p` of `radius` (default
`1.5 * distance(p, l)`, it must exceed that distance) cuts `l` at two
points, and two circles of `radius2` (default `0.75` times the distance
between those points) centered at them cross on the other side of `l`;
`points` is `[x1, x2, y]` and the perpendicular is the line `p, y`.

If `p` is on `l`: the circle centered at `p` of `radius` (default half of
`distance(l.p1, l.p2)`) cuts `l` at `x1` and `x2`, and the perpendicular is
the [`mediator_construction`](@ref) of `[x1, x2]` (with `radius2`); `points`
is `[x1, x2, y1, y2]`.
"""
function perpendicular_construction(l::APLine, p::APPoint; radius::Union{Nothing,Real}=nothing,
    radius2::Union{Nothing,Real}=nothing, sweep::Real=pi / 6)
    if on_line(p, l)
        r = radius === nothing ? distance(l.p1, l.p2) / 2 : radius
        r > 0 || throw(ArgumentError("perpendicular_construction: radius must be positive"))
        u = normalize(direction(l))
        x1, x2 = p - r * u, p + r * u
        m = mediator_construction(x1, x2; radius=radius2, sweep=sweep)
        arcs = vcat([compass_trace(p, x1; angle=sweep), compass_trace(p, x2; angle=sweep)], m.arcs)
        return (result=m.result, arcs=arcs, points=vcat([x1, x2], m.points))
    end
    dl = distance(p, l)
    r = radius === nothing ? 1.5dl : radius
    r > dl || throw(ArgumentError("perpendicular_construction: radius must exceed the distance from p to l"))
    xs = intersection(l, APCircle2(p, r))
    length(xs) == 2 || throw(ArgumentError("perpendicular_construction: the circle does not cut l in two points"))
    x1, x2 = xs
    r2 = radius2 === nothing ? 0.75 * distance(x1, x2) : radius2
    r2 > distance(x1, x2) / 2 || throw(ArgumentError("perpendicular_construction: radius2 must exceed half the distance between the two cut points"))
    ys = intersection(APCircle2(x1, r2), APCircle2(x2, r2))
    length(ys) == 2 || throw(ArgumentError("perpendicular_construction: the two circles do not cross in two points"))
    y = side_of_line(ys[1], l) != side_of_line(p, l) ? ys[1] : ys[2]
    arcs = [compass_trace(p, x1; angle=sweep), compass_trace(p, x2; angle=sweep),
        compass_trace(x1, y; angle=sweep), compass_trace(x2, y; angle=sweep)]
    return (result=APLine(p, y), arcs=arcs, points=[x1, x2, y])
end
"""
    parallel_construction(l::APLine, p::APPoint; sweep=π/6)

The ruler-and-compass construction of the parallel to `l` through `p`, as a
rhombus: with `A = l.p1` and `r = distance(A, p)`, the circle centered at `A`
of radius `r` meets `l` at `D`, and the circles of radius `r` centered at `D`
and at `p` meet again at `E`; the line `p, E` is parallel to `l`. Returns a
`NamedTuple` like [`mediator_construction`](@ref): `result` (the parallel),
`arcs` (four compass traces) and `points` (`[D, E]`). Throws an
`ArgumentError` if `p` is on `l`.
"""
function parallel_construction(l::APLine, p::APPoint; sweep::Real=pi / 6)
    on_line(p, l) && throw(ArgumentError("parallel_construction: p lies on l, the parallel is l itself"))
    A = l.p1
    r = distance(A, p)
    D = A + r * normalize(direction(l))
    es = intersection(APCircle2(D, r), APCircle2(p, r))
    length(es) == 2 || throw(ArgumentError("parallel_construction: the construction circles do not cross in two points"))
    E = distance(es[1], A) > distance(es[2], A) ? es[1] : es[2]
    arcs = [compass_trace(A, p; angle=sweep), compass_trace(A, D; angle=sweep),
        compass_trace(D, E; angle=sweep), compass_trace(p, E; angle=sweep)]
    return (result=APLine(p, E), arcs=arcs, points=[D, E])
end
"""
    bisector_construction(vertex::APPoint, p1::APPoint, p2::APPoint; radius=nothing, radius2=nothing, sweep=π/6)

The ruler-and-compass construction of the bisector of the angle
`p1, vertex, p2`, with everything the figure needs to show it: the circle
centered at `vertex` of `radius` (default half the shorter ray) cuts the two
rays at `x1` and `x2`, and two circles of `radius2` (default `0.75` times
`distance(x1, x2)`) centered at them cross inside the angle at `y`; the line
`vertex, y` is the bisector. Returns a `NamedTuple` like
[`mediator_construction`](@ref): `result`, `arcs` and `points`
(`[x1, x2, y]`). Throws an `ArgumentError` for a degenerate angle (a zero
length ray, or rays that are parallel or opposite).
"""
function bisector_construction(vertex::APPoint, p1::APPoint, p2::APPoint;
    radius::Union{Nothing,Real}=nothing, radius2::Union{Nothing,Real}=nothing, sweep::Real=pi / 6)
    v1, v2 = p1 - vertex, p2 - vertex
    (norm(v1) > 0 && norm(v2) > 0) || throw(ArgumentError("bisector_construction: the angle has a ray of zero length"))
    u1, u2 = normalize(v1), normalize(v2)
    abs(cross2(u1, u2)) > 1e-9 || throw(ArgumentError("bisector_construction: the rays are parallel or opposite"))
    r = radius === nothing ? min(norm(v1), norm(v2)) / 2 : radius
    r > 0 || throw(ArgumentError("bisector_construction: radius must be positive"))
    x1, x2 = vertex + r * u1, vertex + r * u2
    r2 = radius2 === nothing ? 0.75 * distance(x1, x2) : radius2
    r2 > distance(x1, x2) / 2 || throw(ArgumentError("bisector_construction: radius2 must exceed half the distance between x1 and x2"))
    ys = intersection(APCircle2(x1, r2), APCircle2(x2, r2))
    length(ys) == 2 || throw(ArgumentError("bisector_construction: the two circles do not cross in two points"))
    inside = u1 + u2
    y = dot(ys[1] - vertex, inside) > dot(ys[2] - vertex, inside) ? ys[1] : ys[2]
    arcs = [compass_trace(vertex, x1; angle=sweep), compass_trace(vertex, x2; angle=sweep),
        compass_trace(x1, y; angle=sweep), compass_trace(x2, y; angle=sweep)]
    return (result=APLine(vertex, y), arcs=arcs, points=[x1, x2, y])
end
"""
    projection_construction(p::APPoint, l::APLine; radius=nothing, radius2=nothing, sweep=π/6)

The ruler-and-compass construction of the orthogonal projection of `p` onto
`l`, with everything the figure needs to show it: the
[`perpendicular_construction`](@ref) of `l` through `p` (same `radius`,
`radius2` and `sweep`), whose crossing with `l` is the foot. Returns a
`NamedTuple` `(result, arcs, points)` where `result` is the foot (an
[`APPoint`](@ref)) and `arcs` and `points` are those of the perpendicular
construction.
"""
function projection_construction(p::APPoint, l::APLine; radius::Union{Nothing,Real}=nothing,
    radius2::Union{Nothing,Real}=nothing, sweep::Real=pi / 6)
    pc = perpendicular_construction(l, p; radius=radius, radius2=radius2, sweep=sweep)
    return (result=only(intersection(l, pc.result)), arcs=pc.arcs, points=pc.points)
end
"""
    reflection_construction(p::APPoint, l::APLine; radius=nothing, sweep=π/6)

The ruler-and-compass construction of the mirror image of `p` across `l`:
the circle centered at `p` of `radius` (default `1.5 * distance(p, l)`, it
must exceed that distance) cuts `l` at `x1` and `x2`, and the circles of the
same radius centered at them, both through `p`, meet again at the image.
Returns a `NamedTuple` `(result, arcs, points)`: `result` is the image (an
[`APPoint`](@ref)), `arcs` six compass traces (around `x1`, `x2`, `p` and the
image) and `points` is `[x1, x2]`. If `p` is on `l` it is its own image, with
no arcs.
"""
function reflection_construction(p::APPoint, l::APLine; radius::Union{Nothing,Real}=nothing, sweep::Real=pi / 6)
    on_line(p, l) && return (result=p, arcs=APCircularArc2{Float64}[], points=APPoint{2,Float64}[])
    dl = distance(p, l)
    r = radius === nothing ? 1.5dl : radius
    r > dl || throw(ArgumentError("reflection_construction: radius must exceed the distance from p to l"))
    xs = intersection(l, APCircle2(p, r))
    length(xs) == 2 || throw(ArgumentError("reflection_construction: the circle does not cut l in two points"))
    x1, x2 = xs
    cs = intersection(APCircle2(x1, r), APCircle2(x2, r))
    length(cs) == 2 || throw(ArgumentError("reflection_construction: the two circles do not cross in two points"))
    q = distance(cs[1], p) > distance(cs[2], p) ? cs[1] : cs[2]
    arcs = [compass_trace(c, x; angle=sweep) for (c, x) in ((p, x1), (p, x2), (x1, p), (x2, p), (x1, q), (x2, q))]
    return (result=q, arcs=arcs, points=[x1, x2])
end
"""
    symmetry_construction(p::APPoint, center::APPoint; sweep=π/6)

The ruler-and-compass construction of the image of `p` under the point
symmetry about `center`: the circle centered at `center` through `p` meets
the line `p, center` again on the other side. Returns a `NamedTuple`
`(result, arcs, points)`: `result` is the image, `arcs` two compass traces
(around `p` and around the image) and `points` is empty. Throws an
`ArgumentError` if `p == center`.
"""
function symmetry_construction(p::APPoint, center::APPoint; sweep::Real=pi / 6)
    distance(p, center) > 0 || throw(ArgumentError("symmetry_construction: p must differ from center"))
    q = reflection(p, center)
    return (result=q, arcs=[compass_trace(center, p; angle=sweep), compass_trace(center, q; angle=sweep)],
        points=APPoint{2,Float64}[])
end
"""
    translation_construction(p::APPoint, a::APPoint, b::APPoint; sweep=π/6)

The ruler-and-compass construction of the image of `p` under the
translation that takes `a` to `b`, as a parallelogram: the circle centered at
`p` of radius `distance(a, b)` and the circle centered at `b` of radius
`distance(a, p)` meet at `p + (b - a)`. Returns a `NamedTuple`
`(result, arcs, points)`: `result` is the image, `arcs` two compass traces
(around the image) and `points` is empty. If `a == b` the translation is the
identity, with no arcs. Throws an `ArgumentError` if `p == a`.
"""
function translation_construction(p::APPoint, a::APPoint, b::APPoint; sweep::Real=pi / 6)
    v = b - a
    norm(v) > 0 || return (result=p, arcs=APCircularArc2{Float64}[], points=APPoint{2,Float64}[])
    distance(a, p) > 0 || throw(ArgumentError("translation_construction: p must differ from a"))
    expected = p + v
    crossings = intersection(APCircle2(p, norm(v)), APCircle2(b, distance(a, p)))
    isempty(crossings) && throw(ArgumentError("translation_construction: the construction circles do not meet"))
    q = crossings[argmin([distance(c, expected) for c in crossings])]
    return (result=q, arcs=[compass_trace(p, q; angle=sweep), compass_trace(b, q; angle=sweep)],
        points=APPoint{2,Float64}[])
end
