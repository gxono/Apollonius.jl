include("../default_config.jl")
lxm, lxo = @to_luxor_picture width=500 height=300 margin=30 begin
    A, B, C = APPoint(0.0, 0.0), APPoint(8.0, 0.0), APPoint(3.0, 6.0)
    t = APTriangle(A, B, C)
    Om1, Om2 = first_brocard_point(t), second_brocard_point(t)
    bc = brocard_circle(t)
    K = symmedian_point(t)
end
(; A, B, C, t, Om1, Om2, bc, K) = lxo
@svg_doc(lxm, @__FILE__, begin
Luxor.fontsize(15)
sethue(julia_blue)
path(t, action=:stroke)
path([A, B, C]); plot_point(julia_blue)
sethue(julia_purple)
path(bc, action=:stroke)
path([Om1, Om2, K]); plot_point(julia_purple)
sethue(julia_red)
label("Ω1", :W, Om1); label("Ω2", :N, Om2); label("K", :E, K)
end)
