begin
using Apollonius
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
    pts = [APPoint(0.0, 0.0), APPoint(4.0, 0.0), APPoint(4.0, 3.0), APPoint(1.0, 3.0), APPoint(2.0, 1.0)]
    hull = convex_hull(pts)
end


begin
Drawing(sz.width, sz.height, "docs/src/assets/img/polygons/$fmt_name")
origin()

sethue(julia_purple)
path(hull, action=:stroke)

path(pts)
setpoint(julia_red)


finish()
preview()
end