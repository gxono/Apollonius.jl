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
    o = APPoint(0.0, 0.0)
    circ = APCircle2(o, 1)
    pol = APStraightNgon([polar_point_deg(0.6, a, APPoint(0,0)) for a in 0:60:330]) |> translate(APVector(1.25,0))
    cp = invert(pol, o)
end




begin
Drawing(sz.width, sz.height, "docs/src/assets/img/circles/$fmt_name")
origin()

sethue("gray80")
setdash(:dash)
path(circ, action=:stroke)
setdash(:solid)

sethue(julia_blue)
path(pol, action=:stroke)

sethue(julia_purple)
path(cp, action=:stroke)

path(circ.center)
setpoint(julia_red)

finish()
preview()
end
