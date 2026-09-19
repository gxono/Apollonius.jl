include("../default_config.jl")
sz = @to_luxor_picture! width=500 height=280 margin=40 begin
    A, B = APPoint(0.0, 0.0), APPoint(8.0, 1.0)
    p = APPoint(2.0, 4.0)
    extent = parallel_construction(APLine(A, B), p; sweep=pi / 4).arcs
end
l = APLine(A, B)
m = parallel_construction(l, p; sweep=pi / 4)
D, E = m.points
@svg_doc(sz, @__FILE__, begin
Luxor.fontsize(15)
sethue(julia_purple); Luxor.setline(1.2)
path(m.arcs, action=:stroke)
sethue("gray"); setdash("dash"); Luxor.setline(1)
path(APPolyline2([A, p, E, D, A]), action=:stroke)
setdash("solid")
sethue(julia_blue); Luxor.setline(1.8)
path(l; extend=(60, 60), action=:stroke)
path(m.result; add=(0.3, 0.3), action=:stroke)
path([A, D, E, p])
setpoint(julia_red)
sethue("black")
label("A", :SW, A)
label("D", :S, D)
label("E", :NE, E)
label("p", :NW, p)
end)
