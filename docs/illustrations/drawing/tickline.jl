include("../default_config.jl")
lxm, lxo = @prepare_to_picture width=500 height=200 margin=50 begin
    a, b = APPoint(0.0, 0.0), APPoint(7.0, 0.0)
end
(; a, b) = lxo
@svg_doc(lxm, @__FILE__, begin
Luxor.fontsize(10)
sethue(julia_blue)
Luxor.tickline(a, b; major=7, minor=3, startnumber=0, finishnumber=7, rounding=0)
sethue("white"); path([a, b], action=:fillpreserve); sethue(julia_blue); strokepath()
end)
