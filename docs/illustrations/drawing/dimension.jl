include("../default_config.jl")
lxm, lxo = @to_luxor_picture width=500 height=200 margin=50 begin
    a, b = APPoint(0.0, 0.0), APPoint(7.0, 0.0)
end
(; a, b) = lxo
@svg_doc(lxm, @__FILE__, begin
Luxor.fontsize(14)
sethue(julia_blue); Luxor.setline(2)
path(APSegment(a, b), action=:stroke)
path([a, b])
plot_point(julia_blue)
sethue(julia_green); Luxor.setline(1)
Luxor.dimension(a, b; offset=40, format=d -> "7.0", textrotation=-pi / 2, textgap=25)
end)
