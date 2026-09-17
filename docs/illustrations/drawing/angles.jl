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


sz = @to_luxor_picture! flip=false width=500 height=240 margin=20 begin
    t = APTriangle(APPoint(-80.0, 60.0), APPoint(80.0, 60.0), APPoint(-20.0, -80.0))
    ang = APAngle2(t[2], t[1], t[3])

    tv = Apollonius.translate.(t, APVector.([0, 200, 400, 600, 800], 0))
    angv = Apollonius.translate.(ang, APVector.([0, 200, 400, 600, 800], 0))
end



begin
Drawing(sz.width, sz.height, "docs/src/assets/img/drawing/$fmt_name")
origin()
sethue(julia_blue)

path(tv, action=:stroke)

sethue(julia_purple)

path(angv[1]; as=:rays, action=:stroke)
path(angv[2]; as=:arc, action=:stroke)
path(angv[3]; as=:sector, action=:fill)
path(angv[4]; as=:rarc, action=:stroke)
path(angv[5]; as=:rsector, action=:fill) 

finish()
preview()
end

