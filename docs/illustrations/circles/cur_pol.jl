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
    rad1 = APSegment(APPoint(0.0, 3.0), APPoint(0.0, 0.0))
    rad2 = APSegment(APPoint(0.0, 0.0), APPoint(-3.0, 0.0))

    ct = APCurvilinearTriangle2(rad1, arc, rad2)
end



begin
Drawing(sz.width, sz.height, "docs/src/assets/img/circles/$fmt_name")
origin()

sethue(julia_blue)
path(circ, action=:stroke)

sethue(julia_purple)
path(ct, action=:fill)

sethue(julia_green)
path([arc, rad1, rad2], action=:stroke)

path([circ.center, arc.p1, arc.p2])
setpoint(julia_green)

finish()
preview()
end
