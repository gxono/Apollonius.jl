include("../default_config.jl")
lxm, lxo = @prepare_to_picture width=500 height=280 margin=30 begin
    pg = APStraightNgon([APPoint(0.0, 0.0), APPoint(5.0, 0.0), APPoint(6.0, 3.0), APPoint(2.0, 4.0), APPoint(-1.0, 2.0)])
    other = APStraightNgon([APPoint(3.0, -1.0), APPoint(8.0, -1.0), APPoint(8.0, 2.0), APPoint(3.0, 2.0)])
    pts = intersection(pg, other)
end
(; pg, other, pts) = lxo
@svg_doc(lxm, @__FILE__, begin
sethue(julia_blue)
path([pg, other], action=:stroke)
sethue(julia_purple)
sethue("white"); path(pts, action=:fillpreserve); sethue(julia_purple); strokepath()
end)
