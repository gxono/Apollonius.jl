include("../default_config.jl")
lxm, lxo = @to_luxor_picture width=500 height=300 margin=30 begin
    A, B, C = APPoint(0.0, 0.0), APPoint(8.0, 0.0), APPoint(3.0, 6.0)
    t = APTriangle(A, B, C)
    ot = orthic_triangle(t)
    tc = taylor_circle(t)
    tp = collect(taylor_points(t))
end
(; A, B, C, t, ot, tc, tp) = lxo
@svg_doc(lxm, @__FILE__, begin
sethue("gray80")
path(ot, action=:stroke)
sethue(julia_blue)
path(t, action=:stroke)
path([A, B, C]); plot_point(julia_blue)
sethue(julia_purple)
path(tc, action=:stroke)
path(tp); plot_point(julia_purple)
end)
