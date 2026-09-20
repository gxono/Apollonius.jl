include("../default_config.jl")
import Apollonius: distance
lxm, lxo = @to_luxor_picture width=500 height=240 margin=60 begin
    O1, A1, B1 = APPoint(0.0, 0.0), APPoint(5.0, 0.0), APPoint(2.0, 4.0)
    O2, A2, B2 = APPoint(9.0, 0.0), APPoint(14.0, 0.0), APPoint(11.0, 4.0)
    ang1 = APAngle2(O1, A1, B1)
    ang2 = APAngle2(O2, B2, A2)
end
(; O1, A1, B1, O2, A2, B2, ang1, ang2) = lxo
@svg_doc(lxm, @__FILE__, begin
Luxor.fontsize(15)
@layer begin
	setline(1); setdash(:dash)
	sethue(julia_green)
	path([ang1, ang2], action=:stroke, as=:rays, radius=distance(O1, A1))
end

sethue(julia_purple)
path([ang1, ang2], action=:stroke)

sethue(julia_red)
label.("a", :E, [A1, A2], offset=8)
label.("b", :NW, [B1, B2], offset=8)
label("APAngle2(O,a,b)", :SE, O1 + APVector(10, 0.0))
label("APAngle2(O,b,a)", :NE, O2 + APVector(10, 0.0))

sethue("white")
path([O1, A1, B1, O2, A2, B2], action=:fillpreserve)
sethue(julia_blue); strokepath()
end)
