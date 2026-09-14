begin
using EuclideanGeometry
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
    o = EGPoint(0.0, 0.0)
    circ = EGCircle2(o, 1)
    trian = EGTriangle(EGPoint(0.5, 1.5), EGPoint(0.5, -0.5), EGPoint(2.0, 0.0))
    cp = invert(trian, o)
end




begin
Drawing(sz.width, sz.height, "docs/src/assets/img/circles/$fmt_name")
origin()

sethue("gray80")
setdash(:dash)
path(circ, action=:stroke)
setdash(:solid)

sethue(julia_blue)
path(trian, action=:stroke)

sethue(julia_purple)
path(cp, action=:stroke)

path(collect(vertices(trian)))
setpoint(julia_red)

path(circ.center)
setpoint(julia_red)

finish()
preview()
end