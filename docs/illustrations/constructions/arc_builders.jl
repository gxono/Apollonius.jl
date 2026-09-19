include("../default_config.jl")
lxm, lxo = @to_luxor_picture width=500 height=200 margin=45 begin
    O1, P1 = APPoint(0.0, 0.0), APPoint(3.0, 0.0)
    O2, P2 = APPoint(8.0, 0.0), APPoint(11.0, 0.0)
    O3, P3 = APPoint(16.0, 0.0), APPoint(19.0, 0.0)
    a1 = arc_with_angle(O1, P1, pi / 3)
    a2 = semicircle(O2, P2)
    a3 = arc_with_angle(O3, P3, pi / 3)
    a3x = extend_arc(a3, 0.5)
end
(; O1, P1, O2, P2, O3, P3, a1, a2, a3, a3x) = lxo
@svg_doc(lxm, @__FILE__, begin
Luxor.fontsize(14)
sethue(julia_purple)
path([a1, a2, a3x], action=:stroke)
sethue(julia_blue)
path(a3, action=:stroke)
path([O1, P1, O2, P2, O3, P3])
plot_point(julia_blue)
sethue(julia_red)
label("arc_with_angle", :SE, O1)
label("semicircle", :S, O2)
label("extend_arc", :S, O3)
end)
