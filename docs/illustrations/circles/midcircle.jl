include("../default_config.jl")
lxm, lxo = @to_luxor_picture width=500 height=260 margin=30 begin
    c1 = APCircle2(APPoint(0.0, 0.0), 3.0)
    c4 = APCircle2(APPoint(8.0, 0.0), 2.0)
    m1 = only(midcircle(c1, c4))
end
(; c1, c4, m1) = lxo
@svg_doc(lxm, @__FILE__, begin
sethue(julia_blue)
path([c1, c4], action=:stroke)
gsave()
setline(1); setdash("dash")
sethue(julia_purple)
path(m1, action=:stroke)
grestore()
end)
