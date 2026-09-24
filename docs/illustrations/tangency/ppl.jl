include("../default_config.jl")
lxm, lxo = @prepare_to_picture width=500 height=240 margin=20 begin
    a, b = APPoint(-3.0, 0.0), APPoint(3.0, 0.0)
    l = APLine(APPoint(-5.0, -4.0), APPoint(5.0, -4.0))
    sols = tangent_circles(a, b, l)
end
(; a, b, l, sols) = lxo
@svg_doc(lxm, @__FILE__, begin
sethue(julia_purple)
path(sols, action=:stroke)
sethue(julia_blue)
path(l, action=:stroke)
sethue("white"); path([a,b], action=:fillpreserve); sethue(julia_blue); strokepath()
end)
