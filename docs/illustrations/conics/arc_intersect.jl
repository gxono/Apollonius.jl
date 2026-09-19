include("../default_config.jl")
lxm, lxo = @to_luxor_picture width=500 height=260 margin=30 begin
    e = APEllipse2(APPoint(0.0, 0.0), 5.0, 3.0)
    earc = APEllipticArc2(e, point_on_ellipse(e, 0.2), point_on_ellipse(e, 2.0))
    l = APSegment(APPoint(-7.0, 1.0), APPoint(7.0, 1.0))
    xs = intersection(l, earc)
end
(; e, earc, l, xs) = lxo
@svg_doc(lxm, @__FILE__, begin
gsave()
setline(1); setdash("dash")
sethue("gray80")
path(e, action=:stroke)
grestore()
sethue(julia_blue)
path([earc, l], action=:stroke)
sethue(julia_purple)
path(xs); plot_point(julia_purple)
end)
