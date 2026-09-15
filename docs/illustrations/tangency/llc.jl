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
    l1 = EGLine(EGPoint(0.0, 0.0), EGPoint(0.0, 1.0))
    l2 = EGLine(EGPoint(0.0, 0.0), EGPoint(1.0, 0.0))
    c_cll = EGCircle2(EGPoint(6.0, 6.0), 2.0)

    sols_cll = tangent_circles(l1, l2, c_cll)
end


begin
Drawing(w, h, "docs/src/assets/img/tangency/$fmt_name")
origin()

sethue(julia_purple)
path(sols_cll, action=:stroke)

sethue(julia_blue)
path([l1, l2, c_cll], action=:stroke)

finish()
preview()
end