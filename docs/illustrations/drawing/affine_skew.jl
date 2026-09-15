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
    sec = EGCircularSector2(EGCircularArc2(EGCircle2(EGPoint(0.0, 0.0), 30.0), EGPoint(30.0, 0.0), EGPoint(0.0, 30.0)))
end

skew = EGAffineMap(1.3, 0.4, -0.2, 0.9, 0.0, 0.0)


begin
Drawing(sz.width, sz.height, "docs/src/assets/img/drawing/$fmt_name")
origin()

sethue(julia_blue)
path(sec, action=:stroke)

sethue(julia_green)
path(skew(sec), action=:stroke)

finish()
preview()
end
