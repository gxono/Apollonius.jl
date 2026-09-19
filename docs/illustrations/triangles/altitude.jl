include("../default_config.jl")
lxm, lxo = @to_luxor_picture width=500 height=240 margin=20 begin
    A, B, C = APPoint(0.0, 0.0), APPoint(8.0, 0.0), APPoint(3.0, 6.0)
    t = APTriangle(A, B, C)
end
(; A, B, C, t) = lxo
@svg_doc(lxm, @__FILE__, begin
sethue(julia_purple)
path(altitude.(t, 1:3), action=:stroke)
sethue(julia_blue)
path(t, action=:stroke)
path(vertices(t))
plot_point(julia_blue)
end)
