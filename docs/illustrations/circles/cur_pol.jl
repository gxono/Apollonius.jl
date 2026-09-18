include("../default_config.jl")
sz = @to_luxor_picture! width=500 height=240 margin=20 begin
    circ = APCircle2(APPoint(0.0, 0.0), 3.0)
    arc = APCircularArc2(circ, APPoint(0.0, 3.0), APPoint(-3.0, 0.0))
    rad1 = APSegment(APPoint(0.0, 3.0), APPoint(0.0, 0.0))
    rad2 = APSegment(APPoint(0.0, 0.0), APPoint(-3.0, 0.0))
    ct = APCurvilinearTriangle2(rad1, arc, rad2)
end
@svg_doc(sz, @__FILE__, begin
sethue(julia_blue)
path(circ, action=:stroke)
sethue(julia_purple)
path(ct, action=:fill)
sethue(julia_green)
path([arc, rad1, rad2], action=:stroke)
path([circ.center, arc.p1, arc.p2])
setpoint(julia_green)
end)
