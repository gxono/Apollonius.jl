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
    c1_ccl = EGCircle2(EGPoint(0.0, 0.0), 2.0)
    c2_ccl = EGCircle2(EGPoint(6.0, 0.0), 2.0)
    l_ccl = EGLine(EGPoint(0.0, -3.0), EGPoint(1.0, -3.0))

    sols_ccl = tangent_circles(c1_ccl, c2_ccl, l_ccl)
end


begin
Drawing(w, h, "docs/src/assets/img/tangency/$fmt_name")
origin()

sethue(julia_purple)
path(sols_ccl, action=:stroke)

sethue(julia_blue)
path([c1_ccl, c2_ccl, l_ccl], action=:stroke)

finish()
preview()
end