include("../default_config.jl")
lxm, lxo = @to_luxor_picture width=500 height=240 margin=20 begin
    arc = APCircularArc2(APCircle2(APPoint(0.0, 0.0), 5.0), APPoint(5.0, 0.0), APPoint(-5.0, 0.0))
end
(; arc) = lxo
@svg_doc(lxm, @__FILE__, begin
sethue(julia_blue); Luxor.setline(1.5)
path(arc, action=:stroke)
sethue(julia_purple)
path(marks(arc; at=0.2, count=1, style=:tick, size=14); action=:stroke)
path(marks(arc; at=0.5, count=2, style=:chevron, size=14, gap=9); action=:stroke)
path(marks(arc; at=0.8, count=1, style=:circle, size=10); action=:stroke)
end)
