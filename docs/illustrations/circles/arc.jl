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
    @unbounded p1 = APPoint(8.0, 0.0)
    p2 = APPoint(0.0, 2.0)
    arc = APCircularArc2(c, p1, p2)
end
 
arc |> propertynames

begin
Drawing(sz.width, sz.height, "docs/src/assets/img/circles/$fmt_name")
origin()

sethue("gray80")
setdash(:dash)
path([APSegment(arc.circle.center, arc.p1)], action=:stroke)
path([APSegment(arc.circle.center, p1)], action=:stroke)
setdash(:solid)

sethue(julia_blue)
path(c, action=:stroke)

sethue(julia_purple)
path(arc, action=:stroke)

path([p1,p2])
setpoint(julia_red)

path([arc.p1,arc.p2])
setpoint(julia_purple)

finish()
preview()
end
