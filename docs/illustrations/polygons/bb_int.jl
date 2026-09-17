include("../default_config.jl")





sz = @to_luxor_picture! width=500 height=240 margin=20 begin
    pg = APStraightNgon([APPoint(0.0, 0.0), APPoint(4.0, 0.0), APPoint(4.0, 3.0), APPoint(1.0, 3.0)])
    p1, p2 = APPoint(2.0, 1.0), APPoint(6.0, 5.0)
end

bb = APBoundingBox(pg)
bb2 = APBoundingBox([p1, p2])
bi = bbox_intersection(bb, bb2)


@svg_doc(sz, @__FILE__, begin

sethue(julia_blue)
path([bb, bb2], action=:stroke)

sethue(julia_purple)
path(bi, action=:stroke)

path([bb.min, bb.max, bb2.min, bb2.max])
setpoint(julia_red)

path([bi.min, bi.max])
setpoint(julia_purple)

end)
