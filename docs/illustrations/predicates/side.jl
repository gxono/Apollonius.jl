include("../default_config.jl")
lxm, lxo = @prepare_to_picture width=500 height=280 margin=30 begin
    l = APLine(APPoint(0.0, 0.0), APPoint(4.0, 2.0))
    dir = APSegment(APPoint(0.0, 0.0), APPoint(4.0, 2.0))
    left = APPoint(1.0, 3.0)
    right = APPoint(3.0, -1.0)
    on = APPoint(2.0, 1.0)
end
(; l, dir, left, right, on) = lxo
@svg_doc(lxm, @__FILE__, begin
Luxor.fontsize(15)
sethue(julia_blue)
path(l, action=:stroke, extend=40)
path(dir; as=:arrow, action=:stroke)
sethue(julia_purple)
sethue("gray80")
sethue(julia_red)
label("+1", :N, left); label("-1", :S, right); label("0", :SE, on)
sethue("white"); path([on], action=:fillpreserve); sethue(julia_blue); strokepath()
sethue("white"); path([left], action=:fillpreserve); sethue(julia_purple); strokepath()
sethue("white"); path([right], action=:fillpreserve); sethue("gray80"); strokepath()
end)
