include("../default_config.jl")
lxm, lxo = @prepare_to_picture width=500 height=300 margin=30 begin
    A, B, C = APPoint(0.0, 0.0), APPoint(8.0, 0.0), APPoint(3.0, 6.0)
    t = APTriangle(A, B, C)
    mt = medial_triangle(t)
    sc = spieker_circle(t)
    S = spieker_center(t)
end
(; A, B, C, t, mt, sc, S) = lxo
@svg_doc(lxm, @__FILE__, begin
Luxor.fontsize(15)
sethue("gray80")
path(mt, action=:stroke)
sethue(julia_blue)
path(t, action=:stroke)
sethue(julia_purple)
path(sc, action=:stroke)
sethue(julia_red)
label("S", :N, S)
sethue("white"); path([A, B, C], action=:fillpreserve); sethue(julia_blue); strokepath()
sethue("white"); path([S], action=:fillpreserve); sethue(julia_purple); strokepath()
end)
