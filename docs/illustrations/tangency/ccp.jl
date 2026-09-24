include("../default_config.jl")
lxm, lxo = @prepare_to_picture width=500 height=240 margin=20 begin
    c1 = APCircle2(APPoint(-4.0, 0.0), 1.5)
    c2 = APCircle2(APPoint(4.0, 0.0), 1.5)
    p = APPoint(0.0, 1.0)
    sols_p = tangent_circles(c1, c2, p)
end
(; c1, c2, p, sols_p) = lxo
@svg_doc(lxm, @__FILE__, begin
sethue(julia_purple)
path(sols_p, action=:stroke)
sethue(julia_blue)
path([c1,c2], action=:stroke)
sethue("white"); path(p, action=:fillpreserve); sethue(julia_blue); strokepath()
end)
