include("../default_config.jl")
lxm, lxo = @prepare_to_picture width=500 height=240 margin=20 begin
    pts = [APPoint(0.0, 0.0), APPoint(4.0, 0.0), APPoint(4.0, 3.0), APPoint(1.0, 3.0), APPoint(2.0, 1.0)]
    hull = convex_hull(pts)
end
(; pts, hull) = lxo
@svg_doc(lxm, @__FILE__, begin
sethue(julia_purple)
path(hull, action=:stroke)
sethue("white"); path(pts, action=:fillpreserve); sethue(julia_blue); strokepath()
end)
