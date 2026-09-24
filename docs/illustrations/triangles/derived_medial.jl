include("../default_config.jl")
lxm, lxo = @prepare_to_picture width=500 height=300 margin=30 begin
    A, B, C = APPoint(0.0, 0.0), APPoint(8.0, 0.0), APPoint(3.0, 6.0)
    t = APTriangle(A, B, C)
    mt = medial_triangle(t)
    ot = orthic_triangle(t)
end
(; A, B, C, t, mt, ot) = lxo
@svg_doc(lxm, @__FILE__, begin
Luxor.fontsize(15)
sethue(julia_blue)
path(t, action=:stroke)
sethue(julia_purple)
path([mt, ot], action=:stroke)
sethue("white"); path([A, B, C], action=:fillpreserve); sethue(julia_blue); strokepath()
sethue("white"); path(vertices(mt), action=:fillpreserve); sethue(julia_purple); strokepath()
sethue("white"); path(vertices(ot), action=:fillpreserve); sethue(julia_purple); strokepath()
end)
