include("../default_config.jl")
lxm, lxo = @to_luxor_picture width=500 height=280 margin=30 begin
    c = APCircle2(APPoint(0.0, 0.0), 4.0)
    arc = APCircularArc2(c, APPoint(4.0, 0.0), APPoint(0.0, 4.0))
    sec = APCircularSector2(arc)
    @unbounded skew = APAffineMap(1.3, 0.4, -0.2, 0.9, 5.0, 0.0)
    img = skew(sec)
end
(; c, arc, sec, skew, img) = lxo
@svg_doc(lxm, @__FILE__, begin
sethue(julia_blue)
path(sec, action=:stroke)
sethue(julia_purple)
path(img, action=:stroke)
end)
