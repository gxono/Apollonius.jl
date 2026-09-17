begin
using Apollonius
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
    A, B, C = APPoint(0.0,0), APPoint(10,0), APPoint(7,5)
    t = APTriangle(A, B, C)
    l = APLine.(sides(t))
    ex = collect(excenters(t))
    exc = collect(excircles(t)) 
    pp = projection.(ex, [l[2], l[3], l[1]])
    rangles = APAngle2.(pp, ex, getproperty.(l, :p2))
end



begin
Drawing(sz.width, sz.height, "docs/src/assets/img/triangles/$fmt_name")
origin()

gsave()
sethue("gray80")
setdash(:dash)
setline(1)
path(l, action=:stroke)
path(APTriangle(ex...), action=:stroke)
sethue(julia_green)
setdash(:solid)
path(APSegment.(ex, pp), action=:stroke)
grestore()

sethue(julia_purple)
path(exc, action=:stroke)

sethue(julia_green)
path(reverse.(rangles), 
    action=:fill, 
    radius=7, 
    as=:rsector)

sethue(julia_blue)
path(t, action=:stroke)

path(ex)
setpoint(julia_purple)

path(vertices(t))
setpoint(julia_red)

path(pp)
setpoint(julia_green)

finish()
preview()
end
