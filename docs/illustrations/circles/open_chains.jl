include("../default_config.jl")
lxm, lxo = @prepare_to_picture width=500 height=300 margin=30 begin
    zigzag = APPolyline2(APPoint(0.0, 0.0), APPoint(2.0, 3.0), APPoint(4.0, 0.0), APPoint(6.0, 3.0))
    chain = APCurvilinearPolyline2([APSegment(APPoint(0.0, -5.0), APPoint(3.0, -5.0)), APCircularArc2(APCircle2(APPoint(3.0, -3.0), 2.0), APPoint(3.0, -5.0), APPoint(5.0, -3.0))])
end
(; zigzag, chain) = lxo
@svg_doc(lxm, @__FILE__, begin
sethue(julia_blue)
path([zigzag, chain], action=:stroke)
end)
