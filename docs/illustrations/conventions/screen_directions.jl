include("../default_config.jl")
lxm, lxo = @to_luxor_picture width=420 height=300 margin=30 begin
    O = APPoint(0.0, 0.0)
    ring = [polar_point(4.0, k * pi / 4) for k in 0:7]
end
(; O, ring) = lxo
@svg_doc(lxm, @__FILE__, begin
Luxor.fontsize(15)
sethue(julia_blue)
path([O]); plot_point(julia_blue)
sethue(julia_red)
for (n, al, p) in zip(("E", "NE", "N", "NW", "W", "SW", "S", "SE"), (:E, :NE, :N, :NW, :W, :SW, :S, :SE), ring)
    label(n, al, p)
end
end)
