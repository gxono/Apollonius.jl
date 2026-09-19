include("../default_config.jl")
lxm, lxo = @to_luxor_picture width=500 height=240 margin=20 begin
    segs = [APSegment(APPoint(0.0, 2.0 * (3 - i)), APPoint(7.0, 2.0 * (3 - i))) for i in 1:3]
    names = [APPoint(-2.5, 2.0 * (3 - i)) for i in 1:3]
    arc = APCircularArc2(APCircle2(APPoint(11.0, 0.0), 3.0), APPoint(14.0, 0.0), APPoint(8.0, 0.0))
end
(; segs, names, arc) = lxo
@svg_doc(lxm, @__FILE__, begin
Luxor.fontsize(14)
sethue(julia_blue)
path(segs, action=:stroke)
path(arc, action=:stroke)
sethue(julia_purple)
path(arrow_head(segs[1]; style=:triangle, size=14); action=:fill)
path(arrow_head(segs[2]; style=:stealth, size=14); action=:fill)
path(arrow_head(segs[3]; style=:open, size=14); action=:stroke)
path(arrow_head(arc; at=1.0, place=:tip, size=14); action=:fill)
sethue(julia_red)
for (p, style) in zip(names, (:triangle, :stealth, :open))
    label(":" * string(style), :E, p)
end
end)
