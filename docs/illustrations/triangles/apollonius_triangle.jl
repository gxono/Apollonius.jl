include("../default_config.jl")
lxm, lxo = @to_luxor_picture width=500 height=340 margin=30 begin
    A, B, C = APPoint(0.0, 0.0), APPoint(8.0, 0.0), APPoint(3.0, 6.0)
    t = APTriangle(A, B, C)
    ex = excircles(t)
    exc = [ex.A, ex.B, ex.C]
    apc = apollonius_circle_of_triangle(t)
    ap = apollonius_point_of_triangle(t)
end
(; A, B, C, t, ex, exc, apc, ap) = lxo
@svg_doc(lxm, @__FILE__, begin
Luxor.fontsize(15)
sethue("gray80")
path(exc, action=:stroke)
sethue(julia_blue)
path(t, action=:stroke)
path([A, B, C]); plot_point(julia_blue)
sethue(julia_purple)
path(apc, action=:stroke)
path([ap]); plot_point(julia_purple)
end)
