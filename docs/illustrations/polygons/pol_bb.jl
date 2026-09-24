include("../default_config.jl")
lxm = @prepare_to_picture! width=500 height=240 margin=20 begin
    pg = APStraightNgon([APPoint(0.0, 0.0), APPoint(4.0, 0.0), APPoint(4.0, 3.0), APPoint(1.0, 3.0)])
end

bb = APBoundingBox(pg)

@svg_doc(lxm, @__FILE__, begin
sethue(julia_purple)
path(bb, action=:stroke)
sethue(julia_blue)
path(pg, action=:stroke)

sethue("white")
path(bbox_center(bb), action=:fillpreserve)
sethue(julia_purple); strokepath()
sethue("white")
path(vertices(pg), action=:fillpreserve)
sethue(julia_blue); strokepath()
sethue("white")
path([bb.min, bb.max], action=:fillpreserve)
sethue(julia_purple); strokepath()
end)
