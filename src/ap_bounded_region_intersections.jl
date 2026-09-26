const _BoundedRegion2 = Union{APCircle2,APEllipse2,APPolygon{2}}

function _check_intersection_mode(mode)
    mode isa Symbol && (mode = (mode, mode))
    m1, m2 = mode
    (m1 in (:region, :boundary) && m2 in (:region, :boundary)) ||
        throw(ArgumentError("intersection: mode must be :region, :boundary, or a 2-tuple of those, got $(repr(mode))"))
    return m1, m2
end

function _default_boundary_intersection(a, b; atol::Real=1e-9)
    if a isa APCircle2 && b isa APCircle2
        return _circle_circle_boundary_intersection(a, b; atol=atol)
    elseif a isa APConic2 && b isa APConic2
        return _conic_conic_boundary_intersection(a, b; atol=atol)
    else
        return _intersect_pieces(a, b, atol)
    end
end

"""
    intersection(a, b; mode=(:boundary,:boundary))

For two bounded, closed shapes (any of `APCircle2`/`APEllipse2`/the
`APPolygon` family: triangles, quadrilaterals, n-gons, and the
curved-region types), `mode` picks whether each side is read as just its
own boundary curve or as the filled region it encloses, the same
`:boundary`/`:region` vocabulary [`distance`](@ref) already uses:

  - `(:boundary, :boundary)` (the default): today's behavior, the points
    where the two boundaries cross, as a `Vector{APPoint}`.
  - `(:boundary, :region)`/`(:region, :boundary)`: the part of the
    *boundary-only* side's curve that lies inside the *region* side,
    always as a `Vector` (0, 1, or more disjoint pieces, since the region
    side need not be convex).
  - `(:region, :region)`: the actual overlap of the two filled interiors,
    always as a `Vector` (0, 1, or more disjoint pieces), each the
    tightest fitting shape (`APTriangle`/`APQuadrilateral`/`APStraightNgon`
    when every side is straight, `APCurvilinearTriangle2`/
    `APCurvilinearQuadrilateral2`/`APCurvilinearNgon2` when any side is
    curved). One shape entirely inside the other comes back as that inner
    shape unchanged; disjoint shapes give an empty `Vector`.

A bare `mode=:region` (or `:boundary`) is shorthand for applying the same
choice to both sides. Both argument orders work.

Any side read as `:boundary`, and both sides when the mode is
`(:region, :region)`, need that shape's own boundary walked in a single
consistent direction; a side read as `:region` next to a `:boundary` side
only needs `in`, never a walk. `APCircularArc2`/`APEllipticArc2` can only
represent a counterclockwise sweep, so a shape whose boundary needs one of
its arcs walked the other way throws an `ArgumentError` (instead of a wrong
answer) whenever it ends up in a role that walks it. `APAnnularSector2`'s
inner arc always faces opposite its outer one, so it throws as a
`:boundary` side and in `(:region, :region)`, but works as the `:region`
side next to a `:boundary` partner. `APInterstice2` built as the curved gap
between mutually tangent circles has the same underlying shape (each arc
bulges away from the gap), but only in `(:region, :region)`: it works fine
as either side of `(:boundary, :region)`/`(:region, :boundary)`, since
`_ccw_pieces` (which needs the whole loop pointing one way) is the only
caller that needs a full walk of *both* shapes together. Neither limitation
ever applies to `APCircle2`, `APEllipse2`, any straight-sided type, or a
curved type with a single arc side (`APCircularSector2`,
`APCircularSegment2`).

| Keyword | Default | Meaning |
|:--------|:--------|:--------|
| `mode` | `(:boundary, :boundary)` | `:region`/`:boundary` per side, or one shared value for both |
"""
intersection(a::_BoundedRegion2, b::_BoundedRegion2; mode=(:boundary, :boundary), atol::Real=1e-9) =
    _bounded_region_intersection(a, b; mode=mode, atol=atol)
function _bounded_region_intersection(a, b; mode, atol::Real)
    m1, m2 = _check_intersection_mode(mode)
    if m1 === :boundary && m2 === :boundary
        return _default_boundary_intersection(a, b; atol=atol)
    elseif m1 === :region && m2 === :region
        return _region_overlap(a, b; atol=atol)
    elseif m1 === :region
        return _boundary_clip(b, a; atol=atol)
    else
        return _boundary_clip(a, b; atol=atol)
    end
end
# _BoundedRegion2 overlaps both _CompositeCurve2 (at APPolygon{2}) and _PrimitiveCurve2 (at
# APCircle2/APEllipse2), neither containing the other, so Julia sees the method above as
# ambiguous against the generic composite-curve methods for these three narrower pairs.
intersection(a::APPolygon{2}, b::APPolygon{2}; mode=(:boundary, :boundary), atol::Real=1e-9) =
    _bounded_region_intersection(a, b; mode=mode, atol=atol)
intersection(a::APPolygon{2}, b::Union{APCircle2,APEllipse2}; mode=(:boundary, :boundary), atol::Real=1e-9) =
    _bounded_region_intersection(a, b; mode=mode, atol=atol)
intersection(a::Union{APCircle2,APEllipse2}, b::APPolygon{2}; mode=(:boundary, :boundary), atol::Real=1e-9) =
    _bounded_region_intersection(a, b; mode=mode, atol=atol)
intersection(a::Union{APCircle2,APEllipse2}, b::Union{APCircle2,APEllipse2}; mode=(:boundary, :boundary), atol::Real=1e-9) =
    _bounded_region_intersection(a, b; mode=mode, atol=atol)

"""
    region_union(a, b; atol=1e-9)

The union of two bounded, closed shapes (any of `APCircle2`/`APEllipse2`/the
`APPolygon` family, straight or curved), reading both as filled regions:
always a `Vector` (there is no `mode`, since a union only makes sense
between two regions), holding 0, 1, or more pieces, each the tightest
fitting shape (as in [`intersection`](@ref)'s `(:region,:region)`). One
shape entirely inside the other gives the outer one unchanged; disjoint
shapes give both, unmerged, as the two elements of the `Vector`; touching
at a single point, or along a whole shared edge with no other overlap,
also gives both, unmerged, rather than one bigger polygon, since a
coincident boundary contributes no crossing (the same convention
[`intersection`](@ref) already uses for two coincident curves). `a` and `b`
identical gives `[a]`. Both argument orders work.

There is no `:boundary`-side escape hatch here the way `intersection` has
one: both `a` and `b` always need their own boundary walked in a single
consistent direction to be merged, so `APAnnularSector2` and
`APInterstice2` built as the natural curved gap between mutually tangent
circles always raise the same `ArgumentError` as `intersection`'s
`(:region,:region)`, in either argument position, for the same
underlying reason (a circular/elliptic arc that would need walking
backward). `APCircle2`, `APEllipse2`, any straight-sided type, and a
curved type with a single arc side (`APCircularSector2`,
`APCircularSegment2`) never hit this.
"""
function region_union(a::_BoundedRegion2, b::_BoundedRegion2; atol::Real=1e-9)
    return _region_union(a, b; atol=atol)
end

"""
    region_difference(a, b; atol=1e-9)

The part of the bounded, closed shape `a` that lies outside `b` (both read
as filled regions, `a` minus `b`): always a `Vector`, holding 0, 1, or more
pieces, each the tightest fitting shape. `a` and `b` disjoint gives `a`
unchanged; `a` entirely inside `b` gives an empty `Vector`. Unlike
[`intersection`](@ref) and [`region_union`](@ref), the argument order
matters here.

Both `a` and `b` need their own boundary walked in a single consistent
direction (as in [`region_union`](@ref)), so `APAnnularSector2` and
`APInterstice2` built as the natural curved gap always raise an
`ArgumentError` here in either position. On top of that, `b` bites cleanly
into `a`'s edge only when `b`'s own contributing boundary is straight
(`APTriangle`/`APQuadrilateral`/`APStraightNgon`, or the straight sides of
a curved-region type): a genuine circular or elliptic arc of `b` can never
be walked backward either, so a `b` that is a circle, an ellipse, or a
curved-region shape whose bite includes one of its arcs also raises an
`ArgumentError`, even when `a` itself has no such trouble. `b` entirely
inside `a`, not touching `a`'s own boundary, raises a different
`ArgumentError` for a different reason: it would carve a hole out of the
middle of `a`, and no type in this package can represent a region with a
hole.
"""
function region_difference(a::_BoundedRegion2, b::_BoundedRegion2; atol::Real=1e-9)
    return _region_difference(a, b; atol=atol)
end

"""
    region_difference(a, others; atol=1e-9)

`a` with every shape in `others` (any iterable of bounded, closed shapes)
taken out in turn, equivalent to folding [`region_difference`](@ref)`(a, b)`
over `others` one at a time and keeping every surviving piece at each step
(a single shape can split into several disjoint pieces partway through,
each then checked against the rest of `others` independently). Always a
`Vector`; empty once nothing of `a` is left. Each step can raise the same
`ArgumentError`s as the two-shape form, for the same reasons.
"""
function region_difference(a::_BoundedRegion2, others; atol::Real=1e-9)
    return _region_difference_all(a, others; atol=atol)
end

"""
    region_symdiff(a, b; atol=1e-9)

The symmetric difference of two bounded, closed shapes: the parts of each
that lie outside the other, `(a ∖ b) ∪ (b ∖ a)`, as a `Vector` holding every
surviving piece from both (the two sides can never overlap each other, so
no merging or restitching is needed beyond what
[`region_difference`](@ref) already does). Both argument orders give the
same result. Disjoint shapes give both unchanged; identical shapes give an
empty `Vector`. Raises the same `ArgumentError`s as `region_difference`
(from either `region_difference(a,b)` or `region_difference(b,a)`), for
the same reasons: a hole-creating containment in either direction, or a
circular/elliptic arc that would need walking backward.
"""
function region_symdiff(a::_BoundedRegion2, b::_BoundedRegion2; atol::Real=1e-9)
    return _region_symdiff(a, b; atol=atol)
end

"""
    overlaps(a, b; atol=1e-9)

Whether the bounded, closed shapes `a` and `b` share any area at all
(`!isempty(intersection(a, b; mode=:region))`, without needing to build
and classify the overlap shape itself to find out). `false` for two shapes
that only touch along a boundary (a single point, or a whole shared edge
with no other overlap), the same as [`intersection`](@ref)'s
`(:region,:region)` and [`region_union`](@ref) already treat that case.
"""
function overlaps(a::_BoundedRegion2, b::_BoundedRegion2; atol::Real=1e-9)
    return _overlaps(a, b; atol=atol)
end

"""
    is_walkable(pg)

Whether `pg`'s own boundary can be walked in a single consistent direction,
the requirement [`region_union`](@ref)/[`region_difference`](@ref) always
have and [`intersection`](@ref)'s `(:region,:region)` (or a `:boundary`
side) has too. `false` exactly when `pg` is an `APAnnularSector2`, an
`APInterstice2` built as the natural curved gap between mutually tangent
circles, or any other curved-region shape whose sides, taken together,
would need a circular or elliptic arc walked backward; `true` for
`APCircle2`, `APEllipse2`, every straight-sided type, and a curved type
with a single arc side (`APCircularSector2`, `APCircularSegment2`), always.
Check this before a call that would otherwise raise an `ArgumentError`, or
use it to filter a collection of shapes down to the ones safe to pass to
[`region_union`](@ref)'s or [`intersection`](@ref)'s N-ary forms.
"""
function is_walkable(pg::_BoundedRegion2)
    return _is_walkable(pg)
end

"""
    region_union(shapes)

The union of every bounded, closed shape in `shapes` (any iterable of them)
at once, as a `Vector` holding each disjoint merged piece: shapes that
touch or overlap, directly or through a chain of others, merge into one
piece each; shapes with nothing in common with any other stay as their own
piece. Order in `shapes` does not affect the result. Reduces to
[`region_union`](@ref)`(a, b)` for two shapes, and to `[only(shapes)]` for
one. Raises the same `ArgumentError` as the two-shape form for any pair
that would need it, exactly when two shapes end up compared against each
other on the way to finding every merge.
"""
function region_union(shapes)
    return _region_union_all(shapes)
end

"""
    intersection(shapes; atol=1e-9)

The overlap common to every bounded, closed shape in `shapes` (any
iterable of them) at once, as a `Vector` holding each disjoint piece
(there can be more than one once four or more shapes are involved, even
though any two shapes alone always overlap in one connected piece). This
is always the `(:region,:region)` reading, since there is no per-shape
`mode` to give for more than two shapes at once. Reduces to
[`intersection`](@ref)`(a, b; mode=:region)` for two shapes, and to
`[only(shapes)]` for one. Empty as soon as the running overlap becomes
empty, without checking the remaining shapes.
"""
function intersection(shapes::AbstractVector{<:_BoundedRegion2}; atol::Real=1e-9)
    return _region_intersection_all(shapes; atol=atol)
end
