include("../default_config.jl")
import Apollonius: distance
lxm = @prepare_to_picture! width=500 height=240 margin=60 begin
    c1 = APCircle2(APPoint(0.0, 0.0), 2.5)
    l = APLine(APPoint(-4.0, -1.0), APPoint(4.0, 1.0))
    lp = intersection(l, c1)
    d1 = APCircle2(APPoint(9.0, 0.0), 2.5)
    d2 = APCircle2(APPoint(12.0, 0.0), 2.5)
    cp = intersection(d1, d2)
end

@svg_doc(lxm, @__FILE__, begin
Luxor.fontsize(15)
sethue(julia_blue)
path([c1, d1, d2], action=:stroke)
path(l, action=:stroke, extend=40)

sethue(julia_red)
label("1", :NW, lp[1], offset=8)
label("2", :SE, lp[2], offset=8)
label("1", :N, cp[1], offset=8)
label("2", :S, cp[2], offset=8)

sethue("white")
path([lp cp], action=:fillpreserve)
sethue(julia_purple); strokepath()
end)
