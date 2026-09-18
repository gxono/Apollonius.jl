begin
using Apollonius
using Luxor: @drawsvg, @svg,
    Drawing, finish, preview, origin, newsubpath,
    background, RGBA,
    sethue, setdash, setopacity, setline,
    fillpreserve, strokepath, fillpath,
    julia_blue, julia_green, julia_red, julia_purple,
    gsave, grestore,
    label
import Luxor
setpoint(color) = begin sethue("white"); fillpreserve(); sethue(color); strokepath() end
end
macro svg_doc(sz, file, content)
    return quote
        local _subfolder = basename(dirname($(esc(file))))
        local _svg_name = replace(basename($(esc(file))), ".jl" => ".svg")
        Drawing($(esc(sz)).width, $(esc(sz)).height, joinpath("docs", "src", "assets", "img", _subfolder, _svg_name))
        origin()
        $(esc(content))
        finish()
        preview()
    end
end
