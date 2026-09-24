include("../default_config.jl")
lxm, lxo = @prepare_to_picture width=500 height=300 margin=30 begin
    A, B, C = APPoint(0.0, 0.0), APPoint(8.0, 0.0), APPoint(3.0, 6.0)
    t = APTriangle(A, B, C)
    vc = van_lamoen_circle(t)
    vp = collect(van_lamoen_points(t))
    meds = [APSegment(v, midpoint(w1, w2)) for (v, w1, w2) in ((A, B, C), (B, C, A), (C, A, B))]
end
(; A, B, C, t, vc, vp, meds) = lxo
@svg_doc(lxm, @__FILE__, begin
gsave()
setline(1); setdash("dash")
sethue("gray80")
path(meds, action=:stroke)
grestore()
sethue(julia_blue)
path(t, action=:stroke)
sethue(julia_purple)
path(vc, action=:stroke)
sethue("white"); path([A, B, C], action=:fillpreserve); sethue(julia_blue); strokepath()
sethue("white"); path(vp, action=:fillpreserve); sethue(julia_purple); strokepath()
end)
