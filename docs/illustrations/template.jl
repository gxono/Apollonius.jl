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
    
end



begin
Drawing(sz.width, sz.height, "docs/src/assets/img/points_lines/")
origin()

finish()
preview()
end