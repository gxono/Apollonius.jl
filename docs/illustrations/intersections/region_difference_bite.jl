include("../default_config.jl")
lxm, lxo = @prepare_to_picture width=500 height=280 margin=30 begin
    disk = APCircle2(APPoint(0.0, 0.0), 3.0)
    bite = APTriangle(APPoint(2.0, -3.0), APPoint(5.0, -3.0), APPoint(2.0, 3.0))
    remainder = only(region_difference(disk, bite))
end
(; disk, bite, remainder) = lxo
@svg_doc(lxm, @__FILE__, begin
sethue(julia_purple); setopacity(0.25)
path(remainder; action=:fill)
setopacity(1.0)
sethue(julia_blue)
path([disk, bite], action=:stroke)
sethue(julia_purple)
path(remainder; action=:stroke)
end)
