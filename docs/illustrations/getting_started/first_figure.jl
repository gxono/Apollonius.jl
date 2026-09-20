include("../default_config.jl")
lxm, lxo = @to_luxor_picture width=500 height=300 margin=30 begin
    A, B, C = APPoint(0.0, 0.0), APPoint(6.0, 0.0), APPoint(1.5, 4.0)
    t = APTriangle(A, B, C)
    cc = circumcircle(t)
    inc = incircle(t)
    O = circumcenter(t)
end
(; A, B, C, t, cc, inc, O) = lxo
@svg_doc(lxm, @__FILE__, begin
Luxor.fontsize(15)
sethue(julia_blue)
path(t, action=:stroke)
sethue(julia_purple)
path([cc, inc], action=:stroke)
sethue(julia_red)
label("A", :SW, A); label("B", :SE, B); label("C", :N, C)
label("O", :S, O); label("I", :W, inc.center)
path([A, B, C]); plot_point(julia_blue)
path([O, inc.center]); plot_point(julia_purple)
end)
