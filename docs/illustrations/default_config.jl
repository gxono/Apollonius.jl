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


macro svg_doc(sz, path, content)
    return quote
        Drawing($(esc(sz)).width, $(esc(sz)).height, $(esc(path)))
        origin()
        $(esc(content))
        finish()
    end
end
