include("../default_config.jl")
lxm = @prepare_to_picture! width=500 height=240 margin=20 begin
    c1 = APCircle2(APPoint(0.0, 0.0), 3.0)
    c2 = APCircle2(APPoint(4.0, 0.0), 3.0)
    l = APLine(APPoint(-4.0, 1.0), APPoint(4.0, 1.0))
    cc = intersection(c1, c2)
    lp = intersection(l, c1)
end
@svg_doc(lxm, @__FILE__, begin
sethue(julia_blue)
path([c1, c2], action=:stroke)
path(l, action=:stroke, extend=30)
sethue("white"); path(cc, action=:fillpreserve); sethue(julia_purple); strokepath()
sethue("white"); path(lp, action=:fillpreserve); sethue(julia_purple); strokepath()
end)
