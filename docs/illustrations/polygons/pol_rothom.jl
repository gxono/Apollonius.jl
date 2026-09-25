include("../default_config.jl")
lxm, lxo = @prepare_to_picture width=500 height=240 margin=20 begin
    pg = APStraightNgon([APPoint(0.0, 0.0), APPoint(4.0, 0.0), APPoint(4.0, 3.0), APPoint(1.0, 3.0)])
    pr = rotate(pg, pi / 4, centroid(pg))
    ph = homothety(pg, 2.0)
end
(; pg, pr, ph) = lxo
@svg_doc(lxm, @__FILE__, begin
gsave()
sethue(julia_green)
setdash(:dash)
setline(1)
path(APSegment(pg.vertices[1], ph.vertices[3]), action=:stroke)
path(APSegment(pg.vertices[2], centroid(pg)), action=:stroke)
path(APSegment(pr.vertices[2], centroid(pg)), action=:stroke)
path(APCircularSector2(only(marks(APAngle2(centroid(pg), pr.vertices[2], pg.vertices[2]); size=15))),
    action=:fill)
grestore()
sethue(julia_purple)
path(ph, action=:stroke)
path(pr, action=:stroke)
sethue(julia_blue)
path(pg, action=:stroke)
path(centroid(pg))
path(vertices(ph))
sethue("white"); path(vertices(pg), action=:fillpreserve); sethue(julia_blue); strokepath()
sethue("white"); path(vertices(pr), action=:fillpreserve); sethue(julia_purple); strokepath()
end)
