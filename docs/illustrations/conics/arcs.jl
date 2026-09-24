include("../default_config.jl")
lxm, lxo = @prepare_to_picture width=560 height=240 margin=30 begin
    e = APEllipse2(APPoint(0.0, 0.0), 5.0, 3.0)
    earc = APEllipticArc2(e, point_on(e, 0.2), point_on(e, 2.0))
    par = APParabola2(APPoint(12.0, 1.0), APLine(APPoint(8.0, -1.0), APPoint(16.0, -1.0)))
    parc = APParabolicArc2(par, point_on(par, -3.0), point_on(par, 3.0))
    h = APHyperbola2(APPoint(24.0, 0.0), 3.0, 4.0)
    harc = APHyperbolicArc2(h, point_on(h, -0.5), point_on(h, 0.5))
end
(; e, earc, par, parc, h, harc) = lxo
@svg_doc(lxm, @__FILE__, begin
gsave()
setline(1); setdash("dash")
sethue("gray80")
path(e, action=:stroke)
path(par, action=:stroke, srange=(-120.0, 120.0))
path(h, action=:stroke, trange=(-1.5, 1.5))
grestore()
sethue(julia_blue)
path([earc, parc, harc], action=:stroke)
sethue(julia_purple)
sethue("white"); path([earc.p1, earc.p2, parc.p1, parc.p2, harc.p1, harc.p2], action=:fillpreserve); sethue(julia_purple); strokepath()
end)
