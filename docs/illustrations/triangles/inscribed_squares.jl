include("../default_config.jl")
lxm, lxo = @prepare_to_picture width=500 height=340 margin=30 begin
    A, B, C = APPoint(0.0, 0.0), APPoint(8.0, 0.0), APPoint(3.0, 6.0)
    t = APTriangle(A, B, C)
    sqs = [square_inscribed(t, i) for i in 1:3]
end
(; A, B, C, t, sqs) = lxo
@svg_doc(lxm, @__FILE__, begin
sethue(julia_blue)
path(t, action=:stroke)
sethue(julia_purple)
path(sqs, action=:stroke)
sethue("white"); path([A, B, C], action=:fillpreserve); sethue(julia_blue); strokepath()
end)
