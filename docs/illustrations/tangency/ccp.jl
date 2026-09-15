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
    c1 = EGCircle2(EGPoint(-4.0, 0.0), 1.5)
    c2 = EGCircle2(EGPoint(4.0, 0.0), 1.5)
    p = EGPoint(0.0, 1.0)

    sols_p = tangent_circles_through_point(c1, c2, p)
end


begin
Drawing(w, h, "docs/src/assets/img/tangency/$fmt_name")
origin()

sethue(julia_purple)
path(sols_p, action=:stroke)


sethue(julia_blue)
path([c1,c2], action=:stroke)

path(p)
setpoint(julia_red)

finish()
preview()
end