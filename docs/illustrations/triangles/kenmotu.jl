include("../default_config.jl")
lxm, lxo = @prepare_to_picture width=500 height=300 margin=30 begin
    A, B, C = APPoint(0.0, 0.0), APPoint(8.0, 0.0), APPoint(3.0, 6.0)
    t = APTriangle(A, B, C)
    kc = kenmotu_circle(t)
    kp = kenmotu_point(t)
end
(; A, B, C, t, kc, kp) = lxo
@svg_doc(lxm, @__FILE__, begin
sethue(julia_blue)
path(t, action=:stroke)
sethue(julia_purple)
path(kc, action=:stroke)
sethue("white"); path([A, B, C], action=:fillpreserve); sethue(julia_blue); strokepath()
sethue("white"); path([kp], action=:fillpreserve); sethue(julia_purple); strokepath()
end)
