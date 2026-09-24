include("../default_config.jl")
lxm, lxo = @prepare_to_picture width=500 height=240 margin=20 begin
    C, P = APPoint(0.0, 0.0), APPoint(4.0, 2.0)
    circ = APCircle2(C, P)
end
(; C, P, circ) = lxo
@svg_doc(lxm, @__FILE__, begin
sethue(julia_purple)
path(circ, action=:stroke)
sethue("white"); path([C, P], action=:fillpreserve); sethue(julia_blue); strokepath()
end)
