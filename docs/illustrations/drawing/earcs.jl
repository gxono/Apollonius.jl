begin
using Apollonius
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


sz = @to_luxor_picture! flip=false width=500 height=240 margin=20 begin
    e = APEllipse2(APPoint(0.0, 0.0), 40.0, 20.0, pi / 6)
earc = APEllipticArc2(e, point_on_ellipse(e, 0.2), point_on_ellipse(e, 2.0))

end



begin
Drawing(sz.width, sz.height, "docs/src/assets/img/drawing/$fmt_name")
origin()

sethue(julia_blue)
path(e; action=:stroke)

sethue(julia_green)
path(earc; action=:stroke)

path([earc.p1, earc.p2])
setpoint(julia_green)

finish()
preview()
end