include("../default_config.jl")
lxm, lxo = @prepare_to_picture width=500 height=300 margin=30 begin
    p1, p2, p3 = APPoint(-2.0, 4.0), APPoint(0.5, 0.25), APPoint(3.0, 9.0)
    axis = APVector(0.0, 1.0)
    pa = parabola_through_points(p1, p2, p3, axis)
    arc = APParabolicArc2(pa, point_on(pa, -5.0), point_on(pa, 5.0))
end
(; p1, p2, p3, axis, pa, arc) = lxo
@svg_doc(lxm, @__FILE__, begin
Luxor.fontsize(15)
sethue(julia_blue)
sethue(julia_purple)
path(arc, action=:stroke)
sethue(julia_red)
label("p1", :NE, p1); label("p2", :SE, p2); label("p3", :NW, p3)
sethue("white"); path([p1, p2, p3], action=:fillpreserve); sethue(julia_blue); strokepath()
end)
