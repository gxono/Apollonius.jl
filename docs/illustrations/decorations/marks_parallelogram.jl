include("../default_config.jl")
lxm, lxo = @prepare_to_picture width=500 height=200 margin=20 begin
    right = APAngle2(APPoint(0.0, 0.0), APPoint(6.0, 0.0), APPoint(0.0, 6.0))
    other = APAngle2(APPoint(12.0, 0.0), APPoint(18.0, 0.0), rotate(APPoint(18.0, 0.0), pi / 3, APPoint(12.0, 0.0)))
    rays = [APSegment(a.vertex, x) for a in (right, other) for x in (a.a, a.b)]
end
(; right, other, rays) = lxo
@svg_doc(lxm, @__FILE__, begin
sethue(julia_blue)
path(rays, action=:stroke)
sethue(julia_purple)
path(only(marks(right; style=:parallelogram, size=3.0)); action=:stroke)
poly = only(marks(other; style=:parallelogram, size=3.0))
path(APQuadrilateral(other.vertex, poly.vertices...); action=:fill)
end)
