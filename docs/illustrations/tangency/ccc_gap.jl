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
    c1 = EGCircle2(EGPoint(0.0, 0.0), 40.0)
    c2 = EGCircle2(EGPoint(90.0, 0.0), 50.0)
    c3_center = intersection(EGCircle2(c1.center, c1.r + 35.0), EGCircle2(c2.center, c2.r + 35.0))[1]
    c3 = EGCircle2(c3_center, 35.0)
    gaps = interstices(c1, c2, c3)
end


begin
Drawing(w, h, "docs/src/assets/img/tangency/$fmt_name")
origin()

sethue(julia_purple)
path(gaps, action=:fill)

sethue(julia_blue)
path([c1,c2,c3], action=:stroke)

finish()
preview()
end