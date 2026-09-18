include("../default_config.jl")
sz = @to_luxor_picture! flip=false width=500 height=240 margin=20 begin
    sec = APCircularSector2(APCircularArc2(APCircle2(APPoint(0.0, 0.0), 30.0), APPoint(30.0, 0.0), APPoint(0.0, 30.0)))
end
skew = APAffineMap(1.3, 0.4, -0.2, 0.9, 0.0, 0.0)
@svg_doc(sz, @__FILE__, begin
sethue(julia_blue)
path(sec, action=:stroke)
sethue(julia_green)
path(skew(sec), action=:stroke)
end)
