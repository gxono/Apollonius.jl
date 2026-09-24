include("../default_config.jl")
lxm, lxo = @prepare_to_picture width=560 height=260 margin=30 begin
    O1, P1 = APPoint(0.0, 0.0), APPoint(4.0, 0.0)
    ang1 = angle_with_measure(O1, P1, pi / 3)
    r1 = [APSegment(O1, P1), APSegment(O1, ang1.b)]
    l1 = APLine(APPoint(7.0, 0.0), APPoint(11.0, 1.0))
    l2 = APLine(APPoint(7.0, 3.0), APPoint(11.0, 0.0))
    ends = [APPoint(7.0, 0.0), APPoint(11.0, 1.0), APPoint(7.0, 3.0), APPoint(11.0, 0.0)]
    ang2 = APAngle2(APLine(ends[3], ends[4]), APLine(ends[1], ends[2]))
end
(; O1, P1, ang1, r1, l1, l2, ends, ang2) = lxo
@svg_doc(lxm, @__FILE__, begin
Luxor.fontsize(15)
sethue(julia_blue)
path(r1, action=:stroke)
path([l1, l2], action=:stroke, extend=300)
sethue(julia_purple)
path(marks(ang1; size=40); action=:stroke)
path(marks(ang2; size=40); action=:stroke)
sethue(julia_red)
label("60°", label_anchor(ang1; dist=64)...); label("θ", label_anchor(ang2; dist=64)...)
end)
