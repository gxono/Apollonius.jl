include("../default_config.jl")
lxm, lxo = @prepare_to_picture width=500 height=240 margin=20 begin
    c = APCircle2(APPoint(0.0, 0.0), 5.0)
    l = APLine(APPoint(0.0, 3), APPoint(1.0, 4))
    t1, t2 = tangent_parallel(c, l)
end
(; c, l, t1, t2) = lxo
@svg_doc(lxm, @__FILE__, begin
sethue(julia_purple)
path([t1,t2], action=:stroke)
sethue(julia_blue)
path([c, l], action=:stroke)
sethue("white"); path(c.center, action=:fillpreserve); sethue(julia_blue); strokepath()
sethue("white"); path([t1[1], t2[1]], action=:fillpreserve); sethue(julia_purple); strokepath()
end)
