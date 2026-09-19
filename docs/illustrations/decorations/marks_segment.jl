include("../default_config.jl")
styles = [:tick, :slash, :chevron, :cross, :circle]
sz = @to_luxor_picture! width=500 height=240 margin=20 begin
    segs = [APSegment(APPoint(4.0, 2.0 * (5 - i)), APPoint(10.0, 2.0 * (5 - i))) for i in 1:5]
    names = [APPoint(0.0, 2.0 * (5 - i)) for i in 1:5]
end
@svg_doc(sz, @__FILE__, begin
Luxor.fontsize(14)
sethue(julia_blue); Luxor.setline(1.5)
path(segs, action=:stroke)
for (s, style) in zip(segs, styles)
    path(marks(s; count=2, style=style, size=20, gap=12); action=:stroke)
end
sethue(julia_red)
for (p, style) in zip(names, styles)
    label(":" * string(style), :E, p)
end
end)
