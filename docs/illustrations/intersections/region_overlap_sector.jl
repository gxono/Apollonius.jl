include("../default_config.jl")
lxm, lxo = @prepare_to_picture width=500 height=280 margin=30 begin
    sec = APCircularSector2(APCircularArc2(APCircle2(APPoint(0.0, 0.0), 3.0), APPoint(3.0, 0.0), APPoint(0.0, 3.0)))
    sc = APCircle2(APPoint(1.0, 1.0), 2.0)
    overlap = only(intersection(sec, sc; mode=:region))
end
(; sec, sc, overlap) = lxo
@svg_doc(lxm, @__FILE__, begin
sethue(julia_purple); setopacity(0.25)
path(overlap; action=:fill)
setopacity(1.0)
sethue(julia_blue)
path([sec, sc], action=:stroke)
sethue(julia_purple)
path(overlap; action=:stroke)
end)
