begin
using Apollonius
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


sz = @to_luxor_picture! width=500 height=240 margin=75 begin
    A, B, C = APPoint(0.0,0), APPoint(10,0), APPoint(7,5)
    t =  APTriangle(A, B, C)
    oa = orthic_axis(t)
    ba = brocard_axis(t)
    la = lemoine_axis(t)
end



begin
Drawing(sz.width, sz.height, "docs/src/assets/img/triangles/$fmt_name")
origin()

sethue(julia_purple)
path([oa, ba, la], action=:stroke)

sethue(julia_blue)
path(t, action=:stroke)



finish()
preview()
end