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
    circ = APCircle2(APPoint(0.0, 0.0), 3.0)
    arc = APCircularArc2(circ, APPoint(0.0, 3.0), APPoint(-3.0, 0.0))

    eq = APEllipse2(APPoint(6.0, 0.0), 2.0, 1.0, 0.0)
    earc = APEllipticArc2(eq, APPoint(8.0, 0.0), APPoint(6.0, 1.0))
    
    s1 = APSegment(APPoint(0.0, 3.0), APPoint(6.0, 1.0))
    s2 = APSegment(APPoint(-3.0, 0.0), earc.p1)
    cq = APCurvilinearQuadrilateral2(earc, s1, arc, s2)
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
