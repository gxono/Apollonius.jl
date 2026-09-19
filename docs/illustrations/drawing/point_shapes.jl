include("../default_config.jl")
lxm, lxo = @to_luxor_picture width=500 height=140 margin=40 begin
    pts = [APPoint(3.0 * i, 0.0) for i in 0:3]
end
(; pts) = lxo
shapes = (:circle, :square, :cross, :plus)
@svg_doc(lxm, @__FILE__, begin
Luxor.fontsize(14)
sethue(julia_blue); Luxor.setline(2)
for (p, s) in zip(pts, shapes)
    path(p; radius=14, as=s, action=:stroke)
end
sethue(julia_red)
for (p, s) in zip(pts, shapes)
    label(":" * string(s), :S, p + APVector(0.0, 30.0))
end
end)
