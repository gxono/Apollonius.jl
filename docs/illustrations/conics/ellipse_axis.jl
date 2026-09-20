include("../default_config.jl")
lxm, lxo = @to_luxor_picture width=500 height=280 margin=30 begin
    c = APPoint(0.0, 0.0)
    v = APPoint(5.0, 0.0)
    p = APPoint(3.0, 2.4)
    e = ellipse_with_axis(c, v, p)
    ax = APSegment(c, v)
end
(; c, v, p, e, ax) = lxo
@svg_doc(lxm, @__FILE__, begin
Luxor.fontsize(15)
sethue(julia_blue)
path(ax, action=:stroke)
path([c, v, p]); plot_point(julia_blue)
sethue(julia_purple)
path(e, action=:stroke)
sethue(julia_red)
label("center", :S, c); label("vertex", :S, v); label("p", :N, p)
end)
