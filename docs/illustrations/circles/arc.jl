include("../default_config.jl")
lxm, lxo = @prepare_to_picture width=500 height=240 margin=20 begin
    c = APCircle2(APPoint(0.0, 0.0), 5.0)
    @unbounded p1 = APPoint(8.0, 0.0)
    p2 = APPoint(0.0, 2.0)
    arc = APCircularArc2(c, p1, p2)
end
(; c, p1, p2, arc) = lxo
arc |> propertynames
@svg_doc(lxm, @__FILE__, begin
sethue("gray80")
setdash(:dash)
path([APSegment(arc.circle.center, arc.p1)], action=:stroke)
path([APSegment(arc.circle.center, p1)], action=:stroke)
setdash(:solid)
sethue(julia_blue)
path(c, action=:stroke)
sethue(julia_purple)
path(arc, action=:stroke)
sethue("white"); path([p1,p2], action=:fillpreserve); sethue(julia_blue); strokepath()
sethue("white"); path([arc.p1,arc.p2], action=:fillpreserve); sethue(julia_purple); strokepath()
end)
