include("../default_config.jl")
lxm, lxo = @prepare_to_picture width=500 height=340 margin=30 begin
    A, B, C = APPoint(0.0, 0.0), APPoint(8.0, 0.0), APPoint(3.0, 6.0)
    t = APTriangle(A, B, C)
    cc = circumcircle(t)
    I = incenter(t)
    cev = cevian_triangle(t, I)
    ccev = circumcevian_triangle(t, I)
    segs = [APSegment(v, w) for (v, w) in zip((A, B, C), vertices(ccev))]
end
(; A, B, C, t, cc, I, cev, ccev, segs) = lxo
@svg_doc(lxm, @__FILE__, begin
sethue("gray80")
path(cc, action=:stroke)
gsave()
setline(1); setdash("dash")
sethue(julia_green)
path(segs, action=:stroke)
grestore()
sethue(julia_blue)
path(t, action=:stroke)
sethue(julia_purple)
path([cev, ccev], action=:stroke)
sethue("white"); path([A, B, C], action=:fillpreserve); sethue(julia_blue); strokepath()
sethue("white"); path(vertices(cev), action=:fillpreserve); sethue(julia_purple); strokepath()
sethue("white"); path(vertices(ccev), action=:fillpreserve); sethue(julia_purple); strokepath()
sethue("white"); path([I], action=:fillpreserve); sethue(julia_blue); strokepath()
end)
