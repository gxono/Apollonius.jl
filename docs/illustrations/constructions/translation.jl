include("../default_config.jl")
lxm, lxo = @prepare_to_picture width=500 height=280 margin=40 begin
    a, b = APPoint(0.0, 0.0), APPoint(4.0, 1.0)
    p = APPoint(1.0, 3.0)
    extent = translation_construction(p, a, b; sweep=pi / 4).arcs
end
(; a, b, p, extent) = lxo
m = translation_construction(p, a, b; sweep=pi / 4)
@svg_doc(lxm, @__FILE__, begin
Luxor.fontsize(15)
gsave()
setline(1)
sethue(julia_green)
path(m.arcs, action=:stroke)
setdash("dash")
path(APSegment(p, m.result), action=:stroke)
grestore()
sethue(julia_blue)
path(APSegment(a, b); as=:arrow, action=:stroke)
sethue(julia_red)
label("A", :SW, a, offset=8)
label("B", :NE, b, offset=8)
label("p", :SW, p, offset=8)
label("p'", :NE, m.result, offset=8)
sethue("white"); path([a, b, p], action=:fillpreserve); sethue(julia_blue); strokepath()
sethue("white"); path([m.result], action=:fillpreserve); sethue(julia_purple); strokepath()
end)
