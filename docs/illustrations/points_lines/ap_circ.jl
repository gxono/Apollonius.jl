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
    A, B = EGPoint(0.0, 0.0), EGPoint(8.0, 0.0)
    ap = apollonius_circle(A, B, 2.0)
    Ptest1, Ptest2 = polar_point_deg.(ap.r, [50.0, 210], ap.center)
end






begin
Drawing(sz.width, sz.height, "docs/src/assets/img/points_lines/ap_circ.svg")
origin()
sethue(julia_purple)
    path(ap, action=:stroke)

    setdash(:dash)
    path([
        EGSegment(A,Ptest1), EGSegment(B,Ptest1),
        EGSegment(A,Ptest2), EGSegment(B,Ptest2),
        ], action=:stroke)
    setdash(:solid)

    path([A,B])
    setpoint(julia_red)
    path([Ptest1, Ptest2])
    setpoint(julia_purple)
    
    sethue("black")
    label("A", :NW, A)
    label("B", :NW, B)
    label("Ptest1", :NE, Ptest1)
    label("Ptest2", :SW, Ptest2)
finish()
preview()
end
