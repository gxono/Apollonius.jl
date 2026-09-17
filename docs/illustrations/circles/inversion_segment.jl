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






sz = @to_luxor_picture! width=500 height=240 margin=20 begin
    o = APPoint(0, 0)
    s1 = APSegment(APPoint(1.0, 0.5), APPoint(2.0, 1.0))
    s2 = APSegment(APPoint(0.5, -1.5), APPoint(1.5, -1.0))
    t1 = invert(s1, o)
    t2 = invert(s2, o)
    circ = APCircle2(o, 1)
end



begin
Drawing(sz.width, sz.height, "docs/src/assets/img/circles/$fmt_name")
origin()

sethue("gray80")
setdash(:dash)
path(circ, action=:stroke)
setdash(:solid)

sethue(julia_blue)
path([s1,s2], action=:stroke)

sethue(julia_purple)
path([t1, t2], action=:stroke)


path(o)
setpoint(julia_red)

finish()
preview()
end
