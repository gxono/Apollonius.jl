begin
using Apollonius
using Luxor: @drawsvg, @svg,
    Drawing, finish, preview, origin,
    background, RGBA,
    sethue, setdash, setopacity,
    fillpreserve, strokepath, 
    julia_blue, julia_green, julia_red, julia_purple,
    gsave, grestore,
    label
import Luxor

setpoint(color) = begin sethue("white"); fillpreserve(); sethue(color); strokepath() end

fmt_name = replace(split(@__FILE__,"\\")[end],".jl" => ".svg")
end


sz = @to_luxor_picture! width=500 height=240 margin=20 begin
    c = APCircle2(APPoint(0.0, 0.0), 5.0)
    p1, p2 = APPoint(0.0, 1.0), APPoint(-2.0, 0.0)
    arc = APCircularArc2(c, p1, p2)

    arc_rot = rotate(arc, 2pi/3)
    arc_hom = homothety(arc, -2.0)
end




begin
Drawing(sz.width, sz.height, "docs/src/assets/img/circles/$fmt_name")
origin()


sethue(julia_purple)
path(APAngle2(arc.circle.center, arc_rot.p1, arc.p1), action=:fill, as=:sector)
setdash(:dash)
path(APSegment(arc.circle.center, arc_rot.p1), action=:stroke)
path(APSegment(arc.circle.center, arc_hom.p1), action=:stroke)
sethue(julia_red)
path(APSegment(arc.circle.center, arc.p1), action=:stroke)
setdash(:solid)

sethue(julia_blue)
path(arc, action=:stroke)

sethue(julia_purple)
path([arc_rot, arc_hom], action=:stroke)

path([arc_rot.p1, arc_hom.p1])
setpoint(julia_purple)

path([arc.circle.center, arc.p1])
setpoint(julia_red)

finish()
preview()
end
