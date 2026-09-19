"""
    parallelogram(a::APPoint, b::APPoint, c::APPoint)

The parallelogram with consecutive vertices `a`, `b`, `c` and fourth vertex
`d = a + (c - b)` (so `[a,b] ∥ [d,c]` and `[b,c] ∥ [a,d]`).
"""
parallelogram(a::APPoint, b::APPoint, c::APPoint) = APQuadrilateral(a, b, c, a + (c - b))
"""
    square_on_segment(a::APPoint, b::APPoint; ccw=true)

The square with side `[a, b]`, built counterclockwise from `a` to `b`
(`ccw=false` builds it on the other side).

| Keyword | Default | Meaning |
|:--------|:--------|:--------|
| `ccw` | `true` | `true` puts the square on the left of `a → b`, `false` on the right |
"""
function square_on_segment(a::APPoint, b::APPoint; ccw::Bool=true)
    v = orthogonal(b - a)
    v = ccw ? v : -v
    return APQuadrilateral(a, b, b + v, a + v)
end
"""
    rectangle_on_segment(a::APPoint, b::APPoint, height::Real; ccw=true)

The rectangle with side `[a, b]` and the given `height`, built
counterclockwise from `a` to `b` (`ccw=false` builds it on the other side).

| Keyword | Default | Meaning |
|:--------|:--------|:--------|
| `ccw` | `true` | `true` puts the rectangle on the left of `a → b`, `false` on the right |
"""
function rectangle_on_segment(a::APPoint, b::APPoint, height::Real; ccw::Bool=true)
    u = orthogonal((b - a) / norm(b - a))
    v = (ccw ? height : -height) * u
    return APQuadrilateral(a, b, b + v, a + v)
end
"""
    regular_polygon(center::APPoint, vertex::APPoint, n::Integer)

The regular `n`-gon centered at `center` with `vertex` as one of its
vertices.
"""
function regular_polygon(center::APPoint, vertex::APPoint, n::Integer)
    n >= 3 || throw(ArgumentError("regular_polygon needs n >= 3"))
    return APStraightNgon([rotate(vertex, 2pi * k / n, center) for k in 0:n-1])
end
