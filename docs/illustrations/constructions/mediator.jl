include("../default_config.jl")
lxm, lxo = @prepare_to_picture width=500 height=280 margin=30 begin
    a, b = APPoint(0.0, 0.0), APPoint(6.0, 2.0)
    extent = mediator_construction(a, b; sweep=pi / 4).arcs
end
(; a, b, extent) = lxo
m = mediator_construction(a, b; sweep=pi / 4)
@svg_doc(lxm, @__FILE__, begin
Luxor.fontsize(15)
gsave()
setline(1)
sethue(julia_green)
path(m.arcs, action=:stroke)
grestore()
sethue(julia_blue)
path(APSegment(a, b), action=:stroke)
sethue(julia_purple)
path(m.result; add=(0.3, 0.3), action=:stroke)
sethue(julia_red)
label("A", :W, a)
label("B", :E, b)
sethue("white"); path([a, b], action=:fillpreserve); sethue(julia_blue); strokepath()
sethue("white"); path(m.points, action=:fillpreserve); sethue(julia_green); strokepath()
end)
