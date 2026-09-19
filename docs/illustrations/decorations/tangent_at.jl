include("../default_config.jl")
lxm, lxo = @to_luxor_picture width=500 height=240 margin=40 begin
    arc = APCircularArc2(APCircle2(APPoint(0.0, 0.0), 5.0), APPoint(5.0, 0.0), APPoint(-5.0, 0.0))
end
(; arc) = lxo
frames = [tangent_at(arc, t) for t in (0.0, 0.25, 0.5, 0.75, 1.0)]
@svg_doc(lxm, @__FILE__, begin
sethue(julia_blue); Luxor.setline(1.8)
path(arc, action=:stroke)
sethue(julia_purple)
for f in frames
    path(APEquipollentVector(30 * f.vector, f.point); as=:arrow, action=:stroke)
end
path([f.point for f in frames])
plot_point(julia_purple)
end)
