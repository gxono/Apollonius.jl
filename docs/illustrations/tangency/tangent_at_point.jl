include("../default_config.jl")
lxm, lxo = @prepare_to_picture width=560 height=300 margin=30 begin
    l = APSegment(APPoint(-3.0, 0.0), APPoint(9.0, 0.0))
    p = APPoint(2.0, 0.0)
    q = APPoint(0.0, 2.0)
    one = tangent_circle_at_point(APLine(l.p1, l.p2), p, q)
    two = tangent_circles_at_point(APLine(l.p1, l.p2), p, 1.2)
end
(; l, p, q, one, two) = lxo
@svg_doc(lxm, @__FILE__, begin
Luxor.fontsize(15)
sethue(julia_blue)
path(l, action=:stroke)
sethue(julia_purple)
path(one, action=:stroke)
gsave()
setline(1); setdash("dash")
path(two, action=:stroke)
grestore()
sethue(julia_red)
label("p", :S, p); label("q", :NW, q)
sethue("white"); path([p, q], action=:fillpreserve); sethue(julia_blue); strokepath()
end)
