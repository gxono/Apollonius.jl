include("../default_config.jl")
lxm, lxo = @to_luxor_picture width=500 height=300 margin=30 begin
    @unbounded h = APHyperbola2(APPoint(0.0, 0.0), 3.0, 4.0)
    c = h.center
    arc1 = APHyperbolicArc2(h, point_on_hyperbola(h, -1.2), point_on_hyperbola(h, 1.2))
    arc2 = APHyperbolicArc2(h, point_on_hyperbola(h, -1.2; branch=-1), point_on_hyperbola(h, 1.2; branch=-1))
    asy1, asy2 = APSegment(APPoint(-6.0, -8.0), APPoint(6.0, 8.0)), APSegment(APPoint(-6.0, 8.0), APPoint(6.0, -8.0))
    f1, f2 = foci(h)
    v1, v2 = vertices(h)
end
(; h, c, arc1, arc2, asy1, asy2, f1, f2, v1, v2) = lxo
@svg_doc(lxm, @__FILE__, begin
Luxor.fontsize(15)
gsave()
setline(1); setdash("dash")
sethue(julia_purple)
path([asy1, asy2], action=:stroke)
grestore()
sethue(julia_blue)
path([arc1, arc2], action=:stroke)
path([c]); plot_point(julia_blue)
sethue(julia_purple)
path([f1, f2, v1, v2]); plot_point(julia_purple)
sethue(julia_red)
label("F1", :S, f1); label("F2", :S, f2)
end)
