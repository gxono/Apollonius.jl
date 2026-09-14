begin
using EuclideanGeometry
using Luxor: @drawsvg, @svg,
    Drawing, finish, preview, origin,
    background, RGBA,
    sethue, setdash, setopacity, setline,
    fillpreserve, strokepath, 
    julia_blue, julia_green, julia_red, julia_purple,
    gsave, grestore,
    label
import Luxor

setpoint(color) = begin sethue("white"); fillpreserve(); sethue(color); strokepath() end

fmt_name = replace(split(@__FILE__,"\\")[end],".jl" => ".svg")
end


sz = @to_luxor_picture! width=500 height=240 margin=20 begin
    A, B, C = EGPoint(0.0,0), EGPoint(10,0), EGPoint(7,5)
    t =  EGTriangle(A, B, C)
    l1, l2, l3 = EGLine.(sides(t))
    oa = orthic_axis(t)

    h1, h2, h3 = projection.([C, A, B], [l1, l2, l3])
    lh1, lh2, lh3 = EGLine(h2, h3), EGLine(h3, h1), EGLine(h1, h2)
    ih1 = intersection(lh1, l1)
    ih2 = intersection(lh2, l2)
    ih3 = intersection(lh3, l3)
end



begin
Drawing(sz.width, sz.height, "docs/src/assets/img/triangles/$fmt_name")
origin()

sethue("gray80")
setdash(:dash)
gsave()
setline(1)
h = EGSegment.([C,A,B],[h1,h2,h3])
path(h, action=:stroke)
path([l1, l2, l3], action=:stroke)
sethue(julia_green)
path([lh1, lh2, lh3], action=:stroke)
grestore()
setdash(:solid)

sethue(julia_purple)
path(oa, action=:stroke)

sethue(julia_blue)
path(t, action=:stroke)

path([h1,h2,h3])
setpoint(julia_green)

path([ih1 ih2 ih3])
setpoint(julia_purple)

path(vertices(t))
setpoint(julia_red)

finish()
preview()
end