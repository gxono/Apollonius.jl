include("../default_config.jl")
lxm, lxo = @prepare_to_picture width=500 height=280 margin=30 begin
    c = APCircle2(APPoint(0.0, 0.0), 4.0)
    edge = rand(Apollonius.Random.Xoshiro(7), c, 14)
    inner = [rand_inside(Apollonius.Random.Xoshiro(k), c) for k in 1:40]
end
(; c, edge, inner) = lxo
@svg_doc(lxm, @__FILE__, begin
sethue(julia_blue)
path(c, action=:stroke)
sethue(julia_purple)
sethue("white"); path(edge, action=:fillpreserve); sethue(julia_purple); strokepath()
sethue("white"); path(inner, radius=2, action=:fillpreserve); sethue(julia_purple); strokepath()
end)
