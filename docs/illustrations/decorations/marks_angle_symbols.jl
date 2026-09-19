include("../default_config.jl")
styles = [:tick, :slash, :chevron, :cross, :circle]
sz = @to_luxor_picture! width=500 height=280 margin=20 begin
    angs = [APAngle2(APPoint(8.0 * mod(i - 1, 3), -6.0 * fld(i - 1, 3)), APPoint(8.0 * mod(i - 1, 3) + 6.0, -6.0 * fld(i - 1, 3)), APPoint(8.0 * mod(i - 1, 3) + 4.0, 4.0 - 6.0 * fld(i - 1, 3))) for i in 1:6]
    rays = [APSegment(a.vertex, x) for a in angs for x in (a.a, a.b)]
end
@svg_doc(sz, @__FILE__, begin
sethue(julia_blue)
path(rays, action=:stroke)
sethue(julia_red)
Luxor.setline(1.5)
# arcs and a tick that crosses both
path(marks(angs[1]; count=2, size=26, gap=6); action=:stroke)
path(marks(angs[1]; count=1, style=:tick, size=29, mark_size=14); action=:stroke)
for (a, style) in zip(angs[2:end], styles)
    path(marks(a; count=2, style=style, size=36, mark_size=16, gap=13); action=:stroke)
end
end)
