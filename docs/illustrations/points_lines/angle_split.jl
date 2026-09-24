include("../default_config.jl")
lxm, lxo = @prepare_to_picture width=500 height=280 margin=30 begin
    O = APPoint(0.0, 0.0)
    P1 = APPoint(4.0, 0.0)
    P2 = APPoint(0.0, 4.0)
    ang = APAngle2(O, P1, P2)
    tri = collect(angle_trisectors(O, P1, P2))
    bray = APRay(O, first(angle_bisectors(ang)).b)
    rays = [APSegment(O, P1), APSegment(O, P2)]
end
(; O, P1, P2, ang, tri, bray, rays) = lxo
@svg_doc(lxm, @__FILE__, begin
sethue(julia_blue)
path(rays, action=:stroke)
sethue(julia_purple)
path(tri, action=:stroke, extend=40)
gsave()
setline(1); setdash("dash")
sethue(julia_green)
path(bray, action=:stroke, extend=40)
grestore()
end)
