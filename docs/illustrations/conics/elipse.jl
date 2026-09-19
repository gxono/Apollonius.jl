include("../default_config.jl")
lxm, lxo = @to_luxor_picture width=500 height=240 margin=20 begin
    c = APPoint(0.0, 0.0)
    e = APEllipse2(c, 5.0, 3.0)
end
(; c, e) = lxo
@svg_doc(lxm, @__FILE__, begin
    sethue(julia_purple)
    path(e, action=:stroke)
    path(c)
    plot_point(julia_blue)
end)
