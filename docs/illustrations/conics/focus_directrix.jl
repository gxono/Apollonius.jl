include("../default_config.jl")

lxm = @to_luxor_picture! width=560 height=240 margin=20 begin
    F = APPoint(0.0, 0.0)
    dl = APSegment(APPoint(4.0, -5.0), APPoint(4.0, 5.0))
    d = APLine(dl.p1, dl.p2)
    ell = conic_with_focus(F, d, 0.5)
    @unbounded par = conic_with_focus(F, d, 1.0)
    @unbounded hyp = conic_with_focus(F, d, 2.0)
    parc = APParabolicArc2(par, point_on_parabola(par, -6.0), point_on_parabola(par, 6.0))
    harc = APHyperbolicArc2(hyp, point_on_hyperbola(hyp, -1.1; branch=-1), point_on_hyperbola(hyp, 1.1; branch=-1))
end


@svg_doc(lxm, @__FILE__, begin
fontsize(15)

sethue(julia_blue)
path(dl, action=:stroke)

sethue(julia_purple)
path([ell, parc, harc], action=:stroke)

sethue(julia_red)
label("F", :W, F, offset=8)
label("e = 1", :N, parc.p1)
label("e = 2", :S, harc.p1)
text("directrix", dl.p2 + APVector(5.0,0.0) ,angle=pi/2)
label("e = 0.5", :W, point_on_ellipse(ell, pi), offset=8)

sethue("white")
path(F, action=:fillpreserve)
sethue(julia_blue); strokepath()
end)
