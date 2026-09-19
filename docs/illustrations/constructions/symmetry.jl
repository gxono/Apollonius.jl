include("../default_config.jl")
sz = @to_luxor_picture! width=500 height=280 margin=30 begin
    c = APPoint(0.0, 0.0)
    p = APPoint(4.0, 2.5)
    extent = symmetry_construction(p, c; sweep=pi / 4).arcs
end
m = symmetry_construction(p, c; sweep=pi / 4)
@svg_doc(sz, @__FILE__, begin
Luxor.fontsize(15)
sethue(julia_green); Luxor.setline(1)
path(m.arcs, action=:stroke)
setdash("dash"); Luxor.setline(1)
path(APSegment(p, m.result), action=:stroke)
setdash("solid")
sethue(julia_blue)
path([p, c])
plot_point(julia_blue)
path([m.result])
plot_point(julia_purple)
sethue(julia_red)
label("p", :NE, p)
label("center", :NE, c)
label("p'", :SW, m.result)
end)
