include("../default_config.jl")
lxm, lxo = @prepare_to_picture width=500 height=240 margin=20 begin
    c = APPoint(0.0, 0.0)
    circ = APCircle2(c, 5.0)
    p = APPoint(13.0, 0.0)
    pts = tangent_points(circ, p)
end
(; c, circ, p, pts) = lxo
@svg_doc(lxm, @__FILE__, begin
sethue(julia_purple)
setdash(:dash)
path(APQuadrilateral(c, pts[1], p, pts[2]), action=:stroke)
setdash(:solid)
sethue(julia_blue)
path(circ, action=:stroke)
sethue("white"); path([p, c], action=:fillpreserve); sethue(julia_blue); strokepath()
sethue("white"); path(pts, action=:fillpreserve); sethue(julia_purple); strokepath()
end)
