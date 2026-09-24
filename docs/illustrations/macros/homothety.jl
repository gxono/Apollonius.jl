include("../default_config.jl")
lxm, lxo = @prepare_to_picture width=500 height=300 margin=30 begin
    t = APTriangle(APPoint(0.0, 0.0), APPoint(5.0, 1.0), APPoint(2.0, 4.0))
    circ = APCircle2(APPoint(-2.0, -1.0), 1.5)
    H1 = homothety(2.0)(t)
    H2 = homothety(2.0)(circ)
    O = APPoint(0.0, 0.0)
end
(; t, circ, H1, H2, O) = lxo
@svg_doc(lxm, @__FILE__, begin
sethue(julia_blue)
path([t, circ], action=:stroke)
sethue(julia_purple)
path([H1, H2], action=:stroke)
sethue("white"); path([O], action=:fillpreserve); sethue(julia_blue); strokepath()
end)
