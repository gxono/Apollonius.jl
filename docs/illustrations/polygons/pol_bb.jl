include("../default_config.jl")
lxm, lxo = @to_luxor_picture width=500 height=240 margin=20 begin
    pg = APStraightNgon([APPoint(0.0, 0.0), APPoint(4.0, 0.0), APPoint(4.0, 3.0), APPoint(1.0, 3.0)])
end
(; pg) = lxo
bb = APBoundingBox(pg)
@svg_doc(lxm, @__FILE__, begin
path(bb, action=:stroke)
sethue(julia_blue)
path(pg, action=:stroke)
path(bbox_center(bb)); plot_point(julia_purple)
path(vertices(pg)); plot_point(julia_blue)
path([bb.min, bb.max]); plot_point(julia_purple)
end)
