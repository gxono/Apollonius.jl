include("../default_config.jl")
lxm, lxo = @prepare_to_picture width=500 height=300 margin=30 begin
    t = APTriangle(APPoint(0.0, 0.0), APPoint(5.0, 1.0), APPoint(2.0, 4.0))
    circ = APCircle2(APPoint(-2.0, -1.0), 1.5)
    mirror = APLine(APPoint(0.0, 0.0), APPoint(1.0, 1.0))
    M1 = reflection(t, mirror)
    M2 = reflection(circ, mirror)
end
(; t, circ, mirror, M1, M2) = lxo
@svg_doc(lxm, @__FILE__, begin
gsave()
setline(1); setdash("dash")
sethue("gray80")
path(mirror, action=:stroke, extend=40)
grestore()
sethue(julia_blue)
path([t, circ], action=:stroke)
sethue(julia_purple)
path([M1, M2], action=:stroke)
end)
