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

end


sz = @to_luxor_picture! width=500 height=240 margin=20 begin
    C, P = EGPoint(0.0, 0.0), EGPoint(4.0, 2.0)
    circ = EGCircle2(C, P)
end

begin
Drawing(sz.width, sz.height, "docs/src/assets/img/circles/circle_cp.svg")
origin()

sethue(julia_purple)
path(circ, action=:stroke)

path([C, P])
setpoint(julia_red)

finish()
preview()
end
