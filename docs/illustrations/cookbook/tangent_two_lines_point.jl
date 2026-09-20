include("../default_config.jl")
lxm, lxo = @to_luxor_picture width=500 height=300 margin=30 begin
    l1 = APSegment(APPoint(0.0, 0.0), APPoint(12.0, 0.0))
    l2 = APSegment(APPoint(0.0, 0.0), APPoint(0.0, 12.0))
    p = APPoint(3.0, 1.0)
    sols = tangent_circles_through_point(APLine(l1.p1, l1.p2), APLine(l2.p1, l2.p2), p)
end
(; l1, l2, p, sols) = lxo
@svg_doc(lxm, @__FILE__, begin
Luxor.fontsize(15)
sethue(julia_blue)
path([l1, l2], action=:stroke)
path([p]); plot_point(julia_blue)
sethue(julia_purple)
path(sols, action=:stroke)
sethue(julia_red)
label("p", :N, p)
end)
