include("../default_config.jl")
lxm, lxo = @prepare_to_picture width=500 height=280 margin=30 begin
    t1 = APTriangle(APPoint(0.0, 0.0), APPoint(4.0, 0.0), APPoint(2.0, 4.0))
    t2 = APTriangle(APPoint(1.0, 1.0), APPoint(5.0, 1.0), APPoint(3.0, 5.0))
    pieces = region_symdiff(t1, t2)
end
(; t1, t2, pieces) = lxo
@svg_doc(lxm, @__FILE__, begin
sethue(julia_purple); setopacity(0.25)
path(pieces; action=:fill)
setopacity(1.0)
sethue(julia_blue)
path([t1, t2], action=:stroke)
sethue(julia_purple)
path(pieces; action=:stroke)
end)
