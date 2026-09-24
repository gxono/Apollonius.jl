include("../default_config.jl")
lxm, lxo = @prepare_to_picture width=500 height=280 margin=30 begin
    v, p1, p2 = APPoint(0.0, 0.0), APPoint(8.0, 0.0), APPoint(3.0, 6.0)
    extent = bisector_construction(v, p1, p2; sweep=pi / 4).arcs
end
(; v, p1, p2, extent) = lxo
m = bisector_construction(v, p1, p2; sweep=pi / 4)
@svg_doc(lxm, @__FILE__, begin
Luxor.fontsize(15)
@layer begin
	setline(1); sethue(julia_green)
	path(m.arcs, action=:stroke)
end

sethue(julia_blue)
path(APPolyline2(p1, v, p2), action=:stroke)
sethue(julia_purple)
path(m.result; extend=(0, 250), action=:stroke)

sethue(julia_red)
label("vertex", :SW, v)

sethue("white")
path(v, action=:fillpreserve)
sethue(julia_blue); strokepath()
sethue("white")
path(m.points, action=:fillpreserve)
sethue(julia_green); strokepath()
end)
