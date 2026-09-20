include("../default_config.jl")
lxm, lxo = @to_luxor_picture width=500 height=280 margin=30 begin
    A, B = APPoint(0.0, 0.0), APPoint(8.0, 1.0)
    p = APPoint(3.0, 4.0)
    extent = projection_construction(p, APLine(A, B); sweep=pi / 4).arcs
end
(; A, B, p, extent) = lxo
l = APLine(A, B)
m = projection_construction(p, l; sweep=pi / 4)
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
path(l; extend=(80, 80), action=:stroke)
sethue(julia_red)
label("p", :NE, p)
label("foot", :SE, m.result)
path([p]); plot_point(julia_blue)
path(m.points); plot_point(julia_green)
path([m.result]); plot_point(julia_purple)
end)
