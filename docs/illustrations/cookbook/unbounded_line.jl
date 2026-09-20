include("../default_config.jl")
lxm, lxo = @to_luxor_picture width=500 height=280 margin=30 begin
    t = APTriangle(APPoint(0.0, 0.0), APPoint(6.0, 0.0), APPoint(1.5, 4.0))
    @unbounded l = APLine(APPoint(0.0, 0.0), APPoint(1.5, 4.0))
end
(; t, l) = lxo
@svg_doc(lxm, @__FILE__, begin
sethue(julia_blue)
path(t, action=:stroke)
sethue(julia_purple)
path(l, action=:stroke, extend=500)
path(vertices(t)); plot_point(julia_blue)
end)
