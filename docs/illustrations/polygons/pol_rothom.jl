include("../default_config.jl")
lxm, lxo = @to_luxor_picture width=500 height=240 margin=20 begin
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
path(APAngle2(centroid(pg), pr.vertices[2], pg.vertices[2]),
    action=:fill, as=:sector, radius = 15)
grestore()
sethue(julia_purple)
path(ph, action=:stroke)
path(pr, action=:stroke)
sethue(julia_blue)
path(pg, action=:stroke)
path(centroid(pg))
path(vertices(ph))
path(vertices(pg)); plot_point(julia_blue)
path(vertices(pr)); plot_point(julia_purple)
end)
