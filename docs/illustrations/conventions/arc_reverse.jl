include("../default_config.jl")
lxm, lxo = @prepare_to_picture width=500 height=260 margin=30 begin
    arc = APCircularArc2(APCircle2(APPoint(0.0, 0.0), 3.0), APPoint(3.0, 0.0), APPoint(0.0, 3.0))
    comp = reverse(arc)
end
(; arc, comp) = lxo
@svg_doc(lxm, @__FILE__, begin
Luxor.fontsize(15)
sethue(julia_purple); setdash("dash")
path(comp, action=:stroke)
setdash("solid")

sethue(julia_blue)
path(arc, action=:stroke)

sethue(julia_red)
label("arc", :NE, point_on(arc, 0.5))
label("reverse(arc)", :SW, point_on(comp, 0.5))

sethue("white")
path([arc.p1, arc.p2], action=:fillpreserve)
sethue(julia_blue); strokepath()

end)
