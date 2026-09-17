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
    P, Q, C = APPoint(1.0, 1.0), APPoint(6.0, 3.0), APPoint(3.0, 6.0)
    s = APSegment(P, Q)
    l = APLine(s)
    M = midpoint(s)
    lpa = parallel_through(l, C)
    lpe = perpendicular_through(l, C)
    lpb = perpendicular_bisector(s)
end

begin
Drawing(sz.width, sz.height, "docs/src/assets/img/points_lines/par_per_bis.svg")
origin()
sethue(julia_blue)
    path(l, action=:stroke)

    sethue(julia_purple)
    path([lpa, lpe, lpb], action=:stroke)

    path([P,Q,C])
    setpoint(julia_red)

    sethue("black")
    label("Q", :NW ,Q)
    label("P", :NW ,P)
    label("C", :SW ,C)
finish()
preview()
end
