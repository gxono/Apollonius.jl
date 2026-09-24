include("../default_config.jl")
lxm, lxo = @prepare_to_picture width=500 height=300 margin=30 begin
    A, B, C = APPoint(0.0, 0.0), APPoint(8.0, 0.0), APPoint(3.0, 6.0)
    t = APTriangle(A, B, C)
    base = collect(three_tangent_circles(t))
    inc = incircle(t)
end
(; A, B, C, t, base, inc) = lxo
@svg_doc(lxm, @__FILE__, begin
sethue("gray80")
path(inc, action=:stroke)
sethue(julia_blue)
path(t, action=:stroke)
sethue(julia_purple)
path(base, action=:stroke)
sethue("white"); path([A, B, C], action=:fillpreserve); sethue(julia_blue); strokepath()
end)
