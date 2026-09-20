include("../default_config.jl")
lxm, lxo = @to_luxor_picture width=500 height=280 margin=30 begin
    A, B = APPoint(0.0, 0.0), APPoint(6.0, 0.0)
    t = triangle_on_segment(A, B, deg2rad(50), deg2rad(60))
    angA = APAngle2(t[1], t[2], t[3])
    angB = APAngle2(t[2], t[3], t[1])
end
(; A, B, t, angA, angB) = lxo
@svg_doc(lxm, @__FILE__, begin
Luxor.fontsize(15)
sethue(julia_blue)
path(t, action=:stroke)
sethue(julia_purple)
path(marks(angA; size=40); action=:stroke)
path(marks(angB; size=40); action=:stroke)
sethue(julia_red)
label("50°", label_anchor(angA; dist=62)...); label("60°", label_anchor(angB; dist=62)...)
label("A", :SW, A); label("B", :SE, B)
path([A, B]); plot_point(julia_blue)
path([t[3]]); plot_point(julia_purple)
end)
