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
    a, b, c = APPoint(0.0, 0.0), APPoint(4.0, 0.0), APPoint(5.0, 2.0)
    d = APPoint(1.0, 0.0) 
    pa = parallelogram(a, b, c)
    ps = square_on_segment(a, b)
    pr = rectangle_on_segment(a, b, 2.0)
    pp = regular_polygon(a, d, 6)
end

begin
Drawing(sz.width, sz.height, "docs/src/assets/img/polygons/$fmt_name")
origin()

sethue(julia_purple)
path([pa, ps, pr, pp], action=:stroke)


path([a, b, c, d])
setpoint(julia_red)

finish()
preview()
end