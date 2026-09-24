include("../default_config.jl")
lxm, lxo = @prepare_to_picture width=500 height=260 margin=30 begin
    pg = APStraightNgon([APPoint(0.0, 0.0), APPoint(4.0, 0.0), APPoint(4.0, 3.0), APPoint(1.0, 3.0)])
    on_pg = rand(Apollonius.Random.Xoshiro(1), pg, 20)
    on_box = rand(Apollonius.Random.Xoshiro(2), APBoundingBox(pg), 12)
end
(; pg, on_pg, on_box) = lxo
@svg_doc(lxm, @__FILE__, begin
box = APBoundingBox(pg)
gsave()
setline(1); setdash("dash")
sethue("gray80")
path(box, action=:stroke)
grestore()
sethue(julia_blue)
path(pg, action=:stroke)
sethue(julia_purple)
sethue("white"); path(on_pg, action=:fillpreserve); sethue(julia_purple); strokepath()
sethue("white"); path(on_box, action=:fillpreserve); sethue("gray80"); strokepath()
end)
