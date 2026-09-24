include("../default_config.jl")
lxm, lxo = @prepare_to_picture width=500 height=240 margin=20 begin
    A, B, C = APPoint(0.0, 0.0), APPoint(8.0, 0.0), APPoint(3.0, 6.0)
    t = APTriangle(A, B, C)
    tp = trilinear_point(t, 1.0, 1.0, 1.0)
end
(; A, B, C, t, tp) = lxo
@svg_doc(lxm, @__FILE__, begin
gsave()
sethue(julia_green)
setdash(:dash); setline(1)
path(bisector.(t, 1:3), action=:stroke)
grestore()
sethue(julia_blue)
path([t], action=:stroke)
sethue("white"); path(vertices(t), action=:fillpreserve); sethue(julia_blue); strokepath()
sethue("white"); path(tp, action=:fillpreserve); sethue(julia_purple); strokepath()
end)
