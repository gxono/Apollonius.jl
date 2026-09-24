include("../default_config.jl")
lxm, lxo = @prepare_to_picture width=500 height=240 margin=20 begin
    pg = APStraightNgon([APPoint(0.0, 0.0), APPoint(4.0, 0.0), APPoint(4.0, 3.0), APPoint(1.0, 3.0)])
end
(; pg) = lxo
@svg_doc(lxm, @__FILE__, begin
sethue(julia_blue)
path(pg, action=:stroke)
sethue("white"); path(vertices(pg), action=:fillpreserve); sethue(julia_blue); strokepath()
sethue("white"); path(centroid(pg), action=:fillpreserve); sethue(julia_purple); strokepath()
end)
