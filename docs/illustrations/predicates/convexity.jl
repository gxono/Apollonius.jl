include("../default_config.jl")
lxm, lxo = @to_luxor_picture width=560 height=240 margin=30 begin
    convex = APStraightNgon([APPoint(0.0, 0.0), APPoint(4.0, 0.0), APPoint(5.0, 3.0), APPoint(1.0, 4.0)])
    concave = APStraightNgon([APPoint(8.0, 0.0), APPoint(12.0, 0.0), APPoint(10.5, 1.5), APPoint(12.0, 4.0), APPoint(8.0, 4.0)])
    lab = [APPoint(2.5, -1.0), APPoint(10.0, -1.0)]
end
(; convex, concave, lab) = lxo
@svg_doc(lxm, @__FILE__, begin
Luxor.fontsize(15)
sethue(julia_blue)
path([convex, concave], action=:stroke)
path(vertices(convex)); plot_point(julia_blue)
path(vertices(concave)); plot_point(julia_blue)
sethue(julia_red)
label("is_convex: true", :S, lab[1]); label("is_convex: false", :S, lab[2])
end)
