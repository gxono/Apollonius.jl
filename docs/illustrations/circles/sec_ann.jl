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
    vt1 = APVector(12.5,0)
    o1 = APPoint(0.0, 0.0)
    o2 = o1 |> translate(vt1)
    o3 = o2 |> translate(vt1)
    
    c1,c2,c3 = APCircle2.([o1,o2,o3], 5.0)

    s1, e1 = APPoint(5.0, 0.0), APPoint(0.0, 5.0)
    s2, e2 = translate.([s1, e1], vt1)
    s3, e3 = translate.([s2, e2], vt1)
    arc1 = APCircularArc2(c1, s1, e1)
    arc2 = APCircularArc2(c2, s2, e2)
    arc3 = APCircularArc2(c3, s3, e3)
    sec3 = APAnnularSector2(arc3, 2.0)
end




begin
Drawing(sz.width, sz.height, "docs/src/assets/img/circles/$fmt_name")
origin()

sethue(julia_purple)
path(APCircularSector2(arc1), action=:fill)
path(APCircularSegment2(arc2), action=:fill)
path(sec3, action=:fill)


sethue(julia_blue)
path([c1,c2,c3], action=:stroke)


path([s1,e1,s2,e2,s3,e3])
setpoint(julia_red)



finish()
preview()
end
