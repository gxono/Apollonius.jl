include("../default_config.jl")
lxm, lxo = @prepare_to_picture width=500 height=240 margin=30 begin
    l = APLine(APPoint(0.0, 0.0), APPoint(6.0, 2.0))
    longer = extend_line(l, 0.5)
    l2 = APLine(APPoint(0.0, -3.0), APPoint(6.0, -1.0))
    shorter = extend_line(l2, 0.0, -0.3)
end
(; l, longer, l2, shorter) = lxo
@svg_doc(lxm, @__FILE__, begin
sethue(julia_purple)
path(longer, action=:stroke)
path(shorter, action=:stroke)
sethue(julia_blue)
path(APSegment(l.p1, l.p2), action=:stroke)
path(APSegment(l2.p1, l2.p2), action=:stroke)
sethue("white"); path([l.p1, l.p2, l2.p1, l2.p2], action=:fillpreserve); sethue(julia_blue); strokepath()
end)
