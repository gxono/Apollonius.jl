include("../default_config.jl")
lxm, lxo = @to_luxor_picture width=500 height=300 margin=30 begin
    A, B, C = APPoint(0.0, 0.0), APPoint(8.0, 0.0), APPoint(3.0, 6.0)
    t = APTriangle(A, B, C)
    @unbounded el = euler_line(t)
    H = orthocenter(t)
    O = circumcenter(t)
    L = de_longchamps_point(t)
end
(; A, B, C, t, el, H, O, L) = lxo
@svg_doc(lxm, @__FILE__, begin
Luxor.fontsize(15)
sethue(julia_blue)
path(t, action=:stroke)
sethue(julia_purple)
path(el, action=:stroke, extend=30)
sethue(julia_red)
label("H", :N, H); label("O", :S, O); label("L", :N, L)
path([A, B, C]); plot_point(julia_blue)
path([H, O, L]); plot_point(julia_purple)
end)
