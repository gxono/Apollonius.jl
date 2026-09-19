include("../default_config.jl")
lxm, lxo = @to_luxor_picture width=500 height=280 margin=40 begin
    a, b = APPoint(0.0, 0.0), APPoint(4.0, 1.0)
    p = APPoint(1.0, 3.0)
    extent = translation_construction(p, a, b; sweep=pi / 4).arcs
end
(; a, b, p, extent) = lxo
m = translation_construction(p, a, b; sweep=pi / 4)
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
path(APSegment(a, b); as=:arrow, action=:stroke)
path([a, b, p])
plot_point(julia_blue)
path([m.result])
plot_point(julia_purple)
sethue(julia_red)
label("A", :SW, a)
label("B", :SE, b)
label("p", :NW, p)
label("p'", :NE, m.result)
end)
