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
