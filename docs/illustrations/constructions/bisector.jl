include("../default_config.jl")
lxm, lxo = @to_luxor_picture width=500 height=280 margin=30 begin
    v, p1, p2 = APPoint(0.0, 0.0), APPoint(8.0, 0.0), APPoint(3.0, 6.0)
    extent = bisector_construction(v, p1, p2; sweep=pi / 4).arcs
end
(; v, p1, p2, extent) = lxo
m = bisector_construction(v, p1, p2; sweep=pi / 4)
@svg_doc(lxm, @__FILE__, begin
Luxor.fontsize(15)
sethue(julia_green); Luxor.setline(1)
path(m.arcs, action=:stroke)
sethue(julia_blue); Luxor.setline(1.8)
path([APSegment(v, p1), APSegment(v, p2)], action=:stroke)
sethue(julia_purple)
path(m.result; extend=(0, 250), action=:stroke)
path([v])
plot_point(julia_blue)
path(m.points)
plot_point(julia_green)
sethue(julia_red)
label("vertex", :SW, v)
end)
