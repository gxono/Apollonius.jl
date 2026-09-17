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
    c = APPoint(0.0, 0.0)
    circ = APCircle2(c, 5.0)
    p = APPoint(13.0, 0.0)
    pts = tangent_points(circ, p)
end

begin
Drawing(sz.width, sz.height, "docs/src/assets/img/circles/circle_tanp.svg")
origin()

sethue(julia_purple)
setdash(:dash)
path(APQuadrilateral(c, pts[1], p, pts[2]), action=:stroke)

setdash(:solid)
sethue(julia_blue)
path(circ, action=:stroke)

path([p, c])
setpoint(julia_red)

path(pts)
setpoint(julia_purple)

finish()
preview()
end
