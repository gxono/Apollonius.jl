include("../default_config.jl")
lxm, lxo = @prepare_to_picture width=500 height=280 margin=30 begin
    e = APEllipse2(APPoint(0.0, 0.0), 5.0, 2.0)
    c = APCircle2(APPoint(0.0, 0.0), 3.0)
    pts = intersection(e, c)
end
(; e, c, pts) = lxo
@svg_doc(lxm, @__FILE__, begin
sethue(julia_blue)
path([e, c], action=:stroke)
sethue(julia_purple)
sethue("white"); path(pts, action=:fillpreserve); sethue(julia_purple); strokepath()
end)
