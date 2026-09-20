include("../default_config.jl")
lxm, lxo = @to_luxor_picture width=500 height=300 margin=30 begin
    c = APCircle2(APPoint(0.0, 0.0), 3.0)
    p = APPoint(7.0, 0.0)
    o = orthogonal_circle(c, p)
    pts = intersection(c, o)
end
(; c, p, o, pts) = lxo
@svg_doc(lxm, @__FILE__, begin
Luxor.fontsize(15)
sethue(julia_blue)
path(c, action=:stroke)
sethue(julia_purple)
path(o, action=:stroke)
sethue(julia_red)
label("p", :N, p)
path([p]); plot_point(julia_blue)
path(pts); plot_point(julia_purple)
end)
