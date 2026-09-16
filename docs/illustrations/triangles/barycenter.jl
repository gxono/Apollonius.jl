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
    A, B, C = EGPoint(0.0, 0.0), EGPoint(8.0, 0.0), EGPoint(3.0, 6.0)
    t = EGTriangle(A, B, C)
    tp = trilinear_point(t, 1.0, 1.0, 1.0)
end



begin
Drawing(sz.width, sz.height, "docs/src/assets/img/triangles/$fmt_name")
origin()

gsave()
sethue(julia_green)
setdash(:dash); setline(1)
path(bisector.(t, 1:3), action=:stroke)
grestore()

sethue(julia_blue)
path([t], action=:stroke)

path(vertices(t))
setpoint(julia_red)

path(tp)
setpoint(julia_purple)



finish()
preview()
end