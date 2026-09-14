begin
using EuclideanGeometry
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





P = EGPoint(0.0, 0.0)
inv5 = invert(P; k=5.0)
sz = @to_luxor_picture! width=500 height=240 margin=20 begin
    P
    circ = EGCircle2(P, 5.0)
    l1 = EGLine(EGPoint(2.0, 0.0), EGPoint(2.0, 1.0))
    l2 = EGLine(EGPoint(-3.0, 0.0), EGPoint(-3.0, 1.0))
    t1, t2 = map(inv5, [l1, l2])
end


begin
Drawing(sz.width, sz.height, "docs/src/assets/img/circles/$fmt_name")
origin()

sethue("gray80")
setdash(:dash)
path(circ, action=:stroke)

sethue(julia_blue)
path(t1, action=:stroke)
setdash(:solid)
path(l1, action=:stroke)


sethue(julia_green)
path(l2, action=:stroke)
setdash(:dash)
path(t2, action=:stroke)
setdash(:solid)

path(P)
setpoint(julia_red)

finish()
preview()
end
