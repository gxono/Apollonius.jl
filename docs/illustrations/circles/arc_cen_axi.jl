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

    p = APPoint(1.0, 1.0)
    l = APLine(APPoint(0.0, 0.0), APPoint(1.0, 1.0))

    arc_ref_p = reflection(arc, p)
    arc_ref_l = reflection(arc, l)
end




begin
Drawing(sz.width, sz.height, "docs/src/assets/img/circles/$fmt_name")
origin()


sethue(julia_blue)
path(arc, action=:stroke)

sethue(julia_purple)
path([arc_ref_p, arc_ref_l], action=:stroke)
setdash(:dash)
path(APSegment(arc.p1, arc_ref_l.p2), action=:stroke)
path(APSegment(arc.p2, arc_ref_l.p1), action=:stroke)
path(APSegment(arc.p2, arc_ref_p.p2), action=:stroke)
path(APSegment(arc.p1, arc_ref_p.p1), action=:stroke)
setdash(:solid)


sethue(julia_green)
path(l, action=:stroke)
path(p)
setpoint(julia_green)

path([arc.p1, arc.p2])
setpoint(julia_red)

path([arc_ref_l.p1, arc_ref_l.p2, arc_ref_p.p1, arc_ref_p.p2])
setpoint(julia_purple)

finish()
preview()
end
