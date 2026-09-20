include("../default_config.jl")
lxm, lxo = @to_luxor_picture width=500 height=240 margin=20 begin
    pts = [APPoint(0.0, 0.0), APPoint(4.0, 0.0), APPoint(4.0, 3.0), APPoint(1.0, 3.0), APPoint(2.0, 1.0)]
    hull = convex_hull(pts)
end
(; pts, hull) = lxo
@svg_doc(lxm, @__FILE__, begin
sethue(julia_purple)
path(hull, action=:stroke)
path(pts); plot_point(julia_blue)
end)
