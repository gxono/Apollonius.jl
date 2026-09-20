include("../default_config.jl")
lxm, lxo = @to_luxor_picture width=500 height=300 margin=30 begin
    l1 = APSegment(APPoint(-6.0, 0.0), APPoint(6.0, 0.0))
    l2 = APSegment(APPoint(0.0, -6.0), APPoint(0.0, 6.0))
    sols = tangent_circles_with_radius(APLine(l1.p1, l1.p2), APLine(l2.p1, l2.p2), 2.0)
end
(; l1, l2, sols) = lxo
@svg_doc(lxm, @__FILE__, begin
sethue(julia_blue)
path([l1, l2], action=:stroke)
sethue(julia_purple)
path(sols, action=:stroke)
path([s.center for s in sols]); plot_point(julia_purple)
end)
