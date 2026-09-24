begin
using Apollonius
using Luxor
import Apollonius: rotate, translate, distance, midpoint
import Luxor: julia_red, julia_blue, julia_green, julia_purple
end
macro svg_doc(lxm, file, content)
    return quote
        local _subfolder = basename(dirname($(esc(file))))
        local _svg_name = replace(basename($(esc(file))), ".jl" => ".svg")
        Drawing($(esc(lxm)).width, $(esc(lxm)).height, joinpath("docs", "src", "assets", "img", _subfolder, _svg_name))
        origin()
        $(esc(content))
        finish()
        haskey(ENV, "APOLLONIUS_NO_PREVIEW") || preview()
    end
end
