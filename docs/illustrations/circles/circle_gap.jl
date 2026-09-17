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
    u1 = APCircle2(APPoint(0.0, 0.0), 1.0)
    u2 = APCircle2(APPoint(2.0, 0.0), 1.0)
    u3 = APCircle2(APPoint(1.0, sqrt(3)), 1.0)

    gap = only(interstices(u1, u2, u3))
end




begin
Drawing(sz.width, sz.height, "docs/src/assets/img/circles/$fmt_name")
origin()

sethue(julia_red)
path(u1, action=:stroke)
sethue(julia_purple)
path(u2, action=:stroke)
sethue(julia_green)
path(u3, action=:stroke)

sethue(julia_blue)
path(gap, action=:fill)

finish()
preview()
end
