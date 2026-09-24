include("../default_config.jl")
lxm, lxo = @prepare_to_picture width=560 height=260 margin=30 begin
    pg = APStraightNgon([APPoint(0.0, 0.0), APPoint(5.0, 0.0), APPoint(6.0, 3.0), APPoint(2.5, 5.0), APPoint(-0.5, 3.0)])
    outer = offset_polygon(pg, 0.8)
    inner = offset_polygon(pg, -0.8)
    boxpoly = rectangle_with_center(APPoint(10.0, 2.0), 4.0, 3.0)
end
(; pg, outer, inner, boxpoly) = lxo
@svg_doc(lxm, @__FILE__, begin
box = APBoundingBox(boxpoly)
big = inflate(box, 0.25 * bbox_width(box))
sethue(julia_blue)
path([pg, boxpoly], action=:stroke)
gsave()
setline(1); setdash("dash")
sethue(julia_purple)
path([outer, inner, big], action=:stroke)
grestore()
end)
