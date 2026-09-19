include("../default_config.jl")
lxm, lxo = @to_luxor_picture width=500 height=280 margin=30 begin
    O = APPoint(0.0, 0.0)
    P1 = APPoint(4.0, 0.0)
    P2 = APPoint(0.0, 4.0)
    ang = APAngle2(O, P1, P2)
    inside = O + APVector(1.0, 1.0)
    outside = APPoint(-1.5, -1.0)
    rays = [APSegment(O, P1), APSegment(O, P2)]
end
(; O, P1, P2, ang, inside, outside, rays) = lxo
@svg_doc(lxm, @__FILE__, begin
Luxor.fontsize(15)
sethue(julia_blue)
path(rays, action=:stroke)
sethue(julia_purple)
path(marks(ang; size=40); action=:stroke)
path([inside]); plot_point(julia_purple)
path([outside]); plot_point("gray80")
sethue(julia_red)
label("a", :E, P1); label("b", :N, P2)
end)
