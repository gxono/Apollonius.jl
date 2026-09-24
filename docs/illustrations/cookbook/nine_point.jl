include("../default_config.jl")
lxm, lxo = @prepare_to_picture width=500 height=320 margin=30 begin
    A, B, C = APPoint(0.0, 0.0), APPoint(8.0, 0.0), APPoint(3.0, 6.0)
    t = APTriangle(A, B, C)
    npc = nine_point_circle(t)
    pts = [collect(vertices(medial_triangle(t))); collect(vertices(orthic_triangle(t))); collect(euler_points(t))]
end
(; A, B, C, t, npc, pts) = lxo
@svg_doc(lxm, @__FILE__, begin
sethue(julia_blue)
path(t, action=:stroke)
sethue(julia_purple)
path(npc, action=:stroke)
sethue("white"); path([A, B, C], action=:fillpreserve); sethue(julia_blue); strokepath()
sethue("white"); path(pts, action=:fillpreserve); sethue(julia_purple); strokepath()
end)
