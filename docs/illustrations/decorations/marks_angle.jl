include("../default_config.jl")
lxm, lxo = @to_luxor_picture width=500 height=200 margin=20 begin
    angs = [APAngle2(APPoint(8.0 * (i - 1), 0.0), APPoint(8.0 * (i - 1) + 6.0, 0.0), APPoint(8.0 * (i - 1) + 4.0, 4.0)) for i in 1:3]
    rays = [APSegment(a.vertex, x) for a in angs for x in (a.a, a.b)]
end
(; angs, rays) = lxo
@svg_doc(lxm, @__FILE__, begin
sethue(julia_blue); Luxor.setline(1.5)
path(rays, action=:stroke)
sethue(julia_purple)
for (i, a) in enumerate(angs)
    path(marks(a; count=i, size=26, gap=6); action=:stroke)
end
end)
