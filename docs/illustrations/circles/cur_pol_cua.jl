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

fmt_name = replace(split(@__FILE__,"\\")[end],".jl" => ".svg")
end


sz = @to_luxor_picture! width=500 height=240 margin=20 begin
    circ = EGCircle2(EGPoint(0.0, 0.0), 3.0)
    arc = EGCircularArc2(circ, EGPoint(0.0, 3.0), EGPoint(-3.0, 0.0))

    eq = EGEllipse2(EGPoint(6.0, 0.0), 2.0, 1.0, 0.0)
    earc = EGEllipticArc2(eq, EGPoint(8.0, 0.0), EGPoint(6.0, 1.0))
    
    s1 = EGSegment(EGPoint(0.0, 3.0), EGPoint(6.0, 1.0))
    s2 = EGSegment(EGPoint(-3.0, 0.0), earc.p1)
    cq = EGCurvilinearQuadrilateral2(earc, s1, arc, s2)
end


begin
Drawing(sz.width, sz.height, "docs/src/assets/img/circles/$fmt_name")
origin()

sethue(julia_blue)
path([eq,circ], action=:stroke)

sethue(julia_purple)
path(cq, action=:stroke)

path([s1.p1, s1.p2, s2.p1, s2.p2])
setpoint(julia_green)

finish()
preview()
end
