include("../default_config.jl")
lxm, lxo = @to_luxor_picture width=500 height=280 margin=30 begin
    e = APEllipse2(APPoint(0.0, 0.0), 5.0, 3.0)
    c = e.center
    f1, f2 = foci(e)
    v1, v2 = vertices(e)
    p = point_on_ellipse(e, 1.0)
    od = orthoptic(e)
end
(; e, c, f1, f2, v1, v2, p, od) = lxo
@svg_doc(lxm, @__FILE__, begin
Luxor.fontsize(15)
gsave()
setline(1); setdash("dash")
sethue("gray80")
path(od, action=:stroke)
sethue(julia_green)
path([APSegment(p, f1), APSegment(p, f2)], action=:stroke)
grestore()
sethue(julia_blue)
path(e, action=:stroke)
path([c]); plot_point(julia_blue)
sethue(julia_purple)
path([f1, f2, v1, v2, p]); plot_point(julia_purple)
sethue(julia_red)
label("F1", :S, f1); label("F2", :S, f2); label("P", :N, p)
end)
