begin
using EuclideanGeometry
using Luxor: @drawsvg, @svg,
    Drawing, finish, preview, origin, 
    background, RGBA,
    sethue, setdash, setopacity, setline,
    fillpreserve, strokepath, 
    julia_blue, julia_green, julia_red, julia_purple,
    gsave, grestore,
    label
import Luxor

setpoint(color) = begin sethue("white"); fillpreserve(); sethue(color); strokepath() end

fmt_name = replace(split(@__FILE__,"\\")[end],".jl" => ".svg")
end


sz = @to_luxor_picture! flip=false width=500 height=240 margin=20 begin
    circ = EGCircle2(EGPoint(0.0, 0.0), 30.0)
    p1, p2 = EGPoint(30.0, 0.0), EGPoint(0.0, 30.0)
    arc = EGCircularArc2(circ, p1, p2)

    c1 = EGCircle2(EGPoint(0.0, 0.0), 40.0)
    c2 = EGCircle2(EGPoint(90.0, 0.0), 50.0)
    c3_center = intersection(EGCircle2(c1.center, c1.r + 35.0), EGCircle2(c2.center, c2.r + 35.0))[1]
    c3 = EGCircle2(c3_center, 35.0)
    tinv = invert(EGTriangle(EGPoint(50.0, 20.0), EGPoint(90.0, 30.0), EGPoint(60.0, 80.0)), EGPoint(0.0, 0.0), k = 100)
    gap = interstices(c1, c2, c3)
end


begin
Drawing(sz.width, sz.height, "docs/src/assets/img/drawing/$fmt_name")
origin()

sethue("steelblue"); setopacity(0.4)
path(EGCircularSector2(arc); action=:fill)
path(EGCircularSegment2(arc); action=:fill)

setopacity(1)

sethue(julia_blue)
path(circ, action=:stroke)

sethue(julia_green)
path(arc, action=:stroke)

path([c1, c2, c3], action=:stroke)

sethue("red"); setopacity(0.5)
path(gap; action=:fill)


sethue("purple"); setopacity(0.5)
path(tinv, action=:fill)

setopacity(1)
path([p1 p2])
setpoint(julia_green)

finish()
preview()
end

