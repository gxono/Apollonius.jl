include("../default_config.jl")
lxm, lxo = @prepare_to_picture width=500 height=300 margin=30 begin
    center = APPoint(0.0, 0.0)
    far_line = APLine(APPoint(2.5, -2.0), APPoint(2.5, 2.0))
    base = APCircle2(center, 2.0)
    circ = APCircle2(APPoint(-4.0, 1.0), 1.5)
    I1 = invert_neg(far_line, center; k=2.0)
    I2 = invert_neg(circ, center; k=2.0)
end
(; center, far_line, base, circ, I1, I2) = lxo
@svg_doc(lxm, @__FILE__, begin
gsave()
setline(1); setdash("dash")
sethue("gray80")
path(base, action=:stroke)
grestore()
sethue(julia_blue)
path(far_line, action=:stroke, extend=20)
path(circ, action=:stroke)
sethue(julia_purple)
path([I1, I2], action=:stroke)
sethue("white"); path([center], action=:fillpreserve); sethue(julia_blue); strokepath()
end)
