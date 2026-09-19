include("../default_config.jl")
sz = @to_luxor_picture! width=500 height=280 margin=30 begin
    c = APPoint(0.0, 0.0)
    p = APPoint(4.0, 2.5)
    extent = symmetry_construction(p, c; sweep=pi / 4).arcs
end
m = symmetry_construction(p, c; sweep=pi / 4)
@svg_doc(sz, @__FILE__, begin
Luxor.fontsize(15)
sethue(julia_purple); Luxor.setline(1.2)
path(m.arcs, action=:stroke)
sethue("gray"); setdash("dash"); Luxor.setline(1)
path(APSegment(p, m.result), action=:stroke)
setdash("solid")
path([p, c])
setpoint(julia_blue)
path([m.result])
setpoint(julia_red)
sethue("black")
label("p", :NE, p)
label("center", :NE, c)
label("p'", :SW, m.result)
end)
