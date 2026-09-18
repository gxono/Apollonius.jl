include("../default_config.jl")
sz = @to_luxor_picture! width=500 height=240 margin=20 begin
    pg = APStraightNgon([APPoint(0.0, 0.0), APPoint(4.0, 0.0), APPoint(4.0, 3.0), APPoint(1.0, 3.0)])
end
bb = APBoundingBox(pg)
@svg_doc(sz, @__FILE__, begin
path(bbox_center(bb))
setpoint(julia_purple)
path(bb, action=:stroke)
sethue(julia_blue)
path(pg, action=:stroke)
path(vertices(pg))
setpoint(julia_red)
path([bb.min, bb.max])
setpoint(julia_purple)
end)
