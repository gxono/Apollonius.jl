include("../default_config.jl")
lxm, lxo = @to_luxor_picture width=500 height=280 margin=40 begin
    A, B = APPoint(0.0, 0.0), APPoint(8.0, 1.0)
    p = APPoint(2.0, 4.0)
    extent = parallel_construction(APLine(A, B), p; sweep=pi / 4).arcs
end
(; A, B, p, extent) = lxo
l = APLine(A, B)
m = parallel_construction(l, p; sweep=pi / 4)
D, E = m.points
@svg_doc(lxm, @__FILE__, begin
Luxor.fontsize(15)
gsave()
setline(1)
sethue(julia_green)
path(m.arcs, action=:stroke)
setdash("dash")
path(APPolyline2([A, p, E, D, A]), action=:stroke)
grestore()
sethue(julia_blue)
path(l; extend=(80, 80), action=:stroke)
sethue(julia_purple)
path(m.result; add=(0.3, 0.3), action=:stroke)
path([A, p])
plot_point(julia_blue)
path([D, E])
plot_point(julia_green)
sethue(julia_red)
label("A", :SW, A)
label("D", :S, D)
label("E", :NE, E)
label("p", :NW, p)
end)
