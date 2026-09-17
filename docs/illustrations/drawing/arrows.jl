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
    s = APSegment(APPoint(-80.0, 0.0), APPoint(80.0, 0.0))
    l = APLine(APPoint(0.0, -60.0), APPoint(0.0, 60.0))
end



begin
Drawing(sz.width, sz.height, "docs/src/assets/img/drawing/$fmt_name")
origin()
sethue(julia_blue)

path(s, as=:arrow)
path(l, extend=0.0, as=:arrow, arrowheadlength=15)

finish()
preview()
end

