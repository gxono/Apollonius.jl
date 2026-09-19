include("../default_config.jl")
sz = @to_luxor_picture! width=500 height=260 margin=30 begin
    arc = APCircularArc2(APCircle2(APPoint(0.0, 0.0), 3.0), APPoint(3.0, 0.0), APPoint(0.0, 3.0))
    comp = reverse(arc)
end
@svg_doc(sz, @__FILE__, begin
Luxor.fontsize(15)
sethue(julia_purple); setdash("dash"); Luxor.setline(2)
path(comp, action=:stroke)
setdash("solid")
sethue(julia_blue); Luxor.setline(3)
path(arc, action=:stroke)
sethue("black")
path([arc.p1, arc.p2])
setpoint(julia_red)
sethue("black")
label("arc", :NE, point_on_arc(arc, 0.5))
label("reverse(arc)", :SW, point_on_arc(comp, 0.5))
end)
