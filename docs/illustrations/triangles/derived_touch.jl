include("../default_config.jl")
lxm, lxo = @prepare_to_picture width=500 height=340 margin=30 begin
    A, B, C = APPoint(0.0, 0.0), APPoint(8.0, 0.0), APPoint(3.0, 6.0)
    t = APTriangle(A, B, C)
    ct = contact_triangle(t)
    et = extouch_triangle(t)
end
(; A, B, C, t, ct, et) = lxo
@svg_doc(lxm, @__FILE__, begin
sethue(julia_blue)
path(t, action=:stroke)
sethue(julia_purple)
path([ct, et], action=:stroke)
sethue("white"); path([A, B, C], action=:fillpreserve); sethue(julia_blue); strokepath()
sethue("white"); path(vertices(ct), action=:fillpreserve); sethue(julia_purple); strokepath()
sethue("white"); path(vertices(et), action=:fillpreserve); sethue(julia_purple); strokepath()
end)
