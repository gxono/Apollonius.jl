include("../default_config.jl")
sz = @to_luxor_picture! width=500 height=280 margin=30 begin
    v, p1, p2 = APPoint(0.0, 0.0), APPoint(8.0, 0.0), APPoint(3.0, 6.0)
    extent = bisector_construction(v, p1, p2; sweep=pi / 4).arcs
end
m = bisector_construction(v, p1, p2; sweep=pi / 4)
@svg_doc(sz, @__FILE__, begin
Luxor.fontsize(15)
sethue(julia_purple); Luxor.setline(1.2)
path(m.arcs, action=:stroke)
sethue(julia_blue); Luxor.setline(1.8)
path([APSegment(v, p1), APSegment(v, p2)], action=:stroke)
path(m.result; extend=(0, 250), action=:stroke)
path([v, m.points...])
setpoint(julia_red)
sethue("black")
label("vertex", :SW, v)
end)
