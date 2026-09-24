include("../default_config.jl")
lxm, lxo = @prepare_to_picture width=500 height=280 margin=30 begin
    l = APLine(APPoint(0.0, 0.0), APPoint(1.0, 1.0))
    p = APPoint(3.0, 0.0)
    p2 = reflection(p, APLine(APPoint(0.0, 0.0), APPoint(1.0, 1.0)))
    leg = APSegment(p, p2)
end
(; l, p, p2, leg) = lxo
@svg_doc(lxm, @__FILE__, begin
Luxor.fontsize(15)
gsave()
setline(1); setdash("dash")
sethue(julia_green)
path(leg, action=:stroke)
grestore()
sethue(julia_blue)
path(l, action=:stroke, extend=400)
sethue(julia_purple)
sethue(julia_red)
label("p", :S, p); label("p'", :W, p2)
sethue("white"); path([p], action=:fillpreserve); sethue(julia_blue); strokepath()
sethue("white"); path([p2], action=:fillpreserve); sethue(julia_purple); strokepath()
end)
