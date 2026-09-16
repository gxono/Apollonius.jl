begin
using EuclideanGeometry
using Luxor: Drawing, finish, preview, origin,
    sethue, setdash, setopacity, setline,
    fillpreserve, strokepath, 
    julia_blue, julia_green, julia_red, julia_purple,
    gsave, grestore,
    label
import Luxor

setpoint(color) = begin 
    sethue("white"); fillpreserve()
    sethue(color); strokepath() 
end

fmt_name = replace(split(@__FILE__,"\\")[end],".jl" => ".svg")
end




sz = @to_luxor_picture! width=500 height=240 margin=20 begin
    pg = EGStraightNgon([EGPoint(0.0, 0.0), EGPoint(4.0, 0.0), EGPoint(4.0, 3.0), EGPoint(1.0, 3.0)])
    p1, p2 = EGPoint(2.0, 1.0), EGPoint(6.0, 5.0)
end

bb = EGBoundingBox(pg)
bb2 = EGBoundingBox([p1, p2])
bi = bbox_intersection(bb, bb2)

begin
Drawing(sz.width, sz.height, "docs/src/assets/img/polygons/$fmt_name")
origin()

sethue(julia_blue)
path([bb, bb2], action=:stroke)

sethue(julia_purple)
path(bi, action=:stroke)

path([bb.min, bb.max, bb2.min, bb2.max])
setpoint(julia_red)

path([bi.min, bi.max])
setpoint(julia_purple)

finish()
preview()
end