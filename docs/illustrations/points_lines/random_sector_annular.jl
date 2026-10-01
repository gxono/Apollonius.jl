include("../default_config.jl")
lxm, lxo = @prepare_to_picture width=560 height=300 margin=30 begin
    sector = APCircularSector2(APCircle2(APPoint(0.0, 0.0), 4.0), APPoint(4.0, 0.0), APPoint(0.0, 4.0))
    annsec = APAnnularSector2(APPoint(10.0, 0.0), 4.0, APPoint(14.0, 0.0), APPoint(10.0, 4.0), 1.5)
    sector_pts = [rand_inside(Apollonius.Random.Xoshiro(k), sector) for k in 1:250]
    annsec_pts = [rand_inside(Apollonius.Random.Xoshiro(k), annsec) for k in 1:250]
end
(; sector, annsec, sector_pts, annsec_pts) = lxo
@svg_doc(lxm, @__FILE__, begin
sethue(julia_blue)
path([sector, annsec], action=:stroke)
sethue(julia_purple)
sethue("white"); path(vcat(sector_pts, annsec_pts), radius=1.5, action=:fillpreserve); sethue(julia_purple); strokepath()
end)
