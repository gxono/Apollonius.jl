include("../default_config.jl")
lxm, lxo = @to_luxor_picture width=500 height=280 margin=30 begin
    c = APPoint(0.0, 0.0)
    p = APPoint(4.0, 2.5)
    extent = symmetry_construction(p, c; sweep=pi / 4).arcs
end
(; c, p, extent) = lxo
m = symmetry_construction(p, c; sweep=pi / 4)
@svg_doc(lxm, @__FILE__, begin
Luxor.fontsize(15)
gsave()
setline(1)
sethue(julia_green)
path(m.arcs, action=:stroke)
setdash("dash")
path(APSegment(p, m.result), action=:stroke)
grestore()
sethue(julia_blue)
sethue(julia_red)
label("p", :NE, p)
label("center", :NE, c)
label("p'", :SW, m.result)
path([p, c]); plot_point(julia_blue)
path([m.result]); plot_point(julia_purple)
end)
