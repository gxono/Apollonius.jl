include("../default_config.jl")
lxm, lxo = @prepare_to_picture width=500 height=240 margin=20 begin
    l1 = APLine(APPoint(0.0, 0.0), APPoint(1.0, 1.0))
    l2 = APLine(APPoint(0.0, 0.0), APPoint(1.0, 0.0))
    sols_r = tangent_circles_with_radius(l1, l2, 3.0)
end
(; l1, l2, sols_r) = lxo
@svg_doc(lxm, @__FILE__, begin
sethue(julia_purple)
path(sols_r, action=:stroke)
sethue(julia_blue)
path([l1,l2], action=:stroke)
end)
