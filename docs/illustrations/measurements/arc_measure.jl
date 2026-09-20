include("../default_config.jl")
lxm, lxo = @to_luxor_picture width=500 height=300 margin=30 begin
    c = APCircle2(APPoint(0.0, 0.0), 3.0)
    arc = APCircularArc2(c, point_on_circle(c, pi / 9), point_on_circle(c, 7pi / 9))
    ang = APAngle2(c.center, arc.p1, arc.p2)
    mid = midpoint(arc)
    radii = [APSegment(c.center, arc.p1), APSegment(c.center, arc.p2)]
end
(; c, arc, ang, mid, radii) = lxo
@svg_doc(lxm, @__FILE__, begin
Luxor.fontsize(15)
gsave()
setline(1); setdash("dash")
sethue(julia_green)
path(radii, action=:stroke)
grestore()
sethue(julia_blue)
path(arc, action=:stroke)
sethue(julia_purple)
path(marks(ang; size=40); action=:stroke)
sethue(julia_red)
label("measure", label_anchor(ang; dist=75)...)
label("arc_length", :N, mid)
path([c.center, arc.p1, arc.p2]); plot_point(julia_blue)
path([mid]); plot_point(julia_purple)
end)
