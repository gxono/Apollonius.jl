include("../default_config.jl")
lxm, lxo = @prepare_to_picture width=500 height=260 margin=30 begin
    c1 = APCircle2(APPoint(0.0, 0.0), 3.0)
    l4 = APLine(APPoint(-10.0, 5.0), APPoint(10.0, 5.0))
    m2 = only(midcircle(c1, l4))
end
(; c1, l4, m2) = lxo
@svg_doc(lxm, @__FILE__, begin
sethue(julia_blue)
path([c1, l4], action=:stroke)
gsave()
setline(1); setdash("dash")
sethue(julia_purple)
path(m2, action=:stroke)
grestore()
end)
