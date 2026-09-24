include("../default_config.jl")
lxm, lxo = @prepare_to_picture width=500 height=320 margin=30 begin
    A, B, C = APPoint(0.0, 0.0), APPoint(8.0, 0.0), APPoint(3.0, 6.0)
    t = APTriangle(A, B, C)
    D = APPoint(5.0, -2.0)
    tris = [APTriangle(A, B, C), APTriangle(A, B, D), APTriangle(B, C, D), APTriangle(C, A, D)]
    npc = [nine_point_circle(x) for x in tris]
    pp = poncelet_point(t, D)
end
(; A, B, C, t, D, tris, npc, pp) = lxo
@svg_doc(lxm, @__FILE__, begin
Luxor.fontsize(15)
sethue(julia_blue)
path(t, action=:stroke)
sethue(julia_purple)
path(npc, action=:stroke)
sethue(julia_red)
label("D", :S, D)
sethue("white"); path([A, B, C], action=:fillpreserve); sethue(julia_blue); strokepath()
sethue("white"); path([pp], action=:fillpreserve); sethue(julia_purple); strokepath()
sethue("white"); path([D], action=:fillpreserve); sethue(julia_blue); strokepath()
end)
