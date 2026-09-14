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
    p1, p2 = EGPoint(5.0, 0.0), EGPoint(0.0, 5.0)
    arc = EGCircularArc2(c, p1, p2)
end




begin
Drawing(sz.width, sz.height, "docs/src/assets/img/circles/$fmt_name")
origin()

sethue(julia_blue)
path(c, action=:stroke)

sethue(julia_purple)
path(arc, action=:stroke)

path([p1,p2])
setpoint(julia_red)

finish()
preview()
end
