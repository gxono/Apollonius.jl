include("../default_config.jl")
sz = @to_luxor_picture! width=500 height=280 margin=30 begin
    A, B = APPoint(0.0, 0.0), APPoint(8.0, 1.0)
    p = APPoint(3.0, 4.0)
    extent = perpendicular_construction(APLine(A, B), p; sweep=pi / 4).arcs
end
l = APLine(A, B)
m = perpendicular_construction(l, p; sweep=pi / 4)
@svg_doc(sz, @__FILE__, begin
Luxor.fontsize(15)
sethue(julia_green); Luxor.setline(1.2)
path(m.arcs, action=:stroke)
sethue(julia_blue); Luxor.setline(1.8)
path(l; extend=(80, 80), action=:stroke)
sethue(julia_purple)
path(m.result; add=(0.3, 0.3), action=:stroke)
path([p])
plot_point(julia_blue)
path(m.points)
plot_point(julia_green)
sethue(julia_red)
label("p", :NE, p)
label("l", :S, l.p2)
end)
