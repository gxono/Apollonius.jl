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
    c1 = APCircle2(APPoint(0.0, 0.0), 3.0)
    c2 = APCircle2(APPoint(8.0, 0.0), 2.0)
    ec = external_similitude_center(c1, c2)
    ic = internal_similitude_center(c1, c2)
    ext = external_tangent_lines(c1, c2)
    int = internal_tangent_lines(c1, c2)
end



begin
Drawing(sz.width, sz.height, "docs/src/assets/img/circles/$fmt_name")
origin()

sethue(julia_purple)
path([ext..., int...], action=:stroke)

sethue(julia_blue)
path([c1,c2], action=:stroke)

path([c1.center, c2.center])
setpoint(julia_red)

path([ec, ic])
setpoint(julia_purple)

finish()
preview()
end
