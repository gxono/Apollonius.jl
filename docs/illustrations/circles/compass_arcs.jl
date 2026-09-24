include("../default_config.jl")
lxm, lxo = @prepare_to_picture width=500 height=280 margin=30 begin
    c = APCircle2(APPoint(0.0, 0.0), 3.0)
    p1 = APPoint(3.0, 0.0)
    tick = arc_with_measure(c.center, p1, pi / 6)
    back = arc_with_length(c.center, p1, -1.0)
end
(; c, p1, tick, back) = lxo
@svg_doc(lxm, @__FILE__, begin
Luxor.fontsize(15)
gsave()
setline(1); setdash("dash")
sethue("gray80")
path(c, action=:stroke)
grestore()
sethue(julia_purple)
path([tick, back], action=:stroke)
sethue(julia_red)
label("arc_with_measure", :N, tick.p2)
label("arc_with_length", :S, back.p1)
sethue("white"); path([p1], action=:fillpreserve); sethue(julia_blue); strokepath()
end)
