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
    R = 3.0
    centers = [APPoint(R * cos(pi / 2 + 2pi * k / 3), R * sin(pi / 2 + 2pi * k / 3)) for k in 0:2]
    given = [APCircle2(centers[k+1], 1.0) for k in 0:2]

    sols3 = tangent_circles(given[1], given[2], given[3])
end


begin
Drawing(w, h, "docs/src/assets/img/tangency/$fmt_name")
origin()

sethue(julia_purple)
path(sols3, action=:stroke)

sethue(julia_blue)
path(given, action=:stroke)

finish()
preview()
end