include("../default_config.jl")
lxm, lxo = @to_luxor_picture width=500 height=280 margin=30 begin
    e = APEllipse2(APPoint(0.0, 0.0), 5.0, 3.0)
    onp = [point_on_ellipse(e, t) for t in (0.4, 2.0, 4.0)]
    inside = APPoint(1.0, 0.5)
    outside = APPoint(4.0, 3.0)
end
(; e, onp, inside, outside) = lxo
@svg_doc(lxm, @__FILE__, begin
sethue(julia_blue)
path(e, action=:stroke)
sethue(julia_purple)
path(onp); plot_point(julia_purple)
sethue("gray80")
path([inside, outside]); plot_point("gray80")
end)
