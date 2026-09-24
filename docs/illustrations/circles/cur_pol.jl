include("../default_config.jl")
lxm, lxo = @prepare_to_picture width=500 height=240 margin=20 begin
    circ = APCircle2(APPoint(0.0, 0.0), 3.0)
    arc = APCircularArc2(circ, APPoint(0.0, 3.0), APPoint(-3.0, 0.0))
    rad1 = APSegment(APPoint(0.0, 3.0), APPoint(0.0, 0.0))
    rad2 = APSegment(APPoint(0.0, 0.0), APPoint(-3.0, 0.0))
    ct = APCurvilinearTriangle2(rad1, arc, rad2)
end
(; circ, arc, rad1, rad2, ct) = lxo
@svg_doc(lxm, @__FILE__, begin
sethue(julia_blue)
path(circ, action=:stroke)
sethue(julia_purple)
path(ct, action=:fill)
sethue(julia_green)
path([arc, rad1, rad2], action=:stroke)
sethue("white"); path([circ.center, arc.p1, arc.p2], action=:fillpreserve); sethue(julia_green); strokepath()
end)
