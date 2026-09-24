include("../default_config.jl")
lxm, lxo = @prepare_to_picture width=500 height=300 margin=30 begin
    t = APTriangle(APPoint(0.0, 0.0), APPoint(5.0, 1.0), APPoint(2.0, 4.0))
    circ = APCircle2(APPoint(-2.0, -1.0), 1.5)
    pivot = APPoint(1.0, 1.0)
    R1 = rotate(pi / 2, pivot)(t)
    R2 = rotate(pi / 2, pivot)(circ)
end
(; t, circ, pivot, R1, R2) = lxo
@svg_doc(lxm, @__FILE__, begin
sethue(julia_blue)
path([t, circ], action=:stroke)
sethue(julia_purple)
path([R1, R2], action=:stroke)
sethue("white"); path([pivot], action=:fillpreserve); sethue(julia_blue); strokepath()
end)
