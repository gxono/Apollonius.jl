include("../default_config.jl")
lxm, lxo = @prepare_to_picture width=560 height=320 margin=30 begin
    F = APPoint(0.0, 0.0)
    dl = APSegment(APPoint(4.0, -5.0), APPoint(4.0, 5.0))
    d = APLine(dl.p1, dl.p2)
    ell = conic_with_focus(F, d, 0.5)
    par = conic_with_focus(F, d, 1.0)
    hyp = conic_with_focus(F, d, 2.0)
    parc = APParabolicArc2(par, point_on(par, -6.0), point_on(par, 6.0))
    harc = APHyperbolicArc2(hyp, point_on(hyp, -1.1; branch=-1), point_on(hyp, 1.1; branch=-1))
end
(; F, dl, d, ell, par, hyp, parc, harc) = lxo
@svg_doc(lxm, @__FILE__, begin
Luxor.fontsize(15)
sethue(julia_blue)
path(dl, action=:stroke)
sethue(julia_purple)
path([ell, parc, harc], action=:stroke)
sethue(julia_red)
label("F", :SW, F); label("e = 0.5", :N, ell.center + APVector(0.0, ell.b)); label("e = 1", :N, parc.p1); label("e = 2", :N, harc.p1); label("directrix", :N, dl.p2)
sethue("white"); path([F], action=:fillpreserve); sethue(julia_blue); strokepath()
end)
