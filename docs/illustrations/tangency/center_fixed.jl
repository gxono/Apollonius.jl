include("../default_config.jl")
lxm, lxo = @to_luxor_picture width=500 height=240 margin=20 begin
    center = APPoint(0.0, 0.0)
    c = APCircle2(APPoint(10.0, 0.0), 3.0)
    sols = tangent_circles_with_center(center, c)
end
(; center, c, sols) = lxo
@svg_doc(lxm, @__FILE__, begin
sethue(julia_purple)
path(sols, action=:stroke)
sethue(julia_blue)
path(c, action=:stroke)
path(center); plot_point(julia_blue)
end)
