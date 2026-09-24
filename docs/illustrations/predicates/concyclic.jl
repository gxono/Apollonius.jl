include("../default_config.jl")
lxm, lxo = @prepare_to_picture width=500 height=300 margin=30 begin
    a, b, c = APPoint(0.0, 0.0), APPoint(6.0, 0.0), APPoint(5.0, 4.0)
    cc = circumcircle(APTriangle(a, b, c))
    d = point_on(cc, 2.2)
    e = APPoint(0.0, 5.0)
end
(; a, b, c, cc, d, e) = lxo
@svg_doc(lxm, @__FILE__, begin
Luxor.fontsize(15)
gsave()
setline(1); setdash("dash")
sethue("gray80")
path(cc, action=:stroke)
grestore()
sethue(julia_blue)
sethue(julia_purple)
sethue("gray80")
sethue(julia_red)
label("a", :S, a); label("b", :S, b); label("c", :E, c); label("d", :NW, d); label("e", :N, e)
sethue("white"); path([a, b, c], action=:fillpreserve); sethue(julia_blue); strokepath()
sethue("white"); path([d], action=:fillpreserve); sethue(julia_purple); strokepath()
sethue("white"); path([e], action=:fillpreserve); sethue("gray80"); strokepath()
end)
