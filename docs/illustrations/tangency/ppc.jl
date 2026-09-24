include("../default_config.jl")
lxm, lxo = @prepare_to_picture width=500 height=240 margin=20 begin
    a2, b2 = APPoint(-2.0, 1.0), APPoint(2.0, 1.0)
    given_c = APCircle2(APPoint(0.0, -3.0), 2.0)
    sols_c = tangent_circles(a2, b2, given_c)
end
(; a2, b2, given_c, sols_c) = lxo
@svg_doc(lxm, @__FILE__, begin
sethue(julia_purple)
path(sols_c, action=:stroke)
sethue(julia_blue)
path(given_c, action=:stroke)
sethue("white"); path([a2,b2], action=:fillpreserve); sethue(julia_blue); strokepath()
end)
