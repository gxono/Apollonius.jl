include("../default_config.jl")
lxm, lxo = @to_luxor_picture width=500 height=280 margin=30 begin
    c = APCircle2(APPoint(0.0, 0.0), 3.0)
    p = APPoint(7.0, 0.0)
    tp = tangent_points(c, p)
    legs = [APSegment(p, q) for q in tp]
    radii = [APSegment(c.center, q) for q in tp]
end
(; c, p, tp, legs, radii) = lxo
@svg_doc(lxm, @__FILE__, begin
Luxor.fontsize(15)
gsave()
setline(1); setdash("dash")
sethue(julia_green)
path(radii, action=:stroke)
grestore()
sethue(julia_blue)
path(c, action=:stroke)
path([p, c.center]); plot_point(julia_blue)
sethue(julia_purple)
path(legs, action=:stroke)
path(tp); plot_point(julia_purple)
sethue(julia_red)
label("p", :N, p)
end)
