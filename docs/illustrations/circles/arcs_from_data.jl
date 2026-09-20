include("../default_config.jl")
lxm, lxo = @to_luxor_picture width=560 height=260 margin=30 begin
    a, b, c = APPoint(0.0, 0.0), APPoint(2.0, 1.5), APPoint(4.0, 0.0)
    thr = arc_through_points(a, b, c)
    p1, p2 = APPoint(7.0, 0.0), APPoint(10.0, 0.0)
    short = arc_with_radius(p1, p2, 2.0)
    long = arc_with_radius(p1, p2, 2.0; large=true)
end
(; a, b, c, thr, p1, p2, short, long) = lxo
@svg_doc(lxm, @__FILE__, begin
Luxor.fontsize(15)
sethue(julia_blue)
sethue(julia_purple)
path([thr, short, long], action=:stroke)
sethue(julia_red)
label("a", :S, a, offset=8)
label("b", :N, b, offset=8)
label("c", :S, c, offset=8)
label("arc_with_radius", :N, midpoint(p1, p2))
path([a, b, c, p1, p2])
plot_point(julia_blue)
end)
