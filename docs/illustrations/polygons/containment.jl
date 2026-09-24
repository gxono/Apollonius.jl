include("../default_config.jl")
lxm, lxo = @prepare_to_picture width=500 height=260 margin=30 begin
    pg = APStraightNgon([APPoint(0.0, 0.0), APPoint(4.0, 0.0), APPoint(4.0, 3.0), APPoint(1.0, 3.0)])
    pts = [APPoint(2.0, 1.0), APPoint(3.0, 2.0), APPoint(0.5, 2.0), APPoint(5.0, 1.0), APPoint(-1.0, 1.0), APPoint(2.0, 4.0)]
end
(; pg, pts) = lxo
@svg_doc(lxm, @__FILE__, begin
sethue(julia_blue)
path(pg, action=:stroke)
sethue(julia_purple)
sethue("gray80")
sethue("white"); path([p for p in pts if point_in_polygon(p, pg)], action=:fillpreserve); sethue(julia_purple); strokepath()
sethue("white"); path([p for p in pts if !point_in_polygon(p, pg)], action=:fillpreserve); sethue("gray80"); strokepath()
end)
