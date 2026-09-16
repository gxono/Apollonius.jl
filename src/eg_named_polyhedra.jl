# -------------------------------------------------------------------------
# Named regular-polyhedron constructors: regular_tetrahedron3,
# regular_octahedron3 -- the 3D analogues of `regular_polygon` in
# eg_named_polygons.jl. The cube is already covered by `cube3` in
# eg_polyhedron.jl, so it isn't repeated here.
#
# The dodecahedron and icosahedron are deliberately NOT here: their faces
# aren't as simple to hand-enumerate from the vertex coordinates as the
# tetrahedron/octahedron/cube's are, and building them properly needs a
# 3D convex hull algorithm this package doesn't have (the 2D
# `convex_hull` in eg_polygon.jl doesn't generalize to 3D) -- a
# substantial undertaking of its own, left for a later phase.
# -------------------------------------------------------------------------

"""
    regular_tetrahedron3(center::EGPoint{3}, edge::Real)

The regular tetrahedron centered at `center` with the given `edge`
length, inscribed in a cube (the classic construction: alternating
corners of a cube are the vertices of a regular tetrahedron).
"""
function regular_tetrahedron3(c::EGPoint, edge::Real)
    s = edge / (2 * sqrt(2))
    a = c + EGVector(s, s, s)
    b = c + EGVector(s, -s, -s)
    d = c + EGVector(-s, s, -s)
    e = c + EGVector(-s, -s, s)
    return EGTetrahedron3(a, b, d, e)
end

"""
    regular_octahedron3(center::EGPoint{3}, edge::Real)

The regular octahedron centered at `center` with the given `edge` length
-- 6 vertices at `±s` along each axis from `center` (`s = edge/√2`), 8
triangular faces (one per octant).
"""
function regular_octahedron3(c::EGPoint, edge::Real)
    s = edge / sqrt(2)
    verts = [c + EGVector(sx * s, 0.0, 0.0) for sx in (1, -1)]
    append!(verts, [c + EGVector(0.0, sy * s, 0.0) for sy in (1, -1)])
    append!(verts, [c + EGVector(0.0, 0.0, sz * s) for sz in (1, -1)])
    px, nx, py, ny, pz, nz = verts
    # Build all 8 faces explicitly (top 4, bottom 4), each auto-oriented
    # outward from `center` via the same helper EGPolyhedron's own
    # constructors use.
    top = [_outward_face([px, py, pz], c), _outward_face([py, nx, pz], c),
        _outward_face([nx, ny, pz], c), _outward_face([ny, px, pz], c)]
    bottom = [_outward_face([px, py, nz], c), _outward_face([py, nx, nz], c),
        _outward_face([nx, ny, nz], c), _outward_face([ny, px, nz], c)]
    return EGGeneralPolyhedron3(vcat(top, bottom))
end
