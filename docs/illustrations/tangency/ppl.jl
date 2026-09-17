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
    a, b = APPoint(-3.0, 0.0), APPoint(3.0, 0.0)
    l = APLine(APPoint(-5.0, -4.0), APPoint(5.0, -4.0))

    sols = tangent_circles_through_points(a, b, l)
end


begin
Drawing(w, h, "docs/src/assets/img/tangency/$fmt_name")
origin()

sethue(julia_purple)
path(sols, action=:stroke)

sethue(julia_blue)
path(l, action=:stroke)

path([a,b])
setpoint(julia_red)

finish()
preview()
end