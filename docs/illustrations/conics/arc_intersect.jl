include("../default_config.jl")
lxm, lxo = @prepare_to_picture width=500 height=260 margin=30 begin
    e = APEllipse2(APPoint(0.0, 0.0), 5.0, 3.0)
    earc = APEllipticArc2(e, point_on(e, 0.2), point_on(e, 2.0))
    l = APSegment(APPoint(-7.0, 1.0), APPoint(7.0, 1.0))
    xs = intersection(l, earc)
end
(; e, earc, l, xs) = lxo
@svg_doc(lxm, @__FILE__, begin
gsave()
setline(1); setdash("dash")
sethue("gray80")
path(e, action=:stroke)
grestore()
sethue(julia_blue)
path([earc, l], action=:stroke)
sethue(julia_purple)
sethue("white"); path(xs, action=:fillpreserve); sethue(julia_purple); strokepath()
end)
