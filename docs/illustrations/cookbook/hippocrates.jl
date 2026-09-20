include("../default_config.jl")
lxm, lxo = @to_luxor_picture width=500 height=300 margin=30 begin
    A, B, C = APPoint(0.0, 0.0), APPoint(2.0, 0.0), APPoint(1.0, 1.0)
    t = APTriangle(A, B, C)
    big = semicircle(midpoint(A, B), B)
    left = semicircle(midpoint(A, C), C)
    right = semicircle(midpoint(C, B), B)
end
(; A, B, C, t, big, left, right) = lxo
@svg_doc(lxm, @__FILE__, begin
Luxor.fontsize(15)
sethue(julia_blue)
path([t, big], action=:stroke)
sethue(julia_purple)
path([left, right], action=:stroke)
sethue(julia_red)
label("A", :SW, A); label("B", :SE, B); label("C", :S, C)
path([A, B, C]); plot_point(julia_blue)
end)
