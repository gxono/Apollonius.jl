include("../default_config.jl")
sz = @to_luxor_picture! width=500 height=280 margin=30 begin
    a, b = APPoint(0.0, 0.0), APPoint(6.0, 2.0)
    extent = mediator_construction(a, b; sweep=pi / 4).arcs
end
m = mediator_construction(a, b; sweep=pi / 4)
@svg_doc(sz, @__FILE__, begin
Luxor.fontsize(15)
sethue(julia_green); Luxor.setline(1.2)
path(m.arcs, action=:stroke)
sethue(julia_blue); Luxor.setline(1.8)
path(APSegment(a, b), action=:stroke)
sethue(julia_purple)
path(m.result; add=(0.3, 0.3), action=:stroke)
path([a, b])
plot_point(julia_blue)
path(m.points)
plot_point(julia_green)
sethue(julia_red)
label("A", :W, a)
label("B", :E, b)
end)
