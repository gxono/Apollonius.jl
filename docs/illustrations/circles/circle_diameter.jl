include("../default_config.jl")
lxm, lxo = @prepare_to_picture width=500 height=280 margin=30 begin
    d = APSegment(APPoint(0.0, 0.0), APPoint(6.0, 2.0))
    c = circle_with_diameter(d)
    p = point_on(c, 1.0)
    legs = [APSegment(p, d.p1), APSegment(p, d.p2)]
    ang = APAngle2(p, d.p1, d.p2)
end
(; d, c, p, legs, ang) = lxo
@svg_doc(lxm, @__FILE__, begin
Luxor.fontsize(15)
gsave()
setline(1); setdash("dash")
sethue(julia_green)
path(legs, action=:stroke)
grestore()
sethue(julia_blue)
path(d, action=:stroke)
sethue(julia_purple)
path(c, action=:stroke)
path(APAngle2(p, d.p1, d.p2); as=:rarc, radius=14, action=:stroke)
sethue(julia_red)
label("center", :S, c.center); label("p", :N, p)
sethue("white"); path([d.p1, d.p2], action=:fillpreserve); sethue(julia_blue); strokepath()
sethue("white"); path([c.center, p], action=:fillpreserve); sethue(julia_purple); strokepath()
end)
