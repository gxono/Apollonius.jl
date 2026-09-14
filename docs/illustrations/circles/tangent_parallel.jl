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
    c = EGCircle2(EGPoint(0.0, 0.0), 5.0)
    l = EGLine(EGPoint(0.0, 3), EGPoint(1.0, 4))
    t1, t2 = tangent_parallel(c, l)
end




begin
Drawing(sz.width, sz.height, "docs/src/assets/img/circles/$fmt_name")
origin()

sethue(julia_purple)
path([t1,t2], action=:stroke)

sethue(julia_blue)
path([c, l], action=:stroke)

path(c.center)
setpoint(julia_red)

path([t1[1], t2[1]])
setpoint(julia_purple)

finish()
preview()
end