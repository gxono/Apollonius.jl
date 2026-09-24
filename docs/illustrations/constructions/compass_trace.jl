include("../default_config.jl")
lxm, lxo = @prepare_to_picture width=500 height=240 margin=40 begin
    O, P = APPoint(0.0, 0.0), APPoint(5.0, 0.0)
end
(; O, P) = lxo
trace = compass_trace(O, P; angle=pi / 3)
@svg_doc(lxm, @__FILE__, begin
Luxor.fontsize(15)
gsave()
setline(1); setdash("dash")
sethue("gray80")
path(APSegment(O, P), action=:stroke)
grestore()
sethue(julia_purple)
path(trace, action=:stroke)
sethue(julia_red)
label("O", :W, O)
label("P", :E, P)
sethue("white"); path([O, P], action=:fillpreserve); sethue(julia_blue); strokepath()
end)
