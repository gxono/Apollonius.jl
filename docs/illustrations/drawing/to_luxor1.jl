begin
using EuclideanGeometry
using Luxor: @drawsvg, @svg,
    Drawing, finish, preview, origin, 
    background, RGBA,
    sethue, setdash, setopacity, setline,
    fillpreserve, strokepath, 
    julia_blue, julia_green, julia_red, julia_purple,
    gsave, grestore,
    label
import Luxor

setpoint(color) = begin sethue("white"); fillpreserve(); sethue(color); strokepath() end

fmt_name = replace(split(@__FILE__,"\\")[end],".jl" => ".svg")
end

t = EGTriangle(EGPoint(2.0, -5.0), EGPoint(9.0, 3.0), EGPoint(-1.0, 6.0))
circ = EGCircle2(EGPoint(4.0, 1.0), 4.0)

(w, h), (t2, circ2) = @to_luxor_picture width=500 height=240 margin=20 begin
    t
    circ
end


begin
Drawing(w, h, "docs/src/assets/img/drawing/$fmt_name")
origin()

sethue(julia_blue)
path(t2; action=:stroke)
path(circ2; action=:stroke)

finish()
preview()
end