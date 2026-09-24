include("../default_config.jl")
lxm, lxo = @prepare_to_picture width=500 height=200 margin=50 begin
    a, b = APPoint(0.0, 0.0), APPoint(7.0, 0.0)
end
(; a, b) = lxo
@svg_doc(lxm, @__FILE__, begin
Luxor.fontsize(14)
sethue(julia_blue)
path(APSegment(a, b), action=:stroke)
gsave()
setline(1)
sethue(julia_green)
Luxor.dimension(a, b; offset=40, format=d -> "7.0", textrotation=-pi / 2, textgap=25)
grestore()
sethue("white"); path([a, b], action=:fillpreserve); sethue(julia_blue); strokepath()
end)
