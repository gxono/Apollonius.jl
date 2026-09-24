include("../default_config.jl")
lxm, lxo = @prepare_to_picture width=560 height=260 margin=30 begin
    pg = APStraightNgon([APPoint(0.0, 0.0), APPoint(5.0, 0.0), APPoint(6.0, 3.0), APPoint(2.5, 5.0), APPoint(-0.5, 3.0)])
    rc = round_corners(pg, 0.8)
    pl = APPolyline2(APPoint(9.0, 0.0), APPoint(13.0, 0.0), APPoint(13.0, 3.0), APPoint(10.0, 3.0))
    rp = round_corners(pl, 0.9)
end
(; pg, rc, pl, rp) = lxo
@svg_doc(lxm, @__FILE__, begin
gsave()
setline(1); setdash("dash")
sethue("gray80")
path([pg, pl], action=:stroke)
grestore()
sethue(julia_purple)
path([rc, rp], action=:stroke)
end)
