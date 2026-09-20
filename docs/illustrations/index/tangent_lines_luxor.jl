include("../default_config.jl")
lxm, lxo = @to_luxor_picture width=500 height=320 margin=20 begin
    circle1 = APCircle2(APPoint(300.0, 300.0), 300.0)
    circle2 = APCircle2(APPoint(900.0, 200.0), 100.0)
    el1, el2 = external_tangent_lines(circle1, circle2)
    il1, il2 = internal_tangent_lines(circle1, circle2)
    ang = APAngle2(el1.p1, circle1.center, el1.p2)
end
(; circle1, circle2, el1, el2, il1, il2, ang) = lxo
pts = [el1.p1, el1.p2, el2.p1, el2.p2, il1.p1, il1.p2, il2.p1, il2.p2]
@svg_doc(lxm, @__FILE__, begin
using Apollonius, Luxor
import Luxor: julia_red, julia_blue, julia_green, julia_purple


lxm, lxo = @to_luxor_picture width=500 height=320 margin=20 begin
    circle1 = APCircle2(APPoint(300.0, 300.0), 300.0)
    circle2 = APCircle2(APPoint(900.0, 200.0), 100.0)
    el1, el2 = external_tangent_lines(circle1, circle2)
    il1, il2 = internal_tangent_lines(circle1, circle2)
    ang = APAngle2(el1.p1, circle1.center, el1.p2)
end

(; circle1, circle2, el1, el2, il1, il2, ang) = lxo

pts = [el1.p1, el1.p2, el2.p1, el2.p2, il1.p1, il1.p2, il2.p1, il2.p2]

Drawing(lxm.width, lxm.height, :svg)
origin()

#circles
sethue(julia_blue)
path([circle1, circle2], action = :stroke)

#radius and angle
@layer begin
    sethue(julia_green); setdash(:dash)
    path(APSegment(circle1.center, el1.p1), action = :stroke)
    setopacity(0.5)
    path(ang, action = :fill, as = :rsector, radius = 20)
end

#lines
sethue(julia_purple)
path([il1, il2, el1, el2], action = :stroke)

sethue(julia_red); setdash(:solid)
label("A", :NW, circle1.center, offset=8)

sethue("white")
path(pts, action=:fillpreserve)
sethue(julia_purple); strokepath()
sethue("white")
path([circle1.center, circle2.center], action=:fillpreserve)
sethue(julia_blue); strokepath()
finish()
preview()
end)
