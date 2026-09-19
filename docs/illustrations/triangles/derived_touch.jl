include("../default_config.jl")
lxm, lxo = @to_luxor_picture width=500 height=340 margin=30 begin
    A, B, C = APPoint(0.0, 0.0), APPoint(8.0, 0.0), APPoint(3.0, 6.0)
    t = APTriangle(A, B, C)
    ct = contact_triangle(t)
    et = extouch_triangle(t)
end
(; A, B, C, t, ct, et) = lxo
@svg_doc(lxm, @__FILE__, begin
sethue(julia_blue)
path(t, action=:stroke)
path([A, B, C]); plot_point(julia_blue)
sethue(julia_purple)
path([ct, et], action=:stroke)
path(vertices(ct)); plot_point(julia_purple)
path(vertices(et)); plot_point(julia_purple)
end)
