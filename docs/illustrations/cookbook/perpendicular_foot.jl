include("../default_config.jl")
lxm, lxo = @prepare_to_picture width=500 height=280 margin=30 begin
    l = APLine(APPoint(0.0, 0.0), APPoint(4.0, 1.0))
    q = [APPoint(0.0, 0.0), APPoint(4.0, 1.0)]
    p = APPoint(3.0, 4.0)
    foot = projection(p, APLine(q[1], q[2]))
    leg = APSegment(p, foot)
end
(; l, q, p, foot, leg) = lxo
@svg_doc(lxm, @__FILE__, begin
Luxor.fontsize(15)
sethue(julia_blue)
path(l, action=:stroke, extend=400)
sethue(julia_purple)
path(leg, action=:stroke)
sethue(julia_red)
label("p", :NE, p); label("foot", :SE, foot)
sethue("white"); path([q; p], action=:fillpreserve); sethue(julia_blue); strokepath()
sethue("white"); path([foot], action=:fillpreserve); sethue(julia_purple); strokepath()
end)
