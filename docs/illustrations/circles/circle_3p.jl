include("../default_config.jl")
lxm, lxo = @prepare_to_picture width=500 height=240 margin=20 begin
    A, B, C = APPoint(0.0, 0.0), APPoint(4.0, 0.0), APPoint(0.0, 3.0)
    circ = APCircle2(A, B, C)
end
(; A, B, C, circ) = lxo
@svg_doc(lxm, @__FILE__, begin
sethue(julia_purple)
path(circ, action=:stroke)
sethue("white"); path([A,B,C], action=:fillpreserve); sethue(julia_blue); strokepath()
end)
