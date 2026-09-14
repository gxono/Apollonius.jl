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
    P, Q, C = EGPoint(1.0, 1.0), EGPoint(6.0, 3.0), EGPoint(3.0, 6.0)
    l1 = EGLine(P,Q)
    l2 = EGLine(C,Q)
    lb1, lb2 = angle_bisectors(l1, l2)
end



begin
Drawing(sz.width, sz.height, "docs/src/assets/img/points_lines/ang_bis.svg")
origin()
sethue(julia_blue)
    path([l1, l2], action=:stroke)

    sethue(julia_purple)
    path([lb1, lb2], action=:stroke)

    path([P,Q,C])
    setpoint(julia_red)

    sethue("black")
    label("Q", :N ,Q)
    label("P", :NW ,P)
    label("C", :SW ,C)
finish()
preview()
end
