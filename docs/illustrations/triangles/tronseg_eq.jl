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
    p1, p2 = EGPoint(0.0, 0.0), EGPoint(6.0, 0.0)
    s = EGSegment(p1, p2)
    et = equilateral_triangle_on_segment(s)
end



begin
Drawing(sz.width, sz.height, "docs/src/assets/img/triangles/$fmt_name")
origin()

sethue(julia_purple)
path(et, action=:stroke)

sethue(julia_blue)
path(s, action=:stroke)


path(vertices(et))
setpoint(julia_purple)

finish()
preview()
end