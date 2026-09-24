include("../default_config.jl")
lxm, lxo = @prepare_to_picture width=500 height=280 margin=30 begin
    c = APCircle2(APPoint(1.0, 2.0), 3.0)
    s = APSegment(APPoint(0.0, 0.0), APPoint(4.0, 0.0))
    C2 = rotate(pi / 2)(c)
    S2 = rotate(pi / 2)(s)
end
(; c, s, C2, S2) = lxo
@svg_doc(lxm, @__FILE__, begin
sethue(julia_blue)
path([c, s], action=:stroke)
sethue(julia_purple)
path([C2, S2], action=:stroke)
end)
