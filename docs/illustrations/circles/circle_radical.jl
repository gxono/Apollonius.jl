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
    c1 = EGCircle2(EGPoint(0.0, 0.0), 3.0)
    c2 = EGCircle2(EGPoint(8.0, 0.0), 2.0)
    c3 = EGCircle2(EGPoint(3.0, 6.0), 4.0)

    ra1 = radical_axis(c1, c2)
    ra2 = radical_axis(c2, c3)
    ra3 = radical_axis(c3, c1)
    rc = radical_center(c1, c2, c3)
    rcirc = radical_circle(c1, c2, c3)
end


begin
Drawing(sz.width, sz.height, "docs/src/assets/img/circles/circle_radical.svg")
origin()

sethue("gray80")
setdash(:dash)
path(EGSegment(c1.center, c3.center), action=:stroke)
path(EGSegment(c2.center, c3.center), action=:stroke)
path([ra2, ra3], action=:stroke)

sethue(julia_purple)
path(EGSegment(c1.center, c2.center), action=:stroke)
setdash(:solid)

sethue(julia_blue)
path([c1,c2,c3], action=:stroke)


sethue(julia_purple)
path(rcirc, action=:stroke)
path(ra1, action=:stroke)

path(rc)
setpoint(julia_purple)

path([c1.center, c2.center, c3.center])
setpoint(julia_red)
finish()
preview()
end
