# -------------------------------------------------------------------------
# Named quadrilateral/regular-polygon constructors: parallelogram, square,
# rectangle, regular_polygon.
# -------------------------------------------------------------------------

"""
    parallelogram(a::EGPoint, b::EGPoint, c::EGPoint)

The parallelogram with consecutive vertices `a`, `b`, `c` and fourth vertex
`d = a + (c - b)` (so `[a,b] ∥ [d,c]` and `[b,c] ∥ [a,d]`).
"""
parallelogram(a::EGPoint, b::EGPoint, c::EGPoint) = EGQuadrilateral(a, b, c, a + (c - b))

"""
    square_on_segment(a::EGPoint, b::EGPoint; ccw=true)

The square with side `[a, b]`, built counterclockwise from `a` to `b`
(`ccw=false` builds it on the other side).
"""
function square_on_segment(a::EGPoint, b::EGPoint; ccw::Bool=true)
    v = orthogonal(b - a)
    v = ccw ? v : -v
    return EGQuadrilateral(a, b, b + v, a + v)
end

"""
    rectangle_on_segment(a::EGPoint, b::EGPoint, height::Real; ccw=true)

The rectangle with side `[a, b]` and the given `height`, built
counterclockwise from `a` to `b` (`ccw=false` builds it on the other side).
"""
function rectangle_on_segment(a::EGPoint, b::EGPoint, height::Real; ccw::Bool=true)
    u = orthogonal((b - a) / norm(b - a))
    v = (ccw ? height : -height) * u
    return EGQuadrilateral(a, b, b + v, a + v)
end

"""
    regular_polygon(center::EGPoint, vertex::EGPoint, n::Integer)

The regular `n`-gon centered at `center` with `vertex` as one of its
vertices.
"""
function regular_polygon(center::EGPoint, vertex::EGPoint, n::Integer)
    n >= 3 || throw(ArgumentError("regular_polygon needs n >= 3"))
    return EGStraightNgon([rotate(vertex, 2pi * k / n, center) for k in 0:n-1])
end
