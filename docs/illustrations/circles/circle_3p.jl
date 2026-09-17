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

end


sz = @to_luxor_picture! width=500 height=240 margin=20 begin
    A, B, C = APPoint(0.0, 0.0), APPoint(4.0, 0.0), APPoint(0.0, 3.0)
    circ = APCircle2(A, B, C)
end

begin
Drawing(sz.width, sz.height, "docs/src/assets/img/circles/circle_3p.svg")
origin()

sethue(julia_purple)
path(circ, action=:stroke)

path([A,B,C])
setpoint(julia_red)

finish()
preview()
end
